import requests
import logging
import re
from datetime import timedelta
from django.core.cache import cache
from django.utils import timezone
from .ai_service import call_ai

from .models import ScanHistory, DiseaseSolution, MissingSolutionLog, Plant

HF_URL = "https://nafijur-rahaman-crop-doctor-api.hf.space/predict"
logger = logging.getLogger(__name__)


MIN_CONFIDENCE_TO_TRUST = 25.0
MAX_GUEST_SCANS_PER_WEEK = 3


def _normalize_crop_name(value: str) -> str:
    value = (value or "").strip().lower()
    value = value.replace(" ", "_").replace("-", "_")
    value = re.sub(r"[^a-z0-9_()]+", "", value)
    return value


def _crop_from_disease_label(disease_label: str) -> str:
    if not disease_label:
        return ""
    head = str(disease_label).split("___", 1)[0]
    return _normalize_crop_name(head)


def select_best_prediction_for_crop(prediction: dict, crop: str) -> dict:
    """
    Pick the best disease prediction for the user-selected crop.

    - If the top-1 prediction crop matches the user crop, keep it.
    - Otherwise, try to pick the highest-confidence item from top_5 that matches the crop.
    - If nothing matches, return status=crop_mismatch (keeps the original top-1 disease).
    """
    user_crop = _normalize_crop_name(crop)
    status = prediction.get("status") or "ok"

    # Predictor may return "plant" for normal cases; treat it like ok.
    if status in {"error", "not_a_plant"}:
        return prediction

    disease = prediction.get("disease")
    confidence = float(prediction.get("confidence") or 0)
    top_5 = prediction.get("top_5") or []
    if not isinstance(top_5, list):
        top_5 = []

    # Prefer the best match for the selected crop across (top-1 + top_5).
    candidates = [{"disease": disease, "confidence": confidence}, *top_5]

    best = None
    best_conf = -1.0
    for item in candidates:
        if not isinstance(item, dict):
            continue
        item_disease = item.get("disease")
        if not item_disease:
            continue
        if _crop_from_disease_label(item_disease) != user_crop:
            continue
        item_conf = float(item.get("confidence") or 0)
        if item_conf > best_conf:
            best_conf = item_conf
            best = item

    if best is None:
        return {
            **prediction,
            "status": "crop_mismatch",
            "disease": None,
            "confidence": 0.0,
            "message": "Selected crop wasn't found in the prediction results. Please select the correct crop or upload a clearer leaf photo.",
            "detected": {"disease": disease, "confidence": confidence},
        }

    chosen_disease = best.get("disease")
    chosen_conf = float(best.get("confidence") or 0)

    used_top_5 = bool(disease) and chosen_disease != disease
    result_status = "used_top_5" if used_top_5 else "ok"

    result = {
        **prediction,
        "disease": chosen_disease,
        "confidence": chosen_conf,
        "status": result_status,
    }

    if used_top_5:
        result["message"] = "Top prediction didn't match the selected crop; using the best match from top_5."

    if chosen_conf < MIN_CONFIDENCE_TO_TRUST:
        result["status"] = "low_confidence"
        result["message"] = "Low confidence for the selected crop. Please upload a clearer, well-lit photo of a single leaf."

    return result


def get_prediction(image):
    if image is None:
        return {
            "status": "error",
            "message": "image is required",
            "disease": "Unknown",
            "confidence": 0,
            "top_5": [],
        }
    try:
        response = requests.post(
            HF_URL,
            files={"file": image},
            timeout=20
        )
        response.raise_for_status()

        data = response.json()
        if not isinstance(data, dict):
            raise ValueError("Prediction response is not an object")

        data.setdefault("status", "ok")
        data.setdefault("disease", "Unknown")
        data.setdefault("confidence", 0)
        data.setdefault("top_5", [])
        return data
    except (requests.RequestException, ValueError):
        return {
            "status": "error",
            "disease": "Unknown",
            "confidence": 0,
            "top_5": []
        }

