from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Count, Q
from django_filters import FilterSet, CharFilter, BooleanFilter
from .models import (
    Plant,
    DiseaseCatalogItem,
    DiseaseSolution,
    ScanHistory,
    MissingSolutionLog,
)


class PredictionStatusFilter(admin.SimpleListFilter):
    """Custom filter for prediction status"""
    title = "Prediction Status"
    parameter_name = "prediction_status"

    def lookups(self, request, model_admin):
        return [
            ("ok", "✓ Success"),
            ("low_confidence", "⚠️ Low Confidence"),
            ("error", "❌ Error"),
        ]

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(prediction_status=self.value())
        return queryset


@admin.register(Plant)
class PlantAdmin(admin.ModelAdmin):
    list_display = (
        "get_plant_name",
        "get_status_badge",
        "get_disease_count",
        "created_at",
        "updated_at",
    )
    list_filter = ("is_active", "created_at")
    search_fields = ("name",)
    readonly_fields = ("created_at", "updated_at", "get_disease_count")
    fieldsets = (
        ("Plant Information", {
            "fields": ("name", "description"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Status", {
            "fields": ("is_active",),
        }),
        ("Metadata", {
            "fields": ("created_at", "updated_at", "get_disease_count"),
            "classes": ("collapse",),
        }),
    )
    list_per_page = 25
    ordering = ("-created_at",)

    def get_plant_name(self, obj):
        return format_html(
            '<span style="color: #27ae60; font-weight: bold; font-size: 13px;">🌱 {}</span>',
            obj.name
        )
    get_plant_name.short_description = "Plant Name"

    def get_status_badge(self, obj):
        color = "#27ae60" if obj.is_active else "#e74c3c"
        icon = "✓" if obj.is_active else "✗"
        status_text = "Active" if obj.is_active else "Inactive"
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; border-radius: 20px; font-size: 11px; font-weight: bold;">{} {}</span>',
            color,
            icon,
            status_text
        )
    get_status_badge.short_description = "Status"

    def get_disease_count(self, obj):
        count = obj.disease_solutions.count()
        return format_html(
            '<span style="background-color: #3498db; color: white; padding: 3px 8px; border-radius: 15px; font-size: 11px; font-weight: bold;">{} diseases</span>',
            count
        )
    get_disease_count.short_description = "Associated Diseases"

    actions = ["activate_plants", "deactivate_plants"]

    def activate_plants(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f"✓ {updated} plant(s) activated.")
    activate_plants.short_description = "Activate selected plants ✓"

    def deactivate_plants(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f"⛔ {updated} plant(s) deactivated.")
    deactivate_plants.short_description = "Deactivate selected plants ⛔"


