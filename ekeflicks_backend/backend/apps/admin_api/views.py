import hashlib
from datetime import timedelta

from django.contrib.auth import authenticate
from django.contrib.auth.models import Group, Permission
from django.db import transaction
from django.db.models import Count, Prefetch, Sum, Q
from django.db.models.functions import TruncDay, TruncMonth, TruncWeek, TruncYear
from django.utils import timezone
from rest_framework import exceptions, generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from apps.notifications.services import notify_staff, notify_user

from apps.admin_api.security import AdminPermission, audit, provisioning_uri, verify_totp
from apps.admin_api.serializers import (
    AdminContentSerializer, AdminSessionSerializer, AdminStaffCreateSerializer,
    AdminUserDetailSerializer, AdminUserSerializer, AdminUserUpdateSerializer,
    AdminVideoAssetSerializer, AdminPayoutSerializer, CriticalPayoutSerializer, PermissionSerializer,
    RoleAssignmentSerializer, RoleSerializer,
)
from apps.auth.serializers import AccountClosureRequestSerializer, EmailChangeSupportRequestSerializer
from core.models.users import AccountClosureRequest, AdminMFADevice, EmailChangeSupportRequest, User, UserSession
from core.models.content import Content
from core.models.streaming import VideoAsset
from core.models.subscriptions import Payment, Subscription
from core.models.subscriptions import ProducerPayoutRequest
from apps.billing.payout_services import approve_payout_request, mark_payout_paid, reject_payout_request
from apps.billing.serializers import PayoutRejectSerializer, PayoutReviewSerializer
from core.models.notifications import Notification


def token_hash(value):
    return hashlib.sha256(value.encode()).hexdigest()


def issue_session(user, request):
    refresh = RefreshToken.for_user(user)
    expires_at = timezone.now() + timedelta(seconds=int(refresh['exp']) - int(timezone.now().timestamp()))
    session = UserSession.objects.create(
        user=user,
        device_id=request.data.get('device_id', '')[:255],
        device_type=request.data.get('device_type', 'admin-web')[:50],
        expires_at=expires_at,
        is_admin=True,
    )
    refresh['sid'] = session.pk
    access = refresh.access_token
    access['sid'] = session.pk
    value = str(refresh)
    session.refresh_token = token_hash(value)
    session.save(update_fields=['refresh_token'])
    return session, value, str(access)


def serialize_admin_notification(notification):
    return {
        'id': str(notification.pk), 'title': notification.title,
        'message': notification.message, 'data': notification.data,
        'is_read': notification.is_read, 'created_at': notification.created_at,
    }


class AdminLoginView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = 'login'

    def post(self, request):
        user = authenticate(request, email=request.data.get('email'), password=request.data.get('password'))
        if not user or not user.is_active or not user.is_staff:
            raise exceptions.AuthenticationFailed('Identifiants administrateur incorrects.')
        try:
            device = user.admin_mfa_device
        except AdminMFADevice.DoesNotExist as exc:
            raise exceptions.AuthenticationFailed('Le MFA doit être configuré par un super-administrateur.') from exc
        if not device.confirmed_at or not verify_totp(device, request.data.get('otp', '')):
            raise exceptions.AuthenticationFailed('Code MFA invalide ou déjà utilisé.')
        session, refresh, access = issue_session(user, request)
        return Response({'access': access, 'refresh': refresh, 'session_id': session.pk, 'user': AdminUserSerializer(user).data})


class AdminMFAConfirmView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = 'login'

    def post(self, request):
        user = authenticate(request, email=request.data.get('email'), password=request.data.get('password'))
        if not user or not user.is_active or not user.is_staff:
            raise exceptions.AuthenticationFailed('Identifiants administrateur incorrects.')
        try:
            device = user.admin_mfa_device
        except AdminMFADevice.DoesNotExist as exc:
            raise exceptions.AuthenticationFailed('Aucun enrôlement MFA en attente.') from exc
        if device.confirmed_at:
            raise exceptions.ValidationError({'detail': 'Le MFA est déjà confirmé.'})
        if not verify_totp(device, request.data.get('otp', '')):
            raise exceptions.AuthenticationFailed('Code MFA invalide.')
        device.confirmed_at = timezone.now()
        device.save(update_fields=['confirmed_at', 'updated_at'])
        return Response({'detail': 'MFA confirmé. Vous pouvez vous connecter.'})


