from django.db import transaction
from django.utils import timezone

from .models import UserSubscription


def user_has_active_paid_subscription(user):
    return UserSubscription.active_now_for_user(user).exists()


def _expire_overdue_for_user(user):
    now = timezone.now()
    return UserSubscription.objects.filter(
        user=user,
        status="active",
        is_active=True,
        end_date__lt=now,
    ).update(status="expired", is_active=False)


def _demote_paid_without_subscription(user):
    user.refresh_from_db(fields=["role"])
    if user.role != "paid":
        return
    if user_has_active_paid_subscription(user):
        return
    user.role = "guest"
    user.save(update_fields=["role"])


def ensure_subscription_access_synced(user):
    """Expire overdue subscriptions and downgrade paid users with no valid plan."""
    with transaction.atomic():
        _expire_overdue_for_user(user)
        _demote_paid_without_subscription(user)