def _week_start(dt):
    return (dt - timedelta(days=dt.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )


def _next_week_start(dt):
    return (_week_start(dt) + timedelta(days=7))


def _guest_week_cache_key(guest_id, dt):
    iso_year, iso_week, _ = dt.isocalendar()
    return f"scan:guest:week:{iso_year}:{iso_week}:{guest_id}"


def _seconds_until_next_week(dt):
    seconds = int((_next_week_start(dt) - dt).total_seconds())
    return max(seconds, 60)


def _get_cached_or_db_guest_week_count(guest_id, now):
    key = _guest_week_cache_key(guest_id, now)
    cached_count = cache.get(key)
    if cached_count is not None:
        return key, int(cached_count)

    week_start = _week_start(now)
    db_count = ScanHistory.objects.filter(
        guest_id=guest_id,
        created_at__gte=week_start,
    ).count()
    cache.set(key, db_count, timeout=_seconds_until_next_week(now))
    return key, int(db_count)


def check_guest_limit(guest_id):
    now = timezone.now()
    _, count = _get_cached_or_db_guest_week_count(guest_id, now)
    return count < MAX_GUEST_SCANS_PER_WEEK


def consume_guest_scan(guest_id):
    """
    Reserve one guest scan in the current calendar week.
    Returns (allowed: bool, remaining_after: int).
    """
    now = timezone.now()
    key, count = _get_cached_or_db_guest_week_count(guest_id, now)

    if count >= MAX_GUEST_SCANS_PER_WEEK:
        return False, 0

    updated = count + 1
    cache.set(key, updated, timeout=_seconds_until_next_week(now))
    return True, (MAX_GUEST_SCANS_PER_WEEK - updated)

def validate_crop(crop, disease_name):

    if not crop or not disease_name:
        return False

    return disease_name.lower().startswith(crop.lower())





def get_solution(disease_name, crop):

    def _plant_for_crop_name(name: str):
        if not name:
            return None
        return Plant.objects.filter(name__iexact=str(name).strip()).first()

    # -----------------------
    # 1. DB CHECK
    # -----------------------
    solution = DiseaseSolution.objects.filter(
        disease_name=disease_name
    ).first()

    if solution:
        if solution.plant_id is None:
            plant = _plant_for_crop_name(crop)
            if plant is not None:
                solution.plant = plant
                solution.save(update_fields=["plant"])
        return {
            "organic": solution.organic_solution,
            "chemical": solution.chemical_solution,
            "tips": solution.prevention_tips,
            "source": "db"
        }

    # -----------------------
    # 2. AI FALLBACK (NOW CLEAN CALL)
    # -----------------------
    parsed = call_ai(crop, disease_name)

    # -----------------------
    # 3. AI SUCCESS
    # -----------------------
    if parsed and isinstance(parsed, dict) and "__error__" not in parsed:

        organic = (parsed.get("organic") or "").strip()
        chemical = (parsed.get("chemical") or "").strip()
        tips = (parsed.get("tips") or "").strip()

        # Treat empty/invalid payload as failure.
        if organic or chemical or tips:
            plant = _plant_for_crop_name(crop)
            solution = DiseaseSolution.objects.create(
                disease_name=disease_name,
                plant=plant,
                organic_solution=organic,
                chemical_solution=chemical,
                prevention_tips=tips,
                is_ai_generated=True
            )

            return {
                "organic": organic,
                "chemical": chemical,
                "tips": tips,
                "source": "ai"
            }

    logger.warning("AI solution unavailable for crop=%s disease=%s", crop, disease_name)

    # -----------------------
    # 4. AI FAIL → LOG + SAFE RESPONSE
    # -----------------------
    existing = MissingSolutionLog.objects.filter(
        disease_name=disease_name,
        crop=crop,
    ).order_by("resolved", "created_at", "id").first()

    if existing is None:
        MissingSolutionLog.objects.create(
            disease_name=disease_name,
            crop=crop
        )

    return {
        "organic": None,
        "chemical": None,
        "tips": None,
        "source": "missing",
        "message": "We currently don’t have a verified solution for this disease. Please try again later—our team has been notified and will update it soon."
    }
