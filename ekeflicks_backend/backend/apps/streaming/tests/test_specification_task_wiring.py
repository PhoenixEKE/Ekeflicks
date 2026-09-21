from types import SimpleNamespace
from unittest.mock import patch

from django.test import SimpleTestCase

from apps.streaming import tasks


class SpecificationTaskWiringTests(SimpleTestCase):

    @patch(
        "apps.streaming.tasks."
        "_master_technical_specification"
    )
    @patch(
        "apps.streaming.tasks."
        "evaluate_master_conformity"
    )
    def test_master_evaluator_receives_resolved_specification(
        self,
        evaluate,
        resolve,
    ):
        pinned = object()

        asset = SimpleNamespace(
            delivery_level="distribution",
        )

        report = SimpleNamespace(
            frame_rate=25.0,
        )

        resolve.return_value = pinned
        evaluate.return_value = {
            "status": "conform",
            "blocking": False,
            "blocking_errors": [],
            "warnings": [],
            "checks": [],
            "specification_version": "PINNED",
        }

        metadata = {}

        specification = (
            tasks._master_technical_specification(
                asset
            )
        )

        conformity = (
            tasks.evaluate_master_conformity(
                metadata=metadata,
                frame_rate=report.frame_rate,
                delivery_level=asset.delivery_level,
                specification=specification,
            )
        )

        self.assertIs(
            specification,
            pinned,
        )

        evaluate.assert_called_once_with(
            metadata=metadata,
            frame_rate=25.0,
            delivery_level="distribution",
            specification=pinned,
        )

        self.assertEqual(
            conformity[
                "specification_version"
            ],
            "PINNED",
        )

    @patch(
        "apps.streaming.tasks."
        "_trailer_technical_specification"
    )
    @patch(
        "apps.streaming.tasks."
        "evaluate_trailer_conformity"
    )
    def test_trailer_evaluator_receives_resolved_specification(
        self,
        evaluate,
        resolve,
    ):
        pinned = object()

        report = SimpleNamespace()

        resolve.return_value = pinned

        evaluate.return_value = {
            "status": "conform",
            "blocking": False,
            "blocking_errors": [],
            "warnings": [],
            "checks": [],
            "specification_version": "PINNED",
        }

        metadata = {}

        specification = (
            tasks._trailer_technical_specification(
                report
            )
        )

        conformity = (
            tasks.evaluate_trailer_conformity(
                metadata=metadata,
                delivery_level="distribution",
                specification=specification,
            )
        )

        self.assertIs(
            specification,
            pinned,
        )

        evaluate.assert_called_once_with(
            metadata=metadata,
            delivery_level="distribution",
            specification=pinned,
        )

        self.assertEqual(
            conformity[
                "specification_version"
            ],
            "PINNED",
        )
