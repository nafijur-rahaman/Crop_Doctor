from django.urls import path
from .views import (
    RegisterView,
    LoginView,
    LogoutView,
    TokenRefreshAPIView,
    UserProfileView,
    ProfileUpdateView,
    ChangePasswordView,
    UserListView,
    UserDetailView,
    ChangeUserRoleView,
    ToggleUserActiveView,
)


urlpatterns = [
    # ── Public auth 
    path("register/",         RegisterView.as_view(),       name="auth-register"),
    path("login/",            LoginView.as_view(),           name="auth-login"),
    path("logout/",           LogoutView.as_view(),          name="auth-logout"),
    path("token/refresh/",    TokenRefreshAPIView.as_view(), name="auth-token-refresh"),

    # ── Authenticated user 
    path("user-profile/",               UserProfileView.as_view(),              name="auth-user-profile"),
    path("user-profile/update/",        ProfileUpdateView.as_view(),   name="auth-user-profile-update"),
    path("change-password/",  ChangePasswordView.as_view(),  name="auth-change-password"),

    # ── SuperAdmin 
    path("admin/get-users/",                            UserListView.as_view(),         name="admin-user-list"),
    path("admin/get-user/<uuid:user_id>/",                      UserDetailView.as_view(),       name="admin-user-detail"),
    path("admin/<uuid:user_id>/change-role/",        ChangeUserRoleView.as_view(),   name="admin-change-role"),
    path("admin/<uuid:user_id>/toggle-active/",      ToggleUserActiveView.as_view(), name="admin-toggle-active"),
]
