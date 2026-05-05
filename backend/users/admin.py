from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.html import format_html
from django.db.models import Count, Q
from .models import User


class RoleFilter(admin.SimpleListFilter):
    """Custom filter for user roles with icon display"""
    title = "User Role"
    parameter_name = "role"

    def lookups(self, request, model_admin):
        return [
            ("guest", "👤 Guest Users"),
            ("paid", "💳 Paid Users"),
            ("expert", "👨‍🔬 Experts"),
            ("superadmin", "👑 Super Admins"),
        ]

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(role=self.value())
        return queryset


class VerificationFilter(admin.SimpleListFilter):
    """Custom filter for verified users"""
    title = "Verification Status"
    parameter_name = "verified"

    def lookups(self, request, model_admin):
        return [
            ("verified", "✓ Verified"),
            ("unverified", "✗ Unverified"),
        ]

    def queryset(self, request, queryset):
        if self.value() == "verified":
            return queryset.filter(is_verified=True)
        elif self.value() == "unverified":
            return queryset.filter(is_verified=False)
        return queryset


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ("Extra Info", {
            "fields": ("role", "phone", "profile_image", "is_verified"),
            "classes": ("wide", "extrapretty"),
            "description": "Additional user information",
        }),
    )

    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ("Extra Info", {
            "fields": ("role", "phone", "profile_image", "is_verified"),
            "classes": ("wide", "extrapretty"),
        }),
    )

    list_display = (
        "get_user_display",
        "email",
        "get_role_badge",
        "get_verification_status",
        "phone",
        "date_joined",
        "is_active",
    )

    list_filter = (
        RoleFilter,
        VerificationFilter,
        "is_active",
        "date_joined",
        "is_staff",
    )

    search_fields = (
        "username",
        "email",
        "phone",
        "first_name",
        "last_name",
    )

    readonly_fields = (
        "date_joined",
        "last_login",
        "get_role_display_readonly",
    )

    ordering = ("-date_joined",)
    list_per_page = 25

    def get_user_display(self, obj):
        """Display user with avatar-like circle"""
        initials = f"{obj.first_name[0]}{obj.last_name[0]}".upper(
        ) if obj.first_name and obj.last_name else obj.username[0].upper()
        return format_html(
            '<div style="display: flex; align-items: center;"><div style="background-color: #00A36C; color: white; border-radius: 50%; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; margin-right: 8px; font-weight: bold;">{}</div>{}</div>',
            initials,
            obj.username
        )
    get_user_display.short_description = "User"

    def get_role_badge(self, obj):
        """Display role with colored badge"""
        role_colors = {
            "guest": "#95a5a6",
            "paid": "#3498db",
            "expert": "#e74c3c",
            "superadmin": "#9b59b6",
        }
        role_icons = {
            "guest": "👤",
            "paid": "💳",
            "expert": "👨‍🔬",
            "superadmin": "👑",
        }
        color = role_colors.get(obj.role, "#7f8c8d")
        icon = role_icons.get(obj.role, "")
        label = obj.get_role_display()
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; border-radius: 20px; font-size: 11px; font-weight: bold;">{} {}</span>',
            color,
            icon,
            label
        )
    get_role_badge.short_description = "Role"

    def get_verification_status(self, obj):
        """Display verification status with icon"""
        if obj.is_verified:
            return format_html(
                '<span style="color: green; font-size: 14px;">{}</span>',
                '✓ Verified',
            )
        else:
            return format_html(
                '<span style="color: red; font-size: 14px;">{}</span>',
                '✗ Unverified',
            )
    get_verification_status.short_description = "Status"

    def get_role_display_readonly(self, obj):
        """Readonly display for role"""
        return obj.get_role_display()
    get_role_display_readonly.short_description = "Current Role"

    actions = ["mark_verified", "mark_unverified",
               "deactivate_users", "activate_users"]

    def mark_verified(self, request, queryset):
        """Action to mark users as verified"""
        updated = queryset.update(is_verified=True)
        self.message_user(request, f"✓ {updated} user(s) marked as verified.")
    mark_verified.short_description = "Mark selected users as verified ✓"

    def mark_unverified(self, request, queryset):
        """Action to mark users as unverified"""
        updated = queryset.update(is_verified=False)
        self.message_user(
            request, f"✗ {updated} user(s) marked as unverified.")
    mark_unverified.short_description = "Mark selected users as unverified ✗"

    def deactivate_users(self, request, queryset):
        """Action to deactivate users"""
        updated = queryset.update(is_active=False)
        self.message_user(request, f"⛔ {updated} user(s) deactivated.")
    deactivate_users.short_description = "Deactivate selected users ⛔"

    def activate_users(self, request, queryset):
        """Action to activate users"""
        updated = queryset.update(is_active=True)
        self.message_user(request, f"✓ {updated} user(s) activated.")
    activate_users.short_description = "Activate selected users ✓"
