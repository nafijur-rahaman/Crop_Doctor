from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Count, Sum
from .models import SubscriptionPlan, UserSubscription


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = (
        "get_plan_name",
        "get_price_display",
        "get_duration_display",
        "get_subscribers_count",
        "get_revenue_display",
    )
    list_filter = ("duration_days", "name")
    search_fields = ("name",)
    readonly_fields = (
        "get_price_display",
        "get_subscribers_count",
        "get_total_revenue",
    )
    fieldsets = (
        ("Plan Details", {
            "fields": ("name", "description"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Pricing & Duration", {
            "fields": ("price", "duration_days"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Features", {
            "fields": ("features",),
            "classes": ("wide", "extrapretty"),
        }),
        ("Statistics", {
            "fields": ("get_subscribers_count", "get_total_revenue"),
            "classes": ("collapse",),
        }),
    )
    list_per_page = 20
    ordering = ("price",)

    def get_plan_name(self, obj):
        return format_html(
            '<span style="color: #2c3e50; font-weight: bold; font-size: 13px;">💳 {}</span>',
            obj.name
        )
    get_plan_name.short_description = "Plan Name"

    def get_price_display(self, obj):
        return format_html(
            '<span style="color: #27ae60; font-weight: bold; font-size: 13px;">৳ {}</span>',
            obj.price
        )
    get_price_display.short_description = "Price"

    def get_duration_display(self, obj):
        return format_html(
            '<span style="background-color: #3498db; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">📅 {} days</span>',
            obj.duration_days
        )
    get_duration_display.short_description = "Duration"

    def get_subscribers_count(self, obj):
        count = obj.usersubscription_set.filter(is_active=True).count()
        return format_html(
            '<span style="background-color: #9b59b6; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">👥 {} active</span>',
            count
        )
    get_subscribers_count.short_description = "Active Subscribers"

    def get_revenue_display(self, obj):
        count = obj.usersubscription_set.filter(is_active=True).count()
        revenue = count * float(obj.price)
        revenue_text = f"{revenue:.2f}"
        return format_html(
            '<span style="color: #27ae60; font-weight: bold;">৳ {}</span>',
            revenue_text,
        )
    get_revenue_display.short_description = "Est. Revenue"

    def get_total_revenue(self, obj):
        count = obj.usersubscription_set.filter(is_active=True).count()
        revenue = count * float(obj.price)
        revenue_text = f"{revenue:.2f}"
        return format_html(
            '<div style="background-color: #ecf0f1; padding: 10px; border-radius: 5px;"><strong>Estimated Revenue:</strong> ৳ {}<br><strong>Active Subscribers:</strong> {}</div>',
            revenue_text,
            count
        )
    get_total_revenue.short_description = "Revenue Info"

    actions = ["activate_plan", "deactivate_plan"]

    def activate_plan(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f"✓ {updated} plan(s) activated.")
    activate_plan.short_description = "Activate selected plans ✓"

    def deactivate_plan(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f"⛔ {updated} plan(s) deactivated.")
    deactivate_plan.short_description = "Deactivate selected plans ⛔"


@admin.register(UserSubscription)
class UserSubscriptionAdmin(admin.ModelAdmin):
    list_display = (
        "get_user_display",
        "get_plan_display",
        "get_status_display",
        "get_price_display",
        "start_date",
        "end_date",
        "get_days_remaining",
    )
    list_filter = (
        "is_active",
        "plan__name",
        ("start_date", admin.DateFieldListFilter),
        ("end_date", admin.DateFieldListFilter),
    )
    search_fields = ("user__username", "user__email", "plan__name")
    readonly_fields = (
        "created_at",
        "get_subscription_info",
        "get_usage_summary",
    )
    fieldsets = (
        ("Subscription Details", {
            "fields": ("user", "plan"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Subscription Period", {
            "fields": ("start_date", "end_date", "is_active"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Status & Transaction", {
            "fields": ("status", "transaction_id"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Summary", {
            "fields": ("get_subscription_info", "get_usage_summary"),
            "classes": ("collapse",),
        }),
    )
    list_per_page = 30
    ordering = ("-start_date",)

    def get_user_display(self, obj):
        return format_html(
            '<span style="color: #2980b9; font-weight: bold;">👤 {}</span>',
            obj.user.username
        )
    get_user_display.short_description = "User"

    def get_plan_display(self, obj):
        return format_html(
            '<span style="background-color: #9b59b6; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">💳 {}</span>',
            obj.plan.name
        )
    get_plan_display.short_description = "Plan"

    def get_status_display(self, obj):
        from datetime import timedelta
        from django.utils import timezone

        if not obj.is_active:
            return format_html(
                '<span style="background-color: #e74c3c; color: white; padding: 5px 10px; border-radius: 15px; font-size: 10px; font-weight: bold;">{}</span>',
                '❌ Expired',
            )

        now = timezone.now()
        days_left = (obj.end_date - now).days if obj.end_date else 0

        if days_left <= 7:
            color = "#e74c3c"
        elif days_left <= 30:
            color = "#f39c12"
        else:
            color = "#27ae60"

        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; border-radius: 15px; font-size: 10px; font-weight: bold;">✓ Active</span>',
            color
        )
    get_status_display.short_description = "Status"

    def get_price_display(self, obj):
        return format_html(
            '<span style="color: #27ae60; font-weight: bold;">৳ {}</span>',
            obj.plan.price
        )
    get_price_display.short_description = "Amount"

    def get_days_remaining(self, obj):
        from datetime import timedelta
        from django.utils import timezone

        if not obj.is_active:
            return format_html('<span style="color: #e74c3c;">{}</span>', 'Expired')

        now = timezone.now()
        days_left = (obj.end_date - now).days if obj.end_date else 0

        if days_left < 0:
            return format_html('<span style="color: #e74c3c;">{}</span>', 'Expired')
        elif days_left == 0:
            return format_html('<span style="color: #e74c3c; font-weight: bold;">{}</span>', 'Expires today!')
        elif days_left <= 7:
            return format_html(
                '<span style="color: #e74c3c; font-weight: bold;">⚠️ {} days</span>',
                days_left
            )
        elif days_left <= 30:
            return format_html(
                '<span style="color: #f39c12; font-weight: bold;">📅 {} days</span>',
                days_left
            )
        else:
            return format_html(
                '<span style="color: #27ae60; font-weight: bold;">✓ {} days</span>',
                days_left
            )
    get_days_remaining.short_description = "Days Left"

    def get_subscription_info(self, obj):
        from django.utils import timezone

        now = timezone.now()
        days_left = (obj.end_date -
                     now).days if obj.is_active and obj.end_date else 0

        return format_html(
            '<div style="background-color: #ecf0f1; padding: 10px; border-radius: 5px;"><strong>User:</strong> {}<br><strong>Plan:</strong> {}<br><strong>Price:</strong> ৳ {}<br><strong>Started:</strong> {}<br><strong>Expires:</strong> {}<br><strong>Days Remaining:</strong> {}</div>',
            obj.user.username,
            obj.plan.name,
            obj.plan.price,
            obj.start_date.strftime(
                "%Y-%m-%d %H:%M") if obj.start_date else "Pending",
            obj.end_date.strftime(
                "%Y-%m-%d %H:%M") if obj.is_active and obj.end_date else "Expired",
            max(0, days_left) if obj.is_active else "0"
        )
    get_subscription_info.short_description = "Subscription Information"

    def get_usage_summary(self, obj):
        return format_html(
            '<div style="background-color: #ecf0f1; padding: 10px; border-radius: 5px;"><strong>Status:</strong> {}<br><strong>Subscription Status:</strong> {}</div>',
            "Active ✓" if obj.is_active else "Expired ✗",
            obj.get_status_display()
        )
    get_usage_summary.short_description = "Usage Summary"

    actions = ["renew_subscriptions", "expire_subscriptions",
               "mark_active", "mark_inactive"]

    def renew_subscriptions(self, request, queryset):
        from django.utils import timezone
        from datetime import timedelta

        updated = 0
        for subscription in queryset:
            subscription.is_active = True
            subscription.start_date = timezone.now()
            subscription.end_date = timezone.now(
            ) + timedelta(days=subscription.plan.duration_days)
            subscription.save()
            updated += 1

        self.message_user(request, f"✓ {updated} subscription(s) renewed.")
    renew_subscriptions.short_description = "Renew selected subscriptions ✓"

    def expire_subscriptions(self, request, queryset):
        from django.utils import timezone

        for subscription in queryset:
            subscription.is_active = False
            subscription.end_date = timezone.now()
            subscription.save()

        self.message_user(
            request, f"⛔ {queryset.count()} subscription(s) expired.")
    expire_subscriptions.short_description = "Expire selected subscriptions ⛔"

    def mark_active(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(
            request, f"✓ {updated} subscription(s) marked as active.")
    mark_active.short_description = "Mark as Active ✓"

    def mark_inactive(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(
            request, f"⛔ {updated} subscription(s) marked as inactive.")
    mark_inactive.short_description = "Mark as Inactive ⛔"
