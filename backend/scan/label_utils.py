import re
from typing import Optional, Tuple


def split_label(raw_label: str) -> Tuple[str, str]:
    """
    Splits a PlantVillage-style label: "Crop___Disease".
    Returns (crop_raw, disease_raw). If it cannot split, disease_raw may be "".
    """
    raw = (raw_label or "").strip()
    if "___" in raw:
        crop_raw, disease_raw = raw.split("___", 1)
        return crop_raw, disease_raw
    return raw, ""


def _clean_spaces(value: str) -> str:
    value = re.sub(r"\s+", " ", value).strip()
    return value


def format_crop_name(crop_raw: str) -> str:
    """
    "Corn_(maize)" -> "Corn (Maize)"
    "Pepper,_bell" -> "Pepper, Bell"
    """
    s = (crop_raw or "").strip()
    s = s.replace("_", " ")
    s = s.replace(" ,", ",").replace(", ", ", ")
    s = re.sub(r"\(\s+", "(", s)
    s = re.sub(r"\s+\)", ")", s)
    s = _clean_spaces(s)

    # Title-case words while keeping text inside parentheses reasonable.
    # This is a heuristic; we keep acronyms as-is.
    def _title_token(tok: str) -> str:
        if tok.isupper() and len(tok) <= 5:
            return tok
        return tok[:1].upper() + tok[1:].lower() if tok else tok

    parts = []
    for w in re.split(r"(\W+)", s):
        if not w or re.fullmatch(r"\W+", w):
            parts.append(w)
            continue
        parts.append(_title_token(w))
    return "".join(parts).strip()


def format_disease_name(disease_raw: str) -> str:
    """
    "Apple_scab" -> "Apple Scab"
    "Spider_mites Two-spotted_spider_mite" -> "Spider Mites Two-Spotted Spider Mite"
    "healthy" -> "Healthy"
    """
    s = (disease_raw or "").strip()
    if not s:
        return ""
    s = s.replace("_", " ")
    s = _clean_spaces(s)

    # Title-case with hyphens preserved
    def _title_word(word: str) -> str:
        if word.isupper() and len(word) <= 5:
            return word
        return "-".join(p[:1].upper() + p[1:].lower() for p in word.split("-") if p)

    return " ".join(_title_word(w) for w in s.split(" ")).strip()


def format_label_display(raw_label: Optional[str]) -> Optional[str]:
    """
    "Apple___Apple_scab" -> "Apple — Apple Scab"
    "Corn_(maize)___healthy" -> "Corn (Maize) — Healthy"
    """
    if not raw_label:
        return None
    crop_raw, disease_raw = split_label(str(raw_label))
    crop = format_crop_name(crop_raw)
    disease = format_disease_name(disease_raw) if disease_raw else ""
    if crop and disease:
        return f"{crop} — {disease}"
    return crop or disease or None


def format_crop_and_disease(raw_label: Optional[str]) -> Tuple[Optional[str], Optional[str]]:
    if not raw_label:
        return None, None
    crop_raw, disease_raw = split_label(str(raw_label))
    crop = format_crop_name(crop_raw) if crop_raw else None
    disease = format_disease_name(disease_raw) if disease_raw else None
    return crop, disease

