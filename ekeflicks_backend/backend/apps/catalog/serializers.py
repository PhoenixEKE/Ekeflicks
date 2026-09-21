from django.core.exceptions import ObjectDoesNotExist
from rest_framework import serializers

from core.models import (
    Content,
    ContentSimilarity,
    ContentStatus,
    Emission,
    Episode,
    Genre,
    Season,
)
from core.models.streaming import VideoAsset


class GenreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Genre
        fields = ['id', 'name', 'slug', 'description', 'created_at']
        read_only_fields = ['id', 'created_at']


class EmissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Emission
        fields = ['id', 'name', 'slug', 'description', 'display_order', 'created_at']
        read_only_fields = ['id', 'created_at']


class ContentStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContentStatus
        fields = ['id', 'name', 'description']
        read_only_fields = ['id']


class EpisodeSerializer(serializers.ModelSerializer):
    season_id = serializers.PrimaryKeyRelatedField(
        source='season',
        queryset=Season.objects.all(),
        write_only=True,
        required=True,
    )
    content_id = serializers.PrimaryKeyRelatedField(
        source='content',
        queryset=Content.objects.all(),
        write_only=True,
        required=False,
    )

    class Meta:
        model = Episode
        fields = [
            'id',
            'season',
            'season_id',
            'content',
            'content_id',
            'episode_number',
            'title',
            'description',
            'duration',
            'video_url',
            'thumbnail_url',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'season', 'content', 'created_at', 'updated_at']

    def validate(self, attrs):
        season = attrs.get('season') or getattr(self.instance, 'season', None)
        content = attrs.get('content') or getattr(self.instance, 'content', None)

        if season and not content:
            attrs['content'] = season.content
        elif season and content and season.content_id != content.id:
            raise serializers.ValidationError(
                {'content_id': "Le contenu doit correspondre a la saison."}
            )

        return attrs



def _get_trailer_analysis_report(obj):
    """
    Retourne le TrailerAnalysisReport lié au Content ou à la Season.

    Le reverse OneToOne peut ne pas exister :
    dans ce cas l'API expose simplement not_started / null.
    """
    try:
        return obj.trailer_analysis_report
    except ObjectDoesNotExist:
        return None


def _get_trailer_analysis_status(obj):
    report = _get_trailer_analysis_report(obj)

    if report is None:
        return "not_started"

    return report.status


def _get_trailer_analyzed_at(obj):
    report = _get_trailer_analysis_report(obj)

    if report is None:
        return None

    return report.analyzed_at


def _get_trailer_technical_conformity(obj):
    report = _get_trailer_analysis_report(obj)

    if report is None:
        return None

    metadata = (
        report.technical_metadata
        if isinstance(report.technical_metadata, dict)
        else {}
    )

    conformity = metadata.get(
        "technical_specification_conformity"
    )

    return conformity if isinstance(conformity, dict) else None


class SeasonSerializer(serializers.ModelSerializer):
    content_id = serializers.PrimaryKeyRelatedField(
        source='content',
        queryset=Content.objects.all(),
        write_only=True,
        required=True,
    )
    episodes = EpisodeSerializer(many=True, read_only=True)
    trailer_analysis_status = serializers.SerializerMethodField()
    trailer_analyzed_at = serializers.SerializerMethodField()
    trailer_technical_conformity = serializers.SerializerMethodField()

    class Meta:
        model = Season
        fields = [
            'id',
            'content',
            'content_id',
            'season_number',
            'title',
            'description',
            'poster_url',
            'poster_temp_path',
            'backdrop_url',
            'backdrop_temp_path',
            'trailer_url',
            'trailer_temp_path',
            'trailer_analysis_status',
            'trailer_analyzed_at',
            'trailer_technical_conformity',
            'episode_count',
            'episodes',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'content', 'episodes', 'created_at', 'updated_at']


    def get_trailer_analysis_status(self, obj):
        return _get_trailer_analysis_status(obj)

    def get_trailer_analyzed_at(self, obj):
        return _get_trailer_analyzed_at(obj)

    def get_trailer_technical_conformity(self, obj):
        return _get_trailer_technical_conformity(obj)

class ContentListSerializer(serializers.ModelSerializer):
    trailer_analysis_status = serializers.SerializerMethodField()
    trailer_analyzed_at = serializers.SerializerMethodField()
    trailer_technical_conformity = serializers.SerializerMethodField()

    genres = GenreSerializer(many=True, read_only=True)
    emissions = EmissionSerializer(many=True, read_only=True)
    status = serializers.StringRelatedField()
    producer = serializers.PrimaryKeyRelatedField(read_only=True)
    producer_email = serializers.EmailField(source='producer.email', read_only=True)

    class Meta:
        model = Content
        fields = [
            'id',
            'title',
            'original_title',
            'description',
            'type',
            'poster_url',
            'backdrop_url',
            'banner_url',
            'trailer_url',
            'release_year',
            'release_date',
            'duration',
            'age_rating',
            'is_hd',
            'is_4k',
            'is_hdr',
            'rating_avg',
            'rating_count',
            'view_count',
            'popularity_score',
            'ia_score',
            'trending_score',
            'status',
            'producer',
            'producer_email',
            'producer_submission_status',
            'technical_specification',
            'technical_specification_version',
            'genres',
            'emissions',
            'created_at',
            'updated_at',
            'trailer_analysis_status',
            'trailer_analyzed_at',
            'trailer_technical_conformity',
        ]
        read_only_fields = [
            'id',
            'producer',
            'producer_email',
            'producer_submission_status',
            'technical_specification',
            'technical_specification_version',
            'created_at',
            'updated_at',
        ]


    def get_trailer_analysis_status(self, obj):
        return _get_trailer_analysis_status(obj)

    def get_trailer_analyzed_at(self, obj):
        return _get_trailer_analyzed_at(obj)

    def get_trailer_technical_conformity(self, obj):
        return _get_trailer_technical_conformity(obj)

