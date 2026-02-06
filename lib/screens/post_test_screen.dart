import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_routes.dart';
import '../core/constants.dart';
import '../core/design_system.dart';
import '../providers/app_provider.dart';
import '../services/adaptive_learning_service.dart';
import '../models/assessment_result_model.dart';
import '../models/question_model.dart';

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
  /// When non-null, post-test is locked until this date (or null = no pre-test done).
  DateTime? _lockedUntil;
  /// Specific message when locked (so we can show what's lacking).
  String _lockedMessage = 'Complete the pre-test first to unlock the post-test.';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final provider = context.read<AppProvider>();
    debugPrint('[PostTest] _loadQuestions: opening, user=${provider.user != null ? provider.user!.id : "null"}');
    // Always refresh from DB when opening so we have latest pre-test result and module progress
    if (provider.user != null) {
      await provider.refreshForPostTest();
    }
    final preResult = provider.preTestResult;
    if (preResult == null) {
      debugPrint('[PostTest] _loadQuestions: LOCKED - preTestResult is null (show "Complete the pre-test first")');
      if (!mounted) return;
      setState(() {
        _questions = [];
        _lockedUntil = null;
        _lockedMessage = 'Complete the pre-test first to unlock the post-test.';
        _loading = false;
      });
      return;
    }
    debugPrint('[PostTest] _loadQuestions: preTest loaded, completedAt=${preResult.completedAt}');
    if (provider.hasCompletedPostTest && provider.postTestResult != null) {
      debugPrint('[PostTest] _loadQuestions: already completed post-test, loading question details for results');
      _result = provider.postTestResult;
      final result = _result!;
      final responseIds = result.responses.map((r) => r.questionId).toSet();
      final allPost = await provider.dataSource.getPostTestQuestions();
      _questions = allPost.where((q) => responseIds.contains(q.id)).toList();
      _questions.sort((a, b) {
        final i = result.responses.indexWhere((r) => r.questionId == a.id);
        final j = result.responses.indexWhere((r) => r.questionId == b.id);
        return i.compareTo(j);
      });
      if (!mounted) return;
      setState(() {
        _showResults = true;
        _loading = false;
      });
      return;
    }
    final canAccess = provider.canAccessPostTest;
    debugPrint('[PostTest] _loadQuestions: canAccessPostTest=$canAccess');
    if (!canAccess) {
      if (!mounted) return;
      final assignedIds = provider.assignedModules.map((m) => m.id).toList();
      final allAssignedCompleted = assignedIds.every(
        (id) => provider.completedModuleIds.contains(id),
      );
      final daysSince = DateTime.now().difference(preResult.completedAt).inDays;
      debugPrint('[PostTest] _loadQuestions: LOCKED - assignedIds=$assignedIds completed=${provider.completedModuleIds} allAssignedCompleted=$allAssignedCompleted daysSincePreTest=$daysSince (min=${AppConstants.postTestMinDays} max=${AppConstants.postTestMaxDays})');
      String message;
      DateTime? until;
      if (!allAssignedCompleted) {
        message = 'Complete all your assigned modules to unlock the post-test.';
        debugPrint('[PostTest] _loadQuestions: reason=modules not all completed');
      } else if (daysSince < AppConstants.postTestMinDays) {
        until = preResult.completedAt
            .add(const Duration(days: AppConstants.postTestMinDays));
        message = 'Post-test opens on ${_formatDate(until)}. '
            'Complete your learning to unlock.';
        debugPrint('[PostTest] _loadQuestions: reason=too early (need $daysSince >= ${AppConstants.postTestMinDays} days)');
      } else if (daysSince > AppConstants.postTestMaxDays) {
        message = 'The post-test window has ended.';
        debugPrint('[PostTest] _loadQuestions: reason=window ended ($daysSince > ${AppConstants.postTestMaxDays})');
      } else {
        message = 'Complete your learning to unlock the post-test.';
        debugPrint('[PostTest] _loadQuestions: reason=fallback');
      }
      setState(() {
        _questions = [];
        _lockedUntil = until ?? _lockedUntil;
        _lockedMessage = message;
        _loading = false;
      });
      return;
    }
    debugPrint('[PostTest] _loadQuestions: UNLOCKED - loading post-test questions');
    final preResponses = preResult.responses;
    final preQuestionIds = preResponses.map((r) => r.questionId).toSet();
    debugPrint('[PostTest] _loadQuestions: preTest response questionIds=$preQuestionIds');
    final allPost = await provider.dataSource.getPostTestQuestions();
    debugPrint('[PostTest] _loadQuestions: allPostTestQuestions from DB=${allPost.length}');
    _questions = AdaptiveLearningService.getPostTestQuestions(
      preResponses,
      allPost,
    );
    debugPrint('[PostTest] _loadQuestions: filtered post-test questions=${_questions.length}');
    if (!mounted) return;
    if (_questions.isEmpty) {
      setState(() {
        _lockedMessage = 'No post-test questions available yet. Post-test questions must be added for your pre-test set.';
        _loading = false;
      });
      return;
    }
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
      final isPreTestLocked = _lockedMessage == 'Complete the pre-test first to unlock the post-test.';
      return Scaffold(
        appBar: AppBar(
          title: const Text('Post-Test'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _lockedMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: DesignSystem.textBody,
                  ),
                ),
                if (isPreTestLocked) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      setState(() => _loading = true);
                      await _loadQuestions();
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (_showResults && _result != null) {
      return _buildResults();
    }

    final q = _questions[_currentIndex];
    final progress = _questions.isEmpty ? 0.0 : (_currentIndex + 1) / _questions.length;
    final hasSelection = _answers[q.id] != null;
    const horizontalPadding = 16.0;
    const progressBarHeight = 4.0;
    const spacingProgressToQuestion = 24.0;
    const spacingQuestionToOptions = 16.0;
    const spacingOptionsToButtons = 32.0;
    const optionMinHeight = 48.0;
    const optionPadding = 16.0;
    const optionRadius = 12.0;
    const optionSpacing = 12.0;
    const buttonHeight = 48.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post-Test',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: DesignSystem.textTitle,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: DesignSystem.bgMain,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: progressBarHeight,
                backgroundColor: DesignSystem.border,
                valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.primary),
              ),
            ),
          ),
          const SizedBox(height: spacingProgressToQuestion),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: DesignSystem.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DesignSystem.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 27 / 18,
                        color: DesignSystem.textTitle,
                      ),
                    ),
                    const SizedBox(height: spacingQuestionToOptions),
                    ...List.generate(q.options.length, (i) {
                      final selected = _answers[q.id] == i;
                      return Padding(
                        padding: EdgeInsets.only(bottom: i < q.options.length - 1 ? optionSpacing : 0),
                        child: Material(
                          color: selected ? DesignSystem.primarySoft : DesignSystem.bgMain,
                          borderRadius: BorderRadius.circular(optionRadius),
                          child: InkWell(
                            onTap: () => setState(() => _answers[q.id] = i),
                            borderRadius: BorderRadius.circular(optionRadius),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: optionMinHeight),
                              padding: const EdgeInsets.all(optionPadding),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(optionRadius),
                                border: Border.all(
                                  color: selected ? DesignSystem.primary : DesignSystem.border,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      q.options[i],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selected ? DesignSystem.textTitle : DesignSystem.textBody,
                                        fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(Icons.check_circle, color: DesignSystem.primary, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: spacingOptionsToButtons),
                    Row(
                      children: [
                        if (_currentIndex > 0)
                          TextButton(
                            onPressed: () => setState(() => _currentIndex--),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, buttonHeight),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Back'),
                          )
                        else
                          const SizedBox.shrink(),
                        const Spacer(),
                        SizedBox(
                          height: buttonHeight,
                          child: FilledButton(
                            onPressed: hasSelection
                                ? () {
                                    if (_currentIndex < _questions.length - 1) {
                                      setState(() => _currentIndex++);
                                    } else {
                                      _submit();
                                    }
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: DesignSystem.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: DesignSystem.primaryDisabled,
                            ),
                            child: Text(
                              _currentIndex < _questions.length - 1 ? 'Next' : 'Submit',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildResults() {
    final meetsBenchmark = AdaptiveLearningService.meetsCertificateBenchmark(
      _result!,
    );
    const horizontalPadding = 16.0;
    const spacingSummaryToContent = 12.0;
    const spacingIntroToCards = 16.0;
    const spacingCardToCard = 12.0;
    const spacingCardsToCta = 32.0;
    const bottomPadding = 28.0;
    const ctaHeight = 48.0;
    const ctaRadius = 12.0;
    final responseByQuestionId = {
      for (final r in _result!.responses) r.questionId: r,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post-Test Results',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: DesignSystem.textTitle,
          ),
        ),
        centerTitle: true,
        backgroundColor: DesignSystem.bgMain,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, bottomPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_result!.totalCorrect}/${_result!.totalQuestions} (${(_result!.overallScore * 100).round()}%)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: DesignSystem.textTitle,
              ),
            ),
            const SizedBox(height: spacingSummaryToContent),
            const Text(
              'This helps us understand what to focus on as you start learning.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: DesignSystem.textBody,
              ),
            ),
            if (_questions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "You'll see explanations for each question below.",
                style: TextStyle(
                  fontSize: 14,
                  color: DesignSystem.textMuted,
                ),
              ),
              const SizedBox(height: spacingIntroToCards),
              ..._questions.map((q) {
                final response = responseByQuestionId[q.id];
                final isCorrect = response?.isCorrect ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: spacingCardToCard),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignSystem.bgSection,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DesignSystem.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DesignSystem.textTitle,
                          ),
                        ),
                        if (response != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Your answer: ${response.selectedIndex >= 0 && response.selectedIndex < q.options.length ? q.options[response.selectedIndex] : "—"}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Correct answer: ${q.options[q.correctIndex]}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            q.explanation!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: DesignSystem.textBody,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: spacingCardsToCta),
            ],
            if (meetsBenchmark) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'Congratulations! You met the benchmark for certification.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: spacingSummaryToContent),
            if (meetsBenchmark) ...[
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.certificate,
                ),
                child: const Text(
                  'View certificate',
                  style: TextStyle(
                    fontSize: 14,
                    color: DesignSystem.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: ctaHeight,
              child: FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.feedback,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignSystem.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ctaRadius),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Continue to Learning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
