from __future__ import annotations

import hashlib
import io
import re
from dataclasses import dataclass
from html import escape

from django.utils import timezone

from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import (
    ParagraphStyle,
    getSampleStyleSheet,
)
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas as pdfcanvas
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from core.models.producers import ProducerContractVersion

from apps.auth.producer_contract_context import (
    agreement_platform_contract_context,
    full_contract_context,
    producer_contract_context,
)
from apps.auth.contract_templates.producer_contract_placeholders import (
    ALL_CONTRACT_PLACEHOLDERS,
)


class CanonicalContractRenderError(Exception):
    pass


@dataclass(frozen=True)
class CanonicalRenderedContract:
    pdf_bytes: bytes
    sha256: str
    effective_date: object


_PLACEHOLDER_RE = re.compile(
    r"\{\{([a-zA-Z0-9_]+)\}\}"
)


def _normalize(value):
    if value is None:
        return ""
    return str(value).replace(
        "\r\n",
        "\n",
    ).replace(
        "\r",
        "\n",
    )


def _signature_datetime(value):
    if value is None:
        return ""

    if timezone.is_naive(value):
        value = timezone.make_aware(
            value,
            timezone.get_current_timezone(),
        )

    return (
        value.astimezone(
            timezone.utc
        ).strftime(
            "%Y-%m-%d %H:%M:%S UTC"
        )
    )


def get_db_contract_version(version):
    version = str(version or "").strip()

    if not version:
        return None

    return (
        ProducerContractVersion.objects
        .filter(version=version)
        .first()
    )


def uses_db_canonical_renderer(version):
    obj = get_db_contract_version(version)

    return bool(
        obj
        and obj.canonical_content
        and obj.canonical_content.strip()
    )


def build_contract_context(
    account,
    *,
    ekeflicks_signed_at=None,
    agreement=None,
):
    if agreement is None:
        context = full_contract_context(account)
    else:
        context = {}
        context.update(
            producer_contract_context(account)
        )
        context.update(
            agreement_platform_contract_context(
                agreement
            )
        )

    context[
        "ekeflicks_signature_datetime"
    ] = _signature_datetime(
        ekeflicks_signed_at
    )

    return context


def render_canonical_text(
    canonical_content,
    context,
):
    text = _normalize(canonical_content)

    allowed = set(
        ALL_CONTRACT_PLACEHOLDERS
    )

    found = set(
        _PLACEHOLDER_RE.findall(text)
    )

    unknown = sorted(found - allowed)

    if unknown:
        raise CanonicalContractRenderError(
            "Placeholders contractuels inconnus : "
            + ", ".join(unknown)
        )

    optional_values = {
        "producer_phone",
        "producer_tax_number",
    }

    missing_values = sorted(
        name
        for name in found
        if (
            name not in optional_values
            and not str(
                context.get(name, "")
            ).strip()
        )
    )

    if missing_values:
        raise CanonicalContractRenderError(
            "Valeurs contractuelles manquantes : "
            + ", ".join(missing_values)
        )

    for name in sorted(
        found,
        key=len,
        reverse=True,
    ):
        value = context.get(name, "")

        if (
            name in optional_values
            and not str(value).strip()
        ):
            value = "Non renseigné"

        text = text.replace(
            "{{" + name + "}}",
            str(value),
        )

    unresolved = sorted(
        set(
            _PLACEHOLDER_RE.findall(text)
        )
    )

    if unresolved:
        raise CanonicalContractRenderError(
            "Placeholders contractuels non resolus : "
            + ", ".join(unresolved)
        )

    return text


def _inline_markup(value):
    value = escape(value)

    value = re.sub(
        r"\*\*(.+?)\*\*",
        r"<b>\1</b>",
        value,
    )

    value = re.sub(
        r"\*(.+?)\*",
        r"<i>\1</i>",
        value,
    )

    return value


def _paragraph(
    text,
    style,
):
    return Paragraph(
        _inline_markup(text),
        style,
    )


