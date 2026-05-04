from .views import ScanAPIView, ScanHistoryAPIView
from django.urls import path

urlpatterns = [
    path("scan/", ScanAPIView.as_view(), name="scan"),
    path("scan/history/", ScanHistoryAPIView.as_view(), name="scan-history"),
]
