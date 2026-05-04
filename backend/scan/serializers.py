from rest_framework import serializers
from .models import ScanHistory


class ScanHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ScanHistory
        fields = ["id", "user", "guest_id", "crop", "disease_name", "confidence", "created_at"]
     
        
    