import 'package:flutter/material.dart';
import 'design_system.dart';

/// Milestone / celebration greeting types shown after key actions.
enum GreetingType {
  moduleComplete,
  allModulesComplete,
  preTestComplete,
  postTestComplete,
  certificateEarned,
}

extension GreetingTypeExtension on GreetingType {
  String get title {
    switch (this) {
      case GreetingType.moduleComplete:
        return 'Module completed!';
      case GreetingType.allModulesComplete:
        return 'All modules done!';
      case GreetingType.preTestComplete:
        return 'Pre-test completed!';
      case GreetingType.postTestComplete:
        return 'Post-test completed!';
      case GreetingType.certificateEarned:
        return 'Certificate earned!';
    }
  }

  String get message {
    switch (this) {
      case GreetingType.moduleComplete:
        return 'Great progress. Continue to the next module or head back to your dashboard.';
      case GreetingType.allModulesComplete:
        return 'You\'ve finished all assigned modules. The post-test is now unlocked—take it when you\'re ready.';
      case GreetingType.preTestComplete:
        return 'Your learning path is set. Start with your assigned modules.';
      case GreetingType.postTestComplete:
        return 'You\'ve completed the assessment. View your results or continue to feedback.';
      case GreetingType.certificateEarned:
        return 'You met the benchmark. Download or share your certificate.';
    }
  }

  IconData get icon {
    switch (this) {
      case GreetingType.moduleComplete:
        return Icons.check_circle_outline;
      case GreetingType.allModulesComplete:
        return Icons.emoji_events_outlined;
      case GreetingType.preTestComplete:
        return Icons.school_outlined;
      case GreetingType.postTestComplete:
        return Icons.assignment_turned_in_outlined;
      case GreetingType.certificateEarned:
        return Icons.card_membership_outlined;
    }
  }

  Color get accentColor {
    switch (this) {
      case GreetingType.moduleComplete:
        return DesignSystem.primary;
      case GreetingType.allModulesComplete:
        return DesignSystem.success;
      case GreetingType.preTestComplete:
        return DesignSystem.primary;
      case GreetingType.postTestComplete:
        return DesignSystem.success;
      case GreetingType.certificateEarned:
        return DesignSystem.warning;
    }
  }
}
