import re
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User




def get_tokens_for_user(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {
        "access":  str(refresh.access_token),
        "refresh": str(refresh),
    }


# ── Registration 

class RegisterSerializer(serializers.ModelSerializer):
    password         = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model  = User
        fields = ["email", "full_name", "password", "confirm_password", "phone"]

    def validate_email(self, value):
        value = value.lower().strip()
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    def validate_password(self, value):
        validate_password(value)   
        return value

    def validate(self, attrs):
        if attrs["password"] != attrs.pop("confirm_password"):
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return attrs

    def create(self, validated_data):
        user = User.objects.create_user(
            email     = validated_data["email"],
            full_name = validated_data["full_name"],
            password  = validated_data["password"],
            phone     = validated_data.get("phone", ""),
        )
        return user


class RegisterResponseSerializer(serializers.Serializer):
    
    id        = serializers.UUIDField()
    email     = serializers.EmailField()
    full_name = serializers.CharField()
    role      = serializers.CharField()
    tokens    = serializers.DictField()


# ── Login 

class LoginSerializer(serializers.Serializer):
    email    = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email    = attrs["email"].lower().strip()
        password = attrs["password"]

        user = authenticate(request=self.context.get("request"),
                            email=email, password=password)

        if not user:
            raise serializers.ValidationError(
                {"non_field_errors": "Invalid email or password."}
            )
        if not user.is_active:
            raise serializers.ValidationError(
                {"non_field_errors": "This account has been deactivated."}
            )

        attrs["user"] = user
        return attrs


# ── User profile 

class UserSerializer(serializers.ModelSerializer):


    has_active_subscription = serializers.SerializerMethodField()

    class Meta:
        model  = User
        fields = [
            "id",
            "email",
            "full_name",
            "role",
            "phone",
            "profile_image",
            "bio",
            "location",
            "farm_name",
            "subscription_expires_at",
            "has_active_subscription",
            "date_joined",
        ]
        read_only_fields = [
            "id", "email", "role", "subscription_expires_at",
            "has_active_subscription", "date_joined",
        ]

    def get_has_active_subscription(self, obj: User) -> bool:
        return obj.has_active_subscription()


# ── Profile update 

class ProfileUpdateSerializer(serializers.ModelSerializer):


    class Meta:
        model  = User
        fields = ["full_name", "phone", "profile_image", "bio", "location", "farm_name"]

    def validate_phone(self, value):
        if value and not re.match(r"^\+?[\d\s\-]{7,20}$", value):
            raise serializers.ValidationError("Enter a valid phone number.")
        return value




# ── Change password 

class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True)
    new_password     = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True)

    def validate_current_password(self, value):
        user = self.context["request"].user
        if not user.check_password(value):
            raise serializers.ValidationError("Current password is incorrect.")
        return value

    def validate_new_password(self, value):
        validate_password(value)
        return value

    def validate(self, attrs):
        if attrs["new_password"] != attrs["confirm_password"]:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        if attrs["current_password"] == attrs["new_password"]:
            raise serializers.ValidationError(
                {"new_password": "New password must be different from current password."}
            )
        return attrs

    def save(self, **kwargs):
        user = self.context["request"].user
        user.set_password(self.validated_data["new_password"])
        user.save(update_fields=["password", "updated_at"])
        return user


# ── Admin: change user role

class ChangeRoleSerializer(serializers.Serializer):

    role = serializers.ChoiceField(choices=User.ROLE_CHOICES)

    def validate_role(self, value):
        # Prevent self-demotion of superadmin
        target_user     = self.context.get("target_user")
        requesting_user = self.context["request"].user
        if target_user and target_user == requesting_user and value != User.SUPERADMIN:
            raise serializers.ValidationError("You cannot demote your own superadmin account.")
        return value


# ── Logout 

class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()

    def validate_refresh(self, value):
        try:
            token = RefreshToken(value)
            token.check_exp()   
        except Exception:
            raise serializers.ValidationError("Token is invalid or expired.")
        self._token = RefreshToken(value)
        return value

    def save(self, **kwargs):
        self._token.blacklist()

# ── Token refresh 

class RefreshTokenSerializer(serializers.Serializer):
    refresh = serializers.CharField()

    def validate(self, attrs):
        refresh = attrs["refresh"]
        try:
            token = RefreshToken(refresh)
            token.check_exp()
            user_id = token.payload.get("user_id")
            attrs["user"] = User.objects.get(id=user_id)
        except User.DoesNotExist:
            raise serializers.ValidationError("User for this token was not found.")
        except Exception:
            raise serializers.ValidationError("Token is invalid or expired.")
        return attrs