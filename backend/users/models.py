from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    ROLE_CHOICES = [
        ("guest", "Guest"),
        ("paid", "Paid User"),
        ("expert", "Expert"),
        ("superadmin", "Super Admin"),
    ]

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default="guest"
    )

    phone = models.CharField(max_length=20, blank=True, null=True)
    profile_image = models.ImageField(
        upload_to="profiles/",
        blank=True,
        null=True
    )

    is_verified = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.username} - {self.role}"