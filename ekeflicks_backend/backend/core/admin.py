# core/admin.py
from django.contrib import admin
from django.db import transaction
from django.utils import timezone
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _

from core.models import (
    AccountClosureRequest,
    EmailChangeSupportRequest,
    EmailVerificationToken,
    Genre,
    Content,
    OfflineDownloadLicense,
    Payment,
    PaymentWebhookEvent,
    PasswordResetToken,
    PlaybackLicense,
    ProducerContentView,
    ProducerContractVersion,
    PlatformLegalIdentity,
    ProducerCountryCurrency,
    ProducerPayoutRequest,
    ProducerRevenueSetting,
    Profile,
    SubtitleTrack,
    SubscriptionPlan,
    TechnicalSpecification,
    User,
    VideoAsset,
    VideoRendition,
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('email', 'firstname', 'lastname', 'is_verified', 'is_producer', 'producer_remuneration_enabled', 'is_active', 'created_at')
    list_filter = ('is_active', 'is_verified', 'is_staff', 'is_superuser', 'is_producer', 'producer_remuneration_enabled')
    search_fields = ('email', 'firstname', 'lastname', 'producer_company')
    ordering = ('-created_at',)
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        (_('Personal info'), {'fields': ('firstname', 'lastname', 'phone', 'country_code')}),
        (_('Producer'), {'fields': ('is_producer', 'producer_company', 'producer_remuneration_enabled')}),
        (_('Permissions'), {'fields': ('is_active', 'is_verified', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        (_('Important dates'), {'fields': ('last_login', 'created_at', 'updated_at')}),
        (_('Preferences'), {'fields': ('preferences',)}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2'),
        }),
    )
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('name', 'user', 'type', 'age', 'is_active', 'created_at')
    list_filter = ('type', 'is_active')
    search_fields = ('name', 'user__email')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Content)
class ContentAdmin(admin.ModelAdmin):
    list_display = (
        'title',
        'type',
        'producer',
        'producer_submission_status',
        'release_year',
        'rating_avg',
        'view_count',
        'status',
    )
    list_filter = ('type', 'status', 'producer_submission_status', 'release_year')
    search_fields = ('title', 'original_title', 'description', 'producer__email')
    filter_horizontal = ('genres', 'emissions')
    readonly_fields = ('created_at', 'updated_at', 'view_count', 'rating_avg', 'rating_count')


@admin.register(ProducerContractVersion)
class ProducerContractVersionAdmin(admin.ModelAdmin):
    list_display = (
        'version',
        'title',
        'status',
        'effective_date',
        'requires_reacceptance',
        'published_at',
        'updated_at',
    )

    list_filter = (
        'status',
        'requires_reacceptance',
    )

    search_fields = (
        'version',
        'title',
    )

    readonly_fields = (
        'content_sha256',
        'published_at',
        'archived_at',
        'created_at',
        'updated_at',
    )

    fieldsets = (
        (
            'Version',
            {
                'fields': (
                    'version',
                    'title',
                    'status',
                    'effective_date',
                    'requires_reacceptance',
                )
            },
        ),
        (
            'Contenu contractuel',
            {
                'fields': (
                    'canonical_content',
                    'content_sha256',
                )
            },
        ),
        (
            'Publication',
            {
                'fields': (
                    'published_at',
                    'archived_at',
                    'created_at',
                    'updated_at',
                )
            },
        ),
    )

    def get_readonly_fields(self, request, obj=None):
        fields = list(super().get_readonly_fields(request, obj))

        if (
            obj is not None
            and obj.status
            in {
                ProducerContractVersion.STATUS_PUBLISHED,
                ProducerContractVersion.STATUS_ARCHIVED,
            }
        ):
            fields.extend(
                [
                    'version',
                    'title',
                    'status',
                    'effective_date',
                    'requires_reacceptance',
                    'canonical_content',
                ]
            )

        return tuple(dict.fromkeys(fields))

    def has_delete_permission(self, request, obj=None):
        if (
            obj is not None
            and obj.status
            in {
                ProducerContractVersion.STATUS_PUBLISHED,
                ProducerContractVersion.STATUS_ARCHIVED,
            }
        ):
            return False

        return super().has_delete_permission(
            request,
            obj,
        )

    def save_model(
        self,
        request,
        obj,
        form,
        change,
    ):
        from apps.auth.producer_contract_versions import (
            contract_content_sha256,
            normalize_contract_content,
            publish_contract_version,
        )

        previous_status = None

        if obj.pk:
            previous_status = (
                ProducerContractVersion.objects
                .filter(pk=obj.pk)
                .values_list('status', flat=True)
                .first()
            )

        if previous_status in {
            ProducerContractVersion.STATUS_PUBLISHED,
            ProducerContractVersion.STATUS_ARCHIVED,
        }:
            raise ValueError(
                'Une version contractuelle publiee ou archivee '
                'est immuable. Creez une nouvelle version.'
            )

        wants_publish = (
            obj.status
            == ProducerContractVersion.STATUS_PUBLISHED
        )

        if wants_publish:
            # Save the draft first so the publication service can lock
            # and publish the exact persisted version.
            obj.status = ProducerContractVersion.STATUS_DRAFT
            obj.canonical_content = normalize_contract_content(
                obj.canonical_content
            )
            obj.content_sha256 = contract_content_sha256(
                obj.canonical_content
            )

            super().save_model(
                request,
                obj,
                form,
                change,
            )

            publish_contract_version(obj)
            obj.refresh_from_db()
            return

        obj.canonical_content = normalize_contract_content(
            obj.canonical_content
        )

        obj.content_sha256 = (
            contract_content_sha256(obj.canonical_content)
            if obj.canonical_content
            else ''
        )

        super().save_model(
            request,
            obj,
            form,
            change,
        )


@admin.register(TechnicalSpecification)
class TechnicalSpecificationAdmin(admin.ModelAdmin):
    list_display = (
        'title',
        'version',
        'is_published',
        'published_at',
        'updated_at',
    )
    list_filter = ('is_published',)
    search_fields = ('title', 'version')
    readonly_fields = (
        'created_at',
        'updated_at',
    )

    def save_model(
        self,
        request,
        obj,
        form,
        change,
    ):
        with transaction.atomic():
            if obj.is_published:
                TechnicalSpecification.objects.filter(
                    is_published=True,
                ).exclude(
                    pk=obj.pk,
                ).update(
                    is_published=False,
                )

                if obj.published_at is None:
                    obj.published_at = timezone.now()

            super().save_model(
                request,
                obj,
                form,
                change,
            )


@admin.register(Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'created_at')
    search_fields = ('name',)
    prepopulated_fields = {'slug': ('name',)}


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'duration_days', 'max_profiles', 'max_devices', 'is_active')
    list_filter = ('is_active', 'ads_included')
    search_fields = ('name',)


