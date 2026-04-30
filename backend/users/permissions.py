from rest_framework.permissions import BasePermission


class RolePermission(BasePermission):
    allowed_roles = []
    message = "You are not allowed to access this."

    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and request.user.role in self.allowed_roles
        )


class IsPaidUser(RolePermission):
    allowed_roles = ["paid"]


class IsExpert(RolePermission):
    allowed_roles = ["expert"]


class IsSuperAdmin(RolePermission):
    allowed_roles = ["superadmin"]


class IsPremiumAccess(RolePermission):
    allowed_roles = [
        "paid",
        "expert",
        "superadmin",
    ]


class IsExpertAccess(RolePermission):
    allowed_roles = [
        "expert",
        "superadmin",
    ]

