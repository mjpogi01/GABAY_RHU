import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system.dart';
import '../../providers/app_provider.dart';
import '../../models/question_model.dart';
import '../../models/module_model.dart';

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

class _TestQuestionsScreen extends StatefulWidget {
  final String type;
  final VoidCallback onBack;

  const _TestQuestionsScreen({required this.type, required this.onBack});

  @override
  State<_TestQuestionsScreen> createState() => _TestQuestionsScreenState();
}

class _TestQuestionsScreenState extends State<_TestQuestionsScreen> {
  Future<(List<QuestionModel>, List<ModuleModel>)>? _dataFuture;
  int? _expandedQuestionIndex;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    final ds = context.read<AppProvider>().dataSource;
    setState(() {
      _dataFuture = Future(() async {
        final questions = widget.type == 'pre_test'
            ? await ds.getPreTestQuestions()
            : await ds.getPostTestQuestions();
        final modules = await ds.getAllModules();
        return (questions, modules);
      });
    });
  }

  void _showQuestionModal(QuestionModel q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionEditSheet(
        question: q,
        onSave: () {
          Navigator.pop(ctx);
          _loadQuestions();
        },
      ),
    );
  }

  Future<void> _showAddQuestionSheet() async {
    final pre = await context.read<AppProvider>().dataSource.getPreTestQuestions();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddQuestionSheet(
        nextOrderIndex: pre.length,
        onSave: () {
          Navigator.pop(ctx);
          _loadQuestions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPre = widget.type == 'pre_test';
    final title = isPre ? 'Pre-Test' : 'Post-Test';

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textPrimary)),
        backgroundColor: DesignSystem.cardSurface,
        elevation: 0,
        actions: isPre
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddQuestionSheet,
                  tooltip: 'Add question',
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
            child: TextField(
              style: TextStyle(fontSize: DesignSystem.captionSize(context)),
              decoration: InputDecoration(
                hintText: 'Search question no. or keywords.',
                hintStyle: const TextStyle(fontSize: 11, color: DesignSystem.textMuted),
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
          Expanded(
            child: FutureBuilder<(List<QuestionModel>, List<ModuleModel>)>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data;
                final list = data?.$1 ?? [];
                final modules = data?.$2 ?? [];
                final moduleLabel = {for (final m in modules) m.id: (m.moduleNumber ?? m.title)};
                final paddingH = DesignSystem.adminContentPadding(context);
                final isTablet = MediaQuery.sizeOf(context).width >= 600;
                final horizontalPadding = isTablet ? paddingH * 1.5 : paddingH;
                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding).copyWith(bottom: paddingH * 2),
                  children: [
                    if (list.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(paddingH * 2),
                        child: const Center(child: Text('No questions', style: TextStyle(color: DesignSystem.textSecondary))),
                      )
                    else
                      ...list.asMap().entries.map((e) => _QuestionCard(
                        index: e.key + 1,
                        question: e.value,
                        moduleLabel: moduleLabel,
                        expanded: _expandedQuestionIndex == e.key,
                        onTap: () => setState(() {
                          _expandedQuestionIndex = _expandedQuestionIndex == e.key ? null : e.key;
                        }),
                        onEdit: () => _showQuestionModal(e.value),
                      )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible question card: scan-first (number + text + Edit), expand to show choices, correct answer, reference.
class _QuestionCard extends StatelessWidget {
  final int index;
  final QuestionModel question;
  final Map<String, String> moduleLabel;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.moduleLabel,
    required this.expanded,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final correctIndex = question.correctIndex.clamp(0, question.options.length - 1);
    final correctOption = question.options.isNotEmpty && correctIndex < question.options.length
        ? question.options[correctIndex]
        : null;
    final referenceLabel = question.referenceModuleId != null
        ? (moduleLabel[question.referenceModuleId] ?? question.referenceModuleId)
        : question.domain;

    return Card(
      margin: EdgeInsets.only(bottom: DesignSystem.adminGridGap(context)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context)),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      child: Material(
        color: DesignSystem.cardSurface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Question N (left), Edit (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question $index',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: DesignSystem.textMuted,
                        fontSize: DesignSystem.captionSize(context),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, DesignSystem.s(context, -4)),
                      child: IconButton(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined, size: DesignSystem.s(context, 20), color: DesignSystem.primary),
                        style: IconButton.styleFrom(
                          minimumSize: Size(DesignSystem.s(context, 40), DesignSystem.s(context, 40)),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignSystem.s(context, 4)),
                // Question text (primary)
                Text(
                  question.text,
                  style: TextStyle(
                    fontSize: DesignSystem.bodyTextSize(context),
                    fontWeight: FontWeight.w500,
                    color: DesignSystem.textPrimary,
                    height: 1.35,
                  ),
                  maxLines: expanded ? 20 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                // Expanded: choices, correct answer, reference
                if (expanded) ...[
                  SizedBox(height: DesignSystem.adminGridGap(context)),
                  ...question.options.asMap().entries.map((e) {
                    final isCorrect = e.key == correctIndex;
                    return Padding(
                      padding: EdgeInsets.only(bottom: DesignSystem.s(context, 6)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: DesignSystem.s(context, 2)),
                            child: SizedBox(
                              width: DesignSystem.s(context, 18),
                              height: DesignSystem.s(context, 18),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: DesignSystem.textMuted, width: 1.5),
                                  color: isCorrect ? DesignSystem.textMuted : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: DesignSystem.s(context, 8)),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: DesignSystem.captionSize(context) + 1,
                                color: DesignSystem.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: DesignSystem.s(context, 8)),
                  if (correctOption != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: DesignSystem.s(context, 4)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correct answer: ',
                            style: TextStyle(
                              fontSize: DesignSystem.captionSize(context),
                              color: DesignSystem.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              correctOption,
                              style: TextStyle(
                                fontSize: DesignSystem.captionSize(context),
                                color: DesignSystem.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    'Reference: $referenceLabel',
                    style: TextStyle(
                      fontSize: DesignSystem.captionSize(context),
                      color: DesignSystem.textMuted,
                    ),
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
  late TextEditingController _explanationController;
  int _selectedCorrectIndex = 0;
  String? _referenceModuleId;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question.text);
    _optionControllers = widget.question.options.map((o) => TextEditingController(text: o)).toList();
    if (_optionControllers.isEmpty) _optionControllers.add(TextEditingController());
    _explanationController = TextEditingController(text: widget.question.explanation ?? '');
    _selectedCorrectIndex = widget.question.correctIndex.clamp(0, _optionControllers.length - 1);
    _referenceModuleId = widget.question.referenceModuleId;
  }

  @override
  void dispose() {
    _textController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
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
            DesignSystem.adminContentPadding(context) * 1.2 + MediaQuery.of(context).padding.bottom + 8,
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
            Text('Edit question', style: TextStyle(fontSize: DesignSystem.sectionTitleSize(context), fontWeight: FontWeight.bold)),
            SizedBox(height: DesignSystem.adminGridGap(context)),
            Text('Question', style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: _textController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Text('Choices (correct = green border)', style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), fontWeight: FontWeight.w600)),
            ...List.generate(_optionControllers.length, (i) {
              final isCorrect = i == _selectedCorrectIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade50 : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isCorrect ? Border.all(color: Colors.green, width: 2) : null,
                  ),
                  child: RadioListTile<int>(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    title: TextField(
                      controller: _optionControllers[i],
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        filled: true,
                        fillColor: isCorrect ? Colors.green.shade50 : DesignSystem.inputBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      ),
                    ),
                    value: i,
                    groupValue: _selectedCorrectIndex,
                    onChanged: (v) => setState(() => _selectedCorrectIndex = v ?? 0),
                  ),
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _optionControllers.add(TextEditingController())),
              icon: Icon(Icons.add, size: DesignSystem.s(context, 18)),
              label: const Text('Add option', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(height: DesignSystem.adminGridGap(context)),
            Text('Explanation (optional)', style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: _explanationController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Optional explanation',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: DesignSystem.adminGridGap(context)),
            Text('Reference Module', style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            FutureBuilder<List<ModuleModel>>(
              future: context.read<AppProvider>().dataSource.getAllModules(),
              builder: (context, snapshot) {
                final modules = snapshot.data ?? [];
                const dropdownTextStyle = TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: DesignSystem.textPrimary,
                );
                String? selectedLabel;
                if (_referenceModuleId != null && _referenceModuleId!.isNotEmpty) {
                  for (final m in modules) {
                    if (m.id == _referenceModuleId) {
                      selectedLabel = '${m.moduleNumber ?? m.title} – ${m.title}';
                      break;
                    }
                  }
                }
                return InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => _ReferenceModulePickerSheet(
                        modules: modules,
                        currentId: _referenceModuleId,
                        onSelected: (id) => setState(() => _referenceModuleId = id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: DesignSystem.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: DesignSystem.textBody),
                    ),
                    child: Text(
                      selectedLabel ?? 'Select module (optional)',
                      style: selectedLabel != null
                          ? dropdownTextStyle
                          : dropdownTextStyle.copyWith(color: DesignSystem.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: DesignSystem.buttonHeightScaled(context),
              child: ElevatedButton(
                onPressed: () async {
                  final text = _textController.text.trim();
                  final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the question text.')));
                    return;
                  }
                  if (options.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least two choices.')));
                    return;
                  }
                  final modules = await context.read<AppProvider>().dataSource.getAllModules();
                  String domain = widget.question.domain;
                  if (_referenceModuleId != null && _referenceModuleId!.isNotEmpty) {
                    for (final m in modules) {
                      if (m.id == _referenceModuleId) {
                        domain = m.domain;
                        break;
                      }
                    }
                  }
                  final explanationText = _explanationController.text.trim();
                  final correctIndex = _selectedCorrectIndex.clamp(0, options.length - 1);
                  final updated = QuestionModel(
                    id: widget.question.id,
                    pairedId: widget.question.pairedId,
                    domain: domain,
                    text: text,
                    options: options,
                    correctIndex: correctIndex,
                    explanation: explanationText.isEmpty ? null : explanationText,
                    referenceModuleId: _referenceModuleId,
                    orderIndex: widget.question.orderIndex,
                  );
                  try {
                    await context.read<AppProvider>().dataSource.savePreTestQuestion(updated);
                    if (mounted) widget.onSave();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                    }
                  }
                },
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

/// Searchable bottom sheet to pick a reference module.
class _ReferenceModulePickerSheet extends StatefulWidget {
  final List<ModuleModel> modules;
  final String? currentId;
  final ValueChanged<String?> onSelected;

  const _ReferenceModulePickerSheet({
    required this.modules,
    required this.currentId,
    required this.onSelected,
  });

  @override
  State<_ReferenceModulePickerSheet> createState() => _ReferenceModulePickerSheetState();
}

class _ReferenceModulePickerSheetState extends State<_ReferenceModulePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ModuleModel> get _filtered {
    if (_query.isEmpty) return widget.modules;
    return widget.modules.where((m) {
      final num = (m.moduleNumber ?? '').toLowerCase();
      final title = m.title.toLowerCase();
      return num.contains(_query) || title.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: DesignSystem.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search module number or title...',
                  hintStyle: const TextStyle(fontSize: 11, color: DesignSystem.textMuted),
                  prefixIcon: const Icon(Icons.search, size: 20, color: DesignSystem.textMuted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: DesignSystem.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 12, color: DesignSystem.textPrimary),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: DesignSystem.adminContentPadding(context)),
                children: [
                  ListTile(
                    title: const Text('None', style: TextStyle(fontSize: 12, color: DesignSystem.textPrimary)),
                    onTap: () {
                      widget.onSelected(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...filtered.map((m) => ListTile(
                    title: Text(
                      '${m.moduleNumber ?? m.title} – ${m.title}',
                      style: const TextStyle(fontSize: 12, color: DesignSystem.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.onSelected(m.id);
                      Navigator.pop(context);
                    },
                  )),
                  if (filtered.isEmpty && widget.modules.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No modules match "$_query"', style: const TextStyle(fontSize: 12, color: DesignSystem.textMuted))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add new pre-test question: question text, choices, correct answer, reference module.
class _AddQuestionSheet extends StatefulWidget {
  final int nextOrderIndex;
  final VoidCallback onSave;

  const _AddQuestionSheet({required this.nextOrderIndex, required this.onSave});

  @override
  State<_AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends State<_AddQuestionSheet> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final _explanationController = TextEditingController();
  int _correctIndex = 0;
  String? _referenceModuleId;

  @override
  void initState() {
    super.initState();
    _optionControllers.add(TextEditingController());
    _optionControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final text = _questionController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the question text.')));
      return;
    }
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least two choices.')));
      return;
    }
    if (_correctIndex >= options.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select the correct answer.')));
      return;
    }
    final modules = await context.read<AppProvider>().dataSource.getAllModules();
    String domain = 'general';
    if (_referenceModuleId != null && _referenceModuleId!.isNotEmpty) {
      for (final m in modules) {
        if (m.id == _referenceModuleId) {
          domain = m.domain;
          break;
        }
      }
    }
    final explanationText = _explanationController.text.trim();
    final id = 'pre_${DateTime.now().millisecondsSinceEpoch}';
    final q = QuestionModel(
      id: id,
      pairedId: id,
      domain: domain,
      text: text,
      options: options,
      correctIndex: _correctIndex,
      explanation: explanationText.isEmpty ? null : explanationText,
      referenceModuleId: _referenceModuleId,
      orderIndex: widget.nextOrderIndex,
    );
    try {
      await context.read<AppProvider>().dataSource.savePreTestQuestion(q);
      if (mounted) {
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
            DesignSystem.adminContentPadding(context) * 1.2 + MediaQuery.of(context).padding.bottom + 8,
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
            Text('Add question', style: TextStyle(fontSize: DesignSystem.sectionTitleSize(context), fontWeight: FontWeight.bold)),
            SizedBox(height: DesignSystem.s(context, 12)),
            Text('Question', style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: _questionController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Type the question...',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: DesignSystem.adminGridGap(context)),
            Text('Choices (correct = green border)', style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...List.generate(_optionControllers.length, (i) {
              final isCorrect = i == _correctIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade50 : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isCorrect ? Border.all(color: Colors.green, width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: _correctIndex,
                        onChanged: (v) => setState(() => _correctIndex = v ?? 0),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[i],
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            hintText: 'Choice ${i + 1}',
                            hintStyle: const TextStyle(fontSize: 11),
                            filled: true,
                            fillColor: isCorrect ? Colors.green.shade50 : DesignSystem.inputBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, size: DesignSystem.s(context, 18)),
                          onPressed: () => setState(() {
                            final c = _optionControllers.removeAt(i);
                            c.dispose();
                            if (_correctIndex >= _optionControllers.length) _correctIndex = _optionControllers.length - 1;
                          }),
                        ),
                    ],
                  ),
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _optionControllers.add(TextEditingController())),
              icon: Icon(Icons.add, size: DesignSystem.s(context, 18)),
              label: const Text('Add choice', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(height: DesignSystem.adminGridGap(context)),
            Text('Explanation (optional)', style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: _explanationController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Optional explanation',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: DesignSystem.adminGridGap(context)),
            Text('Reference Module', style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            FutureBuilder<List<ModuleModel>>(
              future: context.read<AppProvider>().dataSource.getAllModules(),
              builder: (context, snapshot) {
                final modules = snapshot.data ?? [];
                const dropdownTextStyle = TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: DesignSystem.textPrimary,
                );
                String? selectedLabel;
                if (_referenceModuleId != null && _referenceModuleId!.isNotEmpty) {
                  for (final m in modules) {
                    if (m.id == _referenceModuleId) {
                      selectedLabel = '${m.moduleNumber ?? m.title} – ${m.title}';
                      break;
                    }
                  }
                }
                return InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => _ReferenceModulePickerSheet(
                        modules: modules,
                        currentId: _referenceModuleId,
                        onSelected: (id) => setState(() => _referenceModuleId = id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: DesignSystem.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: DesignSystem.textBody),
                    ),
                    child: Text(
                      selectedLabel ?? 'Select module (optional)',
                      style: selectedLabel != null
                          ? dropdownTextStyle
                          : dropdownTextStyle.copyWith(color: DesignSystem.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: DesignSystem.buttonHeightScaled(context),
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadiusScaled(context))),
                ),
                child: Text('Save question', style: TextStyle(fontSize: DesignSystem.buttonTextSize(context))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
