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

    created_at = models.DateTimeField(auto_now_add=True)
    



class DiseaseSolution(models.Model):
    disease_name = models.CharField(max_length=255, unique=True)

    organic_solution = models.TextField()
    chemical_solution = models.TextField()
    prevention_tips = models.TextField(blank=True, null=True)

    is_ai_generated = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.disease_name
    

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