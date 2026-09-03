import json

from django.utils import timezone
from django.db import IntegrityError, models, transaction
from rest_framework import exceptions, filters, permissions, status, views, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.billing.providers import (
    apply_verified_payment_event,
    normalize_payment_event,
    verify_webhook_signature,
)
from apps.billing.pricing import resolve_market_zone
from apps.billing.payout_services import (
    approve_payout_request,
    create_payout_request,
    mark_payout_paid,
    producer_balance,
    reject_payout_request,
    set_global_remuneration,
    set_producer_remuneration,
)
from apps.billing.serializers import (
    PaymentSerializer,
    PayoutRejectSerializer,
    PayoutReviewSerializer,
    ProducerPayoutRequestSerializer,
    RemunerationToggleSerializer,
    SubscriptionPlanSerializer,
    SubscriptionPlanAdminSerializer,
    SubscriptionPlanOfferAdminSerializer,
    SubscriptionSerializer,
)
from apps.common.permissions import IsAdminOrReadOnly
from core.models import Payment, PaymentWebhookEvent, ProducerPayoutRequest, Subscription, SubscriptionPlan, SubscriptionPlanOffer


class SubscriptionPlanViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionPlanSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['display_order', 'price', 'created_at']
    ordering = ['display_order']

    def _market_context(self):
        user = self.request.user
        country_code = (
            getattr(user, 'country_code', '')
            if user.is_authenticated
            else ''
        )
        zone = resolve_market_zone(country_code)

        regional_offers = SubscriptionPlanOffer.objects.filter(
            zone=zone,
            is_active=True,
            plan__is_active=True,
        )

        return zone, regional_offers

    def get_queryset(self):
        queryset = SubscriptionPlan.objects.all().order_by('display_order')

        user = self.request.user
        is_staff = user.is_authenticated and user.is_staff

        # L'administration doit pouvoir voir et gérer tous les plans.
        if is_staff:
            return queryset

        queryset = queryset.filter(is_active=True)

        zone, regional_offers = self._market_context()

        # Sécurité commerciale :
        # une offre payante n'est publique que si une grille active
        # existe explicitement pour la zone de l'utilisateur.
        #
        # Les plans gratuits restent disponibles indépendamment
        # de la grille régionale.
        regional_plan_ids = regional_offers.values_list(
            'plan_id',
            flat=True,
        )

        return queryset.filter(
            models.Q(slug='free-30-days')
            | models.Q(id__in=regional_plan_ids)
        ).distinct()

    @action(detail=False, methods=['get'], url_path='best-price')
    def best_price(self, request):
        """Return the cheapest active paid offer for the user's market."""

        user = request.user
        is_staff = user.is_authenticated and user.is_staff

        # Pour un administrateur, on conserve le comportement de gestion
        # basé sur les plans globaux.
        if is_staff:
            plan = (
                SubscriptionPlan.objects
                .filter(is_active=True, price__gt=0)
                .order_by('price', 'display_order')
                .first()
            )

            if plan is None:
                return Response(
                    {'detail': "Aucun plan d'abonnement payant actif."},
                    status=status.HTTP_404_NOT_FOUND,
                )

            return Response({
                'best_price': str(plan.price),
                'currency': plan.currency,
            })

        zone, regional_offers = self._market_context()

        offer = (
            regional_offers
            .filter(price__gt=0)
            .select_related('plan')
            .order_by('price', 'display_order')
            .first()
        )

        if offer is None:
            return Response(
                {
                    'detail': (
                        "Aucune offre payante n'est actuellement "
                        "disponible pour votre zone."
                    ),
                    'market_zone': zone,
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response({
            'best_price': str(offer.price),
            'currency': offer.currency,
            'market_zone': zone,
            'plan_slug': offer.plan.slug,
        })


class SubscriptionPlanAdminViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionPlanAdminSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    search_fields = [
        'name',
        'slug',
        'description',
    ]
    ordering_fields = [
        'display_order',
        'price',
        'duration_days',
        'created_at',
        'updated_at',
    ]
    ordering = ['display_order']

    def get_queryset(self):
        return SubscriptionPlan.objects.all().order_by('display_order')


class SubscriptionPlanOfferAdminViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionPlanOfferAdminSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    search_fields = [
        'plan__name',
        'plan__slug',
        'zone',
        'currency',
    ]
    ordering_fields = [
        'zone',
        'price',
        'display_order',
        'created_at',
        'updated_at',
    ]
    ordering = ['zone', 'display_order', 'price']

    def get_queryset(self):
        queryset = (
            SubscriptionPlanOffer.objects
            .select_related('plan')
            .all()
        )

        zone = self.request.query_params.get('zone')
        plan = self.request.query_params.get('plan')
        is_active = self.request.query_params.get('is_active')

        if zone:
            queryset = queryset.filter(zone=zone.strip().upper())

        if plan:
            queryset = queryset.filter(
                models.Q(plan_id=plan)
                | models.Q(plan__slug=plan)
            )

        if is_active is not None:
            normalized = is_active.strip().lower()

            if normalized in {'true', '1', 'yes'}:
                queryset = queryset.filter(is_active=True)
            elif normalized in {'false', '0', 'no'}:
                queryset = queryset.filter(is_active=False)

        return queryset

    def destroy(self, request, *args, **kwargs):
        # Une grille tarifaire ne doit jamais être supprimée
        # physiquement : les abonnements historiques peuvent
        # conserver une référence vers cette offre.
        offer = self.get_object()

        if offer.is_active:
            offer.is_active = False
            offer.save(
                update_fields=[
                    'is_active',
                    'updated_at',
                ]
            )

        return Response(
            {
                'status': 'deactivated',
                'id': str(offer.id),
            },
            status=status.HTTP_200_OK,
        )


class SubscriptionViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['started_at', 'expires_at', 'created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        queryset = (
            Subscription.objects.filter(user=self.request.user)
            .select_related('plan')
            .order_by('-created_at')
        )
        status_name = self.request.query_params.get('status')
        if status_name:
            queryset = queryset.filter(status=status_name)
        return queryset


class PaymentViewSet(viewsets.ModelViewSet):
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['paid_at', 'created_at', 'amount']
    ordering = ['-created_at']

    def get_queryset(self):
        queryset = (
            Payment.objects.filter(subscription__user=self.request.user)
            .select_related('subscription', 'subscription__plan')
            .order_by('-created_at')
        )
        status_name = self.request.query_params.get('status')
        if status_name:
            queryset = queryset.filter(status=status_name)
        return queryset


class ProducerPayoutRequestViewSet(viewsets.ModelViewSet):
    serializer_class = ProducerPayoutRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['created_at', 'amount_eur', 'paid_at']
    ordering = ['-created_at']

    def get_permissions(self):
        if self.action in {
            'approve',
            'reject',
            'mark_paid',
            'set_global_remuneration',
            'set_producer_remuneration',
        }:
            return [permissions.IsAdminUser()]
        return super().get_permissions()

    def get_queryset(self):
        queryset = (
            ProducerPayoutRequest.objects.select_related('producer', 'reviewed_by')
            .order_by('-created_at')
        )
        if not self.request.user.is_staff:
            queryset = queryset.filter(producer=self.request.user)
        status_name = self.request.query_params.get('status')
        if status_name:
            queryset = queryset.filter(status=status_name)
        return queryset

    def perform_create(self, serializer):
        if not getattr(self.request.user, 'is_producer', False):
            raise exceptions.PermissionDenied('Un compte producteur est requis.')
        payout = create_payout_request(
            producer=self.request.user,
            payout_method=serializer.validated_data.get('payout_method', ''),
            payout_account=serializer.validated_data.get('payout_account', ''),
            producer_note=serializer.validated_data.get('producer_note', ''),
        )
        serializer.instance = payout

    @action(detail=False, methods=['get'])
    def balance(self, request):
        producer = request.user
        if request.user.is_staff and request.query_params.get('producer'):
            from core.models import User

            producer = User.objects.get(pk=request.query_params['producer'], is_producer=True)
        if not getattr(producer, 'is_producer', False):
            raise exceptions.PermissionDenied('Un compte producteur est requis.')
        return Response(producer_balance(producer))

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def approve(self, request, pk=None):
        serializer = PayoutReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payout = approve_payout_request(
            ProducerPayoutRequest.objects.select_for_update().get(pk=pk),
            reviewer=request.user,
            reason=serializer.validated_data.get('reason', ''),
        )
        return Response(self.get_serializer(payout).data)

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def reject(self, request, pk=None):
        serializer = PayoutRejectSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payout = reject_payout_request(
            ProducerPayoutRequest.objects.select_for_update().get(pk=pk),
            reviewer=request.user,
            reason=serializer.validated_data['reason'],
        )
        return Response(self.get_serializer(payout).data)

    @action(detail=True, methods=['post'], url_path='mark-paid')
    @transaction.atomic
    def mark_paid(self, request, pk=None):
        serializer = PayoutReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payout = mark_payout_paid(
            ProducerPayoutRequest.objects.select_for_update().get(pk=pk),
            reviewer=request.user,
            reason=serializer.validated_data.get('reason', ''),
        )
        return Response(self.get_serializer(payout).data)

    @action(detail=False, methods=['post'], url_path='set-global-remuneration')
    def set_global_remuneration(self, request):
        serializer = RemunerationToggleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        setting = set_global_remuneration(serializer.validated_data['enabled'])
        return Response({
            'remuneration_enabled': setting.remuneration_enabled,
            'rate_per_1000_views_eur': setting.rate_per_1000_views_eur,
        })

    @action(detail=False, methods=['post'], url_path='set-producer-remuneration')
    def set_producer_remuneration(self, request):
        serializer = RemunerationToggleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        producer = set_producer_remuneration(
            serializer.validated_data['producer_id'],
            serializer.validated_data['enabled'],
        )
        return Response({
            'producer_id': str(producer.id),
            'producer_email': producer.email,
            'producer_remuneration_enabled': producer.producer_remuneration_enabled,
        })


class PaymentWebhookView(views.APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request, provider):
        provider = provider.lower()
        raw_body = request.body
        headers = {
            key.lower(): value
            for key, value in request.headers.items()
        }

        signature_valid = verify_webhook_signature(
            provider,
            raw_body,
            headers,
        )

        if provider == 'stripe':
            try:
                payload = json.loads(raw_body.decode('utf-8'))
            except (UnicodeDecodeError, json.JSONDecodeError):
                return Response(
                    {'detail': 'Payload Stripe invalide.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            payload = (
                request.data
                if isinstance(request.data, dict)
                else {}
            )

        normalized = normalize_payment_event(provider, payload)

        # Un webhook invalide ne doit jamais reserver
        # un vrai event_id dans la table d'idempotence.
        if not signature_valid:
            webhook_event = PaymentWebhookEvent.objects.create(
                provider=provider,
                event_id='',
                event_type=normalized.event_type,
                provider_reference=normalized.provider_reference,
                payload=payload,
                headers=headers,
                signature_valid=False,
                error_message=(
                    'Signature webhook invalide ou secret non configure.'
                ),
            )

            return Response(
                {'detail': webhook_event.error_message},
                status=status.HTTP_400_BAD_REQUEST,
            )

        event_id = normalized.event_id or ''

        # Certains fournisseurs peuvent ne pas fournir
        # d'identifiant d'evenement exploitable.
        if not event_id:
            webhook_event = PaymentWebhookEvent.objects.create(
                provider=provider,
                event_id='',
                event_type=normalized.event_type,
                provider_reference=normalized.provider_reference,
                payload=payload,
                headers=headers,
                signature_valid=True,
            )

            payment, error = apply_verified_payment_event(
                provider,
                normalized,
                payload,
            )

            if payment:
                webhook_event.payment = payment
                webhook_event.processed = True
                webhook_event.processed_at = timezone.now()
                webhook_event.save(
                    update_fields=[
                        'payment',
                        'processed',
                        'processed_at',
                        'updated_at',
                    ]
                )

                return Response(
                    {'status': 'processed'},
                    status=status.HTTP_200_OK,
                )

            webhook_event.error_message = error
            webhook_event.processed_at = timezone.now()
            webhook_event.save(
                update_fields=[
                    'error_message',
                    'processed_at',
                    'updated_at',
                ]
            )

            return Response(
                {
                    'status': 'processing_failed',
                    'detail': error,
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        try:
            with transaction.atomic():
                webhook_event = (
                    PaymentWebhookEvent.objects
                    .select_for_update()
                    .filter(
                        provider=provider,
                        event_id=event_id,
                    )
                    .first()
                )

                if webhook_event and webhook_event.processed:
                    return Response(
                        {'status': 'duplicate'},
                        status=status.HTTP_200_OK,
                    )

                if webhook_event is None:
                    webhook_event = PaymentWebhookEvent.objects.create(
                        provider=provider,
                        event_id=event_id,
                        event_type=normalized.event_type,
                        provider_reference=normalized.provider_reference,
                        payload=payload,
                        headers=headers,
                        signature_valid=True,
                    )
                else:
                    webhook_event.event_type = normalized.event_type
                    webhook_event.provider_reference = (
                        normalized.provider_reference
                    )
                    webhook_event.payload = payload
                    webhook_event.headers = headers
                    webhook_event.signature_valid = True
                    webhook_event.error_message = ''
                    webhook_event.save(
                        update_fields=[
                            'event_type',
                            'provider_reference',
                            'payload',
                            'headers',
                            'signature_valid',
                            'error_message',
                            'updated_at',
                        ]
                    )

                payment, error = apply_verified_payment_event(
                    provider,
                    normalized,
                    payload,
                )

                if payment:
                    webhook_event.payment = payment
                    webhook_event.processed = True
                    webhook_event.processed_at = timezone.now()
                    webhook_event.error_message = ''
                    webhook_event.save(
                        update_fields=[
                            'payment',
                            'processed',
                            'processed_at',
                            'error_message',
                            'updated_at',
                        ]
                    )

                    return Response(
                        {'status': 'processed'},
                        status=status.HTTP_200_OK,
                    )

                webhook_event.error_message = error
                webhook_event.processed_at = timezone.now()
                webhook_event.save(
                    update_fields=[
                        'error_message',
                        'processed_at',
                        'updated_at',
                    ]
                )

                return Response(
                    {
                        'status': 'processing_failed',
                        'detail': error,
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

        except IntegrityError:
            existing = PaymentWebhookEvent.objects.filter(
                provider=provider,
                event_id=event_id,
            ).first()

            if existing and existing.processed:
                return Response(
                    {'status': 'duplicate'},
                    status=status.HTTP_200_OK,
                )

            return Response(
                {
                    'detail': (
                        'Webhook deja en cours de traitement.'
                    )
                },
                status=status.HTTP_409_CONFLICT,
            )

