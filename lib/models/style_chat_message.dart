import 'style_assistant_result.dart';

enum StyleChatRole { user, assistant }

class StyleChatMessage {
  final String id;
  final StyleChatRole role;
  final String text;
  final DateTime createdAt;
  final StyleAssistantResult? assistantResult;

  const StyleChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.assistantResult,
  });

  bool get isUser {
    return role == StyleChatRole.user;
  }

  bool get isAssistant {
    return role == StyleChatRole.assistant;
  }

  factory StyleChatMessage.user({required String id, required String text}) {
    return StyleChatMessage(
      id: id,
      role: StyleChatRole.user,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  factory StyleChatMessage.assistant({
    required String id,
    required String text,
    StyleAssistantResult? result,
  }) {
    return StyleChatMessage(
      id: id,
      role: StyleChatRole.assistant,
      text: text,
      createdAt: DateTime.now(),
      assistantResult: result,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "role": role.name,
      "text": text,
      "createdAt": createdAt.toIso8601String(),
      "assistantResult": assistantResult?.toMap(),
    };
  }

  factory StyleChatMessage.fromMap(Map<String, dynamic> map) {
    final roleText = map["role"]?.toString();

    final rawAssistantResult = map["assistantResult"];

    StyleAssistantResult? assistantResult;

    if (rawAssistantResult is Map) {
      assistantResult = StyleAssistantResult.fromMap(
        Map<String, dynamic>.from(rawAssistantResult),
      );
    }

    return StyleChatMessage(
      id: map["id"]?.toString() ?? "",
      role: roleText == StyleChatRole.user.name
          ? StyleChatRole.user
          : StyleChatRole.assistant,
      text: map["text"]?.toString() ?? "",
      createdAt:
          DateTime.tryParse(map["createdAt"]?.toString() ?? "") ??
          DateTime.now(),
      assistantResult: assistantResult,
    );
  }
}
