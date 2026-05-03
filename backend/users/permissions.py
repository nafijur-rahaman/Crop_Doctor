from rest_framework.permissions import BasePermission


class RolePermission(BasePermission):
    allowed_roles = []
    message = "You are not allowed to access this."

    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and request.user.role in self.allowed_roles
        )


class IsPaidUser(BasePermission):
    message = "Active subscription required."

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.user.role != "paid":
            return False
        from subscriptions.access import (
            ensure_subscription_access_synced,
            user_has_active_paid_subscription,
        )

        ensure_subscription_access_synced(request.user)
        request.user.refresh_from_db(fields=["role"])
        if request.user.role != "paid":
            return False
        return user_has_active_paid_subscription(request.user)


class IsExpert(RolePermission):
    allowed_roles = ["expert"]


class IsSuperAdmin(RolePermission):
    allowed_roles = ["superadmin"]


class IsPremiumAccess(BasePermission):
    message = "Premium access requires an active subscription."

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        role = request.user.role
        if role in ("superadmin", "expert"):
            return True
        if role != "paid":
            return False
        from subscriptions.access import (
            ensure_subscription_access_synced,
            user_has_active_paid_subscription,
        )

        ensure_subscription_access_synced(request.user)
        request.user.refresh_from_db(fields=["role"])
        if request.user.role != "paid":
            return False
        return user_has_active_paid_subscription(request.user)


class IsExpertAccess(RolePermission):
    allowed_roles = [
        "expert",
        "superadmin",
    ]