def _markdown_table(lines, styles):
    rows = []

    for raw in lines:
        cells = [
            cell.strip()
            for cell in raw.strip().strip("|").split("|")
        ]

        rows.append(cells)

    if len(rows) >= 2:
        separator = rows[1]

        if all(
            re.fullmatch(
                r":?-{3,}:?",
                cell.replace(" ", ""),
            )
            for cell in separator
        ):
            rows.pop(1)

    if not rows:
        return None

    width = max(len(row) for row in rows)

    normalized = []

    for row in rows:
        row = row + [""] * (
            width - len(row)
        )

        normalized.append(
            [
                _paragraph(
                    cell,
                    styles["table"],
                )
                for cell in row
            ]
        )

    table = Table(
        normalized,
        repeatRows=1,
        hAlign="LEFT",
    )

    table.setStyle(
        TableStyle(
            [
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
                    0.35,
                    (0, 0, 0),
                ),
                (
                    "BACKGROUND",
                    (0, 0),
                    (-1, 0),
                    (0.92, 0.92, 0.92),
                ),
                (
                    "LEFTPADDING",
                    (0, 0),
                    (-1, -1),
                    4,
                ),
                (
                    "RIGHTPADDING",
                    (0, 0),
                    (-1, -1),
                    4,
                ),
                (
                    "TOPPADDING",
                    (0, 0),
                    (-1, -1),
                    4,
                ),
                (
                    "BOTTOMPADDING",
                    (0, 0),
                    (-1, -1),
                    4,
                ),
            ]
        )
    )

    return table


class _ContractNumberedCanvas(pdfcanvas.Canvas):
    def __init__(self, *args, **kwargs):
        # The presented contract SHA is part of the signing
        # integrity check. ReportLab must therefore generate
        # identical PDF bytes for identical contract content.
        kwargs["invariant"] = 1
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(
            dict(self.__dict__)
        )
        self._startPage()

    def save(self):
        total_pages = len(
            self._saved_page_states
        )

        for state in self._saved_page_states:
            self.__dict__.update(state)
            self._draw_contract_footer(
                total_pages
            )
            super().showPage()

        super().save()

    def _draw_contract_footer(
        self,
        total_pages,
    ):
        page_number = self._pageNumber

        self.saveState()

        left = 18 * mm
        right = A4[0] - (18 * mm)
        line_y = 13 * mm
        text_y = 8.5 * mm

        self.setStrokeColorRGB(
            0.45,
            0.45,
            0.45,
        )
        self.setLineWidth(0.35)

        self.line(
            left,
            line_y,
            right,
            line_y,
        )

        self.setFillColorRGB(
            0,
            0,
            0,
        )
        self.setFont(
            "Helvetica",
            7.5,
        )

        self.drawString(
            left,
            text_y,
            "Contrat-Cadre Producteur EKEFLICKS — "
            "Version 2026-09-v5",
        )

        self.drawRightString(
            right,
            text_y,
            f"Page {page_number} sur {total_pages}",
        )

        self.restoreState()


def _draw_contract_first_page_header(
    canvas,
    doc,
):
    logo_path = (
        "/app/apps/catalog/static/catalog/images/"
        "logo_light.png"
    )

    try:
        canvas.saveState()

        logo_width = 42 * mm
        logo_height = 14 * mm

        x = A4[0] - (10 * mm) - logo_width
        y = A4[1] - (4 * mm) - logo_height

        canvas.drawImage(
            logo_path,
            x,
            y,
            width=logo_width,
            height=logo_height,
            preserveAspectRatio=True,
            anchor="ne",
            mask="auto",
        )

        canvas.restoreState()
    except Exception:
        try:
            canvas.restoreState()
        except Exception:
            pass


