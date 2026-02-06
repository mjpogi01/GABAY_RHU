import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _showInstructions = true;
  bool _showResults = false;
  AssessmentResultModel? _result;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final provider = context.read<AppProvider>();
    final ds = provider.dataSource;
    _questions = await ds.getPreTestQuestions();
    if (!mounted) return;
    if (provider.hasCompletedPreTest && provider.preTestResult != null) {
      _result = provider.preTestResult;
      _showInstructions = false;
      _showResults = true;
    }
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
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

    await provider.completePreTest(_result!);
    if (!mounted) return;
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

    if (_showInstructions) {
      return _buildInstructions();
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
          'Pre-Test',
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

  Widget _buildInstructions() {
    const double appBarTitleSize = 19;
    const double instructionHeaderSize = 16;
    const double bodyFontSize = 15;
    const double bodyLineHeight = 23;
    const double buttonHeight = 48;
    const double cardRadius = 12;
    const double horizontalPadding = 16;
    const double spacingAppBarToTitle = 24;
    const double spacingTitleToCard = 24;
    const double spacingCardToButton = 32;
    const double spacingBottom = 32;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pre-Test',
          style: TextStyle(
            fontSize: appBarTitleSize,
            fontWeight: FontWeight.w600,
            color: DesignSystem.textTitle,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: DesignSystem.bgMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: DesignSystem.border,
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              horizontalPadding,
              spacingAppBarToTitle,
              horizontalPadding,
              spacingBottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This helps personalize your learning',
                  style: TextStyle(
                    fontSize: 14,
                    color: DesignSystem.textMuted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: spacingTitleToCard),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignSystem.bgSection,
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(color: DesignSystem.border, width: 1),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: instructionHeaderSize,
                          fontWeight: FontWeight.w600,
                          color: DesignSystem.textTitle,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Please answer the following questions based on what you currently know.',
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          height: bodyLineHeight / bodyFontSize,
                          color: DesignSystem.textBody,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Select one answer per question. You can go back to change answers before submitting.',
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          height: bodyLineHeight / bodyFontSize,
                          color: DesignSystem.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: spacingCardToButton),
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: FilledButton(
                    onPressed: () => setState(() => _showInstructions = false),
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignSystem.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(cardRadius),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Start Pre-Test'),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Takes about 3–5 minutes',
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignSystem.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    const horizontalPadding = 16.0;
    const spacingSummaryToIntro = 12.0;
    const spacingIntroToCards = 16.0;
    const spacingCardToCard = 12.0;
    const spacingCardsToCta = 32.0;
    const bottomPadding = 28.0;
    const ctaHeight = 48.0;
    const ctaRadius = 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pre-Test Results',
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
            const SizedBox(height: spacingSummaryToIntro),
            const Text(
              'This helps us understand what to focus on as you start learning.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: DesignSystem.textBody,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You'll see explanations for each question below.",
              style: TextStyle(
                fontSize: 14,
                color: DesignSystem.textMuted,
              ),
            ),
            const SizedBox(height: spacingIntroToCards),
            ..._questions.asMap().entries.map((entry) {
              final q = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key < _questions.length - 1 ? spacingCardToCard : 0),
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
                      const SizedBox(height: 8),
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
            SizedBox(
              width: double.infinity,
              height: ctaHeight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
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