class AdminRefreshView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    @transaction.atomic
    def post(self, request):
        value = request.data.get('refresh', '')
        try:
            old = RefreshToken(value)
            session = UserSession.objects.select_for_update().select_related('user').get(
                pk=old.get('sid'), is_active=True, is_admin=True,
            )
        except Exception as exc:
            raise exceptions.AuthenticationFailed('Session expirée ou révoquée.') from exc
        if (not session.user.is_active or not session.user.is_staff
                or not hashlib.sha256(value.encode()).hexdigest() == session.refresh_token
                or session.expires_at <= timezone.now()):
            raise exceptions.AuthenticationFailed('Session expirée ou révoquée.')
        try:
            old.blacklist()
        except AttributeError:
            pass
        session.is_active = False
        session.save(update_fields=['is_active'])
        new_session, refresh, access = issue_session(session.user, request)
        return Response({'access': access, 'refresh': refresh, 'session_id': new_session.pk})


class SessionViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated, AdminPermission]
    serializer_class = AdminSessionSerializer

    def get_queryset(self):
        return UserSession.objects.filter(user=self.request.user).order_by('-created_at')

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['session_id'] = getattr(self.request.auth, 'payload', {}).get('sid')
        return context

    @action(detail=True, methods=['post'])
    def revoke(self, request, pk=None):
        session = self.get_object()
        session.is_active = False
        session.refresh_token = ''
        session.save(update_fields=['is_active', 'refresh_token'])
        audit(request, 'session.revoke', session)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['post'], url_path='revoke-all')
    def revoke_all(self, request):
        count = self.get_queryset().filter(is_active=True).update(is_active=False, refresh_token='')
        audit(request, 'session.revoke_all', request.user, {'count': count})
        return Response({'revoked': count})


class AdminUserViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AdminUserSerializer
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = 'core.view_user'

    def get_queryset(self):
        queryset = User.objects.prefetch_related('groups').order_by('-created_at')
        kind = self.request.query_params.get('kind')
        if kind == 'producer': queryset = queryset.filter(is_producer=True)
        if kind == 'customer': queryset = queryset.filter(is_producer=False, is_staff=False)
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(email__icontains=search) | Q(firstname__icontains=search) |
                Q(lastname__icontains=search) | Q(phone__icontains=search) |
                Q(country_code__icontains=search) | Q(producer_company__icontains=search)
            )
        return queryset

    def get_required_permission(self):
        if self.action in ('roles', 'create_staff'):
            return None
        if self.action in ('set_status', 'update_details'):
            return 'core.change_user'
        if self.action == 'payments':
            return 'core.view_payment'
        return self.required_permission

    def get_serializer_class(self):
        return AdminUserDetailSerializer if self.action == 'retrieve' else AdminUserSerializer

    @action(detail=True, methods=['patch'], url_path='details')
    def update_details(self, request, pk=None):
        user = self.get_object()
        serializer = AdminUserUpdateSerializer(user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        audit(request, 'user.details', user, {'fields': list(serializer.validated_data)})
        notify_user(user, 'admin_profile_updated', title='Profil mis à jour',
                    message='Vos informations de compte ont été mises à jour par un administrateur.',
                    email_enabled=False)
        return Response(AdminUserDetailSerializer(user).data)

    @action(detail=True, methods=['delete'], url_path='delete-account')
    def delete_account(self, request, pk=None):
        if not request.user.is_superuser:
            raise exceptions.PermissionDenied('Suppression réservée au super-administrateur.')
        user = self.get_object()
        if user == request.user or user.is_superuser:
            raise exceptions.PermissionDenied('Ce compte ne peut pas être supprimé.')
        audit(request, 'user.delete', user, {'email': user.email})
        notify_staff('admin_user_deleted', title='Compte supprimé',
                     message=f'Le compte {user.email} a été supprimé par {request.user.email}.',
                     data={'actor_id': request.user.pk})
        user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['get'])
    def payments(self, request, pk=None):
        user = self.get_object()
        rows = Payment.objects.filter(subscription__user=user).order_by('-created_at')[:100]
        return Response([{
            'id': payment.pk, 'amount': payment.amount, 'currency': payment.currency,
            'status': payment.status, 'provider': payment.provider,
            'paid_at': payment.paid_at, 'created_at': payment.created_at,
        } for payment in rows])

    @action(detail=False, methods=['post'], url_path='staff')
    @transaction.atomic
    def create_staff(self, request):
        if not request.user.is_superuser:
            raise exceptions.PermissionDenied('Seul un super-administrateur peut créer un administrateur.')
        serializer = AdminStaffCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        role = Group.objects.get(name=serializer.validated_data['role'])
        user = User.objects.create_user(
            email=serializer.validated_data['email'],
            password=serializer.validated_data['password'],
            firstname=serializer.validated_data.get('firstname', ''),
            lastname=serializer.validated_data.get('lastname', ''),
            is_staff=True,
        )
        user.groups.add(role)
        device = AdminMFADevice.objects.create(user=user)
        audit(request, 'admin.create', user, {'role': role.name})
        notify_staff('admin_staff_created', title='Nouvel administrateur',
                     message=f'{user.email} a rejoint le rôle {role.name}.',
                     data={'user_id': user.pk, 'role': role.name})
        return Response({
            'user': AdminUserSerializer(user).data,
            'mfa_provisioning_uri': provisioning_uri(device),
            'mfa_confirmation_required': True,
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['patch'], url_path='status')
    def set_status(self, request, pk=None):
        user = self.get_object()
        if user.is_superuser and user != request.user:
            raise exceptions.PermissionDenied('Un super-administrateur ne peut être suspendu ici.')
        serializer = AdminUserSerializer(user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        allowed = {'is_active', 'is_verified'}
        unexpected = set(request.data) - allowed
        if unexpected:
            raise exceptions.ValidationError({'detail': f"Champs interdits : {', '.join(sorted(unexpected))}."})
        user = serializer.save()
        if not user.is_active:
            UserSession.objects.filter(user=user, is_active=True).update(is_active=False, refresh_token='')
        audit(request, 'user.status', user, {'fields': serializer.validated_data})
        state = 'réactivé' if user.is_active else 'suspendu'
        notify_user(user, 'admin_account_status', title=f'Compte {state}',
                    message=f'Votre compte a été {state} par l’administration.', email_enabled=False)
        notify_staff('admin_account_status', title=f'Compte {state}',
                     message=f'{user.email} a été {state} par {request.user.email}.',
                     data={'user_id': user.pk, 'is_active': user.is_active})
        return Response(AdminUserSerializer(user).data)

    @action(detail=True, methods=['put'], permission_classes=[IsAuthenticated, AdminPermission])
    def roles(self, request, pk=None):
        if not request.user.is_superuser:
            raise exceptions.PermissionDenied('Seul un super-administrateur peut affecter des rôles.')
        serializer = RoleAssignmentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = self.get_object()
        user.groups.set(serializer.validated_data['roles'])
        user.is_staff = True
        user.save(update_fields=['is_staff'])
        audit(request, 'user.roles', user, {'roles': [r.name for r in serializer.validated_data['roles']]})
        return Response(AdminUserSerializer(user).data)


class RoleViewSet(viewsets.ModelViewSet):
    queryset = Group.objects.prefetch_related('permissions').order_by('name')
    serializer_class = RoleSerializer
    permission_classes = [IsAuthenticated, AdminPermission]

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        if not request.user.is_superuser:
            raise exceptions.PermissionDenied('Gestion réservée au super-administrateur.')

    def perform_create(self, serializer):
        role = serializer.save()
        audit(self.request, 'role.create', role, {'permissions': list(role.permissions.values_list('codename', flat=True))})

    def perform_update(self, serializer):
        role = serializer.save()
        audit(self.request, 'role.update', role, {'permissions': list(role.permissions.values_list('codename', flat=True))})

    def perform_destroy(self, instance):
        if instance.name in {'Modérateur', 'Finance', 'Support'}:
            raise exceptions.ValidationError({
                'detail': 'Un rôle de base ne peut pas être supprimé. Ses permissions restent modifiables.'
            })
        audit(self.request, 'role.delete', instance, {'name': instance.name})
        instance.delete()


class PermissionListView(generics.ListAPIView):
    queryset = Permission.objects.select_related('content_type').order_by('content_type__app_label', 'codename')
    serializer_class = PermissionSerializer
    permission_classes = [IsAuthenticated, AdminPermission]

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        if not request.user.is_superuser:
            raise exceptions.PermissionDenied('Permissions réservées au super-administrateur.')


class AdminSubscriptionListView(generics.ListAPIView):
    """Vue comptable des abonnements, avec agrégats pour le tableau admin."""
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = 'core.view_subscription'
    pagination_class = None

    def get(self, request, *args, **kwargs):
        queryset = Subscription.objects.select_related('user', 'plan').prefetch_related(
            Prefetch('payments', queryset=Payment.objects.order_by('-created_at'))
        ).order_by('-created_at')
        search = request.query_params.get('search', '').strip()
        subscription_status = request.query_params.get('status')
        if search:
            queryset = queryset.filter(
                Q(user__email__icontains=search) | Q(user__firstname__icontains=search) |
                Q(user__lastname__icontains=search) | Q(plan__name__icontains=search)
            )
        if subscription_status:
            queryset = queryset.filter(status=subscription_status)

        totals = Subscription.objects.values('status').annotate(count=Count('id'))
        period = request.query_params.get('period', 'month')
        truncation = {
            'day': TruncDay, 'week': TruncWeek, 'month': TruncMonth, 'year': TruncYear,
        }.get(period, TruncMonth)
        successful_payments = Payment.objects.filter(status='success')
        revenue = successful_payments.aggregate(total=Sum('amount'))['total'] or 0
        revenue_history = list(
            successful_payments.annotate(period=truncation('paid_at')).values('period', 'currency')
            .annotate(amount=Sum('amount'), transactions=Count('id')).order_by('period')
        )
        results = [{
            'id': str(row.pk),
            'user_id': str(row.user_id),
            'email': row.user.email,
            'name': f'{row.user.firstname} {row.user.lastname}'.strip(),
            'plan': row.plan.name,
            'price': row.plan.price,
            'currency': row.plan.currency,
            'status': row.status,
            'started_at': row.started_at,
            'expires_at': row.expires_at,
            'auto_renew': row.auto_renew,
            'payments': [{
                'id': str(payment.pk),
                'transaction_id': payment.provider_payment_id or payment.provider_reference or str(payment.pk),
                'provider_reference': payment.provider_reference,
                'provider': payment.provider,
                'amount': payment.amount,
                'currency': payment.currency,
                'status': payment.status,
                'paid_at': payment.paid_at,
                'created_at': payment.created_at,
            } for payment in list(row.payments.all())[:20]],
        } for row in queryset[:500]]
        return Response({
            'results': results,
            'statistics': {
                'total': Subscription.objects.count(),
                'by_status': {row['status']: row['count'] for row in totals},
                'successful_revenue': revenue,
                'period': period,
                'revenue_history': revenue_history,
            },
        })


class ClaimViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = 'core.view_accountclosurerequest'

    def get_required_permission(self):
        if self.request.query_params.get('type') == 'email':
            return 'core.view_emailchangesupportrequest'
        return self.required_permission

    def get_queryset(self):
        claim_type = self.request.query_params.get('type', 'closure')
        model = EmailChangeSupportRequest if claim_type == 'email' else AccountClosureRequest
        queryset = model.objects.select_related('user', 'reviewed_by').order_by('-created_at')
        state = self.request.query_params.get('status')
        return queryset.filter(status=state) if state else queryset

    def get_serializer_class(self):
        return EmailChangeSupportRequestSerializer if self.request.query_params.get('type') == 'email' else AccountClosureRequestSerializer


class ContentModerationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AdminContentSerializer
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = 'core.view_content'

    def get_queryset(self):
        queryset = Content.objects.select_related('producer', 'reviewed_by').order_by('-submitted_at')
        state = self.request.query_params.get('status')
        search = self.request.query_params.get('search')
        if state:
            queryset = queryset.filter(producer_submission_status=state)
        if search:
            queryset = queryset.filter(title__icontains=search)
        return queryset

    def get_required_permission(self):
        return 'core.change_content' if self.action == 'review' else self.required_permission

    @action(detail=True, methods=['post'])
    def review(self, request, pk=None):
        decision = request.data.get('decision')
        if decision not in ('approved', 'rejected'):
            raise exceptions.ValidationError({'decision': 'Valeurs autorisées : approved, rejected.'})
        content = self.get_object()
        content.producer_submission_status = decision
        content.review_reason = request.data.get('reason', '')
        content.reviewed_by = request.user
        content.reviewed_at = timezone.now()
        content.save(update_fields=['producer_submission_status', 'review_reason', 'reviewed_by', 'reviewed_at'])
        audit(request, f'content.{decision}', content, {'reason': content.review_reason})
        notify_user(content.producer, f'content_{decision}',
                    message=f'Le contenu « {content.title} » a été {"validé" if decision == "approved" else "rejeté"}.',
                    data={'content_id': content.pk})
        notify_staff('admin_content_reviewed', title='Contenu modéré',
                     message=f'{content.title} a été {decision} par {request.user.email}.',
                     data={'content_id': content.pk, 'decision': decision})
        return Response(self.get_serializer(content).data)


class VideoModerationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AdminVideoAssetSerializer
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = 'core.view_videoasset'

    def get_queryset(self):
        queryset = VideoAsset.objects.select_related('content', 'content__producer', 'moderated_by').order_by('-source_uploaded_at')
        state = self.request.query_params.get('status')
        search = self.request.query_params.get('search')
        if state:
            queryset = queryset.filter(moderation_status=state)
        if search:
            queryset = queryset.filter(content__title__icontains=search)
        return queryset

    def get_required_permission(self):
        return 'core.change_videoasset' if self.action == 'review' else self.required_permission

    @action(detail=True, methods=['post'])
    def review(self, request, pk=None):
        decision = request.data.get('decision')
        if decision not in ('approved', 'rejected'):
            raise exceptions.ValidationError({'decision': 'Valeurs autorisées : approved, rejected.'})
        asset = self.get_object()
        asset.moderation_status = decision
        asset.moderation_reason = request.data.get('reason', '')
        asset.moderated_by = request.user
        asset.moderated_at = timezone.now()
        asset.save(update_fields=['moderation_status', 'moderation_reason', 'moderated_by', 'moderated_at'])
        audit(request, f'video.{decision}', asset, {'reason': asset.moderation_reason})
        notify_user(asset.content.producer, f'video_{decision}',
                    message=f'La vidéo de « {asset.content.title} » a été {"validée" if decision == "approved" else "rejetée"}.',
                    data={'video_id': asset.pk})
        notify_staff('admin_video_reviewed', title='Vidéo modérée',
                     message=f'{asset.content.title} a été {decision} par {request.user.email}.',
                     data={'video_id': asset.pk, 'decision': decision})
        return Response(self.get_serializer(asset).data)


class AdminDashboardView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated, AdminPermission]

    def get(self, request):
        now = timezone.now()
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        pending_claims = (AccountClosureRequest.objects.filter(status='pending').count()
                          + EmailChangeSupportRequest.objects.filter(status='pending').count())
        stats = {
            'users': User.objects.filter(is_staff=False).count(),
            'producers': User.objects.filter(is_producer=True, is_active=True).count(),
            'contents': Content.objects.count(),
            'published': Content.objects.filter(producer_submission_status='approved').count(),
            'pending_moderation': Content.objects.filter(producer_submission_status='pending').count()
                                  + VideoAsset.objects.filter(moderation_status='pending').count(),
            'monthly_revenue': Payment.objects.filter(status='success', paid_at__gte=month_start)
                                      .aggregate(total=Sum('amount'))['total'] or 0,
        }
        activities = []
        for user in User.objects.filter(is_staff=False).order_by('-created_at')[:5]:
            activities.append({'type': 'user', 'title': 'Nouvel utilisateur', 'message': user.email,
                               'created_at': user.created_at, 'target_id': user.pk})
        for content in Content.objects.exclude(submitted_at=None).select_related('producer').order_by('-submitted_at')[:5]:
            producer_name = ((content.producer.producer_company or content.producer.email)
                             if content.producer else 'Producteur inconnu')
            activities.append({'type': 'content', 'title': 'Nouveau contenu',
                               'message': f'« {content.title} » par {producer_name}',
                               'created_at': content.submitted_at, 'target_id': content.pk})
        for payment in Payment.objects.filter(status='success').select_related('subscription__user').order_by('-paid_at')[:5]:
            activities.append({'type': 'payment', 'title': 'Paiement reçu',
                               'message': f'{payment.amount} {payment.currency}',
                               'created_at': payment.paid_at or payment.created_at, 'target_id': payment.pk})
        activities = sorted(activities, key=lambda row: row['created_at'], reverse=True)[:5]
        alerts = [
            {'type': 'moderation', 'count': stats['pending_moderation'], 'label': 'contenus en attente de modération'},
            {'type': 'claims', 'count': pending_claims, 'label': 'demandes de réclamation'},
            {'type': 'producers', 'count': User.objects.filter(is_producer=True, is_active=False).count(),
             'label': 'producteurs suspendus'},
        ]
        return Response({'stats': stats, 'recent_activity': activities, 'alerts': alerts})


class AdminNotificationView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated, AdminPermission]

    def get(self, request):
        rows = Notification.objects.filter(user=request.user).order_by('-created_at')[:30]
        return Response({'unread': Notification.objects.filter(user=request.user, is_read=False).count(),
                         'results': [serialize_admin_notification(row) for row in rows]})

    def post(self, request):
        ids = request.data.get('ids')
        queryset = Notification.objects.filter(user=request.user, is_read=False)
        if ids:
            queryset = queryset.filter(pk__in=ids)
        updated = queryset.update(is_read=True)
        return Response({'updated': updated})


class AdminPayoutViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AdminPayoutSerializer
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = 'core.view_producerpayoutrequest'

    def get_queryset(self):
        queryset = ProducerPayoutRequest.objects.select_related('producer', 'reviewed_by').order_by('-created_at')
        state = self.request.query_params.get('status')
        search = self.request.query_params.get('search')
        if state:
            queryset = queryset.filter(status=state)
        if search:
            queryset = queryset.filter(producer__email__icontains=search)
        return queryset

    def get_required_permission(self):
        return ('core.change_producerpayoutrequest'
                if self.action in ('approve', 'reject', 'mark_paid') else self.required_permission)

    def _locked(self, pk):
        return ProducerPayoutRequest.objects.select_for_update().get(pk=pk)

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def approve(self, request, pk=None):
        serializer = PayoutReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payout = approve_payout_request(self._locked(pk), request.user,
                                        serializer.validated_data.get('reason', ''))
        audit(request, 'payout.approve', payout)
        return Response(self.get_serializer(payout).data)

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def reject(self, request, pk=None):
        serializer = PayoutRejectSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payout = reject_payout_request(self._locked(pk), request.user,
                                       serializer.validated_data['reason'])
        audit(request, 'payout.reject', payout)
        return Response(self.get_serializer(payout).data)

    @action(detail=True, methods=['post'], url_path='mark-paid')
    @transaction.atomic
    def mark_paid(self, request, pk=None):
        serializer = CriticalPayoutSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        payout = mark_payout_paid(self._locked(pk), request.user,
                                  serializer.validated_data.get('reason', ''))
        audit(request, 'payout.paid', payout)
        return Response(self.get_serializer(payout).data)
