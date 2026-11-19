from pathlib import Path
from django.conf import settings
from django.core import signing
from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import exceptions, filters, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from apps.catalog.media_services import (
    promote_content_media_to_final,
    store_content_media_temp,
)
from apps.catalog.experience_services import (
    apply_advanced_search_filters,
    base_content_queryset,
    continue_watching_queryset,
    genre_rails,
    get_profile_for_request,
    limit_value,
    new_releases_queryset,
    recommended_queryset,
    top_10_queryset,
    trending_queryset,
)
from apps.catalog.serializers import (
    ContentDetailSerializer,
    ContentListSerializer,
    ContentMediaUploadSerializer,
    ContentRejectSerializer,
    ContentReviewSerializer,
    ContentSimilaritySerializer,
    ContentStatusSerializer,
    ContentSubmitSerializer,
    EmissionSerializer,
    EpisodeSerializer,
    GenreSerializer,
    SeasonSerializer,
)
from apps.common.api import is_int, is_true, paginate
from apps.common.minio_storage import (
    minio_internal_client,
    minio_public_upload_client,
)
from apps.common.permissions import (
    IsAdminOrProducerRelatedContentOrReadOnly,
    IsAdminOrProducerOwnerOrReadOnly,
    IsAdminOrReadOnly,
    is_producer_user,
)
from apps.notifications.services import notify_staff, notify_user
from core.models import Content, ContentSimilarity, ContentStatus, Emission, Episode, Genre, Profile, Season, VideoAsset


class GenreViewSet(viewsets.ModelViewSet):
    queryset = Genre.objects.all().order_by('name')
    serializer_class = GenreSerializer
    permission_classes = [IsAdminOrReadOnly]
    lookup_field = 'slug'
    search_fields = ['name', 'description']
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    ordering_fields = ['name', 'created_at']
    ordering = ['name']


class EmissionViewSet(viewsets.ModelViewSet):
    queryset = Emission.objects.all().order_by('display_order', 'name')
    serializer_class = EmissionSerializer
    permission_classes = [IsAdminOrReadOnly]
    lookup_field = 'slug'
    search_fields = ['name', 'description']
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    ordering_fields = ['name', 'display_order', 'created_at']
    ordering = ['display_order', 'name']


class ContentStatusViewSet(viewsets.ModelViewSet):
    queryset = ContentStatus.objects.all().order_by('name')
    serializer_class = ContentStatusSerializer
    permission_classes = [IsAdminOrReadOnly]
    search_fields = ['name', 'description']
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    ordering_fields = ['name']
    ordering = ['name']


