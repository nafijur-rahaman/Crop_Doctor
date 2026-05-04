from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

from scan.models import ScanHistory
from subscriptions.models import UserSubscription


class UserStatsAPIView(APIView):
    """
    Basic user stats (for paid/guest accounts). Premium gating is handled client-side.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        total_scans = ScanHistory.objects.filter(user=user).count()

        subscriptions_qs = UserSubscription.objects.filter(user=user).order_by("-created_at")
        total_payments = subscriptions_qs.count()
        active_sub = UserSubscription.active_now_for_user(user).order_by("-end_date").first()

        active_payload = None
        if active_sub:
            active_payload = {
                "plan": str(active_sub.plan),
                "status": active_sub.status,
                "start_date": active_sub.start_date,
                "end_date": active_sub.end_date,
                "transaction_id": active_sub.transaction_id,
            }

        return Response(
            {
                "total_scans": total_scans,
                "total_payments": total_payments,
                "active_subscription": active_payload,
            },
            status=status.HTTP_200_OK,
        )

