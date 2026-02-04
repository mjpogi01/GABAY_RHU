import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import '../../core/design_system.dart';
import '../../providers/app_provider.dart';
import '../../models/module_model.dart';
import '../../services/cloudinary_upload_service.dart';
import '../module_screen.dart';

/// Ensures module number is displayed with "Module " prefix on cards.
String _displayModuleNumber(String moduleNumber) {
  final trimmed = moduleNumber.trim();
  if (trimmed.isEmpty) return 'Module';
  if (RegExp(r'^Module\s', caseSensitive: false).hasMatch(trimmed)) return trimmed;
  return 'Module $trimmed';
}

/// Converts Quill delta JSON to plain text for list previews.
String _quillDeltaToPlainText(String? content) {
  if (content == null || content.trim().isEmpty) return '';
  try {
    final decoded = jsonDecode(content);
    if (decoded is! List || decoded.isEmpty) return content;
    final buffer = StringBuffer();
    for (final op in decoded) {
      if (op is Map<String, dynamic>) {
        final insert = op['insert'];
        if (insert is String) {
          buffer.write(insert.replaceAll('\n', ' '));
        }
      }
    }
    return buffer.toString().trim();
  } catch (_) {
    return content;
  }
}

/// Parses Quill content JSON, uploads any inline image embeds (base64 or local file) to Cloudinary,
/// and returns content JSON with image values replaced by HTTPS URLs so they display and persist.
Future<String> _processQuillContentImageUrls(String contentJson, String moduleId) async {
  if (contentJson.trim().isEmpty) return contentJson;
  try {
    final decoded = jsonDecode(contentJson);
    if (decoded is! List || decoded.isEmpty) return contentJson;
    final list = List<Map<String, dynamic>>.from(decoded.map((e) => e is Map<String, dynamic> ? Map<String, dynamic>.from(e) : <String, dynamic>{}));
    int imageIndex = 0;
    for (int i = 0; i < list.length; i++) {
      final op = list[i];
      final insert = op['insert'];
      if (insert is! Map<String, dynamic>) continue;
      final imageValue = insert['image'];
      if (imageValue is! String || imageValue.isEmpty) continue;
      // Already a remote URL – keep as is
      if (imageValue.startsWith('http://') || imageValue.startsWith('https://')) continue;
      List<int>? bytes;
      String? ext = 'png';
      if (imageValue.startsWith('data:image/') && imageValue.contains(';base64,')) {
        final base64 = imageValue.split(';base64,').last;
        try {
          bytes = base64Decode(base64);
          final mime = imageValue.replaceFirst('data:image/', '').split(';').first;
          if (mime == 'jpeg' || mime == 'jpg') ext = 'jpg';
          if (mime == 'gif') ext = 'gif';
          if (mime == 'webp') ext = 'webp';
        } catch (_) {
          continue;
        }
      } else if (!kIsWeb && (imageValue.startsWith('/') || imageValue.contains(RegExp(r'^[A-Za-z]:')))) {
        final file = File(imageValue);
        if (file.existsSync()) {
          bytes = await file.readAsBytes();
          final name = file.path;
          if (name.endsWith('.jpg') || name.endsWith('.jpeg')) ext = 'jpg';
          if (name.endsWith('.gif')) ext = 'gif';
          if (name.endsWith('.webp')) ext = 'webp';
        }
      }
      if (bytes == null || bytes.isEmpty) continue;
      final publicId = 'inline_$imageIndex.$ext';
      final folder = 'gabay/modules/$moduleId';
      final url = await CloudinaryUploadService.uploadImage(
        bytes: bytes,
        publicId: publicId,
        folder: folder,
      );
      if (url != null && url.isNotEmpty) {
        insert['image'] = url;
      }
      imageIndex++;
    }
    return jsonEncode(list);
  } catch (_) {
    return contentJson;
  }
}

/// Admin Modules (LMs): search, list with View/Edit/Delete, Add New Module modal.
class AdminModulesScreen extends StatefulWidget {
  const AdminModulesScreen({super.key});

  @override
  State<AdminModulesScreen> createState() => _AdminModulesScreenState();
}

