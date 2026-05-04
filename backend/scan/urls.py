from .views import (
    ScanAPIView,
    ScanHistoryAPIView,
    DiseaseCatalogAPIView,
    CropCatalogAPIView,
    DiseaseSolutionsCatalogAPIView,
)
from django.urls import path

urlpatterns = [
    path("scan/", ScanAPIView.as_view(), name="scan"),
    path("scan/history/", ScanHistoryAPIView.as_view(), name="scan-history"),
    path("catalog/diseases/", DiseaseCatalogAPIView.as_view(), name="catalog-diseases"),
    path("catalog/crops/", CropCatalogAPIView.as_view(), name="catalog-crops"),
    path("catalog/solutions/", DiseaseSolutionsCatalogAPIView.as_view(), name="catalog-solutions"),
]
