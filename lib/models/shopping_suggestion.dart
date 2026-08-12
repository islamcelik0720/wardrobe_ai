class ShoppingSuggestion {
  final String title;
  final String reason;
  final String category;
  final String suggestedColor;
  final String priority;
  final bool actuallyNeeded;

  const ShoppingSuggestion({
    required this.title,
    required this.reason,
    required this.category,
    required this.suggestedColor,
    required this.priority,
    required this.actuallyNeeded,
  });

  factory ShoppingSuggestion.fromMap(Map<String, dynamic> map) {
    return ShoppingSuggestion(
      title: map['title']?.toString().trim() ?? '',
      reason: map['reason']?.toString().trim() ?? '',
      category: map['category']?.toString().trim() ?? '',
      suggestedColor: map['suggestedColor']?.toString().trim() ?? '',
      priority: map['priority']?.toString().trim() ?? 'low',
      actuallyNeeded: map['actuallyNeeded'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'reason': reason,
      'category': category,
      'suggestedColor': suggestedColor,
      'priority': priority,
      'actuallyNeeded': actuallyNeeded,
    };
  }
}
