import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_routes.dart';
import '../core/design_system.dart';
import '../providers/app_provider.dart';
import '../models/assessment_result_model.dart';
import '../models/question_model.dart';

class PreTestScreen extends StatefulWidget {
  const PreTestScreen({super.key});

  @override
  State<PreTestScreen> createState() => _PreTestScreenState();
}

class _PreTestScreenState extends State<PreTestScreen> {
  List<QuestionModel> _questions = [];
  final Map<String, int> _answers = {};
  int _currentIndex = 0;
  bool _loading = true;
  bool _showResults = false;
  AssessmentResultModel? _result;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final ds = context.read<AppProvider>().dataSource;
    _questions = await ds.getPreTestQuestions();
    setState(() => _loading = false);
  }

  void _submit() {
    if (_questions.isEmpty || _answers.length < _questions.length) return;

    final provider = context.read<AppProvider>();
    final domainScores = <String, int>{};
    final domainTotals = <String, int>{};
    final responses = <QuestionResponse>[];

    for (final q in _questions) {
      domainTotals[q.domain] = (domainTotals[q.domain] ?? 0) + 1;
      final sel = _answers[q.id] ?? -1;
      final correct = sel == q.correctIndex;
      if (correct) {
        domainScores[q.domain] = (domainScores[q.domain] ?? 0) + 1;
      }
      responses.add(QuestionResponse(
        questionId: q.id,
        selectedIndex: sel,
        isCorrect: correct,
      ));
    }

    final totalCorrect = responses.where((r) => r.isCorrect).length;
    _result = AssessmentResultModel(
      id: 'pre_${provider.user!.id}',
      userId: provider.user!.id,
      type: 'pre_test',
      domainScores: domainScores,
      domainTotals: domainTotals,
      totalCorrect: totalCorrect,
      totalQuestions: _questions.length,
      completedAt: DateTime.now(),
      responses: responses,
    );

    provider.completePreTest(_result!);
    setState(() => _showResults = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pre-Test')),
        body: const Center(
          child: Text('No questions loaded. Please ensure seed data is present.'),
        ),
      );
    }

    if (_showResults && _result != null) {
      return _buildResults();
    }

    final q = _questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Pre-Test (${_currentIndex + 1}/${_questions.length})'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: DesignSystem.maxContentWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  q.text,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                ...List.generate(q.options.length, (i) {
                  final selected = _answers[q.id] == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        title: Text(q.options[i], style: const TextStyle(fontSize: 18)),
                        onTap: () => setState(() => _answers[q.id] = i),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      TextButton(
                        onPressed: () => setState(() => _currentIndex--),
                        child: const Text('Back'),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < _questions.length - 1) {
                          setState(() => _currentIndex++);
                        } else {
                          _submit();
                        }
                      },
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? 'Next'
                            : 'Submit',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Test Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignSystem.maxContentWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your score: ${_result!.totalCorrect}/${_result!.totalQuestions} '
                      '(${(_result!.overallScore * 100).round()}%)',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Feedback: Correct answers are shown below.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ..._questions.map((q) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            'Correct answer: ${q.options[q.correctIndex]}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (q.explanation != null) ...[
                            const SizedBox(height: 8),
                            Text(q.explanation!),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.dashboard,
                  ),
                  child: const Text('Continue to Learning'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