def canonical_text_to_pdf(text):
    buffer = io.BytesIO()

    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=18 * mm,
        bottomMargin=22 * mm,
        title="Contrat-cadre Producteur EKEFLICKS",
        author="EKEFLICKS",
    )

    base = getSampleStyleSheet()

    styles = {
        "h1": ParagraphStyle(
            "ContractH1",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=15,
            leading=19,
            spaceBefore=10,
            spaceAfter=8,
            alignment=TA_CENTER,
        ),
        "subtitle": ParagraphStyle(
            "ContractSubtitle",
            parent=base["Heading2"],
            fontName="Helvetica",
            fontSize=11.5,
            leading=15,
            spaceBefore=2,
            spaceAfter=12,
            alignment=TA_CENTER,
        ),
        "h2": ParagraphStyle(
            "ContractH2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=15,
            spaceBefore=9,
            spaceAfter=6,
        ),
        "h3": ParagraphStyle(
            "ContractH3",
            parent=base["Heading3"],
            fontName="Helvetica-Bold",
            fontSize=10.5,
            leading=13,
            spaceBefore=7,
            spaceAfter=5,
        ),
        "body": ParagraphStyle(
            "ContractBody",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.8,
            leading=12,
            spaceAfter=6,
        ),
        "bullet": ParagraphStyle(
            "ContractBullet",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.8,
            leading=12,
            leftIndent=12,
            firstLineIndent=-7,
            spaceAfter=4,
        ),
        "table": ParagraphStyle(
            "ContractTable",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=7.5,
            leading=9.5,
        ),
        "center": ParagraphStyle(
            "ContractCenter",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.5,
            leading=11,
            alignment=TA_CENTER,
        ),
    }

    story = []

    lines = _normalize(text).split("\n")
    i = 0
    first_h2 = True

    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip()

        if not stripped:
            story.append(
                Spacer(1, 3)
            )
            i += 1
            continue

        if stripped == "---":
            story.append(
                Spacer(1, 5)
            )
            i += 1
            continue

        if stripped.startswith("|"):
            table_lines = []

            while (
                i < len(lines)
                and lines[i].strip().startswith("|")
            ):
                table_lines.append(
                    lines[i]
                )
                i += 1

            table = _markdown_table(
                table_lines,
                styles,
            )

            if table is not None:
                story.append(table)
                story.append(
                    Spacer(1, 6)
                )

            continue

        if stripped.startswith("# "):
            story.append(
                _paragraph(
                    stripped[2:].strip(),
                    styles["h1"],
                )
            )
            i += 1
            continue

        if stripped.startswith("## "):
            style = (
                styles["subtitle"]
                if first_h2
                else styles["h2"]
            )

            story.append(
                _paragraph(
                    stripped[3:].strip(),
                    style,
                )
            )

            first_h2 = False
            i += 1
            continue

        if stripped.startswith("### "):
            story.append(
                _paragraph(
                    stripped[4:].strip(),
                    styles["h3"],
                )
            )
            i += 1
            continue

        if stripped.startswith(("- ", "* ")):
            story.append(
                _paragraph(
                    "• " + stripped[2:].strip(),
                    styles["bullet"],
                )
            )
            i += 1
            continue

        paragraph_lines = [
            stripped
        ]

        i += 1

        while i < len(lines):
            candidate = lines[i].strip()

            if (
                not candidate
                or candidate == "---"
                or candidate.startswith("#")
                or candidate.startswith("|")
                or candidate.startswith("- ")
                or candidate.startswith("* ")
            ):
                break

            paragraph_lines.append(
                candidate
            )
            i += 1

        story.append(
            _paragraph(
                " ".join(paragraph_lines),
                styles["body"],
            )
        )

    doc.build(
        story,
        onFirstPage=_draw_contract_first_page_header,
        onLaterPages=_draw_contract_first_page_header,
        canvasmaker=_ContractNumberedCanvas,
    )

    return buffer.getvalue()


def render_db_presented_contract(
    account,
    *,
    contract_version,
    ekeflicks_signed_at,
    agreement=None,
):
    version = get_db_contract_version(
        contract_version
    )

    if (
        version is None
        or not version.canonical_content.strip()
    ):
        raise CanonicalContractRenderError(
            "Version contractuelle canonique BDD introuvable."
        )

    context = build_contract_context(
        account,
        ekeflicks_signed_at=ekeflicks_signed_at,
        agreement=agreement,
    )

    rendered_text = render_canonical_text(
        version.canonical_content,
        context,
    )

    pdf_bytes = canonical_text_to_pdf(
        rendered_text
    )

    effective_date = (
        version.effective_date
        or timezone.localdate(
            ekeflicks_signed_at
        )
    )

    return CanonicalRenderedContract(
        pdf_bytes=pdf_bytes,
        sha256=hashlib.sha256(
            pdf_bytes
        ).hexdigest(),
        effective_date=effective_date,
    )


