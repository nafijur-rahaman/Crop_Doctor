from rest_framework import serializers
from .models import Question, Answer, AnswerLike



class AnswerSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    question = serializers.PrimaryKeyRelatedField(queryset=Question.objects.all())

    class Meta:
        model = Answer
        fields = [
            "id",
            "question",
            "user",
            "text",
            "is_expert",
            "is_ai",
            "likes_count",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "is_expert",
            "is_ai",
            "likes_count",
            "created_at",
        ]

    def update(self, instance, validated_data):
        request = self.context.get("request")
        role = getattr(request.user, "role", None) if request and request.user.is_authenticated else None
        if role != "superadmin":
            validated_data.pop("question", None)
        return super().update(instance, validated_data)



class QuestionSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField()
    answers = AnswerSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = [
            "id",
            "user",
            "title",
            "description",
            "crop",
            "image",
            "status",
            "created_at",
            "answers",
        ]