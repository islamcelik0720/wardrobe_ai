import 'package:cloud_firestore/cloud_firestore.dart';

import 'style_chat_message.dart';

class StyleChatSession {
  final String id;
  final String uid;
  final String title;
  final List<StyleChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StyleChatSession({
    required this.id,
    required this.uid,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'messages': messages.map((message) => message.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory StyleChatSession.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final rawMessages = map['messages'];

    return StyleChatSession(
      id: documentId,
      uid: map['uid']?.toString() ?? '',
      title: map['title']?.toString().trim() ?? 'Stil Sohbeti',
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map>()
                .map(
                  (item) =>
                      StyleChatMessage.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : [],
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}
