from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework.authtoken.models import Token

from .models import User


class RoleAccessTests(APITestCase):
    def setUp(self):
        self.superadmin = User.objects.create_user(
            username="superadmin",
            password="pass12345",
            role="superadmin",
        )
        self.expert = User.objects.create_user(
            username="expert",
            password="pass12345",
            role="expert",
        )
        self.paid = User.objects.create_user(
            username="paid",
            password="pass12345",
            role="paid",
        )

        self.superadmin_token = Token.objects.create(user=self.superadmin)
        self.expert_token = Token.objects.create(user=self.expert)
        self.paid_token = Token.objects.create(user=self.paid)

    def test_superadmin_can_list_users(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.superadmin_token.key}")
        response = self.client.get("/api/users/admin/users/")
        self.assertEqual(response.status_code, 200)

    def test_paid_cannot_access_admin_users(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.paid_token.key}")
        response = self.client.get("/api/users/admin/users/")
        self.assertEqual(response.status_code, 403)

    def test_expert_can_list_expert_users(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.expert_token.key}")
        response = self.client.get("/api/users/expert/users/")
        self.assertEqual(response.status_code, 200)

    def test_paid_can_delete_own_account(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.paid_token.key}")
        response = self.client.delete("/api/users/profile/")
        self.assertEqual(response.status_code, 204)
        self.assertFalse(User.objects.filter(username="paid").exists())
