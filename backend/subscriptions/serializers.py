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

class UserSubscriptionUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserSubscription
        fields = ["status"]