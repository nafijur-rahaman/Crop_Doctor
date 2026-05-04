from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ("Extra Info", {
            "fields": ("role", "phone", "profile_image", "is_verified"),
        }),
    )

    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ("Extra Info", {
            "fields": ("role", "phone", "profile_image", "is_verified"),
        }),
    )