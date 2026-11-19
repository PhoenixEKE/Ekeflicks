from types import SimpleNamespace
from unittest.mock import patch, Mock

from django.test import SimpleTestCase

from apps.catalog.submission_conformity import (
    _source_identity,
    _asset_result,
    _conformity_from_report,
)


class SubmissionConformityGateTests(SimpleTestCase):
    def setUp(self):
        self.asset = SimpleNamespace(
            id="00000000-0000-0000-0000-000000000001",
            delivery_level="distribution",
            source_file_path="uploads/test/submission-master.mp4",
            source_file_size_bytes=100,
            source_file_url="",
            source_uploaded_at=None,
        )
        self.specification = SimpleNamespace(version="1.3")

    def test_review_required_analysis_allows_submission(self):
        report = SimpleNamespace(
            status="review_required",
            technical_metadata={
                "source_identity": _source_identity(self.asset),
            },
            error_message="",
        )

        result = _conformity_from_report(
            report,
            self.specification,
            self.asset,
        )

        self.assertEqual(
            result["status"],
            "review_required",
        )
        self.assertFalse(result["blocking"])

    def test_passed_conform_master_is_acceptable(self):
        report = SimpleNamespace(status="passed")

        conformity = {
            "status": "conform",
            "blocking": False,
        }

        with patch(
            "apps.catalog.submission_conformity._analysis_report",
            return_value=report,
        ), patch(
            "apps.catalog.submission_conformity._conformity_from_report",
            return_value=conformity,
        ):
            result = _asset_result(
                self.asset,
                self.specification,
            )

        self.assertTrue(result["acceptable"])

    def test_passed_non_blocking_review_master_is_acceptable(self):
        report = SimpleNamespace(status="passed")

        conformity = {
            "status": "review_required",
            "blocking": False,
        }

        with patch(
            "apps.catalog.submission_conformity._analysis_report",
            return_value=report,
        ), patch(
            "apps.catalog.submission_conformity._conformity_from_report",
            return_value=conformity,
        ):
            result = _asset_result(
                self.asset,
                self.specification,
            )

        self.assertTrue(result["acceptable"])

    def test_passed_blocking_review_master_is_not_acceptable(self):
        report = SimpleNamespace(status="passed")

        conformity = {
            "status": "review_required",
            "blocking": True,
        }

        with patch(
            "apps.catalog.submission_conformity._analysis_report",
            return_value=report,
        ), patch(
            "apps.catalog.submission_conformity._conformity_from_report",
            return_value=conformity,
        ):
            result = _asset_result(
                self.asset,
                self.specification,
            )

        self.assertFalse(result["acceptable"])

    def test_review_required_report_is_not_acceptable(self):
        report = SimpleNamespace(
            status="review_required",
        )

        conformity = {
            "status": "review_required",
            "blocking": True,
        }

        with patch(
            "apps.catalog.submission_conformity._analysis_report",
            return_value=report,
        ), patch(
            "apps.catalog.submission_conformity._conformity_from_report",
            return_value=conformity,
        ):
            result = _asset_result(
                self.asset,
                self.specification,
            )

        self.assertFalse(result["acceptable"])

    def test_missing_report_is_not_acceptable(self):
        conformity = {
            "status": "analysis_missing",
            "blocking": True,
        }

        with patch(
            "apps.catalog.submission_conformity._analysis_report",
            return_value=None,
        ), patch(
            "apps.catalog.submission_conformity._conformity_from_report",
            return_value=conformity,
        ):
            result = _asset_result(
                self.asset,
                self.specification,
            )

        self.assertFalse(result["acceptable"])
        self.assertEqual(
            result["analysis_status"],
            "not_started",
        )


class SubmissionThreeStateContractTests(SimpleTestCase):
    """
    STEP 2 submission contract.

    The asset-level result exposes the real submission gate contract:
    acceptable=True  -> submission may continue
    acceptable=False -> submission must be blocked
    """

    def test_review_required_is_acceptable_for_submission(self):
        report = Mock(status="review_required")

        conformity = {
            "status": "review_required",
            "blocking": False,
            "blocking_errors": [],
            "warnings": [
                {
                    "code": "technical.human_review_required",
                    "message": "Human technical review required.",
                }
            ],
        }

        with patch(
            "apps.catalog.submission_conformity._analysis_report",
            return_value=report,
        ), patch(
            "apps.catalog.submission_conformity._conformity_from_report",
            return_value=conformity,
        ):
            result = _asset_result(Mock(), Mock())

        self.assertTrue(result["acceptable"])
        self.assertEqual(
            result["analysis_status"],
            "review_required",
        )

    def test_blocking_non_conformity_is_not_acceptable(self):
        report = Mock(status="passed")

        conformity = {
            "status": "non_conform",
            "blocking": True,
            "blocking_errors": [
                {
                    "code": "master.fake.blocking",
                    "message": "Blocking technical failure.",
                }
            ],
            "warnings": [],
        }

        with patch(
            "apps.catalog.submission_conformity._analysis_report",
            return_value=report,
        ), patch(
            "apps.catalog.submission_conformity._conformity_from_report",
            return_value=conformity,
        ):
            result = _asset_result(Mock(), Mock())

        self.assertFalse(result["acceptable"])

    def test_conform_master_is_acceptable(self):
        report = Mock(status="passed")

        conformity = {
            "status": "conform",
            "blocking": False,
            "blocking_errors": [],
            "warnings": [],
        }

        with patch(
            "apps.catalog.submission_conformity._analysis_report",
            return_value=report,
        ), patch(
            "apps.catalog.submission_conformity._conformity_from_report",
            return_value=conformity,
        ):
            result = _asset_result(Mock(), Mock())

        self.assertTrue(result["acceptable"])
