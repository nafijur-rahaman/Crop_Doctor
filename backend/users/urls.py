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

router = DefaultRouter()
router.register(r"admin/users", AdminUserViewSet, basename="admin-users")
router.register(r"expert/users", ExpertUserViewSet, basename="expert-users")

urlpatterns = [
    path("register/", RegisterAPIView.as_view()),
    path("login/", LoginAPIView.as_view()),
    path("profile/", ProfileAPIView.as_view()),
    path("logout/", LogoutAPIView.as_view()),
    *router.urls,
]
