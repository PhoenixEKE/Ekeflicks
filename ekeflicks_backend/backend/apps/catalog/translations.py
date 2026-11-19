"""Helpers for source-hash-aware English/French display translations."""
import hashlib
import json


def source_hash(payload):
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def translated_payload(translations, language, source):
    """Return a cached translation only if it belongs to this exact source."""
    entry = (translations or {}).get(language)
    if not isinstance(entry, dict) or entry.get("source_hash") != source_hash(source):
        return source
    value = entry.get("value")
    return value if isinstance(value, dict) else source


def content_source(content):
    source = {
        "title": content.title,
        "description": content.description,
        "synopsis": content.synopsis,
    }
    # Criteria and other producer-defined text fields are carried in structured
    # extension data when present, without translating technical measurements.
    return source


def language_for_request(request):
    value = request.query_params.get("language") or request.headers.get("Accept-Language", "")
    code = str(value).split(",", 1)[0].split("-", 1)[0].lower()
    return code if code in {"fr", "en"} else "fr"


def translate_texts(value, translate):
    """Translate every human-readable string while preserving JSON shape."""
    if isinstance(value, str):
        return translate(value) if value.strip() else value
    if isinstance(value, list):
        return [translate_texts(item, translate) for item in value]
    if isinstance(value, dict):
        return {key: translate_texts(item, translate) for key, item in value.items()}
    return value


def translate_technical_texts(value, translate):
    """Translate specification prose while keeping machine values/codes exact."""
    if isinstance(value, str):
        return translate(value) if value.strip() else value
    if isinstance(value, list):
        return [translate_technical_texts(item, translate) for item in value]
    if isinstance(value, dict):
        protected_keys = {'value', 'code', 'format', 'id', 'slug', 'version', 'unit', 'source_hash'}
        return {
            key: item if str(key).lower() in protected_keys
            else translate_technical_texts(item, translate)
            for key, item in value.items()
        }
    return value
