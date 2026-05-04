from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import (
    RegisterAPIView,
    LoginAPIView,
    ProfileAPIView,
    LogoutAPIView,
    AdminUserViewSet,
    ExpertUserViewSet,
)
from .stats_views import UserStatsAPIView

router = DefaultRouter()
router.register(r"admin/users", AdminUserViewSet, basename="admin-users")
router.register(r"expert/users", ExpertUserViewSet, basename="expert-users")

urlpatterns = [
    path("register/", RegisterAPIView.as_view(), name="register"),
    path("login/", LoginAPIView.as_view(), name="login"),
    path("profile/", ProfileAPIView.as_view(), name="profile"),
    path("logout/", LogoutAPIView.as_view(), name="logout"),
    path("stats/", UserStatsAPIView.as_view(), name="user-stats"),
    *router.urls,
]
