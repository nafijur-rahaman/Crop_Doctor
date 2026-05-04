from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import BasePermission
from rest_framework import status
import re


from .services import (
    get_prediction,
    check_guest_limit,
    consume_guest_scan,
    get_solution,
    select_best_prediction_for_crop,
)
from users.permissions import IsPremiumAccess

from .models import ScanHistory
from .serializers import ScanHistorySerializer

class IsGuestOrPremium(BasePermission):
    message = "You are not allowed to access this."

    def has_permission(self, request, view):
        # Scan is allowed for:
        # - unauthenticated guests (rate-limited by guest_id in the view)
        # - authenticated users of any role (guest/paid/expert/superadmin)
        return True



class ScanAPIView(APIView):
    permission_classes = [IsGuestOrPremium]

    def post(self, request):

        image = request.FILES.get("image")
        crop = request.data.get("crop")  

        user = request.user if request.user.is_authenticated else None
        guest_id = None

        if image is None:
            return Response({"error": "image file required"}, status=400)

        if not crop:
            return Response({"error": "crop required"}, status=400)

        if user is None:
            guest_id = request.data.get("guest_id") or request.headers.get("X-Guest-Id")
            if not guest_id:
                return Response({"error": "guest_id required for guest scan"}, status=400)
            if not check_guest_limit(guest_id):
                return Response({"error": "Weekly guest scan limit exceeded (3)"}, status=403)


        prediction = get_prediction(image)

        if prediction.get("status") == "error":
            return Response(
                {"error": "Prediction service unavailable"},
                status=502,
            )

        if prediction.get("status") == "not_a_plant":
            confidence = float(prediction.get("confidence") or 0)
            message = prediction.get("message")
            entropy = prediction.get("entropy")

            # Treat "not a plant" as a successful prediction: store it and
            # count it against guest limits the same way as other successful scans.
            ScanHistory.objects.create(
                user=user,
                guest_id=guest_id,
                crop=crop,
                image=image,
                disease_name="Not a plant leaf",
                confidence=confidence,
                prediction_status="not_a_plant",
                message=message,
                entropy=entropy,
                solution=None,
            )
            if user is None and guest_id:
                consume_guest_scan(guest_id)

            return Response(
                {
                    "prediction": {
                        "crop": crop,
                        "disease": None,
                        "confidence": confidence,
                        "top_5": [],
                        "status": "not_a_plant",
                        "message": prediction.get(
                            "message",
                            "Not a plant leaf. Please upload a clear photo of a plant leaf.",
                        ),
                        "entropy": entropy,
                    },
                    "solution": None,
                },
            status=status.HTTP_200_OK,
            )

        prediction = select_best_prediction_for_crop(prediction, crop)

        disease = prediction.get("disease")
        confidence = float(prediction.get("confidence") or 0)
        prediction_status = prediction.get("status", "ok")
        message = prediction.get("message")

        if prediction_status in {"crop_mismatch", "low_confidence"}:
            return Response(
                {
                    "prediction": {
                        "crop": crop,
                        "disease": disease,
                        "confidence": confidence,
                        "status": prediction_status,
                        "message": message,
                        "entropy": prediction.get("entropy"),
                        "detected": prediction.get("detected"),
                    },
                    "solution": None,
                },
                status=422,
            )


        solution = None
        if prediction_status not in {"crop_mismatch", "low_confidence"} and disease:
            solution = get_solution(disease, crop)

 
        ScanHistory.objects.create(
            user=user,
            guest_id=guest_id,
            crop=crop,
            image=image,
            disease_name=disease,
            confidence=confidence
            ,
            prediction_status=prediction_status,
            message=message,
            entropy=prediction.get("entropy"),
            solution=solution,
        )
        if user is None and guest_id:
            consume_guest_scan(guest_id)


        return Response({
            "prediction": {
                "crop": crop,
                "disease": disease,
                "confidence": confidence,
                "status": prediction_status,
                "message": message,
                "entropy": prediction.get("entropy"),
            },
            "solution": solution
        })


class ScanHistoryAPIView(APIView):
    permission_classes = [IsPremiumAccess]

    def get(self, request):
        user = request.user
        history = ScanHistory.objects.filter(user=user).order_by("-created_at")
        serializer = ScanHistorySerializer(history, many=True)
        return Response({
            "success": True,
            "history": serializer.data
        }, status=status.HTTP_200_OK)
