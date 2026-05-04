from django.contrib import admin
from .models import Question, Answer, AnswerLike

@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ("title", "user", "status", "created_at")
    list_filter = ("status", "created_at")
    search_fields = ("title", "description", "user__username")


@admin.register(Answer)
class AnswerAdmin(admin.ModelAdmin):
    list_display = ("question", "user", "is_expert", "is_ai")
    list_filter = ("is_expert", "is_ai")
    search_fields = ("text", "user__username", "question__title")

@admin.register(AnswerLike)
class AnswerLikeAdmin(admin.ModelAdmin):
    list_display = ("answer", "user")
    search_fields = ("answer__text", "user__username")
    

