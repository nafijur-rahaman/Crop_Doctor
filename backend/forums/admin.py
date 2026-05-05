from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Count, Q
from .models import Question, Answer, AnswerLike


class AnswerInline(admin.TabularInline):
    """Inline display of answers for a question"""
    model = Answer
    extra = 0
    fields = ("user", "is_expert", "is_ai", "created_at")
    readonly_fields = ("created_at",)
    can_delete = True


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = (
        "get_question_title",
        "get_user_display",
        "get_status_badge",
        "get_answer_count",
        "created_at",
    )
    list_filter = (
        "status",
        ("created_at", admin.DateFieldListFilter),
        "user",
    )
    search_fields = ("title", "description", "user__username")
    readonly_fields = (
        "created_at",
        "get_question_preview",
        "get_answer_count",
    )
    fieldsets = (
        ("Question Details", {
            "fields": ("title", "get_question_preview"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Content", {
            "fields": ("description",),
            "classes": ("wide", "extrapretty"),
        }),
        ("Author Information", {
            "fields": ("user",),
            "classes": ("wide", "extrapretty"),
        }),
        ("Status & Activity", {
            "fields": ("status", "get_answer_count", "created_at"),
            "classes": ("wide", "extrapretty"),
        }),
    )
    inlines = [AnswerInline]
    list_per_page = 25
    ordering = ("-created_at",)

    def get_question_title(self, obj):
        return format_html(
            '<span style="color: #2c3e50; font-weight: bold; font-size: 13px;">❓ {}</span>',
            obj.title[:50] + "..." if len(obj.title) > 50 else obj.title
        )
    get_question_title.short_description = "Question"

    def get_user_display(self, obj):
        return format_html(
            '<span style="color: #2980b9; font-weight: bold;">👤 {}</span>',
            obj.user.username
        )
    get_user_display.short_description = "Author"

    def get_status_badge(self, obj):
        status_colors = {
            "open": "#27ae60",
            "answered": "#3498db",
            "closed": "#95a5a6",
        }
        status_icons = {
            "open": "🟢",
            "answered": "✓",
            "closed": "🔒",
        }
        color = status_colors.get(obj.status, "#7f8c8d")
        icon = status_icons.get(obj.status, "?")
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">{} {}</span>',
            color,
            icon,
            obj.get_status_display()
        )
    get_status_badge.short_description = "Status"

    def get_answer_count(self, obj):
        count = obj.answers.count()
        return format_html(
            '<span style="background-color: #9b59b6; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">💬 {} answer(s)</span>',
            count
        )
    get_answer_count.short_description = "Answers"

    def get_question_preview(self, obj):
        return format_html(
            '<div style="background-color: #ecf0f1; padding: 10px; border-radius: 5px;"><p><strong>{}</strong></p><p>{}</p></div>',
            obj.title,
            obj.description[:200] +
            "..." if len(obj.description) > 200 else obj.description
        )
    get_question_preview.short_description = "Preview"

    actions = ["mark_open", "mark_answered", "mark_closed"]

    def mark_open(self, request, queryset):
        updated = queryset.update(status="open")
        self.message_user(request, f"🟢 {updated} question(s) marked as open.")
    mark_open.short_description = "Mark as Open 🟢"

    def mark_answered(self, request, queryset):
        updated = queryset.update(status="answered")
        self.message_user(
            request, f"✓ {updated} question(s) marked as answered.")
    mark_answered.short_description = "Mark as Answered ✓"

    def mark_closed(self, request, queryset):
        updated = queryset.update(status="closed")
        self.message_user(
            request, f"🔒 {updated} question(s) marked as closed.")
    mark_closed.short_description = "Mark as Closed 🔒"


