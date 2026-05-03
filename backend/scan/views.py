from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import BasePermission
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


class IsGuestOrPremium(BasePermission):
    message = "Guest limit reached or active subscription required."

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return True
        return IsPremiumAccess().has_permission(request, view)



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

        # -----------------------
        # 1. ML PREDICTION
        # -----------------------
        prediction = get_prediction(image)

        if prediction.get("status") == "error":
            return Response(
                {"error": "Prediction service unavailable"},
                status=502,
            )

        if prediction.get("status") == "not_a_plant":
            return Response(
                {
                    "prediction": {
                        "crop": crop,
                        "disease": None,
                        "confidence": prediction.get("confidence", 0),
                        "top_5": [],
                        "status": "not_a_plant",
                        "message": prediction.get(
                            "message",
                            "Not a plant leaf. Please upload a clear photo of a plant leaf.",
                        ),
                        "entropy": prediction.get("entropy"),
                    },
                    "solution": None,
                },
                status=400,
            )

        prediction = select_best_prediction_for_crop(prediction, crop)

        disease = prediction.get("disease")
        confidence = float(prediction.get("confidence") or 0)
        status = prediction.get("status", "ok")
        message = prediction.get("message")

        if status in {"crop_mismatch", "low_confidence"}:
            return Response(
                {
                    "prediction": {
                        "crop": crop,
                        "disease": disease,
                        "confidence": confidence,
                        "status": status,
                        "message": message,
                        "entropy": prediction.get("entropy"),
                        "detected": prediction.get("detected"),
                    },
                    "solution": None,
                },
                status=422,
            )

        # -----------------------
        # 4. SOLUTION ENGINE
        # -----------------------
        solution = None
        if status not in {"crop_mismatch", "low_confidence"} and disease:
            solution = get_solution(disease, crop)

        # -----------------------
        # 5. SAVE HISTORY
        # -----------------------
        ScanHistory.objects.create(
            user=user,
            guest_id=guest_id,
            crop=crop,
            image=image,
            disease_name=disease,
            confidence=confidence
        )
        if user is None and guest_id:
            consume_guest_scan(guest_id)

        # -----------------------
        # 6. FINAL RESPONSE
        # -----------------------
        return Response({
            "prediction": {
                "crop": crop,
                "disease": disease,
                "confidence": confidence,
                "status": status,
                "message": message,
                "entropy": prediction.get("entropy"),
            },
            "solution": solution
        })
