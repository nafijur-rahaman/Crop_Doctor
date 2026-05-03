import uuid
import requests
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

from .models import SubscriptionPlan, UserSubscription
from .serializers import SubscriptionPlanSerializer, UserSubscriptionUpdateSerializer, UserSubscriptionSerializer
from users.permissions import IsSuperAdmin


class AdminPlanManageView(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request):
        serializer = SubscriptionPlanSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def get(self, request):
        plans = SubscriptionPlan.objects.all()
        serializer = SubscriptionPlanSerializer(plans, many=True)
        return Response(serializer.data)
    
    def put(self, request, pk):
        plan = SubscriptionPlan.objects.get(id=pk)
        serializer = SubscriptionPlanSerializer(plan, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, pk):
        plan = SubscriptionPlan.objects.get(id=pk)
        plan.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)



class AdminListUserSubscriptionsView(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def get(self, request):
        subscriptions = UserSubscription.objects.all()
        serializer = UserSubscriptionSerializer(subscriptions, many=True)
        return Response(serializer.data)
    
    def get(self, request, pk):
        subscription = UserSubscription.objects.get(id=pk)
        serializer = UserSubscriptionSerializer(subscription)
        return Response(serializer.data)
    
    def put(self, request, pk):
        subscription = UserSubscription.objects.get(id=pk)
        status_value = request.data.get("status")
        valid_statuses = {c[0] for c in UserSubscription.STATUS_CHOICES}
        if status_value not in valid_statuses:
            return Response({"detail": "Invalid status value"}, status=status.HTTP_400_BAD_REQUEST)
        if status_value == "active":
            subscription.activate()
        elif status_value == "cancelled":
            subscription.cancel()
        else:
            subscription.status = status_value
            subscription.is_active = status_value == "active"
            subscription.save()
        subscription.user.refresh_from_db()
        return Response(UserSubscriptionSerializer(subscription).data, status=status.HTTP_200_OK)
    
    def delete(self, request, pk):
        subscription = UserSubscription.objects.get(id=pk)
        subscription.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)



class CreateSubscriptionPaymentAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        plan_id = request.data.get("plan_id")

        plan = SubscriptionPlan.objects.get(id=plan_id)

        tran_id = str(uuid.uuid4())

        subscription = UserSubscription.objects.create(
            user=request.user,
            plan=plan,
            transaction_id=tran_id
        )

        payload = {
            "store_id": settings.SSLCOMMERZ_STORE_ID,
            "store_passwd": settings.SSLCOMMERZ_STORE_PASSWORD,
            "total_amount": str(plan.price),
            "currency": "BDT",
            "tran_id": tran_id,
            "success_url": "http://127.0.0.1:8000/api/payment-success/",
            "fail_url": "https://yourdomain.com/api/subscriptions/payment/fail/",
            "cancel_url": "https://yourdomain.com/api/subscriptions/payment/cancel/",
            "ipn_url": "https://yourdomain.com/api/subscriptions/payment/ipn/",
            "product_name": plan.name,
            "product_category": "Subscription",
            "product_profile": "service",
            "cus_name": request.user.username,
            "cus_email": request.user.email,
            "shipping_method": "NO",
            "num_of_item": 1,
        }

        response = requests.post(
            f"{settings.SSLCOMMERZ_BASE_URL}/gwprocess/v4/api.php",
            data=payload
        )

        data = response.json()

        return Response({
            "payment_url": data.get("GatewayPageURL"),
            "transaction_id": tran_id
        })
        


class PaymentSuccessAPIView(APIView):
    permission_classes = []

    def post(self, request):
        tran_id = request.data.get("tran_id")

        subscription = UserSubscription.objects.filter(
            transaction_id=tran_id
        ).first()

        if not subscription:
            return Response({"error": "invalid transaction"}, status=404)

        subscription.activate()
        subscription.user.refresh_from_db()

        return Response({
            "message": "subscription activated",
            "role": subscription.user.role,
            "expires_at": subscription.end_date
        })