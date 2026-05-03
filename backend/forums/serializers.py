from rest_framework import serializers
from .models import Question, Answer, AnswerLike



class AnswerSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField()

    class Meta:
        model = Answer
        fields = [
            "id",
            "user",
            "text",
            "is_expert",
            "is_ai",
            "likes_count",
            "created_at",
        ]



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