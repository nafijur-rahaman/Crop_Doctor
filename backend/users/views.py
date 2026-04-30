from django.contrib.auth import authenticate
from django.db.models import Q
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework import viewsets, mixins
from rest_framework.decorators import action

from .serializers import (
    RegisterSerializer,
    LoginSerializer,
    ProfileSerializer,
    AdminUserSerializer,
    ExpertUserSerializer,
)
from .models import User
from .permissions import IsSuperAdmin, IsExpertAccess


class RegisterAPIView(APIView):
    permission_classes = []

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)

        if serializer.is_valid():
            user = serializer.save()

            token = Token.objects.create(user=user)

            return Response(
                {
                    "message": "Registration successful",
                    "token": token.key,
                    "role": user.role
                },
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )


class LoginAPIView(APIView):
    permission_classes = []

    def post(self, request):
        serializer = LoginSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=400
            )

        username = serializer.validated_data["username"]
        password = serializer.validated_data["password"]

        user = authenticate(
            username=username,
            password=password
        )

        if not user:
            return Response(
                {"error": "Invalid credentials"},
                status=400
            )

        token, _ = Token.objects.get_or_create(user=user)

        return Response(
            {
                "token": token.key,
                "role": user.role
            }
        )


class ProfileAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = ProfileSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        serializer = ProfileSerializer(
            request.user,
            data=request.data,
            partial=True
        )

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(serializer.errors, status=400)

    def delete(self, request):
        request.user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class LogoutAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Token.objects.filter(user=request.user).delete()

        return Response(
            {"message": "Logged out successfully"}
        )


class AdminUserViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    serializer_class = AdminUserSerializer
    queryset = User.objects.all().order_by("-date_joined")

    @action(detail=True, methods=["patch"], url_path="verify")
    def verify(self, request, pk=None):
        user = self.get_object()
        user.is_verified = bool(request.data.get("is_verified", True))
        user.save(update_fields=["is_verified"])
        return Response(self.get_serializer(user).data)


class ExpertUserViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [IsAuthenticated, IsExpertAccess]
    serializer_class = ExpertUserSerializer

    def get_queryset(self):
        return User.objects.filter(Q(role="paid") | Q(role="expert")).order_by("-date_joined")

    @action(detail=True, methods=["patch"], url_path="verify")
    def verify(self, request, pk=None):
        user = self.get_object()
        if user.role != "paid":
            return Response(
                {"detail": "Only paid users can be verified by experts."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user.is_verified = bool(request.data.get("is_verified", True))
        user.save(update_fields=["is_verified"])
        return Response(self.get_serializer(user).data)
