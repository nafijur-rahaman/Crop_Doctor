

from django.core.cache import cache
from django.utils import timezone

GUEST_WEEKLY_LIMIT = 3
CACHE_TTL_SECONDS  = 8 * 24 * 3600   


def _cache_key(device_id: str) -> str:
    iso = timezone.now().isocalendar()
    return f"guest_scans:{device_id}:{iso.year}:{iso.week}"


def get_guest_scan_status(device_id: str) -> dict:

    if not device_id:
        return {"allowed": False, "used": GUEST_WEEKLY_LIMIT,
                "remaining": 0, "limit": GUEST_WEEKLY_LIMIT}

    key  = _cache_key(device_id)
    used = cache.get(key, 0)

    return {
        "allowed":   used < GUEST_WEEKLY_LIMIT,
        "used":      used,
        "remaining": max(0, GUEST_WEEKLY_LIMIT - used),
        "limit":     GUEST_WEEKLY_LIMIT,
    }


def increment_guest_scan(device_id: str) -> int:

    key = _cache_key(device_id)
    try:
        # cache.incr is atomic in Redis
        new_count = cache.incr(key)
        if new_count == 1:
            # First scan this week — set the TTL
            cache.expire(key, CACHE_TTL_SECONDS)
        return new_count
    except ValueError:
        # Key didn't exist yet (some cache backends raise ValueError on incr of missing key)
        cache.set(key, 1, timeout=CACHE_TTL_SECONDS)
        return 1


def reset_guest_scans(device_id: str):
    """Admin utility to manually reset a guest's scan counter."""
    cache.delete(_cache_key(device_id))




def get_registered_guest_scan_status(user_id: str) -> dict:
    iso = timezone.now().isocalendar()
    key  = f"user_scans:{user_id}:{iso.year}:{iso.week}"
    used = cache.get(key, 0)
    return {
        "allowed":   used < GUEST_WEEKLY_LIMIT,
        "used":      used,
        "remaining": max(0, GUEST_WEEKLY_LIMIT - used),
        "limit":     GUEST_WEEKLY_LIMIT,
    }


def increment_registered_guest_scan(user_id: str) -> int:
    iso = timezone.now().isocalendar()
    key = f"user_scans:{user_id}:{iso.year}:{iso.week}"
    try:
        new_count = cache.incr(key)
        if new_count == 1:
            cache.expire(key, CACHE_TTL_SECONDS)
        return new_count
    except ValueError:
        cache.set(key, 1, timeout=CACHE_TTL_SECONDS)
        return 1