@admin.register(VideoAsset)
class VideoAssetAdmin(admin.ModelAdmin):
    list_display = (
        'content',
        'episode',
        'status',
        'moderation_status',
        'moderated_by',
        'source_uploaded_by',
        'is_default',
        'is_downloadable',
        'drm_provider',
        'created_at',
    )
    list_filter = ('status', 'moderation_status', 'is_default', 'is_downloadable', 'drm_provider')
    search_fields = ('content__title', 'episode__title', 'title', 'source_uploaded_by__email')
    readonly_fields = ('created_at', 'updated_at', 'moderated_at')


@admin.register(VideoRendition)
class VideoRenditionAdmin(admin.ModelAdmin):
    list_display = ('asset', 'quality', 'width', 'height', 'bandwidth', 'display_order')
    list_filter = ('quality',)
    search_fields = ('asset__content__title',)
    readonly_fields = ('created_at', 'updated_at')


@admin.register(SubtitleTrack)
class SubtitleTrackAdmin(admin.ModelAdmin):
    list_display = ('asset', 'language', 'label', 'kind', 'is_default')
    list_filter = ('language', 'kind', 'is_default')
    search_fields = ('asset__content__title', 'label')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(OfflineDownloadLicense)
class OfflineDownloadLicenseAdmin(admin.ModelAdmin):
    list_display = ('profile', 'content', 'device_id', 'status', 'expires_at', 'created_at')
    list_filter = ('status', 'device_type')
    search_fields = ('profile__name', 'profile__user__email', 'content__title', 'device_id')
    readonly_fields = ('offline_token', 'created_at', 'updated_at')


@admin.register(PlaybackLicense)
class PlaybackLicenseAdmin(admin.ModelAdmin):
    list_display = ('profile', 'content', 'device_id', 'drm_provider', 'status', 'expires_at', 'created_at')
    list_filter = ('status', 'drm_provider', 'license_mode', 'device_type')
    search_fields = ('profile__name', 'profile__user__email', 'content__title', 'device_id')
    readonly_fields = ('license_token', 'created_at', 'updated_at', 'last_verified_at')


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('subscription', 'provider', 'status', 'amount', 'currency', 'provider_reference', 'paid_at')
    list_filter = ('provider', 'status', 'currency')
    search_fields = ('subscription__user__email', 'provider_reference', 'provider_payment_id')
    readonly_fields = ('created_at', 'updated_at', 'verified_at', 'provider_payload')


@admin.register(PaymentWebhookEvent)
class PaymentWebhookEventAdmin(admin.ModelAdmin):
    list_display = ('provider', 'event_type', 'provider_reference', 'signature_valid', 'processed', 'created_at')
    list_filter = ('provider', 'signature_valid', 'processed')
    search_fields = ('event_id', 'provider_reference', 'payment__subscription__user__email')
    readonly_fields = ('created_at', 'updated_at', 'processed_at')


