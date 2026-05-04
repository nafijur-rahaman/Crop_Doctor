import uuid
import requests
from django.conf import settings
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

from .models import SubscriptionPlan, UserSubscription
from .serializers import (
    SubscriptionPlanSerializer,
    UserSubscriptionUpdateSerializer,
    UserSubscriptionSerializer,
    UserSubscriptionMeSerializer,
)
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

class GetplanListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        plans = SubscriptionPlan.objects.all()
        serializer = SubscriptionPlanSerializer(plans, many=True)
        return Response(serializer.data)

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

        if not plan_id:
            return Response({"error": "plan_id required"}, status=400)

        try:
            plan = SubscriptionPlan.objects.get(id=plan_id)
        except SubscriptionPlan.DoesNotExist:
            return Response({"error": "Invalid plan"}, status=404)

        tran_id = str(uuid.uuid4())

        subscription = UserSubscription.objects.create(
            user=request.user,
            plan=plan,
            transaction_id=tran_id,
            status="pending"
        )

        payload = {
            "store_id": settings.SSLCOMMERZ_STORE_ID,
            "store_passwd": settings.SSLCOMMERZ_STORE_PASSWORD,
            "total_amount": str(plan.price),
            "currency": "BDT",
            "tran_id": tran_id,


            "success_url": f"{settings.BACKEND_HOST}/api/subscriptions/payment-success/",
            "fail_url": f"{settings.BACKEND_HOST}/api/subscriptions/payment-fail/",
            "cancel_url": f"{settings.BACKEND_HOST}/api/subscriptions/payment-cancel/",
            "ipn_url": f"{settings.BACKEND_HOST}/api/subscriptions/payment-ipn/",

            "product_name": plan.name,  
            "product_category": "Subscription",
            "product_profile": "service",

            "cus_name": request.user.username,
            "cus_email": request.user.email or "",
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

    def _tran_id(self, request):
        return request.data.get("tran_id") or request.query_params.get("tran_id")

    def get(self, request):
        return self._handle(request)

    def post(self, request):
        return self._handle(request)

    def _handle(self, request):
        tran_id = self._tran_id(request)
        if not tran_id:
            return render(
                request,
                "subscriptions/payment_fail.html",
                {
                    "title": "Payment status unknown",
                    "message": "Missing transaction ID. Please return to the app and try again.",
                    "transaction_id": None,
                    "app_return_url": getattr(settings, "APP_RETURN_URL", "/"),
                    "site_url": getattr(settings, "SITE_URL", "/"),
                },
                status=400,
            )

        subscription = UserSubscription.objects.filter(transaction_id=tran_id).first()
        if not subscription:
            return render(
                request,
                "subscriptions/payment_fail.html",
                {
                    "title": "Payment not found",
                    "message": "We couldn't find this transaction. Please return to the app and contact support if the issue persists.",
                    "transaction_id": tran_id,
                    "app_return_url": getattr(settings, "APP_RETURN_URL", "/"),
                    "site_url": getattr(settings, "SITE_URL", "/"),
                },
                status=404,
            )

        if subscription.status != "active":
            subscription.activate()

        return render(
            request,
            "subscriptions/payment_success.html",
            {
                "title": "Premium activated",
                "message": "Your payment was successful. Premium features are now available in the app.",
                "transaction_id": tran_id,
                "app_return_url": getattr(settings, "APP_RETURN_URL", "/"),
                "site_url": getattr(settings, "SITE_URL", "/"),
            },
            status=200,
        )


@method_decorator(csrf_exempt, name="dispatch")
class PaymentIPNAPIView(APIView):

    def post(self, request):
        data = request.data

        tran_id = data.get("tran_id")
        status = data.get("status")

        if not tran_id:
            return Response({"error": "missing tran_id"}, status=400)

        try:
            subscription = UserSubscription.objects.get(transaction_id=tran_id)
        except UserSubscription.DoesNotExist:
            return Response({"error": "invalid transaction"}, status=404)

   
        if status == "VALID":
            subscription.status = "active"
            subscription.activate()
            subscription.save()

        elif status == "FAILED":
            subscription.status = "failed"
            subscription.save()

        return Response({"message": "IPN processed"})
    

class PaymentFailAPIView(APIView):
    permission_classes = []

    def _tran_id(self, request):
        return request.data.get("tran_id") or request.query_params.get("tran_id")

    def get(self, request):
        return self._handle(request)

    def post(self, request):
        return self._handle(request)

    def _handle(self, request):
        tran_id = self._tran_id(request)
        if tran_id:
            UserSubscription.objects.filter(transaction_id=tran_id).update(status="failed")

        return render(
            request,
            "subscriptions/payment_fail.html",
            {
                "title": "Payment failed",
                "message": "Your payment was not completed. You can try again from the app.",
                "transaction_id": tran_id,
                "app_return_url": getattr(settings, "APP_RETURN_URL", "/"),
                "site_url": getattr(settings, "SITE_URL", "/"),
            },
            status=200,
        )
    

class PaymentCancelAPIView(APIView):
    permission_classes = []

    def _tran_id(self, request):
        return request.data.get("tran_id") or request.query_params.get("tran_id")

    def get(self, request):
        return self._handle(request)

    def post(self, request):
        return self._handle(request)

    def _handle(self, request):
        tran_id = self._tran_id(request)
        if tran_id:
            UserSubscription.objects.filter(transaction_id=tran_id).update(status="cancelled")

        return render(
            request,
            "subscriptions/payment_cancel.html",
            {
                "title": "Payment cancelled",
                "message": "You cancelled the payment. You can restart the upgrade any time from the app.",
                "transaction_id": tran_id,
                "app_return_url": getattr(settings, "APP_RETURN_URL", "/"),
                "site_url": getattr(settings, "SITE_URL", "/"),
            },
            status=200,
        )


class MySubscriptionsAPIView(APIView):
    """
    Authenticated user's payment/subscription history.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, pk=None):
        qs = UserSubscription.objects.filter(user=request.user).order_by("-created_at")
        if pk is not None:
            sub = qs.filter(id=pk).first()
            if not sub:
                return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)
            return Response({"success": True, "subscription": UserSubscriptionMeSerializer(sub).data})

        data = UserSubscriptionMeSerializer(qs, many=True).data
        return Response({"success": True, "subscriptions": data})