def append_signature_evidence_page(
    presented_pdf_bytes,
    *,
    contract_version,
    contract_title,
    producer_legal_name,
    signer_name,
    signer_role,
    signer_email,
    signer_ip,
    signed_at,
    contract_hash,
    ekeflicks_signer_name,
    ekeflicks_signer_role,
):
    """
    Append signature evidence to the exact presented PDF.

    The original presented PDF pages are copied unchanged. Only one
    evidence page is appended. The contract body is never regenerated.
    """
    from pypdf import PdfReader, PdfWriter
    from reportlab.pdfgen import canvas

    if not presented_pdf_bytes.startswith(b"%PDF"):
        raise CanonicalContractRenderError(
            "Le document présenté n'est pas un PDF valide."
        )

    actual_hash = hashlib.sha256(
        presented_pdf_bytes
    ).hexdigest()

    if actual_hash != contract_hash:
        raise CanonicalContractRenderError(
            "Le hash du document présenté ne correspond pas "
            "au hash contractuel enregistré."
        )

    signed_at_text = _signature_datetime(
        signed_at
    )

    evidence = io.BytesIO()

    c = canvas.Canvas(
        evidence,
        pagesize=A4,
    )

    width, height = A4

    left = 20 * mm
    right = width - 20 * mm
    y = height - 22 * mm

    c.setTitle(
        "Preuve de signature électronique EKEFLICKS"
    )

    c.setFont(
        "Helvetica-Bold",
        15,
    )
    c.drawString(
        left,
        y,
        "PREUVE DE SIGNATURE ÉLECTRONIQUE",
    )

    y -= 10 * mm

    c.setFont(
        "Helvetica",
        9,
    )

    rows = [
        (
            "Version du contrat",
            contract_version,
        ),
        (
            "Titre",
            contract_title,
        ),
        (
            "Producteur",
            producer_legal_name,
        ),
        (
            "Signataire Producteur",
            signer_name,
        ),
        (
            "Qualité du signataire",
            signer_role,
        ),
        (
            "E-mail du signataire",
            signer_email,
        ),
        (
            "Adresse IP",
            signer_ip,
        ),
        (
            "Date et heure de signature",
            signed_at_text,
        ),
        (
            "Signataire EKEFLICKS",
            ekeflicks_signer_name,
        ),
        (
            "Qualité EKEFLICKS",
            ekeflicks_signer_role,
        ),
        (
            "SHA-256 du document présenté",
            contract_hash,
        ),
    ]

    label_width = 55 * mm
    line_height = 7 * mm

    for label, value in rows:
        value = str(value or "")

        c.setFont(
            "Helvetica-Bold",
            8.5,
        )
        c.drawString(
            left,
            y,
            label + " :",
        )

        c.setFont(
            "Helvetica",
            8.5,
        )

        max_chars = 78
        chunks = [
            value[i:i + max_chars]
            for i in range(
                0,
                max(len(value), 1),
                max_chars,
            )
        ] or [""]

        value_y = y

        for chunk in chunks:
            c.drawString(
                left + label_width,
                value_y,
                chunk,
            )
            value_y -= 4.5 * mm

        y = min(
            y - line_height,
            value_y,
        )

        if y < 30 * mm:
            c.showPage()
            y = height - 22 * mm

    y -= 5 * mm

    c.setFont(
        "Helvetica",
        8,
    )

    statement = (
        "Le présent feuillet constitue la preuve technique "
        "attachée au document contractuel présenté au Producteur. "
        "Le corps du contrat précédent n'a pas été régénéré lors "
        "de la signature."
    )

    text_obj = c.beginText(
        left,
        y,
    )
    text_obj.setLeading(
        11
    )

    words = statement.split()
    line = ""

    for word in words:
        candidate = (
            line + " " + word
        ).strip()

        if len(candidate) > 95:
            text_obj.textLine(line)
            line = word
        else:
            line = candidate

    if line:
        text_obj.textLine(line)

    c.drawText(text_obj)

    c.save()

    evidence.seek(0)

    original_reader = PdfReader(
        io.BytesIO(
            presented_pdf_bytes
        )
    )

    evidence_reader = PdfReader(
        evidence
    )

    writer = PdfWriter()

    for page in original_reader.pages:
        writer.add_page(page)

    for page in evidence_reader.pages:
        writer.add_page(page)

    output = io.BytesIO()
    writer.write(output)

    signed_pdf = output.getvalue()

    if not signed_pdf.startswith(b"%PDF"):
        raise CanonicalContractRenderError(
            "Le PDF signé généré est invalide."
        )

    return signed_pdf
