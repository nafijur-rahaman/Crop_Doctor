from .views import ScanAPIView
from django.urls import path

urlpatterns = [
    path("scan/", ScanAPIView.as_view(), name="scan"),
]
