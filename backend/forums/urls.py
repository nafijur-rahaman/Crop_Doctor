from django.urls import path
from .views import QuestionAPIView, AnswerAPIView, ToggleLikeAPIView, AllQuestionsAPIView

urlpatterns = [
    path("questions/get-all-questions/", QuestionAPIView.as_view(), name="get-all-questions"),
    path("questions/all/", AllQuestionsAPIView.as_view(), name="get-all-questions-global"),
    path("question/<int:pk>/", QuestionAPIView.as_view(), name="get-question"),
    path("question/create-question/", QuestionAPIView.as_view(), name="create-question"),
    path("question/<int:pk>/update-question/", QuestionAPIView.as_view(), name="update-question"),
    path("question/<int:pk>/delete-question/", QuestionAPIView.as_view(), name="delete-question"),

    
    path("answers/get-all-answers/", AnswerAPIView.as_view(), name="get-all-answers"),
    path("answer/<int:pk>/", AnswerAPIView.as_view(), name="get-answer"),
    path("answer/create-answer/", AnswerAPIView.as_view(), name="create-answer"),
    path("answer/<int:pk>/update-answer/", AnswerAPIView.as_view(), name="update-answer"),
    path("answer/<int:pk>/delete-answer/", AnswerAPIView.as_view(), name="delete-answer"),
    
    
    path("answer/<int:pk>/like/", ToggleLikeAPIView.as_view(), name="toggle-like"),
]
