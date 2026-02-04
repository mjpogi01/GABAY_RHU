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
import '../providers/app_provider.dart';
import '../models/module_model.dart';

class ModuleScreen extends StatefulWidget {
  final String moduleId;
  /// When true, shows the module as a read-only preview (e.g. for admin View). No timer, back/close instead of Finish.
  final bool isPreview;

  const ModuleScreen({super.key, required this.moduleId, this.isPreview = false});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  ModuleModel? _module;
  int _cardIndex = 0;
  bool _loading = true;
  int _secondsSpent = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadModule();
    if (!widget.isPreview) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _secondsSpent++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
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

  void _next() {
    if (_module == null) return;
    if (_cardIndex < _module!.cards.length - 1) {
      setState(() => _cardIndex++);
    } else {
      if (widget.isPreview) {
        Navigator.of(context).pop();
      } else {
        _complete();
      }
    }
  }

  void _prev() {
    if (_cardIndex > 0) setState(() => _cardIndex--);
  }

  Future<void> _complete() async {
    _timer?.cancel();
    await context.read<AppProvider>().completeModule(widget.moduleId, _secondsSpent);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _module == null) {
      return Scaffold(
        appBar: widget.isPreview
            ? AppBar(
                title: const Text('Preview'),
                leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
              )
            : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cards = _module!.cards..sort((a, b) => a.order.compareTo(b.order));
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isPreview ? 'Preview: ${_module!.title}' : _module!.title),
          automaticallyImplyLeading: widget.isPreview,
          leading: widget.isPreview ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()) : null,
        ),
        body: const Center(child: Text('No content in this module.')),
      );
    }

    final isLast = _cardIndex == cards.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPreview ? 'Preview: ${_module!.title}' : _module!.title),
        automaticallyImplyLeading: widget.isPreview,
        leading: widget.isPreview ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()) : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignSystem.maxContentWidth),
            child: Column(
              children: [
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_cardIndex + 1} / ${cards.length}'),
                  if (widget.isPreview)
                    const Text('Preview', style: TextStyle(color: DesignSystem.textMuted))
                  else
                    Text('${_secondsSpent}s'),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: cards.length,
                controller: PageController(initialPage: _cardIndex),
                onPageChanged: (i) => setState(() => _cardIndex = i),
                itemBuilder: (_, i) {
                  final c = cards[i];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (c.imagePath != null && c.imagePath!.isNotEmpty) ...[
                                _buildCardImage(c.imagePath!),
                                const SizedBox(height: 16),
                              ],
                              _QuillContentReader(content: c.content),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_cardIndex > 0)
                    TextButton(
                      onPressed: _prev,
                      child: const Text('Previous'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(widget.isPreview && isLast ? 'Close preview' : isLast ? 'Finish' : 'Next'),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
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
