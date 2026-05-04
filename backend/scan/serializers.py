from rest_framework import serializers
from .models import ScanHistory, DiseaseCatalogItem, DiseaseSolution, Plant
from .label_utils import format_label_display


class ScanHistorySerializer(serializers.ModelSerializer):
    disease_display = serializers.SerializerMethodField()

    def get_disease_display(self, obj):
        return format_label_display(getattr(obj, "disease_name", None)) or getattr(obj, "disease_name", None)

    class Meta:
        model = ScanHistory
        fields = [
            "id",
            "user",
            "guest_id",
            "crop",
            "disease_name",
            "disease_display",
            "confidence",
            "prediction_status",
            "message",
            "entropy",
            "solution",
            "image",
            "created_at",
        ]


class PlantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Plant
        fields = ["id", "name", "description", "is_active", "created_at", "updated_at"]
        read_only_fields = fields


class DiseaseCatalogItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiseaseCatalogItem
        fields = [
            "class_index",
            "raw_label",
            "crop_display",
            "disease_display",
            "label_display",
            "is_healthy",
        ]
        read_only_fields = fields


class DiseaseSolutionCatalogSerializer(serializers.ModelSerializer):
    organic = serializers.CharField(source="organic_solution")
    chemical = serializers.CharField(source="chemical_solution")
    tips = serializers.CharField(source="prevention_tips", allow_null=True, required=False)
    plant = serializers.SerializerMethodField()

    def get_plant(self, obj):
        plant = getattr(obj, "plant", None)
        if not plant:
            return None
        return {"id": plant.id, "name": plant.name}

    class Meta:
        model = DiseaseSolution
        fields = ["disease_name", "plant", "organic", "chemical", "tips", "is_ai_generated", "created_at"]
        read_only_fields = fields
     
        
    
