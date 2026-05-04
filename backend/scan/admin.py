from django.contrib import admin

from .models import (
    Plant,
    DiseaseCatalogItem,
    DiseaseSolution,
    ScanHistory,
    MissingSolutionLog,
)


@admin.register(Plant)
class PlantAdmin(admin.ModelAdmin):
    list_display = ("name", "is_active", "updated_at")
    list_filter = ("is_active",)
    search_fields = ("name",)


@admin.register(DiseaseCatalogItem)
class DiseaseCatalogItemAdmin(admin.ModelAdmin):
    list_display = ("class_index", "crop_display", "disease_display", "is_healthy")
    list_filter = ("is_healthy",)
    search_fields = ("raw_label", "crop_display", "disease_display", "label_display")


@admin.register(DiseaseSolution)
class DiseaseSolutionAdmin(admin.ModelAdmin):
    list_display = ("disease_name", "is_ai_generated", "created_at")
    list_filter = ("is_ai_generated",)
    search_fields = ("disease_name",)


@admin.register(ScanHistory)
class ScanHistoryAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "guest_id", "crop", "disease_name", "confidence", "prediction_status", "created_at")
    list_filter = ("prediction_status", "crop")
    search_fields = ("crop", "disease_name", "guest_id", "user__username")


@admin.register(MissingSolutionLog)
class MissingSolutionLogAdmin(admin.ModelAdmin):
    list_display = ("disease_name", "crop", "resolved", "created_at")
    list_filter = ("resolved", "crop")
    search_fields = ("disease_name", "crop")
