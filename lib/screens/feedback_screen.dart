import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../core/design_system.dart';

/// Post-test usability and experience survey
/// Prevents duplicate or incomplete submissions
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _usabilityRating;
  int? _experienceRating;
  final _commentsController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Survey'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignSystem.maxContentWidth),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How would you rate the usability of the app?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final v = i + 1;
                  return ChoiceChip(
                    label: Text('$v'),
                    selected: _usabilityRating == v,
                    onSelected: (sel) =>
                        setState(() => _usabilityRating = sel ? v : null),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Text(
                'How would you rate your learning experience?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final v = i + 1;
                  return ChoiceChip(
                    label: Text('$v'),
                    selected: _experienceRating == v,
                    onSelected: (sel) =>
                        setState(() => _experienceRating = sel ? v : null),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  labelText: 'Additional comments (optional)',
                  hintText: 'Share your thoughts...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit Feedback'),
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_usabilityRating == null || _experienceRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate both usability and experience.'),
        ),
      );
      return;
    }
    // TODO: Save to local DB and sync when online
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }
}
