from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import BasePermission
from rest_framework import status
import re
from datetime import timedelta
from django.utils import timezone


from .services import (
    get_prediction,
    check_guest_limit,
    consume_guest_scan,
    get_solution,
    select_best_prediction_for_crop,
    MAX_GUEST_SCANS_PER_WEEK,
)
from users.permissions import IsPremiumAccess

from .models import ScanHistory, DiseaseCatalogItem, DiseaseSolution, Plant
from .serializers import (
    ScanHistorySerializer,
    DiseaseCatalogItemSerializer,
    PlantSerializer,
    DiseaseSolutionCatalogSerializer,
)
from .label_utils import format_label_display, format_crop_and_disease


class IsGuestOrPremium(BasePermission):
    message = "You are not allowed to access this."

    def has_permission(self, request, view):
        return True


class ScanAPIView(APIView):
    permission_classes = [IsGuestOrPremium]

    def post(self, request):

        image = request.FILES.get("image")
        crop = request.data.get("crop")

        user = request.user if request.user.is_authenticated else None
        guest_id = None
        weekly_scans = None

        if image is None:
            return Response({"error": "image file required"}, status=400)

        if not crop:
            return Response({"error": "crop required"}, status=400)

        if user is None:
            guest_id = request.data.get(
                "guest_id") or request.headers.get("X-Guest-Id")
            if not guest_id:
                return Response({"error": "guest_id required for guest scan"}, status=400)
            if not check_guest_limit(guest_id):
                return Response(
                    {
                        "error": "Weekly guest scan limit exceeded (3)",
                        "code": "SCAN_LIMIT_EXCEEDED",
                        "remaining_scans": 0,
                        "limit_per_week": MAX_GUEST_SCANS_PER_WEEK,
                    },
                    status=403,
                )
        elif getattr(user, "role", "guest") == "guest":
            now = timezone.now()
            week_start = (now - timedelta(days=now.weekday())).replace(
                hour=0,
                minute=0,
                second=0,
                microsecond=0,
            )
            weekly_scans = ScanHistory.objects.filter(
                user=user,
                created_at__gte=week_start,
            ).count()
            if weekly_scans >= MAX_GUEST_SCANS_PER_WEEK:
                return Response(
                    {
                        "error": "Weekly guest scan limit exceeded (3)",
                        "code": "SCAN_LIMIT_EXCEEDED",
                        "remaining_scans": 0,
                        "limit_per_week": MAX_GUEST_SCANS_PER_WEEK,
                    },
                    status=403,
                )

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
            disease_display = "Not a plant leaf"

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
            usage = None
            if user is None and guest_id:
                _, remaining_after = consume_guest_scan(guest_id)
                usage = {
                    "remaining_scans": remaining_after,
                    "limit_per_week": MAX_GUEST_SCANS_PER_WEEK,
                }
            elif getattr(user, "role", "guest") == "guest" and weekly_scans is not None:
                usage = {
                    "remaining_scans": max(MAX_GUEST_SCANS_PER_WEEK - (weekly_scans + 1), 0),
                    "limit_per_week": MAX_GUEST_SCANS_PER_WEEK,
                }

            payload = {
                "prediction": {
                    "crop": crop,
                    "disease": None,
                    "disease_display": disease_display,
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
            }
            if usage is not None:
                payload["usage"] = usage

            return Response(payload, status=status.HTTP_200_OK)

        prediction = select_best_prediction_for_crop(prediction, crop)

        disease = prediction.get("disease")
        confidence = float(prediction.get("confidence") or 0)
        prediction_status = prediction.get("status", "ok")
        message = prediction.get("message")
        disease_display = format_label_display(disease) if disease else None

        if prediction_status in {"crop_mismatch", "low_confidence"}:
            detected = prediction.get("detected") or {}
            detected_label = detected.get("disease")
            detected_crop, detected_disease = format_crop_and_disease(
                detected_label)
            return Response(
                {
                    "prediction": {
                        "crop": crop,
                        "disease": disease,
                        "disease_display": disease_display,
                        "confidence": confidence,
                        "status": prediction_status,
                        "message": message,
                        "entropy": prediction.get("entropy"),
                        "detected": {
                            **(detected if isinstance(detected, dict) else {}),
                            "crop_display": detected_crop,
                            "disease_display": format_label_display(detected_label) if detected_label else None,
                            "disease_name": detected_disease,
                        } if isinstance(detected, dict) else detected,
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
            confidence=confidence,
            prediction_status=prediction_status,
            message=message,
            entropy=prediction.get("entropy"),
            solution=solution,
        )
        usage = None
        if user is None and guest_id:
            _, remaining_after = consume_guest_scan(guest_id)
            usage = {
                "remaining_scans": remaining_after,
                "limit_per_week": MAX_GUEST_SCANS_PER_WEEK,
            }
        elif getattr(user, "role", "guest") == "guest" and weekly_scans is not None:
            usage = {
                "remaining_scans": max(MAX_GUEST_SCANS_PER_WEEK - (weekly_scans + 1), 0),
                "limit_per_week": MAX_GUEST_SCANS_PER_WEEK,
            }

        payload = {
            "prediction": {
                "crop": crop,
                "disease": disease,
                "disease_display": disease_display,
                "confidence": confidence,
                "status": prediction_status,
                "message": message,
                "entropy": prediction.get("entropy"),
            },
            "solution": solution
        }
        if usage is not None:
            payload["usage"] = usage

        return Response(payload)


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


class DiseaseCatalogAPIView(APIView):

    permission_classes = [IsPremiumAccess]

    def get(self, request):
        qs = DiseaseCatalogItem.objects.all().order_by("class_index")
        items = DiseaseCatalogItemSerializer(qs, many=True).data
        return Response({"count": len(items), "items": items}, status=status.HTTP_200_OK)


class CropCatalogAPIView(APIView):

    permission_classes = [IsPremiumAccess]

    def get(self, request):
        qs = Plant.objects.filter(is_active=True).order_by("name")
        items = PlantSerializer(qs, many=True).data
        return Response({"count": len(items), "items": items}, status=status.HTTP_200_OK)


class DiseaseSolutionsCatalogAPIView(APIView):

    permission_classes = [IsPremiumAccess]

    def get(self, request):
        qs = DiseaseSolution.objects.all().order_by("disease_name")
        plant_id = request.query_params.get("plant_id")
        if plant_id:
            try:
                qs = qs.filter(plant_id=int(plant_id))
            except (TypeError, ValueError):
                return Response({"error": "plant_id must be an integer"}, status=status.HTTP_400_BAD_REQUEST)
        items = DiseaseSolutionCatalogSerializer(qs, many=True).data
        return Response({"count": len(items), "items": items}, status=status.HTTP_200_OK)
