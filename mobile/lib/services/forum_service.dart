import '../core/constants/api_constants.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';
import 'api_client.dart';

class ForumService {
  /// GET /api/questions/get-all-questions/
  /// Returns the authenticated user's own questions (backend limitation).
  static Future<List<ForumPost>> getMyQuestions() async {
    final data = await ApiClient.get(kGetAllQuestionsUrl);
    final list = data['questions'] as List? ?? [];
    return list
        .map((q) => ForumPost.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/questions/all/ (premium global feed)
  static Future<List<ForumPost>> getAllQuestions() async {
    final data = await ApiClient.get(kGetAllQuestionsGlobalUrl);
    final list = data['questions'] as List? ?? [];
    return list
        .map((q) => ForumPost.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/question/<id>/
  static Future<ForumPost> getQuestion(int id) async {
    final data = await ApiClient.get('$kQuestionBaseUrl$id/');
    final q = (data['question'] as Map<String, dynamic>?) ?? const {};
    return ForumPost.fromJson(q);
  }

  /// POST /api/question/create-question/
  static Future<ForumPost> createQuestion({
    required String title,
    required String crop,
  }) async {
    final data = await ApiClient.post(kCreateQuestionUrl, {
      'title': title,
      'description': title, // mirror title as description
      'crop': crop,
    });
    return ForumPost.fromJson(data);
  }

  /// PUT /api/question/<id>/update-question/
  static Future<ForumPost> updateQuestion({
    required int id,
    required String title,
    required String crop,
    String? description,
  }) async {
    final data = await ApiClient.put(
      '$kQuestionBaseUrl$id/update-question/',
      {
        'title': title,
        'description': description ?? title,
        'crop': crop,
      },
    );
    return ForumPost.fromJson(data);
  }

  /// DELETE /api/question/<id>/delete-question/
  static Future<void> deleteQuestion(int id) async {
    await ApiClient.delete('$kQuestionBaseUrl$id/delete-question/');
  }

  /// POST /api/answer/create-answer/
  static Future<ForumReply> createAnswer({
    required int questionId,
    required String text,
  }) async {
    final data = await ApiClient.post(kCreateAnswerUrl, {
      'question': questionId,
      'text': text,
    });
    return ForumReply.fromJson(data);
  }

  /// PUT /api/answer/<id>/update-answer/
  static Future<ForumReply> updateAnswer({
    required int id,
    required String text,
  }) async {
    final data = await ApiClient.put(
      '$kAnswerBaseUrl$id/update-answer/',
      {'text': text},
    );
    return ForumReply.fromJson(data);
  }

  /// DELETE /api/answer/<id>/delete-answer/
  static Future<void> deleteAnswer(int id) async {
    await ApiClient.delete('$kAnswerBaseUrl$id/delete-answer/');
  }

  /// POST /api/answer/<id>/like/
  static Future<String> toggleLike(int answerId) async {
    final data =
        await ApiClient.post('$kAnswerBaseUrl$answerId/like/', {});
    return (data['message'] as String?) ?? '';
  }
}
