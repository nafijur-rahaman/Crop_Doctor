from rest_framework import serializers
from .models import SubscriptionPlan, UserSubscription

class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = "__all__"
        

class UserSubscriptionSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField()
    plan = serializers.StringRelatedField()

    class Meta:
        model = UserSubscription
        fields = "__all__"


class UserSubscriptionMeSerializer(serializers.ModelSerializer):
    plan = SubscriptionPlanSerializer(read_only=True)

    class Meta:
        model = UserSubscription
        fields = [
            "id",
            "transaction_id",
            "status",
            "start_date",
            "end_date",
            "is_active",
            "created_at",
            "plan",
        ]
        read_only_fields = fields

class UserSubscriptionUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserSubscription
        fields = ["status"]
