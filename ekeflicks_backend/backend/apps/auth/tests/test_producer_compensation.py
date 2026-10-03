from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from apps.auth.producer_compensation import (
    parse_contract_compensation,
    terms_for_new_agreement,
)
from apps.auth.producer_contract_versions import (
    ProducerContractVersionError,
    publish_contract_version,
)
from core.models import ProducerAccount, ProducerAgreement, ProducerContractVersion


class ProducerCompensationContractTests(TestCase):
    def setUp(self):
        user = get_user_model().objects.create_user(
            email='contract-producer@example.com', password='StrongPassword!234',
            is_producer=True,
        )
        self.account = ProducerAccount.objects.create(
            user=user, company_name='Contract Producer',
        )
        self.previous = ProducerAgreement.objects.create(
            producer_account=self.account,
            contract_version='legacy-2024',
            contract_title='Legacy agreement',
            status=ProducerAgreement.STATUS_SIGNED,
            signed_at=timezone.now(),
            effective_date=timezone.localdate(),
            rate_per_1000_views_eur=Decimal('1.524490'),
            eligible_progress_percent=Decimal('70.00'),
            advertising_share_percent=Decimal('57.50'),
            compensation_terms_source='backfilled_contract_text',
        )

    def test_extracts_compensation_from_immutable_contract_text(self):
        content = '''
        Le Producteur perçoit (1,23 €) pour mille Vues Éligibles.
        Une Vue Éligible suppose 75 % du Contenu.
        - 55 % au Producteur ;
        - 45 % à EKEFLICKS.
        '''
        self.assertEqual(parse_contract_compensation(content), {
            'rate_per_1000_views_eur': Decimal('1.23'),
            'eligible_progress_percent': Decimal('75'),
            'advertising_share_percent': Decimal('55'),
        })

    def test_fcfa_contract_rate_converts_to_reference_eur(self):
        terms = parse_contract_compensation(
            'Le montant de référence de mille (1 000) francs CFA BCEAO '
            '(FCFA) pour mille (1 000) Vues Éligibles.'
        )
        self.assertEqual(terms['rate_per_1000_views_eur'], Decimal('1.524490'))

    def test_new_contract_without_amendment_carries_old_signed_terms(self):
        version = ProducerContractVersion.objects.create(
            version='new-legal-text', title='New legal text',
            canonical_content='New legal content with compensation placeholders.',
        )
        terms = terms_for_new_agreement(
            self.account, contract_version=version.version,
        )
        self.assertEqual(terms['rate_per_1000_views_eur'], Decimal('1.524490'))
        self.assertEqual(terms['advertising_share_percent'], Decimal('57.50'))
        self.assertEqual(terms['previous_agreement'], self.previous)
        self.assertFalse(terms['compensation_amendment'])

    def test_explicit_signed_version_amendment_changes_terms(self):
        version = ProducerContractVersion.objects.create(
            version='compensation-amendment', title='Compensation amendment',
            amends_compensation=True,
            rate_per_1000_views_eur=Decimal('2.250000'),
            eligible_progress_percent=Decimal('65.00'),
            advertising_share_percent=Decimal('62.00'),
            canonical_content='Amendment with compensation placeholders.',
        )
        terms = terms_for_new_agreement(
            self.account, contract_version=version.version,
        )
        self.assertEqual(terms['rate_per_1000_views_eur'], Decimal('2.250000'))
        self.assertEqual(terms['advertising_share_percent'], Decimal('62.00'))
        self.assertEqual(terms['previous_agreement'], self.previous)
        self.assertTrue(terms['compensation_amendment'])

    def test_compensation_amendment_must_require_producer_reacceptance(self):
        version = ProducerContractVersion.objects.create(
            version='unaccepted-amendment', title='Amendment',
            amends_compensation=True,
            rate_per_1000_views_eur=Decimal('2.250000'),
            eligible_progress_percent=Decimal('65.00'),
            advertising_share_percent=Decimal('62.00'),
            canonical_content=(
                '{{producer_rate_per_1000_views_eur}} '
                '{{producer_eligible_progress_percent}} '
                '{{producer_advertising_share_percent}} '
                '{{ekeflicks_advertising_share_percent}}'
            ),
        )
        with self.assertRaises(ProducerContractVersionError):
            publish_contract_version(version)
