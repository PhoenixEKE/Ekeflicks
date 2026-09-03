from django.conf import settings
from django.db import models

from .base import TimeStampedModel


class ProducerAccount(TimeStampedModel):
    """
    Compte professionnel d'un producteur EKEFLICKS.

    Le rôle User.is_producer identifie le type d'utilisateur.
    ProducerAccount gère l'état métier de son onboarding.
    """

    STATUS_ONBOARDING = 'onboarding'
    STATUS_CONTRACT_PENDING = 'contract_pending'
    STATUS_ACTIVE = 'active'
    STATUS_SUSPENDED = 'suspended'
    STATUS_REJECTED = 'rejected'

    STATUS_CHOICES = [
        (STATUS_ONBOARDING, 'Onboarding'),
        (STATUS_CONTRACT_PENDING, 'Contract pending'),
        (STATUS_ACTIVE, 'Active'),
        (STATUS_SUSPENDED, 'Suspended'),
        (STATUS_REJECTED, 'Rejected'),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='producer_account',
    )

    company_name = models.CharField(max_length=255)
    legal_name = models.CharField(max_length=255, blank=True)

    legal_form = models.CharField(
        max_length=120,
        blank=True,
        help_text="Legal form of the producer, e.g. SAS, SARL, SA, LLC.",
    )

    registration_number = models.CharField(
        max_length=120,
        blank=True,
        help_text="Company/business registration number when applicable.",
    )

    tax_number = models.CharField(
        max_length=120,
        blank=True,
    )

    country_code = models.CharField(
        max_length=2,
        blank=True,
    )

    address = models.TextField(blank=True)
    city = models.CharField(max_length=120, blank=True)
    phone = models.CharField(max_length=30, blank=True)

    representative_name = models.CharField(
        max_length=255,
        blank=True,
    )

    representative_role = models.CharField(
        max_length=150,
        blank=True,
    )

    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default=STATUS_ONBOARDING,
        db_index=True,
    )

    activated_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    suspended_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    rejection_reason = models.TextField(blank=True)

    class Meta:
        db_table = 'producer_accounts'
        indexes = [
            models.Index(
                fields=['status', 'created_at'],
                name='producer_acc_status_idx',
            ),
        ]

    def __str__(self):
        return f'{self.company_name} ({self.user_id})'


class ProducerAgreement(TimeStampedModel):
    """
    Trace immuable du contrat présenté et signé par un producteur.

    Une nouvelle version de contrat doit créer un nouvel enregistrement
    plutôt que modifier l'historique de la version précédente.
    """

    STATUS_PENDING = 'pending'
    STATUS_SIGNED = 'signed'
    STATUS_SUPERSEDED = 'superseded'
    STATUS_TERMINATED = 'terminated'

    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_SIGNED, 'Signed'),
        (STATUS_SUPERSEDED, 'Superseded'),
        (STATUS_TERMINATED, 'Terminated'),
    ]

    SIGNATURE_CLICKWRAP = 'clickwrap'
    SIGNATURE_EXTERNAL = 'external_esign'

    SIGNATURE_METHOD_CHOICES = [
        (SIGNATURE_CLICKWRAP, 'Clickwrap'),
        (SIGNATURE_EXTERNAL, 'External electronic signature'),
    ]

    producer_account = models.ForeignKey(
        ProducerAccount,
        on_delete=models.CASCADE,
        related_name='agreements',
    )

    contract_version = models.CharField(
        max_length=50,
    )

    contract_title = models.CharField(
        max_length=255,
    )

    contract_hash = models.CharField(
        max_length=64,
        blank=True,
        help_text='SHA-256 hexadecimal hash of the exact contract document.',
    )

    contract_document_url = models.URLField(
        max_length=1000,
        blank=True,
    )

    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default=STATUS_PENDING,
        db_index=True,
    )

    signer_name = models.CharField(
        max_length=255,
        blank=True,
    )

    signer_role = models.CharField(
        max_length=150,
        blank=True,
    )

    signature_method = models.CharField(
        max_length=30,
        choices=SIGNATURE_METHOD_CHOICES,
        default=SIGNATURE_CLICKWRAP,
    )

    accepted_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    signed_at = models.DateTimeField(
        null=True,
        blank=True,
        db_index=True,
    )

    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
    )

    user_agent = models.TextField(blank=True)

    # --------------------------------------------------------
    # Immutable legal snapshot used for this exact agreement.
    # These fields must not depend on future modifications of
    # ProducerAccount once the agreement has been signed.
    # --------------------------------------------------------

    effective_date = models.DateField(
        null=True,
        blank=True,
    )

    producer_legal_name = models.CharField(
        max_length=255,
        blank=True,
    )

    producer_legal_form = models.CharField(
        max_length=120,
        blank=True,
    )

    producer_country_code = models.CharField(
        max_length=2,
        blank=True,
    )

    producer_address = models.TextField(
        blank=True,
    )

    producer_city = models.CharField(
        max_length=120,
        blank=True,
    )

    producer_registration_number = models.CharField(
        max_length=120,
        blank=True,
    )

    producer_tax_number = models.CharField(
        max_length=120,
        blank=True,
    )

    producer_representative_name = models.CharField(
        max_length=255,
        blank=True,
    )

    producer_representative_role = models.CharField(
        max_length=150,
        blank=True,
    )

    # Private B2 object key for the exact personalized contract
    # presented to the Producer before acceptance.
    presented_document_key = models.CharField(
        max_length=1000,
        blank=True,
    )

    # Private B2 object key for the final signed contract.
    signed_document_key = models.CharField(
        max_length=1000,
        blank=True,
    )

    # Authenticated application URL, never the private B2 object URL.
    signed_document_url = models.URLField(
        max_length=1000,
        blank=True,
    )

    signed_document_hash = models.CharField(
        max_length=64,
        blank=True,
        help_text="SHA-256 of the final personalized signed PDF.",
    )

    ekeflicks_signer_name = models.CharField(
        max_length=255,
        blank=True,
    )

    ekeflicks_signer_role = models.CharField(
        max_length=150,
        blank=True,
    )

    ekeflicks_signed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    class Meta:
        db_table = 'producer_agreements'
        constraints = [
            models.UniqueConstraint(
                fields=['producer_account', 'contract_version'],
                name='producer_agreement_version_unique',
            ),
        ]
        indexes = [
            models.Index(
                fields=['producer_account', 'status'],
                name='producer_agr_status_idx',
            ),
        ]

    def __str__(self):
        return (
            f'{self.producer_account_id} - '
            f'{self.contract_version} - {self.status}'
        )
