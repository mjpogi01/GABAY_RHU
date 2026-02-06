import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/app_routes.dart';
import '../core/greeting_type.dart';

/// Reusable greetings / milestone card for finishing a module, unlocking post-test, etc.
class GreetingsCard extends StatelessWidget {
  final GreetingType type;
  final VoidCallback onDismiss;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  const GreetingsCard({
    super.key,
    required this.type,
    required this.onDismiss,
    this.primaryActionLabel,
    this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final accent = type.accentColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignSystem.screenPaddingH),
      decoration: BoxDecoration(
        color: DesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.icon, size: 28, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: DesignSystem.textTitle,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type.message,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: DesignSystem.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: DesignSystem.textMuted,
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (primaryActionLabel != null && onPrimaryAction != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: DesignSystem.buttonHeight,
              child: FilledButton(
                onPressed: onPrimaryAction,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                  ),
                  textStyle: const TextStyle(
                    fontSize: DesignSystem.buttonTextSizeValue,
                    fontWeight: DesignSystem.buttonTextWeight,
                  ),
                ),
                child: Text(primaryActionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Builds a greeting card with a sensible primary action for the type (e.g. "Take Post-Test", "View Certificate").
Widget buildGreetingsCardWithAction({
  required BuildContext context,
  required GreetingType type,
  required VoidCallback onDismiss,
}) {
  String? label;
  VoidCallback? action;
  switch (type) {
    case GreetingType.moduleComplete:
      label = null;
      action = null;
      break;
    case GreetingType.allModulesComplete:
      label = 'Take Post-Test';
      action = () {
        onDismiss();
        Navigator.pushNamed(context, AppRoutes.postTest);
      };
      break;
    case GreetingType.preTestComplete:
      label = 'Go to Dashboard';
      action = () {
        onDismiss();
        Navigator.popUntil(context, (r) => r.isFirst);
      };
      break;
    case GreetingType.postTestComplete:
      label = 'Continue';
      action = onDismiss;
      break;
    case GreetingType.certificateEarned:
      label = 'View Certificate';
      action = () {
        onDismiss();
        Navigator.pushNamed(context, AppRoutes.certificate);
      };
      break;
  }
  return GreetingsCard(
    type: type,
    onDismiss: onDismiss,
    primaryActionLabel: label,
    onPrimaryAction: action,
  );
}