class ContentDetailSerializer(ContentListSerializer):
    technical_submission_summary = serializers.SerializerMethodField()
    audio_languages = serializers.ListField(
        child=serializers.CharField(
            allow_blank=False,
            trim_whitespace=True,
        ),
        required=False,
        allow_empty=True,
    )
    subtitle_languages = serializers.ListField(
        child=serializers.CharField(
            allow_blank=False,
            trim_whitespace=True,
        ),
        required=False,
        allow_empty=True,
    )

    def get_technical_submission_summary(self, obj):
        """
        Résumé technique en lecture seule pour les interfaces.

        La décision métier reste exclusivement portée par
        submission_conformity.py.
        """
        from apps.catalog.submission_conformity import _asset_result
        from core.models.technical_specification import (
            TechnicalSpecification,
        )

        specification = obj.technical_specification

        if specification is None:
            specification = (
                TechnicalSpecification.objects
                .filter(is_published=True)
                .order_by('-published_at', '-created_at')
                .first()
            )

        if specification is None:
            return {
                'status': 'specification_missing',
                'submission_allowed': False,
                'human_review_required': False,
                'blocking': True,
                'blocking_errors': [
                    (
                        'Aucun cahier des charges technique '
                        'n\'est actuellement publié.'
                    )
                ],
                'warnings': [],
                'assets': [],
            }

        if obj.type == 'series':
            assets = (
                VideoAsset.objects
                .filter(episode__content=obj)
                .select_related('analysis_report')
                .order_by(
                    'episode__season__season_number',
                    'episode__episode_number',
                    'created_at',
                )
            )
        else:
            assets = (
                VideoAsset.objects
                .filter(content=obj)
                .select_related('analysis_report')
                .order_by('created_at')
            )

        results = [
            _asset_result(asset, specification)
            for asset in assets
        ]

        blocking_errors = []
        warnings = []
        human_review_required = False

        for result in results:
            conformity = result.get('conformity') or {}

            if conformity.get('status') == 'review_required':
                human_review_required = True

            blocking_errors.extend(
                conformity.get('blocking_errors') or []
            )
            warnings.extend(
                conformity.get('warnings') or []
            )

        submission_allowed = bool(results) and all(
            result.get('acceptable') is True
            for result in results
        )

        if not results:
            summary_status = 'not_started'
        elif any(
            (result.get('conformity') or {}).get('blocking')
            for result in results
        ):
            summary_status = 'non_conform'
        elif human_review_required:
            summary_status = 'review_required'
        elif submission_allowed:
            summary_status = 'conform'
        else:
            summary_status = 'not_ready'

        return {
            'status': summary_status,
            'submission_allowed': submission_allowed,
            'human_review_required': human_review_required,
            'blocking': not submission_allowed,
            'blocking_errors': blocking_errors,
            'warnings': warnings,
            'specification_version': specification.version,
            'assets': results,
        }

    status_id = serializers.PrimaryKeyRelatedField(
        source='status',
        queryset=ContentStatus.objects.all(),
        write_only=True,
        required=False,
        allow_null=True,
    )
    genre_ids = serializers.PrimaryKeyRelatedField(
        source='genres',
        queryset=Genre.objects.all(),
        many=True,
        write_only=True,
        required=False,
    )
    emission_ids = serializers.PrimaryKeyRelatedField(
        source='emissions',
        queryset=Emission.objects.all(),
        many=True,
        write_only=True,
        required=False,
    )
    seasons = SeasonSerializer(many=True, read_only=True)
    reviewed_by = serializers.PrimaryKeyRelatedField(read_only=True)
    reviewed_by_email = serializers.EmailField(source='reviewed_by.email', read_only=True)

    class Meta(ContentListSerializer.Meta):
        fields = ContentListSerializer.Meta.fields + [
            'synopsis',
            'video_url',
            'available_from',
            'available_until',
            'producer_notes',
            'poster_temp_path',
            'backdrop_temp_path',
            'trailer_temp_path',
            'director_image_temp_path',
            'screenwriter_image_temp_path',
            'language',
            'country',
            'audio_languages',
            'subtitle_languages',
            'director_name',
            'director_image_url',
            'screenwriter_name',
            'screenwriter_image_url',
            'producer_team',
            'cast_team',
            'review_reason',
            'submitted_at',
            'reviewed_by',
            'reviewed_by_email',
            'reviewed_at',
            'status_id',
            'genre_ids',
            'emission_ids',
            'seasons',
            'technical_submission_summary',
        ]
        read_only_fields = ContentListSerializer.Meta.read_only_fields + [
            'poster_temp_path',
            'backdrop_temp_path',
            'trailer_temp_path',
            'director_image_temp_path',
            'screenwriter_image_temp_path',
            'review_reason',
            'submitted_at',
            'reviewed_by',
            'reviewed_by_email',
            'reviewed_at',
            'technical_submission_summary',
        ]


class ContentSimilaritySerializer(serializers.ModelSerializer):
    content = ContentListSerializer(source='content_2', read_only=True)

    class Meta:
        model = ContentSimilarity
        fields = ['id', 'content', 'similarity_score', 'calculated_at']
        read_only_fields = fields


class ContentMediaUploadSerializer(serializers.Serializer):
    file = serializers.FileField(required=True)


class ContentSubmitSerializer(serializers.Serializer):
    producer_notes = serializers.CharField(required=False, allow_blank=True)


class ContentReviewSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True)


class ContentRejectSerializer(serializers.Serializer):
    reason = serializers.CharField(required=True, allow_blank=False)
