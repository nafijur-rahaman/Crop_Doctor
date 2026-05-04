from django.db import models
from django.conf import settings



class ScanHistory(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.CASCADE
    )

    guest_id = models.CharField(max_length=255, null=True, blank=True)

    crop = models.CharField(max_length=100)  

    image = models.ImageField(upload_to="scans/")

    disease_name = models.CharField(max_length=255)
    confidence = models.FloatField()
    prediction_status = models.CharField(max_length=32, default="ok")
    message = models.TextField(blank=True, null=True)
    entropy = models.FloatField(blank=True, null=True)
    solution = models.JSONField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    



class DiseaseSolution(models.Model):
    disease_name = models.CharField(max_length=255, unique=True)
    plant = models.ForeignKey(
        "Plant",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="disease_solutions",
    )

    organic_solution = models.TextField()
    chemical_solution = models.TextField()
    prevention_tips = models.TextField(blank=True, null=True)

    is_ai_generated = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.disease_name


class DiseaseCatalogItem(models.Model):
    """
    Catalog of supported model classes (from docs/class_names.json).

    raw_label example: "Corn_(maize)___healthy"
    """

    class_index = models.PositiveIntegerField(unique=True)
    raw_label = models.CharField(max_length=255, unique=True)
    crop_raw = models.CharField(max_length=255, blank=True, default="")
    disease_raw = models.CharField(max_length=255, blank=True, default="")
    crop_display = models.CharField(max_length=255, blank=True, default="")
    disease_display = models.CharField(max_length=255, blank=True, default="")
    label_display = models.CharField(max_length=512, blank=True, default="")
    is_healthy = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.label_display or self.raw_label


class Plant(models.Model):

    name = models.CharField(max_length=120, unique=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name
    

class MissingSolutionLog(models.Model):
    disease_name = models.CharField(max_length=255)
    crop = models.CharField(max_length=100)

    created_at = models.DateTimeField(auto_now_add=True)

    resolved = models.BooleanField(default=False)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["disease_name", "crop"],
                name="uniq_missing_solution_disease_crop",
            )
        ]
    def __str__(self):
        return self.disease_name
