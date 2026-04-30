import json
import os
import logging
import hashlib
import uuid
import re
from typing import Any, Optional

try:
    import google.generativeai as genai
except Exception:  # pragma: no cover
    genai = None
from django.conf import settings

_CONFIGURED = False
_LAST_WORKING_MODEL: Optional[str] = None
logger = logging.getLogger(__name__)


def _get_api_key() -> Optional[str]:
    return (
        getattr(settings, "GEMINI_API_KEY", None)
        or os.environ.get("GEMINI_API_KEY")
        or os.environ.get("GOOGLE_API_KEY")
    )


def _configure_client() -> bool:
    global _CONFIGURED

    if _CONFIGURED:
        return True

    if genai is None:
        logger.warning("Gemini client not available (google-generativeai not installed).")
        return False

    api_key = _get_api_key()
    if not api_key:
        logger.warning("Gemini API key not configured (set GEMINI_API_KEY or GOOGLE_API_KEY).")
        return False

    genai.configure(api_key=api_key)
    _CONFIGURED = True
    return True


def _normalize_model_name(name: str) -> str:
    name = name.strip()
    return name[len("models/") :] if name.startswith("models/") else name


def _list_supported_models() -> list[str]:
    if genai is None:
        return []
    try:
        models = genai.list_models()
    except Exception:
        return []

    supported: list[str] = []
    for model in models or []:
        model_name = getattr(model, "name", None)
        methods = getattr(model, "supported_generation_methods", None) or []
        try:
            if model_name and "generateContent" in list(methods):
                supported.append(_normalize_model_name(str(model_name)))
        except Exception:
            continue

    return supported


def _candidate_model_names(preferred: Optional[str]) -> list[str]:
    candidates: list[str] = []

    if _LAST_WORKING_MODEL:
        candidates.append(_LAST_WORKING_MODEL)

    if preferred:
        candidates.append(preferred)

    # Reasonable defaults across Gemini generations; actual availability varies by project/API version.
    candidates.extend(
        [
            "gemini-1.5-flash-latest",
            "gemini-1.5-pro-latest",
            "gemini-2.0-flash",
            "gemini-2.0-flash-lite",
            "gemini-2.0-pro",
        ]
    )

    # De-duplicate while preserving order.
    seen: set[str] = set()
    uniq: list[str] = []
    for name in candidates:
        if not name:
            continue
        normalized = _normalize_model_name(str(name))
        if normalized in seen:
            continue
        seen.add(normalized)
        uniq.append(normalized)
    return uniq


def _build_prompt(crop: str, disease_name: str) -> str:
    schema = {
        "organic": "step by step organic treatment",
        "chemical": "chemical treatment with usage guidance",
        "tips": "prevention methods",
    }

    return (
        "You are an expert agricultural plant pathologist.\n\n"
        f"Crop: {crop}\n"
        f"Disease: {disease_name}\n\n"
        "Return ONLY valid JSON:\n"
        f"{json.dumps(schema, indent=2)}\n\n"
        "Rules:\n"
        "- No explanation\n"
        "- No markdown\n"
        "- Only JSON\n"
    )


def _try_parse_json_object(text: str) -> Optional[dict[str, Any]]:
    cleaned = text.strip().replace("```json", "").replace("```", "").strip()

    try:
        parsed = json.loads(cleaned)
        return parsed if isinstance(parsed, dict) else None
    except json.JSONDecodeError:
        pass

    # Fallback: extract the first {...} blob in case the model adds extra text.
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return None

    try:
        parsed = json.loads(cleaned[start : end + 1])
        return parsed if isinstance(parsed, dict) else None
    except json.JSONDecodeError:
        return None


def call_ai(crop, disease_name):

    try:
        if not _configure_client():
            return None

        if not crop or not disease_name:
            return None

        prompt = _build_prompt(str(crop), str(disease_name))
        request_id = uuid.uuid4().hex[:10]
        prompt_hash = hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:12]

        preferred_model = getattr(settings, "GEMINI_MODEL", None)
        model_candidates = _candidate_model_names(preferred_model)

        logger.info(
            "Gemini call start id=%s crop=%s disease=%s prompt_hash=%s models=%s",
            request_id,
            crop,
            disease_name,
            prompt_hash,
            ",".join(model_candidates[:5]) + ("..." if len(model_candidates) > 5 else ""),
        )
        if getattr(settings, "GEMINI_DEBUG", False):
            logger.debug("Gemini prompt id=%s:\n%s", request_id, prompt)

        def _attempt_models(candidates: list[str]) -> Optional[dict[str, Any]]:
            nonlocal last_error
            for model_name in candidates:
                try:
                    model = genai.GenerativeModel(model_name)
                    response = model.generate_content(prompt)
                    text = getattr(response, "text", None)
                    if not text:
                        logger.warning("Gemini empty response id=%s model=%s", request_id, model_name)
                        continue

                    parsed = _try_parse_json_object(text)
                    if parsed is None:
                        preview = text.strip().replace("\n", " ")
                        logger.warning(
                            "Gemini parse failed id=%s model=%s preview=%s",
                            request_id,
                            model_name,
                            preview[:200],
                        )
                        continue

                    global _LAST_WORKING_MODEL
                    _LAST_WORKING_MODEL = model_name
                    logger.info(
                        "Gemini call success id=%s model=%s keys=%s",
                        request_id,
                        model_name,
                        sorted(parsed.keys()),
                    )
                    return parsed
                except Exception as exc:
                    last_error = exc
                    message = str(exc)
                    if "ResourceExhausted" in exc.__class__.__name__ or "quota" in message.lower():
                        logger.warning("Gemini quota exceeded id=%s model=%s", request_id, model_name)
                        return None
                    if "is not found" in message or "NotFound" in exc.__class__.__name__:
                        logger.warning("Gemini model not found id=%s model=%s", request_id, model_name)
                        continue
                    raise
            return None

        def _quota_error_payload(exc: Exception) -> dict[str, Any]:
            message = str(exc)
            retry_after = None
            m = re.search(r"Please retry in ([0-9.]+)s", message)
            if m:
                try:
                    retry_after = float(m.group(1))
                except ValueError:
                    retry_after = None

            payload: dict[str, Any] = {"__error__": "quota_exceeded", "message": message}
            if retry_after is not None:
                payload["retry_after_seconds"] = retry_after
            return payload

        last_error: Optional[Exception] = None

        parsed = _attempt_models(model_candidates)
        if parsed is not None:
            return parsed

        if getattr(settings, "GEMINI_LIST_MODELS", False):
            try:
                supported = _list_supported_models()
                if supported:
                    logger.info(
                        "Gemini retry with listed models id=%s count=%s",
                        request_id,
                        len(supported),
                    )
                    parsed = _attempt_models(supported)
                    if parsed is not None:
                        return parsed
            except Exception:
                logger.exception("Gemini list_models failed id=%s", request_id)

        if last_error is not None:
            # Special-case quota errors to inform the caller.
            if "ResourceExhausted" in last_error.__class__.__name__ or "quota" in str(last_error).lower():
                logger.warning("Gemini quota exceeded id=%s", request_id)
                return _quota_error_payload(last_error)

            logger.warning(
                "Gemini no working model id=%s last_error=%s",
                request_id,
                str(last_error)[:200],
            )
        return None

    except Exception:
        logger.exception("Gemini call failed")
        return None
