from io import BytesIO
from pathlib import Path

from django.conf import settings
from django.http import FileResponse
from django.utils import timezone
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import (
    ParagraphStyle,
    getSampleStyleSheet,
)
from reportlab.lib.units import mm
from reportlab.platypus import (
    Image,
    Paragraph,
    PageBreak,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)
from rest_framework import serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import TechnicalSpecification


class TechnicalSpecificationSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = TechnicalSpecification
        fields = [
            "id",
            "title",
            "version",
            "introduction",
            "sections",
            "published_at",
            "updated_at",
        ]
        read_only_fields = fields


def _published_specification():
    return (
        TechnicalSpecification.objects
        .filter(is_published=True)
        .order_by(
            "-published_at",
            "-created_at",
        )
        .first()
    )


class PublishedTechnicalSpecificationView(
    APIView
):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        specification = (
            _published_specification()
        )

        if specification is None:
            return Response(
                {
                    "detail": (
                        "Aucun cahier des charges "
                        "technique n'est actuellement "
                        "publie."
                    )
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = (
            TechnicalSpecificationSerializer(
                specification
            )
        )

        return Response(serializer.data)



def _technical_specification_logo_path():
    candidates = [
        (
            Path(settings.BASE_DIR)
            / "apps"
            / "catalog"
            / "static"
            / "catalog"
            / "images"
            / "logo_light.png"
        ),
        (
            Path(settings.BASE_DIR)
            / "backend"
            / "apps"
            / "catalog"
            / "static"
            / "catalog"
            / "images"
            / "logo_light.png"
        ),
    ]

    for candidate in candidates:
        if candidate.is_file():
            return candidate

    return None


def _technical_specification_page(
    canvas,
    document,
    specification,
):
    canvas.saveState()

    width, height = A4

    logo_path = _technical_specification_logo_path()

    if logo_path is not None:
        try:
            canvas.drawImage(
                str(logo_path),
                document.leftMargin,
                height - 16 * mm,
                width=28 * mm,
                height=8 * mm,
                preserveAspectRatio=True,
                anchor="w",
                mask="auto",
            )
        except Exception:
            pass

    canvas.setFont("Helvetica-Bold", 7.5)
    canvas.setFillColor(
        colors.HexColor("#444444")
    )
    canvas.drawRightString(
        width - document.rightMargin,
        height - 11.5 * mm,
        "CAHIER DES CHARGES TECHNIQUE",
    )

    canvas.setStrokeColor(
        colors.HexColor("#DDDDDD")
    )
    canvas.setLineWidth(0.4)
    canvas.line(
        document.leftMargin,
        height - 18 * mm,
        width - document.rightMargin,
        height - 18 * mm,
    )

    canvas.line(
        document.leftMargin,
        14 * mm,
        width - document.rightMargin,
        14 * mm,
    )

    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(
        colors.HexColor("#666666")
    )
    canvas.drawString(
        document.leftMargin,
        9 * mm,
        (
            "EKEFLICKS — Spécifications techniques "
            "de livraison"
        ),
    )

    canvas.drawRightString(
        width - document.rightMargin,
        9 * mm,
        (
            f"Version {specification.version}  |  "
            f"Page {document.page}"
        ),
    )

    canvas.restoreState()

def _build_pdf(specification):
    buffer = BytesIO()

    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=25 * mm,
        bottomMargin=22 * mm,
        title=specification.title,
        author="EKEFLICKS",
    )

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        "EkeflicksTitle",
        parent=styles["Title"],
        alignment=TA_CENTER,
        fontSize=20,
        leading=24,
        spaceAfter=8 * mm,
    )

    section_style = ParagraphStyle(
        "EkeflicksSection",
        parent=styles["Heading2"],
        fontSize=14,
        leading=18,
        spaceBefore=5 * mm,
        spaceAfter=3 * mm,
    )

    body_style = ParagraphStyle(
        "EkeflicksBody",
        parent=styles["BodyText"],
        fontSize=10,
        leading=14,
        spaceAfter=2 * mm,
    )

    story = []

    logo_path = _technical_specification_logo_path()

    if logo_path is not None:
        story.extend(
            [
                Spacer(1, 18 * mm),
                Image(
                    str(logo_path),
                    width=52 * mm,
                    height=15 * mm,
                    kind="proportional",
                ),
                Spacer(1, 14 * mm),
            ]
        )
    else:
        story.append(Spacer(1, 25 * mm))

    story.extend(
        [
            Paragraph(
                specification.title,
                title_style,
            ),
            Paragraph(
                "Spécifications pour la livraison des assets",
                ParagraphStyle(
                    "EkeflicksSubtitle",
                    parent=styles["Heading2"],
                    alignment=TA_CENTER,
                    fontSize=12,
                    leading=16,
                    textColor=colors.HexColor("#555555"),
                    spaceAfter=8 * mm,
                ),
            ),
            Paragraph(
                f"Version {specification.version}",
                ParagraphStyle(
                    "EkeflicksVersion",
                    parent=styles["Heading3"],
                    alignment=TA_CENTER,
                    fontSize=11,
                    leading=14,
                ),
            ),
        ]
    )

    if specification.published_at:
        published = timezone.localtime(
            specification.published_at
        ).strftime("%d/%m/%Y")

        story.append(
            Paragraph(
                f"Publication : {published}",
                body_style,
            )
        )

    introduction = str(
        specification.introduction or ""
    ).strip()

    if introduction:
        story.extend(
            [
                Spacer(1, 4 * mm),
                Paragraph(
                    introduction,
                    body_style,
                ),
            ]
        )

    sections = (
        specification.sections
        if isinstance(
            specification.sections,
            list,
        )
        else []
    )

    if sections:
        story.append(PageBreak())

    for section in sections:
        if not isinstance(section, dict):
            continue

        section_title = str(
            section.get("title") or "Section"
        ).strip()

        story.append(
            Paragraph(
                section_title,
                section_style,
            )
        )

        description = str(
            section.get("description") or ""
        ).strip()

        if description:
            story.append(
                Paragraph(
                    description,
                    body_style,
                )
            )

        items = section.get("items") or []

        if not isinstance(items, list):
            continue

        rows = [
            [
                "Critere",
                "Exigence",
            ]
        ]

        for item in items:
            if isinstance(item, dict):
                label = str(
                    item.get("label") or ""
                ).strip()

                value = str(
                    item.get("value") or ""
                ).strip()
            else:
                label = ""
                value = str(item).strip()

            if not label and not value:
                continue

            rows.append(
                [
                    Paragraph(
                        label,
                        body_style,
                    ),
                    Paragraph(
                        value,
                        body_style,
                    ),
                ]
            )

        if len(rows) <= 1:
            continue

        table = Table(
            rows,
            colWidths=[
                55 * mm,
                101 * mm,
            ],
            repeatRows=1,
        )

        table.setStyle(
            TableStyle(
                [
                    (
                        "BACKGROUND",
                        (0, 0),
                        (-1, 0),
                        colors.HexColor(
                            "#EEEEEE"
                        ),
                    ),
                    (
                        "FONTNAME",
                        (0, 0),
                        (-1, 0),
                        "Helvetica-Bold",
                    ),
                    (
                        "VALIGN",
                        (0, 0),
                        (-1, -1),
                        "TOP",
                    ),
                    (
                        "GRID",
                        (0, 0),
                        (-1, -1),
                        0.4,
                        colors.HexColor(
                            "#CCCCCC"
                        ),
                    ),
                    (
                        "LEFTPADDING",
                        (0, 0),
                        (-1, -1),
                        6,
                    ),
                    (
                        "RIGHTPADDING",
                        (0, 0),
                        (-1, -1),
                        6,
                    ),
                    (
                        "TOPPADDING",
                        (0, 0),
                        (-1, -1),
                        5,
                    ),
                    (
                        "BOTTOMPADDING",
                        (0, 0),
                        (-1, -1),
                        5,
                    ),
                ]
            )
        )

        story.extend(
            [
                table,
                Spacer(1, 3 * mm),
            ]
        )

    page_callback = lambda canvas, doc: (
        _technical_specification_page(
            canvas,
            doc,
            specification,
        )
    )

    document.build(
        story,
        onFirstPage=page_callback,
        onLaterPages=page_callback,
    )
    buffer.seek(0)

    return buffer


class PublishedTechnicalSpecificationPdfView(
    APIView
):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        specification = (
            _published_specification()
        )

        if specification is None:
            return Response(
                {
                    "detail": (
                        "Aucun cahier des charges "
                        "technique n'est actuellement "
                        "publie."
                    )
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        buffer = _build_pdf(specification)

        filename = (
            "cahier-des-charges-technique-"
            f"{specification.version}.pdf"
        )

        return FileResponse(
            buffer,
            as_attachment=True,
            filename=filename,
            content_type="application/pdf",
        )