class _AdminModulesScreenState extends State<AdminModulesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  Future<List<ModuleModel>>? _modulesFuture;

  void _refreshModules() {
    setState(() {
      _modulesFuture = context.read<AppProvider>().dataSource.getAllModules();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.read<AppProvider>().dataSource;
    _modulesFuture ??= ds.getAllModules();

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: DesignSystem.s(context, 12)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Modules',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: DesignSystem.textPrimary,
                fontSize: DesignSystem.appTitleSize(context),
              ),
            ),
          ),
        ),
        backgroundColor: DesignSystem.cardSurface,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: DesignSystem.s(context, 12)),
            child: IconButton(
              icon: Icon(Icons.add, color: DesignSystem.primary, size: DesignSystem.s(context, 28)),
              onPressed: () => _showAddModuleModal(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: DesignSystem.captionSize(context)),
              decoration: InputDecoration(
                hintText: 'Search module number or title.',
                hintStyle: TextStyle(fontSize: DesignSystem.captionSize(context), color: DesignSystem.textMuted),
                prefixIcon: Icon(Icons.search, color: DesignSystem.textMuted, size: DesignSystem.s(context, 22)),
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadiusScaled(context)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ModuleModel>>(
              future: _modulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.hasError ? <ModuleModel>[] : (snapshot.data ?? <ModuleModel>[]);
                final filtered = _query.isEmpty
                    ? list
                    : list.where((m) {
                        final q = _query.toLowerCase();
                        final byNumber = m.moduleNumber?.toLowerCase().contains(q) ?? false;
                        return m.id.toLowerCase().contains(q) ||
                            m.title.toLowerCase().contains(q) ||
                            byNumber;
                      }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      list.isEmpty ? 'No modules yet' : 'No matches',
                      style: TextStyle(color: DesignSystem.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: DesignSystem.adminContentPadding(context)),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final m = filtered[i];
                    return _ModuleCard(
                      module: m,
                      onView: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ModuleScreen(moduleId: m.id, isPreview: true),
                          ),
                        );
                      },
                      onEdit: () => _showEditModuleModal(context, m),
                      onDelete: () => _confirmDelete(context, m),
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

  void _showAddModuleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditModuleSheet(
        title: 'Add New Module',
        onSave: (moduleNumber, title, content, imagePath, imageBytes, imageExtension, [clearCover = false]) async {
          Navigator.pop(ctx);
          await _saveModule(context, moduleNumber: moduleNumber, title: title, content: content, imageBytes: imageBytes, imageExtension: imageExtension);
        },
      ),
    );
  }

  void _showEditModuleModal(BuildContext context, ModuleModel m) {
    final existingCoverUrl = m.cards.isNotEmpty ? m.cards.first.imagePath : null;
    final coverUrl = (existingCoverUrl != null && existingCoverUrl.startsWith('http')) ? existingCoverUrl : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditModuleSheet(
        title: 'Edit Module',
        initialModuleNumber: m.moduleNumber,
        initialTitle: m.title,
        initialContent: m.cards.isNotEmpty ? m.cards.first.content : '',
        initialCoverImageUrl: coverUrl,
        isEdit: true,
        onSave: (moduleNumber, title, content, imagePath, imageBytes, imageExtension, [clearCover = false]) async {
          Navigator.pop(ctx);
          await _saveModule(context, moduleNumber: moduleNumber, title: title, content: content, existingModule: m, imageBytes: imageBytes, imageExtension: imageExtension, clearCover: clearCover);
        },
      ),
    );
  }

  Future<void> _saveModule(
    BuildContext context, {
    required String moduleNumber,
    required String title,
    required String content,
    ModuleModel? existingModule,
    List<int>? imageBytes,
    String? imageExtension,
    bool clearCover = false,
  }) async {
    final ds = context.read<AppProvider>().dataSource;
    final id = existingModule?.id ?? 'mod_${DateTime.now().millisecondsSinceEpoch}';
    final order = existingModule?.order ?? 999;
    final number = moduleNumber.trim();
    // Upload inline RTE images (base64/file) to Cloudinary and replace with URLs
    final processedContent = await _processQuillContentImageUrls(content, id);
    final existingCoverPath = existingModule?.cards.isNotEmpty == true ? existingModule!.cards.first.imagePath : null;
    final keepCoverUrl = !clearCover && imageBytes == null && existingCoverPath != null && existingCoverPath.startsWith('http');
    final module = ModuleModel(
      id: id,
      title: title.trim().isEmpty ? 'Untitled module' : title.trim(),
      domain: existingModule?.domain ?? 'general',
      order: order,
      cards: [ModuleCard(id: 'card_1', content: processedContent, imagePath: keepCoverUrl ? existingCoverPath : null, order: 0)],
      moduleNumber: number.isEmpty ? null : number,
    );
    try {
      await ds.saveModule(module, coverImageBytes: imageBytes, coverImageExtension: imageExtension);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Module saved')));
        _refreshModules();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  void _confirmDelete(BuildContext context, ModuleModel m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete module?'),
        content: Text('Delete "${m.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<AppProvider>().dataSource.deleteModule(m.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Module deleted')));
                  _refreshModules();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ModuleCard({
    required this.module,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rawContent = module.cards.isNotEmpty ? module.cards.first.content : '';
    final plainText = _quillDeltaToPlainText(rawContent);
    final description = plainText.isEmpty ? 'No content' : plainText;
    final shortDesc = description.length > 120 ? '${description.substring(0, 120)}...' : description;

    final moduleLabel = (module.moduleNumber != null && module.moduleNumber!.isNotEmpty)
        ? _displayModuleNumber(module.moduleNumber!)
        : null;
    final moduleNumSize = DesignSystem.sectionTitleSize(context);
    final titleSize = DesignSystem.bodyTextSize(context);
    final descSize = DesignSystem.captionSize(context);

    return Card(
      margin: EdgeInsets.only(bottom: DesignSystem.adminGridGap(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context))),
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: DesignSystem.textPrimary, height: 1.3),
                      children: [
                        if (moduleLabel != null)
                          TextSpan(
                            text: '$moduleLabel ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: moduleNumSize,
                            ),
                          ),
                        TextSpan(
                          text: module.title,
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: titleSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: DesignSystem.s(context, 18)),
                  child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 0, minHeight: 0),
                      iconSize: DesignSystem.s(context, 24),
                      child: SizedBox(
                        height: moduleNumSize * 1.3,
                        width: DesignSystem.s(context, 40),
                        child: Icon(Icons.more_vert, size: DesignSystem.s(context, 24)),
                      ),
                      onSelected: (v) {
                        if (v == 'View') onView();
                        if (v == 'Edit') onEdit();
                        if (v == 'Delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'View', child: Text('View')),
                        const PopupMenuItem(value: 'Edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: DesignSystem.s(context, 4)),
            Text(
              shortDesc,
              style: TextStyle(
                fontSize: descSize,
                color: DesignSystem.textSecondary,
                height: 1.35,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEditModuleSheet extends StatefulWidget {
  final String title;
  final String? initialModuleNumber;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCoverImageUrl;
  final bool isEdit;
  final Future<void> Function(String moduleNumber, String title, String content, String? imagePath, List<int>? imageBytes, String? imageExtension, [bool clearCover]) onSave;

  const _AddEditModuleSheet({
    required this.title,
    this.initialModuleNumber,
    this.initialTitle,
    this.initialContent,
    this.initialCoverImageUrl,
    this.isEdit = false,
    required this.onSave,
  });

  @override
  State<_AddEditModuleSheet> createState() => _AddEditModuleSheetState();
}

/// Module number: numeric part must be 1–50. Required when adding.
String? _validateModuleNumber(String? value, {bool isEdit = false}) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return isEdit ? null : 'Module number is required';
  final n = int.tryParse(v);
  if (n == null || n < 1 || n > 50) return 'Enter a number from 1 to 50';
  return null;
}

class _AddEditModuleSheetState extends State<_AddEditModuleSheet> {
  late final TextEditingController _moduleNumberController;
  late final TextEditingController _titleController;
  late final quill.QuillController _quillController;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  final GlobalKey _contentSectionKey = GlobalKey();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _moduleNumberError;
  bool _removedExistingCover = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.initialModuleNumber ?? '';
    final numberPart = raw.startsWith(RegExp(r'^Module\s*')) ? raw.replaceFirst(RegExp(r'^Module\s*'), '').trim() : raw.trim();
    _moduleNumberController = TextEditingController(text: numberPart.isEmpty ? '' : numberPart);
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _focusNode.addListener(_scrollToContentWhenFocused);
    _quillController = _createQuillController(widget.initialContent);
  }

  void _scrollToContentWhenFocused() {
    if (!_focusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _contentSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  quill.QuillController _createQuillController(String? initialContent) {
    quill.Document doc;
    if (initialContent != null && initialContent.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(initialContent);
        if (decoded is List) {
          doc = quill.Document.fromJson(decoded);
        } else {
          doc = quill.Document()..insert(0, initialContent);
        }
      } catch (_) {
        doc = quill.Document()..insert(0, initialContent);
      }
    } else {
      doc = quill.Document();
    }
    return quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_scrollToContentWhenFocused);
    _moduleNumberController.dispose();
    _titleController.dispose();
    _quillController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Prefer no compression to avoid "Could not decompress image" on some devices
      XFile? picked = await _picker.pickImage(source: source);
      if (picked == null) return;
      if (mounted) setState(() => _imageFile = picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceChoice() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, size: DesignSystem.s(ctx, 24)),
              title: Text('Gallery', style: TextStyle(fontSize: DesignSystem.bodyTextSize(ctx))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, size: DesignSystem.s(ctx, 24)),
              title: Text('Camera', style: TextStyle(fontSize: DesignSystem.bodyTextSize(ctx))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
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
            DesignSystem.adminContentPadding(context) * 1.2 + bottomInset,
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
            Text(
              widget.title,
              style: TextStyle(
                fontSize: DesignSystem.sectionTitleSize(context),
                fontWeight: FontWeight.bold,
                color: DesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: DesignSystem.s(context, 12)),
            Text('Module number', style: TextStyle(fontWeight: FontWeight.w600, color: DesignSystem.textPrimary)),
            SizedBox(height: 4),
            TextField(
              controller: _moduleNumberController,
              keyboardType: TextInputType.number,
              maxLength: 2,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: 'Module ',
                prefixStyle: TextStyle(color: DesignSystem.textMuted, fontSize: DesignSystem.bodyTextSize(context)),
                hintText: '1–50',
                errorText: _moduleNumberError,
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius), borderSide: BorderSide.none),
                counterText: '',
              ),
              onChanged: (_) => setState(() => _moduleNumberError = null),
            ),
            SizedBox(height: DesignSystem.adminSectionGap(context)),
            Text('Image', style: TextStyle(fontWeight: FontWeight.w600, color: DesignSystem.textPrimary)),
            SizedBox(height: 4),
            GestureDetector(
              onTap: _showImageSourceChoice,
              child: Container(
                height: DesignSystem.wRatio(context, 140 / 375),
                decoration: BoxDecoration(
                  color: DesignSystem.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DesignSystem.inputBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageFile != null && _imageFile!.path.isNotEmpty
                    ? _buildImagePreview()
                    : _buildExistingCoverOrPlaceholder(context),
              ),
            ),
            SizedBox(height: DesignSystem.adminSectionGap(context)),
            Text('Title', style: TextStyle(fontWeight: FontWeight.w600, color: DesignSystem.textPrimary)),
            SizedBox(height: 4),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Module title',
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: DesignSystem.s(context, 16)),
            Text('Content', style: TextStyle(fontWeight: FontWeight.w600, color: DesignSystem.textPrimary)),
            SizedBox(height: 4),
            Container(
              key: _contentSectionKey,
              decoration: BoxDecoration(
                color: DesignSystem.inputBackground,
                borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
                border: Border.all(color: DesignSystem.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  quill.QuillSimpleToolbar(
                    controller: _quillController,
                    config: quill.QuillSimpleToolbarConfig(
                      embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                      multiRowsDisplay: false,
                      showDividers: false,
                      showFontFamily: false,
                      showFontSize: false,
                      showBoldButton: true,
                      showItalicButton: true,
                      showUnderLineButton: true,
                      showStrikeThrough: false,
                      showInlineCode: false,
                      showColorButton: false,
                      showBackgroundColorButton: false,
                      showClearFormat: false,
                      showAlignmentButtons: false,
                      showLeftAlignment: false,
                      showCenterAlignment: false,
                      showRightAlignment: false,
                      showJustifyAlignment: false,
                      showHeaderStyle: false,
                      showListNumbers: true,
                      showListBullets: true,
                      showListCheck: false,
                      showCodeBlock: false,
                      showQuote: false,
                      showIndent: false,
                      showLink: true,
                      showUndo: true,
                      showRedo: true,
                      showDirection: false,
                      showSearchButton: false,
                      showSubscript: false,
                      showSuperscript: false,
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: 240,
                    child: quill.QuillEditor.basic(
                      controller: _quillController,
                      focusNode: _focusNode,
                      scrollController: _scrollController,
                      config: quill.QuillEditorConfig(
                        placeholder: 'Write module content... Use the image button to insert and layout images.',
                        padding: EdgeInsets.symmetric(horizontal: DesignSystem.s(context, 12), vertical: DesignSystem.s(context, 8)),
                        embedBuilders: kIsWeb
                            ? FlutterQuillEmbeds.editorWebBuilders()
                            : FlutterQuillEmbeds.editorBuilders(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignSystem.adminSectionGap(context) * 1.2),
            SizedBox(
              width: double.infinity,
              height: DesignSystem.buttonHeightScaled(context),
              child: ElevatedButton(
                onPressed: () async {
                  final numberPart = _moduleNumberController.text.trim();
                  final moduleNumberError = _validateModuleNumber(numberPart, isEdit: widget.isEdit);
                  if (moduleNumberError != null) {
                    setState(() => _moduleNumberError = moduleNumberError);
                    return;
                  }
                  final moduleNumber = numberPart.isEmpty ? '' : 'Module $numberPart';
                  final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
                  List<int>? imageBytes;
                  String? imageExtension;
                  if (_imageFile != null) {
                    imageBytes = await _imageFile!.readAsBytes();
                    final name = _imageFile!.name;
                    imageExtension = name.contains('.') ? name.split('.').last : 'png';
                  }
                  await widget.onSave(
                    moduleNumber,
                    _titleController.text,
                    contentJson,
                    _imageFile?.path,
                    imageBytes,
                    imageExtension,
                    _removedExistingCover,
                  );
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

  Widget _buildImagePreview() {
    final path = _imageFile!.path;
    if (path.isEmpty) return const SizedBox.shrink();
    if (!kIsWeb) {
      final file = File(path);
      if (!file.existsSync()) return _buildPlaceholder(context);
    }
    final t = DesignSystem.s(context, 8);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        ),
        Positioned(
          top: t,
          right: t,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: DesignSystem.s(context, 24)),
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
            onPressed: () => setState(() => _imageFile = null),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingCoverOrPlaceholder(BuildContext context) {
    final showExisting = widget.initialCoverImageUrl != null &&
        widget.initialCoverImageUrl!.isNotEmpty &&
        !_removedExistingCover;
    if (showExisting) {
      final t = DesignSystem.s(context, 8);
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.initialCoverImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)),
            errorBuilder: (_, __, ___) => _buildPlaceholder(context),
          ),
          Positioned(
            top: t,
            right: t,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: DesignSystem.s(context, 24)),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: () => setState(() => _removedExistingCover = true),
            ),
          ),
        ],
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 48, color: DesignSystem.textMuted),
          SizedBox(height: DesignSystem.s(context, 8)),
          Text(
            'Tap to upload image',
            style: TextStyle(fontSize: DesignSystem.captionSize(context), color: DesignSystem.textMuted),
          ),
        ],
      ),
    );
  }
}
