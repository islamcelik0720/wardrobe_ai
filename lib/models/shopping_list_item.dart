import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListItem {
  final String id;
  final String uid;
  final String title;
  final String category;
  final String suggestedColor;
  final String reason;
  final String priority;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingListItem({
    required this.id,
    required this.uid,
    required this.title,
    required this.category,
    required this.suggestedColor,
    required this.reason,
    required this.priority,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'category': category,
      'suggestedColor': suggestedColor,
      'reason': reason,
      'priority': priority,
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ShoppingListItem.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ShoppingListItem(
      id: documentId,
      uid: map['uid']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      suggestedColor: map['suggestedColor']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      priority: map['priority']?.toString() ?? 'low',
      completed: map['completed'] == true,
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
