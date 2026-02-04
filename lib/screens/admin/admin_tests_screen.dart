import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system.dart';
import '../../providers/app_provider.dart';
import '../../models/question_model.dart';

/// Admin Tests: Pre-Test and Post-Test cards; tap opens question list + edit.
class AdminTestsScreen extends StatefulWidget {
  const AdminTestsScreen({super.key});

  @override
  State<AdminTestsScreen> createState() => _AdminTestsScreenState();
}

class _AdminTestsScreenState extends State<AdminTestsScreen> {
  String? _selectedTest; // 'pre_test' | 'post_test'

  @override
  Widget build(BuildContext context) {
    if (_selectedTest != null) {
      return _TestQuestionsScreen(
        type: _selectedTest!,
        onBack: () => setState(() => _selectedTest = null),
      );
    }

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: DesignSystem.s(context, 12)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tests',
              style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textPrimary, fontSize: DesignSystem.appTitleSize(context)),
            ),
          ),
        ),
        backgroundColor: DesignSystem.cardSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(DesignSystem.adminContentPadding(context) * 1.2),
        child: Column(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedTest = 'pre_test'),
                borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context)),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context))),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_outlined, size: DesignSystem.wRatio(context, 56 / 375), color: DesignSystem.primary),
                        SizedBox(height: DesignSystem.adminGridGap(context)),
                        Text(
                          'Pre-Test',
                          style: TextStyle(
                            fontSize: DesignSystem.sectionTitleSize(context),
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: DesignSystem.adminSectionGap(context)),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedTest = 'post_test'),
                borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context)),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context))),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: DesignSystem.wRatio(context, 56 / 375), color: DesignSystem.primary),
                        SizedBox(height: DesignSystem.adminGridGap(context)),
                        Text(
                          'Post-Test',
                          style: TextStyle(
                            fontSize: DesignSystem.sectionTitleSize(context),
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestQuestionsScreen extends StatelessWidget {
  final String type;
  final VoidCallback onBack;

  const _TestQuestionsScreen({required this.type, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isPre = type == 'pre_test';
    final title = isPre ? 'Pre-Test' : 'Post-Test';

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textPrimary)),
        backgroundColor: DesignSystem.cardSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
            child: TextField(
              style: TextStyle(fontSize: DesignSystem.captionSize(context)),
              decoration: InputDecoration(
                hintText: 'Search question no. or keywords.',
                hintStyle: TextStyle(fontSize: DesignSystem.captionSize(context), color: DesignSystem.textMuted),
                prefixIcon: const Icon(Icons.search, color: DesignSystem.textMuted),
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _InstructionsCard(onEdit: () {}),
          Expanded(
            child: FutureBuilder<List<QuestionModel>>(
              future: isPre
                  ? context.read<AppProvider>().dataSource.getPreTestQuestions()
                  : context.read<AppProvider>().dataSource.getPostTestQuestions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return Center(child: Text('No questions', style: TextStyle(color: DesignSystem.textSecondary)));
                }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: DesignSystem.adminContentPadding(context)),
          itemCount: list.length,
                  itemBuilder: (_, i) {
                    final q = list[i];
                    return _QuestionCard(
                      index: i + 1,
                      question: q,
                      onEdit: () => _showQuestionModal(context, q),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showQuestionModal(BuildContext context, QuestionModel q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionEditSheet(
        question: q,
        onSave: () => Navigator.pop(ctx),
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final VoidCallback onEdit;

  const _InstructionsCard({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignSystem.adminContentPadding(context), vertical: DesignSystem.adminGridGap(context) * 0.7),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context))),
        child: Padding(
          padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textPrimary)),
                  TextButton(onPressed: onEdit, child: const Text('Edit')),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Please answer the following questions based on what you currently know. This helps us tailor learning content for you.',
                style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), color: DesignSystem.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuestionModel question;
  final VoidCallback onEdit;

  const _QuestionCard({required this.index, required this.question, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = question.correctIndex;
    final selectedOption = question.options.isNotEmpty && selectedIndex < question.options.length
        ? question.options[selectedIndex]
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: DesignSystem.adminGridGap(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context))),
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question $index', style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textPrimary)),
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
            Text(question.text, style: TextStyle(color: DesignSystem.textPrimary)),
            SizedBox(height: DesignSystem.adminGridGap(context)),
            ...question.options.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('${String.fromCharCode(65 + e.key)}. ', style: TextStyle(color: DesignSystem.textSecondary)),
                      Expanded(child: Text(e.value, style: TextStyle(color: DesignSystem.textPrimary))),
                    ],
                  ),
                )),
            if (selectedOption != null) ...[
              SizedBox(height: DesignSystem.adminGridGap(context)),
              Text('Answer: ${String.fromCharCode(65 + selectedIndex)}', style: TextStyle(fontSize: 12, color: DesignSystem.textSecondary)),
              Text('Reference: ${question.domain}', style: TextStyle(fontSize: 12, color: DesignSystem.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionEditSheet extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback onSave;

  const _QuestionEditSheet({required this.question, required this.onSave});

  @override
  State<_QuestionEditSheet> createState() => _QuestionEditSheetState();
}

class _QuestionEditSheetState extends State<_QuestionEditSheet> {
  late TextEditingController _textController;
  late List<TextEditingController> _optionControllers;
  int _selectedCorrectIndex = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question.text);
    _optionControllers = widget.question.options.map((o) => TextEditingController(text: o)).toList();
    if (_optionControllers.isEmpty) _optionControllers.add(TextEditingController());
    _selectedCorrectIndex = widget.question.correctIndex.clamp(0, _optionControllers.length - 1);
  }

  @override
  void dispose() {
    _textController.dispose();
    for (final c in _optionControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: DesignSystem.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            DesignSystem.adminContentPadding(context) * 1.2,
            DesignSystem.s(context, 12),
            DesignSystem.adminContentPadding(context) * 1.2,
            DesignSystem.adminContentPadding(context) * 1.2,
          ),
          children: [
            Center(
              child: Container(
                width: DesignSystem.wRatio(context, 40 / 375),
                height: 4,
                decoration: BoxDecoration(
                  color: DesignSystem.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: DesignSystem.s(context, 12)),
            Text('Question 1', style: TextStyle(fontSize: DesignSystem.sectionTitleSize(context), fontWeight: FontWeight.bold)),
            SizedBox(height: DesignSystem.s(context, 12)),
            const Text('Type: Multiple Choice'),
            SizedBox(height: DesignSystem.adminGridGap(context)),
            Text('Question', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            TextField(
              controller: _textController,
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 16),
            Text('Choices', style: TextStyle(fontWeight: FontWeight.w600)),
            ...List.generate(_optionControllers.length, (i) => RadioListTile<int>(
                  title: TextField(
                    controller: _optionControllers[i],
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: DesignSystem.inputBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  value: i,
                  groupValue: _selectedCorrectIndex,
                  onChanged: (v) => setState(() => _selectedCorrectIndex = v ?? 0),
                )),
            TextButton.icon(
              onPressed: () => setState(() => _optionControllers.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
            SizedBox(height: 12),
            const Text('Reference: Module 1'),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: DesignSystem.buttonHeightScaled(context),
              child: ElevatedButton(
                onPressed: () => widget.onSave(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadiusScaled(context))),
                ),
                child: Text('Save', style: TextStyle(fontSize: DesignSystem.buttonTextSize(context))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
