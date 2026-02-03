import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_routes.dart';
import '../core/design_system.dart';
import '../providers/app_provider.dart';
import '../services/adaptive_learning_service.dart';
import '../models/assessment_result_model.dart';
import '../models/question_model.dart';
import '../services/certificate_service.dart';

class PostTestScreen extends StatefulWidget {
  const PostTestScreen({super.key});

  @override
  State<PostTestScreen> createState() => _PostTestScreenState();
}

class _PostTestScreenState extends State<PostTestScreen> {
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
    final provider = context.read<AppProvider>();
    final preResponses = provider.preTestResult!.responses;
    final allPost = await provider.dataSource.getPostTestQuestions();
    _questions = AdaptiveLearningService.getPostTestQuestions(
      preResponses,
      allPost,
    );
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
      id: 'post_${provider.user!.id}',
      userId: provider.user!.id,
      type: 'post_test',
      domainScores: domainScores,
      domainTotals: domainTotals,
      totalCorrect: totalCorrect,
      totalQuestions: _questions.length,
      completedAt: DateTime.now(),
      responses: responses,
    );

    provider.completePostTest(_result!);
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
        appBar: AppBar(
          title: const Text('Post-Test'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Text('No post-test questions available.'),
        ),
      );
    }

    if (_showResults && _result != null) {
      return _buildResults();
    }

    final q = _questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Post-Test (${_currentIndex + 1}/${_questions.length})'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
            const Spacer(),
            Row(
              children: [
                if (_currentIndex > 0)
                  TextButton(
                    onPressed: () => setState(() => _currentIndex--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_currentIndex < _questions.length - 1) {
                      setState(() => _currentIndex++);
                    } else {
                      _submit();
                    }
                  },
                  child: Text(
                    _currentIndex < _questions.length - 1 ? 'Next' : 'Submit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final provider = context.read<AppProvider>();
    final meetsBenchmark = AdaptiveLearningService.meetsCertificateBenchmark(
      _result!,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post-Test Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignSystem.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
              'Your score: ${_result!.totalCorrect}/${_result!.totalQuestions} '
              '(${(_result!.overallScore * 100).round()}%)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            if (meetsBenchmark)
              Card(
                color: Colors.green.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Congratulations! You met the benchmark for certification.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.feedback,
              ),
              child: const Text('Complete Feedback Survey'),
            ),
            if (meetsBenchmark) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final pdf = await CertificateService.generateCertificate(
                    user: provider.user!,
                    postTestResult: _result!,
                    completionDate: _result!.completedAt,
                  );
                  await CertificateService.printCertificate(pdf);
                },
                icon: const Icon(Icons.print),
                label: const Text('Print Certificate'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.certificate,
                ),
                child: const Text('View Certificate'),
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
