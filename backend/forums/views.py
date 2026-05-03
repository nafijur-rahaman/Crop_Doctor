from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from django.shortcuts import get_object_or_404

from .models import Question, Answer, AnswerLike
from .serializers import QuestionSerializer, AnswerSerializer
from users.permissions import IsPremiumAccess


class QuestionAPIView(APIView):
    permission_classes = [IsAuthenticated, IsPremiumAccess]
    
    def get(self, request, pk=None):
        if pk:
            question = get_object_or_404(Question, pk=pk)
            serializer = QuestionSerializer(question)
            return Response({
                "success": True,
                "question": serializer.data
            }, status=status.HTTP_200_OK)
        else:
            questions = Question.objects.filter(user=request.user)
            serializer = QuestionSerializer(questions, many=True)
            return Response({
                "success": True,
                "questions": serializer.data
            }, status=status.HTTP_200_OK)



    def post(self, request):

        data = request.data.copy()
        data["user"] = request.user.id

        serializer = QuestionSerializer(data=data)

        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def put(self, request, pk):
        question = Question.objects.get(id=pk)
        serializer = QuestionSerializer(question, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, pk):

        question = get_object_or_404(Question, pk=pk)

        if question.user != request.user and request.user.role != "superadmin":
            return Response({
                "success": False,
                "message": "not allowed"
            }, status=status.HTTP_403_FORBIDDEN)

        question.delete()
        return Response({
            "success": True,
            "message": "Question deleted successfully"
        }, status=status.HTTP_200_OK)


class AnswerAPIView(APIView):
    permission_classes = [IsAuthenticated, IsPremiumAccess]
    
    
    def get(self, request, pk=None):
        if pk:
            answer = get_object_or_404(Answer, pk=pk)
            serializer = AnswerSerializer(answer)
            return Response({
                "success": True,
                "answer": serializer.data
            }, status=status.HTTP_200_OK)
        else:
            answers = Answer.objects.filter(user=request.user)
            serializer = AnswerSerializer(answers, many=True)
            return Response({
                "success": True,
                "answers": serializer.data
            }, status=status.HTTP_200_OK)


    def post(self, request):

        serializer = AnswerSerializer(data=request.data)

        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def put(self, request, pk):
        answer = get_object_or_404(Answer, pk=pk)
        if answer.user != request.user and request.user.role != "superadmin":
            return Response({"error": "not allowed"}, status=status.HTTP_403_FORBIDDEN)
        serializer = AnswerSerializer(
            answer, data=request.data, partial=True, context={"request": request}
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, pk):
        answer = get_object_or_404(Answer, pk=pk)
        if answer.user != request.user and request.user.role != "superadmin":
            return Response({"error": "not allowed"}, status=status.HTTP_403_FORBIDDEN)
        answer.delete()
        return Response({
            "success": True,
            "message": "Answer deleted successfully"
        }, status=status.HTTP_200_OK)


class ToggleLikeAPIView(APIView):
    permission_classes = [IsAuthenticated, IsPremiumAccess]

    def post(self, request, pk):

        answer = get_object_or_404(Answer, pk=pk)
        if answer.user == request.user:
            return Response({"error": "not allowed"}, status=status.HTTP_403_FORBIDDEN)

        obj, created = AnswerLike.objects.get_or_create(
            user=request.user,
            answer=answer
        )

        if not created:
            # unlike
            obj.delete()
            answer.likes_count -= 1
            answer.save()
            return Response({"message": "unliked"})

        # like
        answer.likes_count += 1
        answer.save()

        return Response({"message": "liked"})