@admin.register(Answer)
class AnswerAdmin(admin.ModelAdmin):
    list_display = (
        "get_answer_preview",
        "get_question_link",
        "get_user_display",
        "get_type_badge",
        "get_likes_count",
        "created_at",
    )
    list_filter = (
        "is_expert",
        "is_ai",
        ("created_at", admin.DateFieldListFilter),
        "question__status",
    )
    search_fields = ("text", "user__username", "question__title")
    readonly_fields = (
        "created_at",
        "get_answer_display",
        "get_likes_count",
    )
    fieldsets = (
        ("Answer Details", {
            "fields": ("question", "get_answer_display"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Author Information", {
            "fields": ("user",),
            "classes": ("wide", "extrapretty"),
        }),
        ("Answer Type", {
            "fields": ("is_expert", "is_ai"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Engagement", {
            "fields": ("get_likes_count",),
            "classes": ("wide", "extrapretty"),
        }),
        ("Metadata", {
            "fields": ("created_at",),
            "classes": ("collapse",),
        }),
    )
    list_per_page = 30
    ordering = ("-created_at",)

    def get_answer_preview(self, obj):
        preview = obj.text[:50] + "..." if len(obj.text) > 50 else obj.text
        return format_html(
            '<span style="color: #2c3e50; font-size: 13px;">💬 {}</span>',
            preview
        )
    get_answer_preview.short_description = "Answer"

    def get_question_link(self, obj):
        return format_html(
            '<span style="color: #2980b9; font-weight: bold;">❓ {}</span>',
            obj.question.title[:40] +
            "..." if len(obj.question.title) > 40 else obj.question.title
        )
    get_question_link.short_description = "Question"

    def get_user_display(self, obj):
        return format_html(
            '<span style="color: #27ae60; font-weight: bold;">👤 {}</span>',
            obj.user.username
        )
    get_user_display.short_description = "Answerer"

    def get_type_badge(self, obj):
        if obj.is_expert and obj.is_ai:
            return format_html(
                '<span style="background-color: #e74c3c; color: white; padding: 3px 8px; border-radius: 10px; font-size: 10px; font-weight: bold; margin-right: 3px;">{}</span> '
                '<span style="background-color: #3498db; color: white; padding: 3px 8px; border-radius: 10px; font-size: 10px; font-weight: bold;">{}</span>',
                '👨‍🔬 Expert',
                '🤖 AI',
            )
        if obj.is_expert:
            return format_html(
                '<span style="background-color: #e74c3c; color: white; padding: 3px 8px; border-radius: 10px; font-size: 10px; font-weight: bold;">{}</span>',
                '👨‍🔬 Expert',
            )
        if obj.is_ai:
            return format_html(
                '<span style="background-color: #3498db; color: white; padding: 3px 8px; border-radius: 10px; font-size: 10px; font-weight: bold;">{}</span>',
                '🤖 AI',
            )
        return format_html(
            '<span style="background-color: #95a5a6; color: white; padding: 3px 8px; border-radius: 10px; font-size: 10px; font-weight: bold;">{}</span>',
            '👤 User',
        )
    get_type_badge.short_description = "Type"

    def get_likes_count(self, obj):
        count = obj.likes.count()
        return format_html(
            '<span style="background-color: #e74c3c; color: white; padding: 5px 10px; border-radius: 15px; font-size: 11px; font-weight: bold;">❤️ {} like(s)</span>',
            count
        )
    get_likes_count.short_description = "Likes"

    def get_answer_display(self, obj):
        return format_html(
            '<div style="background-color: #ecf0f1; padding: 10px; border-radius: 5px;"><p>{}</p></div>',
            obj.text[:500] + "..." if len(obj.text) > 500 else obj.text
        )
    get_answer_display.short_description = "Answer Preview"

    actions = ["mark_expert_answer", "mark_ai_answer", "mark_user_answer"]

    def mark_expert_answer(self, request, queryset):
        updated = queryset.update(is_expert=True, is_ai=False)
        self.message_user(
            request, f"👨‍🔬 {updated} answer(s) marked as expert.")
    mark_expert_answer.short_description = "Mark as Expert Answer 👨‍🔬"

    def mark_ai_answer(self, request, queryset):
        updated = queryset.update(is_ai=True, is_expert=False)
        self.message_user(
            request, f"🤖 {updated} answer(s) marked as AI generated.")
    mark_ai_answer.short_description = "Mark as AI Answer 🤖"

    def mark_user_answer(self, request, queryset):
        updated = queryset.update(is_expert=False, is_ai=False)
        self.message_user(
            request, f"👤 {updated} answer(s) marked as user answer.")
    mark_user_answer.short_description = "Mark as User Answer 👤"


@admin.register(AnswerLike)
class AnswerLikeAdmin(admin.ModelAdmin):
    list_display = (
        "get_answer_preview",
        "get_user_display",
        "created_at",
    )
    list_filter = (
        ("created_at", admin.DateFieldListFilter),
        "answer__question__status",
    )
    search_fields = ("answer__text", "user__username",
                     "answer__question__title")
    readonly_fields = (
        "created_at",
        "get_full_info",
    )
    fieldsets = (
        ("Like Information", {
            "fields": ("answer", "user", "get_full_info"),
            "classes": ("wide", "extrapretty"),
        }),
        ("Metadata", {
            "fields": ("created_at",),
            "classes": ("collapse",),
        }),
    )
    list_per_page = 50
    ordering = ("-created_at",)

    def get_answer_preview(self, obj):
        preview = obj.answer.text[:50] + \
            "..." if len(obj.answer.text) > 50 else obj.answer.text
        return format_html(
            '<span style="color: #2c3e50; font-size: 13px;">💬 {}</span>',
            preview
        )
    get_answer_preview.short_description = "Answer"

    def get_user_display(self, obj):
        return format_html(
            '<span style="color: #e74c3c; font-weight: bold;">❤️ {}</span>',
            obj.user.username
        )
    get_user_display.short_description = "Liked by"

    def get_full_info(self, obj):
        return format_html(
            '<div style="background-color: #ecf0f1; padding: 10px; border-radius: 5px;"><strong>Answer:</strong> {}<br><strong>Question:</strong> {}<br><strong>Liked by:</strong> {}<br><strong>Liked at:</strong> {}</div>',
            obj.answer.text[:100] + "...",
            obj.answer.question.title[:50] + "...",
            obj.user.username,
            obj.created_at.strftime("%Y-%m-%d %H:%M:%S")
        )
    get_full_info.short_description = "Full Information"
