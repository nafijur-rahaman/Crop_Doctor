import '../core/constants/api_constants.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';
import 'api_client.dart';

class ForumService {
  /// GET /api/questions/get-all-questions/
  /// Returns the authenticated user's own questions (backend limitation).
  static Future<List<ForumPost>> getQuestions() async {
    final data = await ApiClient.get(kGetAllQuestionsUrl);
    final list = data['questions'] as List? ?? [];
    return list
        .map((q) => ForumPost.fromJson(q as Map<String, dynamic>))
        .toList();
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

  /// POST /api/answer/<id>/like/
  static Future<String> toggleLike(int answerId) async {
    final data =
        await ApiClient.post('$kAnswerBaseUrl$answerId/like/', {});
    return (data['message'] as String?) ?? '';
  }
}
