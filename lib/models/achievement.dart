import 'package:flutter/material.dart';

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final int currentValue;
  final int targetValue;

  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.currentValue,
    required this.targetValue,
  });

  double get progress {
    if (targetValue <= 0) {
      return 0;
    }

    return (currentValue / targetValue).clamp(0.0, 1.0);
  }
}
