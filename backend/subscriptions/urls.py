from django.urls import path
from .views import AdminPlanManageView, AdminListUserSubscriptionsView, CreateSubscriptionPaymentAPIView, PaymentSuccessAPIView, PaymentFailAPIView, PaymentCancelAPIView, PaymentIPNAPIView, GetplanListView

urlpatterns = [
    path("admin/get-plans/", AdminPlanManageView.as_view(), name="admin-plan-manage"),
    path("admin/create-plan/", AdminPlanManageView.as_view(), name="admin-plan-manage"),
    path("admin/update-plan/<int:pk>/", AdminPlanManageView.as_view(), name="admin-plan-manage"),
    path("admin/delete-plan/<int:pk>/", AdminPlanManageView.as_view(), name="admin-plan-manage"),
    path("get-plans/", GetplanListView.as_view(), name="get-plans"),
    
    path("admin/get-subscriptions/", AdminListUserSubscriptionsView.as_view(), name="admin-list-user-subscriptions"),
    path("admin/get-subscription/<int:pk>/", AdminListUserSubscriptionsView.as_view(), name="admin-list-user-subscriptions-detail"),
    path("admin/update-subscription/<int:pk>/", AdminListUserSubscriptionsView.as_view(), name="admin-list-user-subscriptions-detail"),
    path("admin/delete-subscription/<int:pk>/", AdminListUserSubscriptionsView.as_view(), name="admin-list-user-subscriptions-detail"),
    
    path("subscriptions/create-subscription-payment/", CreateSubscriptionPaymentAPIView.as_view(), name="create-subscription-payment"),
    path("subscriptions/payment-success/", PaymentSuccessAPIView.as_view(), name="payment-success"),
    path("subscriptions/payment-fail/", PaymentFailAPIView.as_view(), name="payment-fail"),
    path("subscriptions/payment-cancel/", PaymentCancelAPIView.as_view(), name="payment-cancel"),
    path("subscriptions/payment-ipn/", PaymentIPNAPIView.as_view(), name="payment-ipn"),
]