@admin.register(ProducerRevenueSetting)
class ProducerRevenueSettingAdmin(admin.ModelAdmin):
    list_display = ('remuneration_enabled', 'eligible_progress_percent', 'rate_per_1000_views_eur', 'minimum_payout_eur', 'updated_at')


@admin.register(ProducerCountryCurrency)
class ProducerCountryCurrencyAdmin(admin.ModelAdmin):
    list_display = ('country_code', 'currency', 'eur_to_currency_rate', 'is_active', 'updated_at')
    list_filter = ('currency', 'is_active')
    search_fields = ('country_code', 'currency')


@admin.register(ProducerContentView)
class ProducerContentViewAdmin(admin.ModelAdmin):
    list_display = ('content', 'producer', 'progress_percent', 'amount_eur', 'currency', 'amount_local', 'status', 'counted_at')
    list_filter = ('status', 'currency', 'viewer_country_code')
    search_fields = ('content__title', 'producer__email')
    readonly_fields = ('counted_at',)


@admin.register(ProducerPayoutRequest)
class ProducerPayoutRequestAdmin(admin.ModelAdmin):
    list_display = ('producer', 'amount_eur', 'amount_local', 'currency', 'eligible_views', 'status', 'created_at')
    list_filter = ('status', 'currency')
    search_fields = ('producer__email', 'payout_account')
    readonly_fields = ('created_at', 'updated_at', 'reviewed_at', 'paid_at')


@admin.register(AccountClosureRequest)
class AccountClosureRequestAdmin(admin.ModelAdmin):
    list_display = ('user', 'request_type', 'status', 'requested_for', 'processed_at', 'created_at')
    list_filter = ('request_type', 'status')
    search_fields = ('user__email', 'reason', 'admin_reason')
    readonly_fields = ('created_at', 'updated_at', 'reviewed_at', 'processed_at')


@admin.register(EmailVerificationToken)
class EmailVerificationTokenAdmin(admin.ModelAdmin):
    list_display = ('user', 'token', 'expires_at', 'used_at', 'created_at')
    list_filter = ('used_at', 'expires_at')
    search_fields = ('user__email', '=token')
    readonly_fields = ('token', 'created_at', 'updated_at', 'used_at')


@admin.register(PasswordResetToken)
class PasswordResetTokenAdmin(admin.ModelAdmin):
    list_display = ('user', 'token', 'expires_at', 'used_at', 'created_at')
    list_filter = ('used_at', 'expires_at')
    search_fields = ('user__email', '=token')
    readonly_fields = ('token', 'created_at', 'updated_at', 'used_at')


@admin.register(EmailChangeSupportRequest)
class EmailChangeSupportRequestAdmin(admin.ModelAdmin):
    list_display = ('user', 'requested_email', 'status', 'reviewed_by', 'reviewed_at', 'created_at')
    list_filter = ('status',)
    search_fields = ('user__email', 'requested_email', 'reason', 'admin_reason')
    readonly_fields = ('created_at', 'updated_at', 'reviewed_at')


@admin.register(PlatformLegalIdentity)
class PlatformLegalIdentityAdmin(admin.ModelAdmin):
    list_display = (
        "legal_name",
        "legal_form",
        "siret",
        "city",
        "country",
        "is_active",
        "effective_from",
        "updated_at",
    )

    list_filter = (
        "is_active",
        "country",
    )

    search_fields = (
        "legal_name",
        "siret",
        "rcs",
        "vat_number",
        "city",
    )

    readonly_fields = (
        "created_at",
        "updated_at",
    )

    fieldsets = (
        (
            "Entreprise",
            {
                "fields": (
                    "legal_name",
                    "legal_form",
                    "capital",
                )
            },
        ),
        (
            "Immatriculation",
            {
                "fields": (
                    "siret",
                    "rcs",
                    "vat_number",
                )
            },
        ),
        (
            "Siège social",
            {
                "fields": (
                    "registered_office",
                    "postal_code",
                    "city",
                    "country",
                )
            },
        ),
        (
            "Représentation",
            {
                "fields": (
                    "representative_name",
                    "representative_role",
                )
            },
        ),
        (
            "Contact",
            {
                "fields": (
                    "email",
                    "website",
                )
            },
        ),
        (
            "Activation",
            {
                "fields": (
                    "effective_from",
                    "is_active",
                )
            },
        ),
        (
            "Audit",
            {
                "fields": (
                    "created_at",
                    "updated_at",
                )
            },
        ),
    )

    def save_model(
        self,
        request,
        obj,
        form,
        change,
    ):
        from apps.auth.platform_legal_identity import (
            activate_platform_legal_identity,
        )

        requested_active = bool(obj.is_active)

        # Save as inactive first so two active identities
        # cannot be introduced by a normal admin save.
        if requested_active:
            obj.is_active = False

        super().save_model(
            request,
            obj,
            form,
            change,
        )

        if requested_active:
            activate_platform_legal_identity(obj)