class ContentViewSet(viewsets.ModelViewSet):
    queryset = Content.objects.all()
    permission_classes = [IsAdminOrProducerOwnerOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'original_title', 'description', 'synopsis']
    ordering_fields = [
        'title',
        'release_year',
        'rating_avg',
        'view_count',
        'popularity_score',
        'trending_score',
        'created_at',
    ]
    ordering = ['-popularity_score', '-created_at']

    def get_serializer_class(self):
        if self.action in ['list', 'popular', 'trending']:
            return ContentListSerializer
        return ContentDetailSerializer

    def get_permissions(self):
        if self.action in {'pending_submissions', 'approve_submission', 'reject_submission'}:
            return [permissions.IsAdminUser()]
        if self.action in {
            'mine',
            'producer_dashboard',
            'trailer_upload_session',
            'trailer_upload_complete',
        }:
            return [permissions.IsAuthenticated()]
        return super().get_permissions()

    def get_queryset(self):
        queryset = (
            Content.objects.select_related('status', 'producer', 'reviewed_by')
            .prefetch_related('genres', 'emissions', 'seasons__episodes')
            .all()
        )
        params = self.request.query_params

        content_type = params.get('type')
        if content_type:
            queryset = queryset.filter(type=content_type)

        genre = params.get('genre')
        if genre:
            genre_filter = Q(genres__slug=genre)
            if is_int(genre):
                genre_filter |= Q(genres__id=genre)
            queryset = queryset.filter(genre_filter)

        emission = params.get('emission')
        if emission:
            emission_filter = Q(emissions__slug=emission)
            if is_int(emission):
                emission_filter |= Q(emissions__id=emission)
            queryset = queryset.filter(emission_filter)

        status_name = params.get('status')
        if status_name:
            queryset = queryset.filter(status__name__iexact=status_name)

        producer_status = params.get('producer_status') or params.get('submission_status')
        if producer_status:
            queryset = queryset.filter(producer_submission_status=producer_status)

        producer = params.get('producer')
        if producer and self.request.user.is_authenticated and self.request.user.is_staff:
            queryset = queryset.filter(producer_id=producer)

        # Filtrage par âge pour les profils enfants
        profile_id = self.request.headers.get('x-profile-id')
        if profile_id and self.request.user.is_authenticated:
            child_profile = Profile.objects.filter(
                pk=profile_id,
                user=self.request.user,
                type__name='child',
                is_active=True,
            ).first()
            if child_profile:
                ratings = []
                for age in range(
                    child_profile.allowed_min_age,
                    child_profile.allowed_max_age + 1,
                ):
                    ratings.extend((str(age), f'{age}+'))
                queryset = queryset.filter(Q(age_rating='') | Q(age_rating__in=ratings))

        year = params.get('year')
        if is_int(year):
            queryset = queryset.filter(release_year=year)

        min_year = params.get('min_year')
        if is_int(min_year):
            queryset = queryset.filter(release_year__gte=min_year)

        max_year = params.get('max_year')
        if is_int(max_year):
            queryset = queryset.filter(release_year__lte=max_year)

        if 'is_4k' in params:
            queryset = queryset.filter(is_4k=is_true(params.get('is_4k')))

        if 'is_hd' in params:
            queryset = queryset.filter(is_hd=is_true(params.get('is_hd')))

        q = params.get('q')
        if q:
            queryset = queryset.filter(
                Q(title__icontains=q)
                | Q(original_title__icontains=q)
                | Q(description__icontains=q)
                | Q(synopsis__icontains=q)
            )

        return queryset.distinct()

    def perform_create(self, serializer):
        if self.request.user.is_staff:
            serializer.save()
            return
        serializer.save(
            producer=self.request.user,
            producer_submission_status='draft',
        )

    def perform_update(self, serializer):
        if self.request.user.is_staff:
            serializer.save()
            return

        content = self.get_object()

        if content.producer_submission_status in {
            'pending',
            'approved',
        }:
            raise exceptions.ValidationError({
                'producer_submission_status': (
                    'Ce contenu ne peut pas être modifié pendant '
                    'ou après sa validation.'
                )
            })

        # Un brouillon reste un brouillon.
        # Un contenu rejeté redevient un brouillon dès que
        # le producteur commence à le corriger.
        serializer.save(
            producer_submission_status='draft',
            review_reason='',
            reviewed_by=None,
            reviewed_at=None,
        )

    def _require_producer_role(self, request):
        if not is_producer_user(request.user):
            raise exceptions.PermissionDenied('Un compte producteur est requis.')

    def _producer_queryset(self, request):
        self._require_producer_role(request)
        queryset = self.get_queryset()
        if request.user.is_staff:
            producer_id = request.query_params.get('producer')
            if producer_id:
                queryset = queryset.filter(producer_id=producer_id)
            return queryset
        return queryset.filter(producer=request.user)

    def _status_counts(self, queryset, field_name):
        return {
            item[field_name]: item['total']
            for item in queryset.values(field_name).annotate(total=Count('id')).order_by()
        }

    def _serialize_contents(self, contents):
        return ContentListSerializer(
            contents,
            many=True,
            context=self.get_serializer_context(),
        ).data

    def _content_row(self, key, title, contents, layout='standard'):
        items = self._serialize_contents(contents)
        return {
            'key': key,
            'title': title,
            'layout': layout,
            'items': items,
        }

    def _continue_row(self, histories):
        items = []
        for history in histories:
            items.append({
                'content': ContentListSerializer(
                    history.content,
                    context=self.get_serializer_context(),
                ).data,
                'episode_id': str(history.episode_id) if history.episode_id else None,
                'progress': history.progress,
                'last_position': history.last_position,
                'watched_duration': history.watched_duration,
                'updated_at': history.updated_at,
            })
        return {
            'key': 'continue_watching',
            'title': 'Continuer a regarder',
            'layout': 'continue',
            'items': items,
        }

    @action(detail=False, methods=['get'])
    def popular(self, request):
        queryset = self.filter_queryset(
            self.get_queryset().order_by('-popularity_score', '-view_count', '-created_at')
        )
        return paginate(self, queryset, ContentListSerializer)

    @action(detail=False, methods=['get'])
    def trending(self, request):
        queryset = self.filter_queryset(
            self.get_queryset().order_by('-trending_score', '-view_count', '-created_at')
        )
        return paginate(self, queryset, ContentListSerializer)

    @action(detail=False, methods=['get'])
    def mine(self, request):
        queryset = self.filter_queryset(
            self._producer_queryset(request).order_by('-updated_at')
        )
        return paginate(self, queryset, ContentDetailSerializer)

    @action(detail=False, methods=['get'], url_path='producer-dashboard')
    def producer_dashboard(self, request):
        queryset = self._producer_queryset(request)
        video_assets = VideoAsset.objects.filter(content__in=queryset)
        return Response({
            'content_total': queryset.count(),
            'content_by_submission_status': self._status_counts(
                queryset,
                'producer_submission_status',
            ),
            'video_asset_total': video_assets.count(),
            'video_asset_by_moderation_status': self._status_counts(
                video_assets,
                'moderation_status',
            ),
            'pending_content_reviews': queryset.filter(
                producer_submission_status='pending',
            ).count(),
            'pending_video_reviews': video_assets.filter(
                moderation_status='pending',
            ).count(),
            'recent_contents': self._serialize_contents(queryset.order_by('-updated_at')[:10]),
        })

    @action(detail=False, methods=['get'], url_path='pending-submissions')
    def pending_submissions(self, request):
        queryset = self.filter_queryset(
            self.get_queryset()
            .filter(producer_submission_status='pending')
            .order_by('submitted_at', 'created_at')
        )
        return paginate(self, queryset, ContentDetailSerializer)

    @action(detail=False, methods=['get'])
    def search(self, request):
        limit = limit_value(request, default=20, maximum=50)
        queryset = apply_advanced_search_filters(base_content_queryset(), request.query_params)
        ordering = request.query_params.get('ordering')
        allowed_ordering = {
            'title',
            '-title',
            'release_year',
            '-release_year',
            'rating_avg',
            '-rating_avg',
            'popularity_score',
            '-popularity_score',
            'created_at',
            '-created_at',
        }
        if ordering in allowed_ordering:
            queryset = queryset.order_by(ordering)
        else:
            queryset = queryset.order_by('-popularity_score', '-rating_avg', '-created_at')

        return Response({
            'query': request.query_params.get('q') or request.query_params.get('query') or '',
            'count': queryset.count(),
            'results': self._serialize_contents(queryset[:limit]),
        })

    @action(detail=False, methods=['get'], url_path='top-10')
    def top_10(self, request):
        limit = min(limit_value(request, default=10, maximum=50), 10)
        contents = list(top_10_queryset()[:limit])
        return Response({
            'key': 'top_10',
            'title': 'Top 10',
            'items': self._serialize_contents(contents),
        })

    @action(detail=False, methods=['get'], url_path='new-releases')
    def new_releases(self, request):
        limit = limit_value(request, default=20, maximum=50)
        contents = list(new_releases_queryset()[:limit])
        return Response({
            'key': 'new_releases',
            'title': 'Nouveautes',
            'items': self._serialize_contents(contents),
        })

    @action(detail=False, methods=['get'])
    def home(self, request):
        limit = limit_value(request, default=12, maximum=30)
        profile = get_profile_for_request(request)
        rows = []

        hero_content = list(top_10_queryset()[:1])
        if hero_content:
            rows.append(self._content_row('hero', 'A la une', hero_content, layout='hero'))

        if profile:
            continue_items = list(continue_watching_queryset(profile)[:limit])
            if continue_items:
                rows.append(self._continue_row(continue_items))

        recommended_items = list(recommended_queryset(profile)[:limit])
        if recommended_items:
            rows.append(self._content_row('recommended', 'Pour vous', recommended_items))

        trending_items = list(trending_queryset(request.query_params.get('period', 'week'))[:limit])
        if trending_items:
            rows.append(self._content_row('trending', 'Tendances', trending_items))

        top_items = list(top_10_queryset()[:10])
        if top_items:
            rows.append(self._content_row('top_10', 'Top 10', top_items, layout='ranked'))

        new_items = list(new_releases_queryset()[:limit])
        if new_items:
            rows.append(self._content_row('new_releases', 'Nouveautes', new_items))

        movie_items = list(base_content_queryset().filter(type='movie').order_by('-popularity_score', '-created_at')[:limit])
        if movie_items:
            rows.append(self._content_row('movies', 'Films', movie_items))

        series_items = list(base_content_queryset().filter(type='series').order_by('-popularity_score', '-created_at')[:limit])
        if series_items:
            rows.append(self._content_row('series', 'Series', series_items))

        for genre, items in genre_rails(limit=limit):
            rows.append(self._content_row(f'genre_{genre.slug}', genre.name, items))

        return Response({
            'profile_id': str(profile.id) if profile else None,
            'rows': rows,
        })

    @action(detail=True, methods=['get'])
    def seasons(self, request, pk=None):
        content = self.get_object()
        queryset = content.seasons.prefetch_related('episodes').order_by('season_number')
        serializer = SeasonSerializer(queryset, many=True, context=self.get_serializer_context())
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def submit(self, request, pk=None):
        content = self.get_object()
        serializer = ContentSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if content.producer_submission_status != 'draft':
            return Response(
                {
                    'detail': (
                        'Seul un brouillon peut être soumis '
                        'pour validation.'
                    )
                },
                status=status.HTTP_409_CONFLICT,
            )

        if not content.producer_id and not request.user.is_staff:
            content.producer = request.user
        content.producer_notes = serializer.validated_data.get(
            'producer_notes',
            content.producer_notes,
        )
        content.producer_submission_status = 'pending'
        content.submitted_at = timezone.now()
        content.review_reason = ''
        content.reviewed_by = None
        content.reviewed_at = None
        content.save(update_fields=[
            'producer',
            'producer_notes',
            'producer_submission_status',
            'submitted_at',
            'review_reason',
            'reviewed_by',
            'reviewed_at',
            'updated_at',
        ])
        if content.producer:
            notify_user(
                content.producer,
                'content_submitted',
                data={'content_id': str(content.id)},
            )
        notify_staff(
            'content_submitted',
            title='Nouveau contenu a valider',
            message=f"{content.title} a ete soumis par un producteur.",
            data={'content_id': str(content.id)},
        )
        return Response(self.get_serializer(content).data)

    @action(detail=True, methods=['post'], url_path='approve-submission')
    def approve_submission(self, request, pk=None):
        content = self.get_object()
        serializer = ContentReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if content.producer_submission_status != 'pending':
            return Response(
                {
                    'detail': (
                        'Seul un contenu en attente de validation '
                        'peut être approuvé.'
                    )
                },
                status=status.HTTP_409_CONFLICT,
            )

        # IMPORTANT :
        # la promotion MinIO TEMP -> B2 FINAL/CDN doit réussir
        # entièrement AVANT le passage au statut approved.
        try:
            promote_content_media_to_final(content)
        except Exception:
            return Response(
                {
                    'detail': (
                        'La promotion des médias vers le stockage final '
                        'a échoué. Le contenu reste en attente.'
                    )
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        content.producer_submission_status = 'approved'
        content.review_reason = serializer.validated_data.get('reason', '')
        content.reviewed_by = request.user
        content.reviewed_at = timezone.now()

        content.save(update_fields=[
            'producer_submission_status',
            'review_reason',
            'reviewed_by',
            'reviewed_at',
            'updated_at',
        ])

        if content.producer:
            notify_user(
                content.producer,
                'content_approved',
                message=(
                    content.review_reason
                    or f"{content.title} a ete valide."
                ),
                data={'content_id': str(content.id)},
            )

        return Response(self.get_serializer(content).data)

    @action(detail=True, methods=['post'], url_path='reject-submission')
    def reject_submission(self, request, pk=None):
        content = self.get_object()
        serializer = ContentRejectSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        content.producer_submission_status = 'rejected'
        content.review_reason = serializer.validated_data['reason']
        content.reviewed_by = request.user
        content.reviewed_at = timezone.now()
        content.save(update_fields=[
            'producer_submission_status',
            'review_reason',
            'reviewed_by',
            'reviewed_at',
            'updated_at',
        ])
        if content.producer:
            notify_user(
                content.producer,
                'content_rejected',
                message=content.review_reason,
                data={'content_id': str(content.id)},
            )
        return Response(self.get_serializer(content).data)

    @action(detail=True, methods=['get'])
    def similar(self, request, pk=None):
        content = self.get_object()
        similarities = (
            ContentSimilarity.objects.filter(content_1=content)
            .select_related('content_2', 'content_2__status')
            .prefetch_related('content_2__genres', 'content_2__emissions')
            .order_by('-similarity_score')
        )

        if similarities.exists():
            return paginate(self, similarities, ContentSimilaritySerializer)

        queryset = (
            Content.objects.filter(genres__in=content.genres.all())
            .exclude(pk=content.pk)
            .select_related('status')
            .prefetch_related('genres', 'emissions')
            .distinct()
            .order_by('-popularity_score', '-rating_avg')[:20]
        )
        serializer = ContentListSerializer(queryset, many=True, context=self.get_serializer_context())
        return Response(serializer.data)

    def _upload_media(self, request, media_type):
        content = self.get_object()
        serializer = ContentMediaUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = store_content_media_temp(
            content=content,
            uploaded_file=serializer.validated_data['file'],
            media_type=media_type,
            uploader=request.user,
        )
        return Response(payload, status=status.HTTP_200_OK)

    @action(
        detail=True,
        methods=['post'],
        url_path='upload-poster',
        parser_classes=[MultiPartParser, FormParser],
    )
    def upload_poster(self, request, pk=None):
        return self._upload_media(request, 'poster')

    @action(
        detail=True,
        methods=['post'],
        url_path='upload-backdrop',
        parser_classes=[MultiPartParser, FormParser],
    )
    def upload_backdrop(self, request, pk=None):
        return self._upload_media(request, 'backdrop')

    @action(
        detail=True,
        methods=['post'],
        url_path='upload-trailer',
        parser_classes=[MultiPartParser, FormParser],
    )
    def upload_trailer(self, request, pk=None):
        return self._upload_media(request, 'trailer')


    def _ensure_trailer_direct_upload_allowed(
        self,
        request,
        content,
    ):
        user = request.user

        if user.is_staff:
            return

        if (
            not getattr(user, 'is_producer', False)
            or content.producer_id != user.id
        ):
            raise exceptions.PermissionDenied(
                'Ce contenu appartient à un autre producteur.'
            )

        if content.producer_submission_status != 'draft':
            raise exceptions.ValidationError({
                'producer_submission_status': (
                    'Le trailer ne peut être remplacé que '
                    'pendant l’état brouillon.'
                )
            })

    @action(
        detail=True,
        methods=['post'],
        url_path='trailer-upload-session',
    )
    def trailer_upload_session(self, request, pk=None):
        content = self.get_object()

        self._ensure_trailer_direct_upload_allowed(
            request,
            content,
        )

        filename = str(
            request.data.get('filename') or ''
        ).strip()
        raw_size = request.data.get('size_bytes')

        if not filename:
            raise exceptions.ValidationError({
                'filename':
                    'Le nom du fichier trailer est obligatoire.'
            })

        try:
            size_bytes = int(raw_size)
        except (TypeError, ValueError):
            raise exceptions.ValidationError({
                'size_bytes':
                    'La taille du trailer est invalide.'
            })

        if size_bytes <= 0:
            raise exceptions.ValidationError({
                'size_bytes': (
                    'La taille du trailer doit être '
                    'supérieure à zéro.'
                )
            })

        max_size = int(
            getattr(
                settings,
                'PRODUCER_TRAILER_MAX_BYTES',
                1073741824,
            )
        )

        if size_bytes > max_size:
            raise exceptions.ValidationError({
                'size_bytes': (
                    'Le trailer dépasse la taille '
                    'maximale autorisée.'
                )
            })

        extension = Path(filename).suffix.lower()

        allowed_extensions = {
            '.mp4',
            '.m4v',
            '.mov',
            '.webm',
        }

        if extension not in allowed_extensions:
            raise exceptions.ValidationError({
                'filename': (
                    f'Extension trailer non autorisée: '
                    f'{extension or "aucune"}'
                )
            })

        producer_id = (
            content.producer_id
            or request.user.id
        )

        object_key = (
            f'uploads/producer_{producer_id}/'
            f'content_{content.id}/'
            f'trailer_original{extension}'
        )

        bucket = settings.MINIO_BUCKET
        expires_in = 3600

        upload_url = (
            minio_public_upload_client()
            .generate_presigned_url(
                ClientMethod='put_object',
                Params={
                    'Bucket': bucket,
                    'Key': object_key,
                },
                ExpiresIn=expires_in,
                HttpMethod='PUT',
            )
        )

        completion_token = signing.dumps(
            {
                'content_id': str(content.id),
                'producer_id': str(producer_id),
                'user_id': str(request.user.id),
                'media_type': 'trailer',
                'bucket': bucket,
                'object_key': object_key,
                'size_bytes': size_bytes,
            },
            salt='catalog-trailer-upload',
            compress=True,
        )

        return Response({
            'upload_url': upload_url,
            'completion_token': completion_token,
            'expires_in': expires_in,
            'size_bytes': size_bytes,
        })

    @action(
        detail=True,
        methods=['post'],
        url_path='trailer-upload-complete',
    )
    def trailer_upload_complete(self, request, pk=None):
        content = self.get_object()

        self._ensure_trailer_direct_upload_allowed(
            request,
            content,
        )

        completion_token = str(
            request.data.get('completion_token') or ''
        ).strip()

        if not completion_token:
            raise exceptions.ValidationError({
                'completion_token': (
                    'Le jeton de confirmation '
                    'est obligatoire.'
                )
            })

        try:
            payload = signing.loads(
                completion_token,
                salt='catalog-trailer-upload',
                max_age=3600,
            )
        except signing.SignatureExpired:
            raise exceptions.ValidationError({
                'completion_token':
                    'La session d’upload a expiré.'
            })
        except signing.BadSignature:
            raise exceptions.ValidationError({
                'completion_token':
                    'La session d’upload est invalide.'
            })

        if (
            str(payload.get('content_id'))
            != str(content.id)
        ):
            raise exceptions.ValidationError({
                'completion_token': (
                    'La session ne correspond pas '
                    'à ce contenu.'
                )
            })

        if (
            str(payload.get('user_id'))
            != str(request.user.id)
        ):
            raise exceptions.PermissionDenied(
                'Cette session appartient à '
                'un autre utilisateur.'
            )

        producer_id = (
            content.producer_id
            or request.user.id
        )

        if (
            str(payload.get('producer_id'))
            != str(producer_id)
        ):
            raise exceptions.ValidationError({
                'completion_token':
                    'Producteur de stockage invalide.'
            })

        if payload.get('media_type') != 'trailer':
            raise exceptions.ValidationError({
                'completion_token':
                    'Type de média invalide.'
            })

        bucket = str(
            payload.get('bucket') or ''
        )
        object_key = str(
            payload.get('object_key') or ''
        )

        try:
            expected_size = int(
                payload.get('size_bytes') or 0
            )
        except (TypeError, ValueError):
            expected_size = 0

        if (
            bucket != settings.MINIO_BUCKET
            or not object_key
            or expected_size <= 0
        ):
            raise exceptions.ValidationError({
                'completion_token':
                    'Référence de stockage invalide.'
            })

        expected_prefix = (
            f'uploads/producer_{producer_id}/'
            f'content_{content.id}/'
            f'trailer_original'
        )

        if not object_key.startswith(expected_prefix):
            raise exceptions.ValidationError({
                'completion_token':
                    'Chemin de stockage invalide.'
            })

        client = minio_internal_client()

        try:
            metadata = client.head_object(
                Bucket=bucket,
                Key=object_key,
            )
        except Exception as exc:
            raise exceptions.ValidationError({
                'trailer': (
                    'Le trailer envoyé est introuvable '
                    'dans le stockage temporaire.'
                )
            }) from exc

        stored_size = int(
            metadata.get('ContentLength') or 0
        )

        if stored_size <= 0:
            raise exceptions.ValidationError({
                'trailer':
                    'Le trailer stocké est vide.'
            })

        if stored_size != expected_size:
            raise exceptions.ValidationError({
                'trailer': (
                    'La taille du trailer stocké '
                    'ne correspond pas au fichier envoyé.'
                )
            })

        content.trailer_temp_path = object_key
        content.trailer_url = ''

        content.save(
            update_fields=[
                'trailer_temp_path',
                'trailer_url',
                'updated_at',
            ]
        )

        return Response({
            'media_type': 'trailer',
            'field': 'trailer_temp_path',
            'temporary_path': object_key,
            'final_field': 'trailer_url',
            'url': '',
            'storage': 'temporary',
            'size_bytes': stored_size,
        })


class ProducerContentOwnershipMixin:
    def _ensure_can_manage_content(self, content):
        user = self.request.user
        if user.is_staff:
            return
        if not getattr(user, 'is_producer', False) or content.producer_id != user.id:
            raise exceptions.PermissionDenied('Ce contenu appartient a un autre producteur.')


class SeasonViewSet(ProducerContentOwnershipMixin, viewsets.ModelViewSet):
    serializer_class = SeasonSerializer
    permission_classes = [IsAdminOrProducerRelatedContentOrReadOnly]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['season_number', 'created_at']
    ordering = ['season_number']

    def get_queryset(self):
        queryset = (
            Season.objects.select_related('content', 'content__producer')
            .prefetch_related('episodes')
            .all()
        )
        content_id = self.request.query_params.get('content')
        if content_id:
            queryset = queryset.filter(content_id=content_id)
        return queryset

    def perform_create(self, serializer):
        self._ensure_can_manage_content(serializer.validated_data['content'])
        serializer.save()

    def perform_update(self, serializer):
        content = serializer.validated_data.get('content') or serializer.instance.content
        self._ensure_can_manage_content(content)
        serializer.save()


class EpisodeViewSet(ProducerContentOwnershipMixin, viewsets.ModelViewSet):
    serializer_class = EpisodeSerializer
    permission_classes = [IsAdminOrProducerRelatedContentOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description']
    ordering_fields = ['episode_number', 'created_at']
    ordering = ['episode_number']

    def get_queryset(self):
        queryset = Episode.objects.select_related('season', 'content', 'content__producer').all()
        content_id = self.request.query_params.get('content')
        season_id = self.request.query_params.get('season')
        if content_id:
            queryset = queryset.filter(content_id=content_id)
        if season_id:
            queryset = queryset.filter(season_id=season_id)
        return queryset

    def perform_create(self, serializer):
        content = serializer.validated_data.get('content')
        season = serializer.validated_data.get('season')
        if not content and season:
            content = season.content
        self._ensure_can_manage_content(content)
        serializer.save()

    def perform_update(self, serializer):
        content = (
            serializer.validated_data.get('content')
            or getattr(serializer.instance, 'content', None)
        )
        season = serializer.validated_data.get('season')
        if season:
            content = season.content
        self._ensure_can_manage_content(content)
        serializer.save()
