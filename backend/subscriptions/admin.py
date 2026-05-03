from django.contrib import admin
from .models import SubscriptionPlan, UserSubscription
from .serializers import SubscriptionPlanSerializer, UserSubscriptionSerializer

admin.site.register(SubscriptionPlan)
admin.site.register(UserSubscription)

class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ['name', 'price', 'duration_days']
    list_filter = ['name', 'price', 'duration_days']
    search_fields = ['name', 'price', 'duration_days']
    list_per_page = 10
    ordering = ['name', 'price', 'duration_days']
    form = SubscriptionPlanSerializer
