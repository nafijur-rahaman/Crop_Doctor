import uuid
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.utils import timezone
from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):

    # ── Roles 
    GUEST      = "guest"
    PAID       = "paid"
    EXPERT     = "expert"
    SUPERADMIN = "superadmin"

    ROLE_CHOICES = [
        (GUEST,      "Guest"),
        (PAID,       "Paid"),
        (EXPERT,     "Expert"),
        (SUPERADMIN, "Super Admin"),
    ]

  
    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email      = models.EmailField(unique=True, db_index=True)
    full_name  = models.CharField(max_length=150)
    role       = models.CharField(max_length=20, choices=ROLE_CHOICES, default=GUEST, db_index=True)


    phone         = models.CharField(max_length=20, blank=True)
    profile_image = models.ImageField(upload_to="profile_images/", blank=True)
    bio           = models.TextField(blank=True)
    location      = models.CharField(max_length=100, blank=True)
    farm_name     = models.CharField(max_length=150, blank=True)


    subscription_expires_at = models.DateTimeField(null=True, blank=True)
    gateway_customer_ref    = models.CharField(
        max_length=200,
        blank=True,
        help_text=(
            "Gateway-side customer or transaction reference "
            "(SSLCommerz tran_id / bKash paymentID). "
            "Blank for demo activations."
        ),
    )

    is_active    = models.BooleanField(default=True)
    is_staff     = models.BooleanField(default=False)
    date_joined  = models.DateTimeField(default=timezone.now)
    updated_at   = models.DateTimeField(auto_now=True)

    USERNAME_FIELD  = "email"
    REQUIRED_FIELDS = ["full_name"]

    objects = UserManager()

    class Meta:
        db_table  = "users"
        ordering  = ["-date_joined"]
        verbose_name        = "User"
        verbose_name_plural = "Users"

    def __str__(self):
        return f"{self.email} [{self.role}]"


    @property
    def is_paid_or_above(self) -> bool:
  
        return self.role in (self.PAID, self.EXPERT, self.SUPERADMIN)

    @property
    def is_expert_or_above(self) -> bool:

        return self.role in (self.EXPERT, self.SUPERADMIN)

    @property
    def is_superadmin(self) -> bool:
        return self.role == self.SUPERADMIN

    @property
    def is_guest(self) -> bool:
        return self.role == self.GUEST

    def has_active_subscription(self) -> bool:

        if self.role not in (self.PAID,):
            return True   
        if not self.subscription_expires_at:
            return False
        return timezone.now() < self.subscription_expires_at

    def upgrade_to_paid(self, expires_at, gateway_customer_ref: str = ""):

        self.role                    = self.PAID
        self.subscription_expires_at = expires_at
        if gateway_customer_ref:
            self.gateway_customer_ref = gateway_customer_ref
        self.save(update_fields=[
            "role",
            "subscription_expires_at",
            "gateway_customer_ref",
            "updated_at",
        ])

    def downgrade_to_guest(self):
  
        self.role                    = self.GUEST
        self.subscription_expires_at = None
        self.save(update_fields=["role", "subscription_expires_at", "updated_at"])