@admin.register(DiseaseCatalogItem)
class DiseaseCatalogItemAdmin(admin.ModelAdmin):
    list_display = (
        "get_class_badge",
        "get_crop_display",
        "get_disease_display",
        "get_health_status",
        "label_display",
    )
    list_filter = ("is_healthy", "crop_display")
    search_fields = ("raw_label", "crop_display",
                     "disease_display", "label_display")
    readonly_fields = ("created_at", "updated_at", "get_raw_label_display")
    fieldsets = (
        ("Classification", {
            "fields": ("class_index", "raw_label", "get_raw_label_display"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Display Labels", {
            "fields": ("crop_display", "disease_display", "label_display"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Health Status", {
            "fields": ("is_healthy",),
        }),
        ("Metadata", {
            "fields": ("created_at", "updated_at"),
            "classes": ("collapse",),
        }),
    )
    list_per_page = 50
    ordering = ("class_index",)

    def get_class_badge(self, obj):
        return format_html(
            '<span style="background-color: #9b59b6; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">#{}</span>',
            obj.class_index
        )
    get_class_badge.short_description = "Class"

    def get_crop_display(self, obj):
        return format_html(
            '<span style="color: #27ae60; font-weight: bold;">🌾 {}</span>',
            obj.crop_display or obj.crop_raw
        )
    get_crop_display.short_description = "Crop"

    def get_disease_display(self, obj):
        return format_html(
            '<span style="color: #e74c3c; font-weight: bold;">🦠 {}</span>',
            obj.disease_display or obj.disease_raw
        )
    get_disease_display.short_description = "Disease"

    def get_health_status(self, obj):
        if obj.is_healthy:
            return format_html(
                '<span style="color: green; font-weight: bold; font-size: 12px;">{}</span>',
                '✓ Healthy',
            )
        else:
            return format_html(
                '<span style="color: red; font-weight: bold; font-size: 12px;">{}</span>',
                '⚠️ Disease',
            )
    get_health_status.short_description = "Health Status"

    def get_raw_label_display(self, obj):
        return format_html(
            '<code style="background-color: #ecf0f1; padding: 5px; border-radius: 5px;">{}</code>',
            obj.raw_label
        )
    get_raw_label_display.short_description = "Raw Label"


@admin.register(DiseaseSolution)
class DiseaseSolutionAdmin(admin.ModelAdmin):
    list_display = (
        "get_disease_name",
        "get_plant_link",
        "get_generation_badge",
        "created_at",
    )
    list_filter = ("is_ai_generated", "created_at", "plant")
    search_fields = ("disease_name",)
    readonly_fields = ("created_at", "get_solution_preview")
    fieldsets = (
        ("Disease Information", {
            "fields": ("disease_name", "plant"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Solutions", {
            "fields": ("organic_solution", "chemical_solution", "prevention_tips"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Source", {
            "fields": ("is_ai_generated",),
        }),
        ("Metadata", {
            "fields": ("created_at",),
            "classes": ("collapse",),
        }),
    )
    list_per_page = 25
    ordering = ("-created_at",)

    def get_disease_name(self, obj):
        return format_html(
            '<span style="color: #e74c3c; font-weight: bold; font-size: 13px;">🦠 {}</span>',
            obj.disease_name
        )
    get_disease_name.short_description = "Disease"

    def get_plant_link(self, obj):
        if obj.plant:
            return format_html(
                '<span style="color: #27ae60; font-weight: bold;">🌱 {}</span>',
                obj.plant.name
            )
        return "—"
    get_plant_link.short_description = "Plant"

    def get_generation_badge(self, obj):
        if obj.is_ai_generated:
            return format_html(
                '<span style="background-color: #3498db; color: white; padding: 5px 10px; border-radius: 15px; font-size: 10px; font-weight: bold;">{}</span>',
                '🤖 AI Generated',
            )
        else:
            return format_html(
                '<span style="background-color: #27ae60; color: white; padding: 5px 10px; border-radius: 15px; font-size: 10px; font-weight: bold;">{}</span>',
                '👤 Manual',
            )
    get_generation_badge.short_description = "Source"

    def get_solution_preview(self, obj):
        return format_html(
            '<div style="background-color: #ecf0f1; padding: 10px; border-radius: 5px;"><p><strong>Organic:</strong> {}</p><p><strong>Chemical:</strong> {}</p></div>',
            obj.organic_solution[:100] + "..." if len(
                obj.organic_solution) > 100 else obj.organic_solution,
            obj.chemical_solution[:100] + "..." if len(
                obj.chemical_solution) > 100 else obj.chemical_solution,
        )
    get_solution_preview.short_description = "Preview"


@admin.register(ScanHistory)
class ScanHistoryAdmin(admin.ModelAdmin):
    list_display = (
        "get_scan_id",
        "get_user_display",
        "get_crop_badge",
        "get_disease_badge",
        "get_confidence_display",
        "get_status_display",
        "created_at",
    )
    list_filter = (
        PredictionStatusFilter,
        "crop",
        ("created_at", admin.DateFieldListFilter),
    )
    search_fields = ("crop", "disease_name", "guest_id", "user__username")
    readonly_fields = (
        "created_at",
        "get_image_display",
        "get_solution_display",
    )
    fieldsets = (
        ("Scan Information", {
            "fields": ("id", "created_at"),
            "classes": ("wide", "extrapretty"),
        }),
        ("User Information", {
            "fields": ("user", "guest_id"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Prediction Results", {
            "fields": ("crop", "disease_name", "confidence", "prediction_status", "message"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Image & Analysis", {
            "fields": ("image", "get_image_display", "entropy"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Solution", {
            "fields": ("solution", "get_solution_display"),
            "classes": ("wide", "extrapretty"),
        }),
    )
    list_per_page = 30
    ordering = ("-created_at",)

    def get_scan_id(self, obj):
        return format_html(
            '<span style="background-color: #34495e; color: white; padding: 5px 8px; border-radius: 10px; font-size: 10px; font-weight: bold; font-family: monospace;">{}</span>',
            str(obj.id)[:8]
        )
    get_scan_id.short_description = "Scan ID"

    def get_user_display(self, obj):
        if obj.user:
            return format_html(
                '<span style="color: #2980b9; font-weight: bold;">👤 {}</span>',
                obj.user.username
            )
        return format_html(
            '<span style="color: #95a5a6; font-style: italic;">Guest ({})</span>',
            obj.guest_id[:8] if obj.guest_id else "Unknown"
        )
    get_user_display.short_description = "User"

    def get_crop_badge(self, obj):
        return format_html(
            '<span style="background-color: #27ae60; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">🌾 {}</span>',
            obj.crop
        )
    get_crop_badge.short_description = "Crop"

    def get_disease_badge(self, obj):
        return format_html(
            '<span style="background-color: #e74c3c; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">🦠 {}</span>',
            obj.disease_name
        )
    get_disease_badge.short_description = "Disease"

    def get_confidence_display(self, obj):
        confidence = float(obj.confidence) * 100
        if confidence >= 90:
            color = "#27ae60"
        elif confidence >= 70:
            color = "#f39c12"
        else:
            color = "#e74c3c"
        confidence_text = f"{confidence:.1f}%"
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            confidence_text,
        )
    get_confidence_display.short_description = "Confidence"

    def get_status_display(self, obj):
        status_colors = {
            "ok": ("#27ae60", "✓ Success"),
            "low_confidence": ("#f39c12", "⚠️ Low Confidence"),
            "error": ("#e74c3c", "❌ Error"),
        }
        color, icon_text = status_colors.get(
            obj.prediction_status, ("#95a5a6", "? Unknown"))
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; border-radius: 15px; font-size: 10px; font-weight: bold;">{}</span>',
            color,
            icon_text
        )
    get_status_display.short_description = "Status"

    def get_image_display(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" style="max-width: 300px; max-height: 300px; border-radius: 10px; border: 2px solid #3498db;" />',
                obj.image.url
            )
        return "No image"
    get_image_display.short_description = "Scan Image"

    def get_solution_display(self, obj):
        if obj.solution:
            return format_html(
                '<pre style="background-color: #ecf0f1; padding: 10px; border-radius: 5px; overflow-x: auto;"><code>{}</code></pre>',
                str(obj.solution)[:500]
            )
        return "—"
    get_solution_display.short_description = "Solution Details"

    actions = ["mark_success", "mark_low_confidence", "mark_error"]

    def mark_success(self, request, queryset):
        updated = queryset.update(prediction_status="ok")
        self.message_user(request, f"✓ {updated} scan(s) marked as success.")
    mark_success.short_description = "Mark as Success ✓"

    def mark_low_confidence(self, request, queryset):
        updated = queryset.update(prediction_status="low_confidence")
        self.message_user(
            request, f"⚠️ {updated} scan(s) marked as low confidence.")
    mark_low_confidence.short_description = "Mark as Low Confidence ⚠️"

    def mark_error(self, request, queryset):
        updated = queryset.update(prediction_status="error")
        self.message_user(request, f"❌ {updated} scan(s) marked as error.")
    mark_error.short_description = "Mark as Error ❌"


@admin.register(MissingSolutionLog)
class MissingSolutionLogAdmin(admin.ModelAdmin):
    list_display = (
        "get_disease_name",
        "get_crop_badge",
        "get_resolution_status",
        "created_at",
    )
    list_filter = ("resolved", "created_at", "crop")
    search_fields = ("disease_name", "crop")
    readonly_fields = ("created_at", "get_creation_time_display")
    fieldsets = (
        ("Missing Solution Report", {
            "fields": ("disease_name", "crop"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Resolution", {
            "fields": ("resolved",),
        }),
        ("Metadata", {
            "fields": ("created_at", "get_creation_time_display"),
            "classes": ("collapse",),
        }),
    )
    list_per_page = 25
    ordering = ("-created_at",)

    def get_disease_name(self, obj):
        return format_html(
            '<span style="color: #e74c3c; font-weight: bold; font-size: 13px;">🦠 {}</span>',
            obj.disease_name
        )
    get_disease_name.short_description = "Disease"

    def get_crop_badge(self, obj):
        return format_html(
            '<span style="background-color: #27ae60; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">🌾 {}</span>',
            obj.crop
        )
    get_crop_badge.short_description = "Crop"

    def get_resolution_status(self, obj):
        if obj.resolved:
            return format_html(
                '<span style="color: #27ae60; font-weight: bold; font-size: 12px;">{}</span>',
                '✓ Resolved',
            )
        else:
            return format_html(
                '<span style="color: #e74c3c; font-weight: bold; font-size: 12px;">{}</span>',
                '⏳ Pending',
            )
    get_resolution_status.short_description = "Resolution Status"

    def get_creation_time_display(self, obj):
        from django.utils.timesince import timesince
        return format_html(
            '{} ago',
            timesince(obj.created_at)
        )
    get_creation_time_display.short_description = "Created"

    actions = ["mark_resolved", "mark_unresolved"]

    def mark_resolved(self, request, queryset):
        updated = queryset.update(resolved=True)
        self.message_user(
            request, f"✓ {updated} report(s) marked as resolved.")
    mark_resolved.short_description = "Mark as Resolved ✓"

    def mark_unresolved(self, request, queryset):
        updated = queryset.update(resolved=False)
        self.message_user(
            request, f"⏳ {updated} report(s) marked as unresolved.")
    mark_unresolved.short_description = "Mark as Unresolved ⏳"
