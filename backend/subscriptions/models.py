from django.db import models
from django.conf import settings
from django.utils import timezone
from datetime import timedelta


class SubscriptionPlan(models.Model):
    PLAN_CHOICES = [
        ("monthly", "Monthly"),
        ("yearly", "Yearly"),
    ]

    name = models.CharField(max_length=50, choices=PLAN_CHOICES, unique=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_days = models.PositiveIntegerField()

    def __str__(self):
        return f"{self.name} - {self.price}"


class UserSubscription(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("active", "Active"),
        ("expired", "Expired"),
        ("cancelled", "Cancelled"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="subscriptions"
    )

    plan = models.ForeignKey(
        SubscriptionPlan,
        on_delete=models.CASCADE
    )

    transaction_id = models.CharField(max_length=100, unique=True)

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )

    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)

    is_active = models.BooleanField(default=False) 

    created_at = models.DateTimeField(auto_now_add=True)

    def _promote_guest_to_paid(self):
        """Registered users start as guest; an active plan makes them paid."""
        user = self.user
        if user.role == "guest":
            user.role = "paid"
            user.save(update_fields=["role"])

    def activate(self):
        """Mark subscription active and upgrade guest accounts to paid."""
        self.status = "active"
        self.is_active = True
        self.start_date = timezone.now()
        self.end_date = timezone.now() + timedelta(days=self.plan.duration_days)
        self.save()
        self._promote_guest_to_paid()

    def cancel(self):
        user = self.user
        self.status = "cancelled"
        self.is_active = False
        self.save()
        has_active = UserSubscription.objects.filter(
            user=user, is_active=True, status="active"
        ).exists()
        if not has_active and user.role == "paid":
            user.role = "guest"
            user.save(update_fields=["role"])

    def __str__(self):
        return f"{self.user} - {self.plan} ({self.status})"