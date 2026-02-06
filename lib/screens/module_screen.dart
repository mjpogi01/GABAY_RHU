import 'dart:async';
import 'dart:convert';
import 'dart:io' if (dart.library.html) '../utils/io_web_stub.dart' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import '../core/app_routes.dart';
import '../core/design_system.dart';
import '../core/greeting_type.dart';
import '../providers/app_provider.dart';
import '../models/module_model.dart';

class ModuleScreen extends StatefulWidget {
  final String moduleId;
  /// When true, shows the module as a read-only preview (e.g. for admin View). No timer, back/close instead of Finish.
  final bool isPreview;
  /// When true, opened from "All Modules" section – no timer, only Next button (card → card, last card → next module).
  final bool hideTimer;
  /// When from All Modules, ordered list of module ids so "Next" on last card opens the next module.
  final List<String>? allModuleIds;

  const ModuleScreen({
    super.key,
    required this.moduleId,
    this.isPreview = false,
    this.hideTimer = false,
    this.allModuleIds,
  });

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  ModuleModel? _module;
  int _cardIndex = 0;
  bool _loading = true;
  int _secondsSpent = 0;
  Timer? _timer;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadModule();
    if (!widget.isPreview && !widget.hideTimer) {
      final provider = context.read<AppProvider>();
      _secondsSpent = provider.getInProgressSeconds(widget.moduleId);
      final moduleId = widget.moduleId;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _secondsSpent++);
        provider.setInProgressSeconds(moduleId, _secondsSpent);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!widget.isPreview && !widget.hideTimer && mounted) {
      try {
        context.read<AppProvider>().setInProgressSeconds(widget.moduleId, _secondsSpent);
      } catch (_) {}
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadModule() async {
    final ds = context.read<AppProvider>().dataSource;
    _module = await ds.getModuleById(widget.moduleId);
    setState(() => _loading = false);
  }

  /// Shows card image: asset (assets/...), remote URL, or local file (non-web only).
  Widget _buildCardImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
        child: Image.network(
          imagePath,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }
    if (!kIsWeb) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
          child: Image.file(
            file,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _saveTimerAndPop() {
    if (!widget.isPreview && !widget.hideTimer) {
      context.read<AppProvider>().setInProgressSeconds(widget.moduleId, _secondsSpent);
    }
    Navigator.of(context).pop();
  }

  void _next() {
    if (_module == null) return;
    final cards = _module!.cards..sort((a, b) => a.order.compareTo(b.order));
    if (_cardIndex < cards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (widget.isPreview) {
        Navigator.of(context).pop();
      } else if (widget.hideTimer && widget.allModuleIds != null) {
        final ids = widget.allModuleIds!;
        final i = ids.indexOf(widget.moduleId);
        if (i >= 0 && i < ids.length - 1) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.module,
            arguments: <String, dynamic>{
              'moduleId': ids[i + 1],
              'fromAllModules': true,
              'allModuleIds': ids,
            },
          );
        } else {
          Navigator.of(context).pop();
        }
      } else {
        _complete(openNextModule: true);
      }
    }
  }

  /// Completes the current module (saves progress + time), then either goes to
  /// dashboard [openNextModule: false] or to the next assigned module [openNextModule: true].
  Future<void> _complete({bool openNextModule = false}) async {
    _timer?.cancel();
    final timeToSave = widget.hideTimer ? 0 : _secondsSpent;
    try {
      await context.read<AppProvider>().completeModule(widget.moduleId, timeToSave);
    } catch (_) {
      // Still navigate even if save fails
    }
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (openNextModule) {
      final next = provider.nextAssignedModule;
      // Only open next if it's actually a different module (safeguard)
      if (next != null && next.id != widget.moduleId) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.module,
          arguments: <String, dynamic>{'moduleId': next.id},
        );
        return;
      }
    }
    // Show greeting on dashboard: all modules done vs single module done
    provider.setPendingGreeting(
      provider.nextAssignedModule == null
          ? GreetingType.allModulesComplete
          : GreetingType.moduleComplete,
    );
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _module == null) {
      return Scaffold(
        backgroundColor: DesignSystem.bgMain,
        appBar: widget.isPreview
            ? AppBar(
                backgroundColor: DesignSystem.appBarBackground,
                foregroundColor: DesignSystem.appBarIconColor,
                title: const Text('Preview', style: TextStyle(color: DesignSystem.textTitle, fontSize: DesignSystem.appBarTitleSize, fontWeight: DesignSystem.appBarTitleWeight)),
                leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.of(context).pop()),
              )
            : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cards = _module!.cards..sort((a, b) => a.order.compareTo(b.order));
    if (cards.isEmpty) {
      return Scaffold(
        backgroundColor: DesignSystem.bgMain,
        appBar: AppBar(
          backgroundColor: DesignSystem.appBarBackground,
          foregroundColor: DesignSystem.appBarIconColor,
          title: Text(
            widget.isPreview ? 'Preview: ${_module!.title}' : _module!.title,
            style: const TextStyle(color: DesignSystem.textTitle, fontSize: DesignSystem.appBarTitleSize, fontWeight: DesignSystem.appBarTitleWeight),
          ),
          leading: widget.isPreview ? IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.of(context).pop()) : null,
        ),
        body: const Center(child: Text('No content in this module.', style: TextStyle(color: DesignSystem.textBody))),
      );
    }

    final isLast = _cardIndex == cards.length - 1;
    final moduleLabel = _module!.moduleNumber != null && _module!.moduleNumber!.isNotEmpty
        ? _module!.moduleNumber!
        : '${_module!.order}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _saveTimerAndPop();
      },
      child: Scaffold(
        backgroundColor: DesignSystem.bgMain,
        body: SafeArea(
          child: Column(
            children: [
              // 1. App Bar – height 56, back left, title center, timer right, bottom divider
              SizedBox(
                height: DesignSystem.appBarHeight,
                child: Material(
                  color: DesignSystem.appBarBackground,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: DesignSystem.appBarIconColor,
                        onPressed: _saveTimerAndPop,
                      ),
                    Expanded(
                      child: Center(
                        child: Text(
                          moduleLabel,
                          style: const TextStyle(
                            fontSize: DesignSystem.appBarTitleSize,
                            fontWeight: DesignSystem.appBarTitleWeight,
                            height: DesignSystem.appBarTitleHeight / DesignSystem.appBarTitleSize,
                            color: DesignSystem.appBarTitleColor,
                          ),
                        ),
                      ),
                    ),
                    if (widget.hideTimer)
                      const SizedBox(width: 56)
                    else
                      SizedBox(
                        width: 56,
                        child: Center(
                          child: Text(
                            widget.isPreview ? '0:00' : _formatTimer(_secondsSpent),
                            style: const TextStyle(
                              fontSize: DesignSystem.captionSizeValue,
                              height: DesignSystem.captionLineHeight / DesignSystem.captionSizeValue,
                              color: DesignSystem.textMuted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: DesignSystem.appBarDivider),
            // 2 & 3. Scrollable content – title (centered) + body, padding 16, max width 640
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: DesignSystem.maxContentWidth),
                  child: PageView.builder(
                    itemCount: cards.length,
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _cardIndex = i),
                    itemBuilder: (_, i) {
                      final c = cards[i];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.screenPaddingH),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: DesignSystem.spacingSectionValue),
                            Center(
                              child: Text(
                                _module!.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: DesignSystem.moduleTitleSize,
                                  fontWeight: DesignSystem.moduleTitleWeight,
                                  height: DesignSystem.moduleTitleHeight / DesignSystem.moduleTitleSize,
                                  color: DesignSystem.textTitle,
                                ),
                              ),
                            ),
                            const SizedBox(height: DesignSystem.spacingParagraph),
                            if (c.imagePath != null && c.imagePath!.isNotEmpty) ...[
                              _buildCardImage(c.imagePath!),
                              const SizedBox(height: DesignSystem.spacingParagraph),
                            ],
                            _QuillContentReader(content: c.content),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // 4. Action buttons – from All Modules: single Next; otherwise Finish + Next Module
            if (!widget.isPreview)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSystem.screenPaddingH,
                  DesignSystem.spacingSectionValue,
                  DesignSystem.screenPaddingH,
                  DesignSystem.spacingSectionValue,
                ),
                child: widget.hideTimer
                    ? SizedBox(
                        width: double.infinity,
                        height: DesignSystem.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                            ),
                            textStyle: const TextStyle(
                              fontSize: DesignSystem.buttonTextSizeValue,
                              fontWeight: DesignSystem.buttonTextWeight,
                            ),
                          ),
                          child: const Text('Next'),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: DesignSystem.buttonHeight,
                              child: OutlinedButton(
                                onPressed: isLast ? () => _complete(openNextModule: false) : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: DesignSystem.primarySoft,
                                  foregroundColor: DesignSystem.primary,
                                  side: const BorderSide(color: DesignSystem.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: DesignSystem.buttonTextSizeValue,
                                    fontWeight: DesignSystem.buttonTextWeight,
                                  ),
                                ),
                                child: const Text('Finish'),
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignSystem.buttonGap),
                          Expanded(
                            child: SizedBox(
                              height: DesignSystem.buttonHeight,
                              child: ElevatedButton(
                                onPressed: _next,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignSystem.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: DesignSystem.buttonTextSizeValue,
                                    fontWeight: DesignSystem.buttonTextWeight,
                                  ),
                                ),
                                child: Text(isLast ? 'Next Module' : 'Next'),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// Read-only Quill content viewer so inline images and formatting display correctly.
class _QuillContentReader extends StatefulWidget {
  final String content;

  const _QuillContentReader({required this.content});

  @override
  State<_QuillContentReader> createState() => _QuillContentReaderState();
}

class _QuillContentReaderState extends State<_QuillContentReader> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.content);
  }

  @override
  void didUpdateWidget(_QuillContentReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller.dispose();
      _controller = _createController(widget.content);
    }
  }

  quill.QuillController _createController(String content) {
    quill.Document doc;
    if (content.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(content);
        if (decoded is List) {
          doc = quill.Document.fromJson(decoded);
        } else {
          doc = quill.Document()..insert(0, content);
        }
      } catch (_) {
        doc = quill.Document()..insert(0, content);
      }
    } else {
      doc = quill.Document();
    }
    return quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: quill.QuillEditor.basic(
        controller: _controller,
        config: quill.QuillEditorConfig(
          padding: EdgeInsets.zero,
          embedBuilders: kIsWeb
              ? FlutterQuillEmbeds.editorWebBuilders()
              : FlutterQuillEmbeds.editorBuilders(),
        ),
      ),
    );
  }
}
