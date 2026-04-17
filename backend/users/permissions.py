from rest_framework.permissions import BasePermission


# ── Paid tier 

class IsPaidUser(BasePermission):

    message = "A paid subscription is required to access this feature."

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.is_paid_or_above
        )


# ── Expert tier 

class IsExpert(BasePermission):

    message = "Expert access is required."

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.is_expert_or_above
        )


# ── Super admin 

class IsSuperAdmin(BasePermission):

    message = "Super admin access is required."

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.is_superadmin
        )


# ── Read-only for paid, write for expert 

class IsPaidReadExpertWrite(BasePermission):

    message = "You do not have permission for this action."

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        if request.method in ("GET", "HEAD", "OPTIONS"):
            return request.user.is_paid_or_above
        return request.user.is_expert_or_above


# ── Owner or admin ────────────────────────────────────────────────────────────

class IsOwnerOrSuperAdmin(BasePermission):

    message = "You do not have permission to access this resource."

    def has_object_permission(self, request, view, obj):
        if request.user and request.user.is_superadmin:
            return True
        owner = getattr(obj, "user", obj)
        return owner == request.user


# ── Safe-read 

class IsAuthenticatedOrGuestReadOnly(BasePermission):

    def has_permission(self, request, view):
        if request.method in ("GET", "HEAD", "OPTIONS"):
            return True
        return request.user and request.user.is_authenticated
