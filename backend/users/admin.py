from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display  = ["email", "full_name", "role", "is_active", "date_joined"]
    list_filter   = ["role", "is_active", "is_staff"]
    search_fields = ["email", "full_name", "phone"]
    ordering      = ["-date_joined"]

    fieldsets = (
        (None,           {"fields": ("email", "password")}),
        ("Personal",     {"fields": ("full_name", "phone", "profile_image", "bio", "location", "farm_name")}),
        ("Role",         {"fields": ("role",)}),
        # gateway_customer_ref stores the SSLCommerz tran_id (or bKash paymentID)
        # of the first successful payment. Blank for demo/sandbox activations.
        ("Subscription", {"fields": ("subscription_expires_at", "gateway_customer_ref")}),
        ("Permissions",  {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Dates",        {"fields": ("date_joined", "last_login")}),
    )

    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields":  ("email", "full_name", "role", "password1", "password2"),
        }),
    )

    readonly_fields = ["date_joined", "last_login"]

    # Use email instead of username
    USERNAME_FIELD = "email"
