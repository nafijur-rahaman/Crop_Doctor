from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.generics import GenericAPIView, RetrieveUpdateAPIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenRefreshView

from .models import User
from .permissions import IsPaidUser, IsSuperAdmin
from .serializers import (
    ChangePasswordSerializer,
    ChangeRoleSerializer,
    LoginSerializer,
    LogoutSerializer,
    ProfileUpdateSerializer,
    RegisterSerializer,
    UserSerializer,
    RefreshTokenSerializer,
    get_tokens_for_user,
)


# ── Register 

class RegisterView(GenericAPIView):

    permission_classes = [AllowAny]
    serializer_class   = RegisterSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user   = serializer.save()
        tokens = get_tokens_for_user(user)

        return Response(
            {
                "message": "Account created successfully.",
                "user":    UserSerializer(user).data,
                "tokens":  tokens,
            },
            status=status.HTTP_201_CREATED,
        )


# ── Login 

class LoginView(GenericAPIView):

    permission_classes = [AllowAny]
    serializer_class   = LoginSerializer

    def post(self, request):
        serializer = self.get_serializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        user   = serializer.validated_data["user"]
        tokens = get_tokens_for_user(user)

        return Response(
            {
                "message": "Login successful.",
                "user":    UserSerializer(user).data,
                "tokens":  tokens,
            },
            status=status.HTTP_200_OK,
        )


# ── Logout 

class LogoutView(GenericAPIView):

    permission_classes = [IsAuthenticated]
    serializer_class   = LogoutSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"message": "Logged out successfully."}, status=status.HTTP_200_OK)



class UserProfileView(APIView):
 
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)


class ProfileUpdateView(GenericAPIView):

    permission_classes = [IsAuthenticated, IsPaidUser]
    serializer_class   = ProfileUpdateSerializer

    def patch(self, request):
        serializer = self.get_serializer(
            request.user, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(
            {
                "message": "Profile updated.",
                "user":    UserSerializer(request.user).data,
            }
        )


# ── Change password 

class ChangePasswordView(GenericAPIView):

    permission_classes = [IsAuthenticated]
    serializer_class   = ChangePasswordSerializer

    def post(self, request):
        serializer = self.get_serializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"message": "Password changed successfully."})


# ── Admin: list users 

class UserListView(APIView):

    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request):
        qs = User.objects.all().order_by("-date_joined")

        role   = request.query_params.get("role")
        search = request.query_params.get("search")

        if role:
            qs = qs.filter(role=role)
        if search:
            qs = qs.filter(full_name__icontains=search) | qs.filter(email__icontains=search)

     
        page      = int(request.query_params.get("page", 1))
        page_size = int(request.query_params.get("page_size", 20))
        start     = (page - 1) * page_size
        end       = start + page_size

        return Response(
            {
                "count":   qs.count(),
                "page":    page,
                "results": UserSerializer(qs[start:end], many=True).data,
            }
        )


class UserDetailView(APIView):

    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request, user_id):
        target_user = get_object_or_404(User, id=user_id)
        return Response(UserSerializer(target_user).data)


# ── Admin: change role 

class ChangeUserRoleView(GenericAPIView):

    permission_classes = [IsAuthenticated, IsSuperAdmin]
    serializer_class   = ChangeRoleSerializer

    def patch(self, request, user_id):
        target_user = get_object_or_404(User, id=user_id)
        serializer  = self.get_serializer(
            data=request.data,
            context={"request": request, "target_user": target_user},
        )
        serializer.is_valid(raise_exception=True)

        new_role = serializer.validated_data["role"]
        old_role = target_user.role
        target_user.role = new_role
        target_user.save(update_fields=["role", "updated_at"])

        return Response(
            {
                "message":  f"User role changed from {old_role} to {new_role}.",
                "user":     UserSerializer(target_user).data,
            }
        )


# ── Admin: activate / deactivate user

class ToggleUserActiveView(APIView):

    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def patch(self, request, user_id):
        target_user = get_object_or_404(User, id=user_id)

        if target_user == request.user:
            return Response(
                {"error": "You cannot deactivate your own account."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        target_user.is_active = not target_user.is_active
        target_user.save(update_fields=["is_active"])

        action = "activated" if target_user.is_active else "deactivated"
        return Response({"message": f"User {action} successfully.",
                         "is_active": target_user.is_active})

class TokenRefreshAPIView(TokenRefreshView):
    permission_classes = [AllowAny]
    serializer_class = RefreshTokenSerializer
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tokens = get_tokens_for_user(serializer.validated_data["user"])
        return Response(tokens)