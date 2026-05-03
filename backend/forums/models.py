from django.db import models
from django.conf import settings


class Question(models.Model):

    STATUS_CHOICES = [
        ("open", "Open"),
        ("answered", "Answered"),
        ("closed", "Closed"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="questions"
    )

    title = models.CharField(max_length=255)
    description = models.TextField()

    crop = models.CharField(max_length=100)

    image = models.ImageField(
        upload_to="forum/questions/",
        null=True,
        blank=True
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="open"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
    

class Answer(models.Model):

    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name="answers"
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="answers"
    )

    text = models.TextField()

    is_expert = models.BooleanField(default=False)
    is_ai = models.BooleanField(default=False)  

    likes_count = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        # auto mark expert
        if hasattr(self.user, "role") and self.user.role == "expert":
            self.is_expert = True
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Answer by {self.user}"
    

class AnswerLike(models.Model):

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )

    answer = models.ForeignKey(
        Answer,
        on_delete=models.CASCADE,
        related_name="likes"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "answer")