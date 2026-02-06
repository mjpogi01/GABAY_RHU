import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/module_model.dart';
import '../core/app_routes.dart';
import '../core/design_system.dart';
import '../core/greeting_type.dart';
import '../providers/app_provider.dart';
import '../widgets/greetings_card.dart';

/// Home - Standardized layout matching design
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onAvatarTap;

  const DashboardScreen({super.key, this.onAvatarTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static double _horizontalPadding(BuildContext context) => DesignSystem.s(context, 16);
  static double _sectionGap(BuildContext context) => DesignSystem.s(context, 24);
  static double _cardGap(BuildContext context) => DesignSystem.s(context, 16);

  void _showPostTestLockedMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post-Test'),
        content: const Text(
          'Complete the modules to unlock the Post-Test.',
          style: TextStyle(color: DesignSystem.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DesignSystem.background,
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final userName = provider.user?.displayName ?? 'User';
          final preTestScore = provider.preTestResult != null
              ? (provider.preTestResult!.overallScore * 100).round()
              : null;
          final postTestScore = provider.postTestResult != null
              ? (provider.postTestResult!.overallScore * 100).round()
              : null;
          final postTestAvailable = provider.canAccessPostTest;
          final postTestDate = provider.preTestResult?.completedAt
                  .add(const Duration(days: 60));
          final assignedModules = provider.assignedModules;
          final nextModule = provider.nextAssignedModule;
          final listAllModules = provider.allModules;

          final paddingH = _horizontalPadding(context);
          final sectionGap = _sectionGap(context);
          final cardGap = _cardGap(context);
          final screenWidth = MediaQuery.sizeOf(context).width;
          final contentWidth = screenWidth.clamp(0.0, DesignSystem.maxContentWidth);
          final horizontalMargin = (screenWidth - contentWidth) / 2;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // 1. Hero Card Header
                  SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    paddingH + horizontalMargin,
                    MediaQuery.of(context).padding.top,
                    paddingH + horizontalMargin,
                    0,
                  ),
                  height: DesignSystem.s(context, 96),
                  decoration: BoxDecoration(
                    color: DesignSystem.cardSurface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      DesignSystem.s(context, 20),
                      DesignSystem.s(context, 8),
                      DesignSystem.s(context, 20),
                      DesignSystem.s(context, 8),
                    ),
                    child: SizedBox(
                      height: DesignSystem.s(context, 80),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Hello, $userName',
                                      style: TextStyle(
                                        fontSize: DesignSystem.s(context, 22),
                                        fontWeight: FontWeight.w600,
                                        color: DesignSystem.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: DesignSystem.s(context, 4)),
                                    Text.rich(
                                      TextSpan(
                                        text: 'Welcome to ',
                                        style: TextStyle(
                                          fontSize: DesignSystem.s(context, 14),
                                          color: DesignSystem.textMuted,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'GABAY',
                                            style: TextStyle(
                                              fontSize: DesignSystem.s(context, 14),
                                              color: DesignSystem.textMuted,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: DesignSystem.s(context, 40)),
                            ],
                          ),
                          GestureDetector(
                            onTap: widget.onAvatarTap,
                            child: CircleAvatar(
                              radius: DesignSystem.s(context, 20),
                              backgroundColor: DesignSystem.primarySoft,
                              child: Icon(
                                Icons.person,
                                color: DesignSystem.primary,
                                size: DesignSystem.s(context, 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 2. Assessment – 2-column grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(paddingH + horizontalMargin, DesignSystem.s(context, 16), paddingH + horizontalMargin, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessment',
                        style: TextStyle(
                          fontSize: DesignSystem.s(context, 18),
                          fontWeight: FontWeight.w600,
                          color: DesignSystem.textPrimary,
                        ),
                      ),
                      SizedBox(height: DesignSystem.s(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _AssessmentCard(
                              title: 'Pre-Test',
                              isPreTest: true,
                              isFinished: provider.hasCompletedPreTest,
                              score: preTestScore,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.preTest),
                            ),
                          ),
                          SizedBox(width: cardGap),
                          Expanded(
                            child: _AssessmentCard(
                              title: 'Post-Test',
                              isPreTest: false,
                              isFinished: provider.hasCompletedPostTest,
                              score: postTestScore,
                              availableDate: postTestAvailable ? postTestDate : null,
                              onTap: provider.canAccessPostTest || provider.hasCompletedPostTest
                                  ? () => Navigator.pushNamed(context, AppRoutes.postTest)
                                  : () => _showPostTestLockedMessage(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
              // 3. Continue Learning – featured big card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingH + horizontalMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue Learning',
                        style: TextStyle(
                          fontSize: DesignSystem.s(context, 18),
                          fontWeight: FontWeight.w600,
                          color: DesignSystem.textPrimary,
                        ),
                      ),
                      SizedBox(height: DesignSystem.s(context, 16)),
                      nextModule == null
                          ? Container(
                              height: DesignSystem.s(context, 220),
                              padding: EdgeInsets.all(sectionGap),
                              decoration: BoxDecoration(
                                color: DesignSystem.bgSection,
                                borderRadius: BorderRadius.circular(DesignSystem.s(context, 16)),
                                border: Border.all(color: DesignSystem.border),
                              ),
                              child: Center(
                                child: Text(
                                  assignedModules.isEmpty
                                      ? 'No modules assigned yet. Complete the pre-test to get your learning path.'
                                      : "You've completed all assigned modules. Great job!",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: DesignSystem.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : _buildFeaturedModuleCard(
                              context,
                              nextModule,
                              provider.completedModuleIds.contains(nextModule.id),
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.module,
                                arguments: {'moduleId': nextModule.id},
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
              // 4. All Modules – horizontal list
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingH + horizontalMargin),
                  child: Text(
                    'All Modules',
                    style: TextStyle(
                      fontSize: DesignSystem.s(context, 18),
                      fontWeight: FontWeight.w600,
                      color: DesignSystem.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: DesignSystem.s(context, 16))),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: DesignSystem.s(context, 200),
                  child: listAllModules.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: paddingH + horizontalMargin),
                          itemCount: listAllModules.length,
                          itemBuilder: (context, i) {
                            final module = listAllModules[i];
                            final isCompleted = provider.completedModuleIds.contains(module.id);
                            return Padding(
                              padding: EdgeInsets.only(right: cardGap),
                              child: _buildModuleDetailCard(
                                context,
                                module,
                                isCompleted,
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.module,
                                  arguments: {
                                    'moduleId': module.id,
                                    'fromAllModules': true,
                                    'allModuleIds': listAllModules.map((m) => m.id).toList(),
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: DesignSystem.s(context, 24))),
            ],
          ),
          if (provider.pendingGreeting != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _GreetingOverlay(
                type: provider.pendingGreeting!,
                paddingH: paddingH,
                horizontalMargin: horizontalMargin,
                onDismiss: () => provider.clearPendingGreeting(),
              ),
            ),
        ],
      );
        },
      ),
    );
  }

  /// Sanitize card content: strip HTML/JSON, never show raw placeholder data.
  static String _sanitizePreview(String raw) {
    final plain = raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\{[^}]*\}'), ' ')
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (plain.isEmpty || plain.length < 2) return '';
    if (RegExp(r'^[\s,\[\]{}\\]*$').hasMatch(plain)) return '';
    return plain.length > 80 ? '${plain.substring(0, 80)}…' : plain;
  }

  /// Preview text for a module (from first cards’ content).
  /// Extract plain text from card content. Handles Quill delta JSON so raw code is never shown.
  static String _contentToPreviewText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed) as List<dynamic>?;
        if (decoded == null) return '';
        final buffer = StringBuffer();
        for (final item in decoded) {
          if (item is! Map<String, dynamic>) continue;
          final insert = item['insert'];
          if (insert is String) buffer.write(insert.replaceAll('\n', ' '));
        }
        final text = buffer.toString().trim();
        if (text.isEmpty) return '';
        return text.length > 80 ? '${text.substring(0, 80)}…' : text;
      } catch (_) {}
    }
    return _sanitizePreview(raw);
  }

  static String _getModulePreview(ModuleModel module) {
    if (module.cards.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < module.cards.length; i++) {
      final text = _contentToPreviewText(module.cards[i].content);
      if (text.isNotEmpty) {
        buffer.write(text);
        if (i < module.cards.length - 1) buffer.write(' ');
      }
      if (buffer.length > 100) break;
    }
    final result = buffer.toString().trim();
    return result.length > 80 ? '${result.substring(0, 80)}…' : result;
  }

  Widget _buildFeaturedModuleCard(
    BuildContext context,
    ModuleModel module,
    bool isCompleted,
    VoidCallback onTap,
  ) {
    final coverImagePath = module.cards.isNotEmpty
        ? module.cards.first.imagePath
        : null;
    final shortPreview = _getModulePreview(module);

    final cardH = DesignSystem.s(context, 220);
    final imageW = DesignSystem.s(context, 140);
    final radius = DesignSystem.s(context, 16);
    final innerPad = DesignSystem.s(context, 16);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardH,
        width: double.infinity,
        decoration: BoxDecoration(
          color: DesignSystem.cardSurface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: DesignSystem.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Row(
            children: [
              SizedBox(
                width: imageW,
                height: double.infinity,
                child: coverImagePath != null && coverImagePath.isNotEmpty
                    ? _buildModuleCardImage(coverImagePath)
                    : _gradientFallback(),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(innerPad, DesignSystem.s(context, 14), innerPad, DesignSystem.s(context, 14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              module.moduleNumber ?? 'Module ${module.order}',
                              style: TextStyle(
                                fontSize: DesignSystem.s(context, 12),
                                color: DesignSystem.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              module.title,
                              style: TextStyle(
                                fontSize: DesignSystem.s(context, 18),
                                fontWeight: FontWeight.w600,
                                color: DesignSystem.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              shortPreview.isNotEmpty
                                  ? shortPreview
                                  : 'Tap to view module content.',
                              style: TextStyle(
                                fontSize: DesignSystem.s(context, 13),
                                color: DesignSystem.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isCompleted ? 'Completed' : 'In progress',
                              style: TextStyle(
                                fontSize: DesignSystem.s(context, 13),
                                color: DesignSystem.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: DesignSystem.s(context, 14),
                              color: DesignSystem.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleDetailCard(
    BuildContext context,
    ModuleModel module,
    bool isCompleted,
    VoidCallback onTap,
  ) {
    final coverImagePath = module.cards.isNotEmpty
        ? module.cards.first.imagePath
        : null;
    final shortPreview = _getModulePreview(module);
    final cardHeight = DesignSystem.s(context, 160);
    final cardWidth = DesignSystem.wRatio(context, 280 / 375);
    final radius = DesignSystem.s(context, 16);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: coverImagePath != null && coverImagePath.isNotEmpty
                  ? _buildModuleCardImage(coverImagePath)
                  : Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.grey.shade100,
                          ],
                        ),
                      ),
                    ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(DesignSystem.s(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    module.moduleNumber ?? 'Module ${module.order}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        module.title,
                        style: TextStyle(
                          fontSize: DesignSystem.s(context, 18),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shortPreview.isNotEmpty
                            ? shortPreview
                            : 'Tap to view module content.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Read more',
                          style: TextStyle(
                            fontSize: 14,
                            color: DesignSystem.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCardImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _gradientFallback(),
      );
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _gradientFallback(),
      );
    }
    return _gradientFallback();
  }

  Widget _gradientFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.grey.shade100,
          ],
        ),
      ),
    );
  }
}

/// Sliding marquee for status text that overflows; shows static text when it fits.
class _SlidingStatusText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _SlidingStatusText(this.text, {required this.style});

  @override
  State<_SlidingStatusText> createState() => _SlidingStatusTextState();
}

class _SlidingStatusTextState extends State<_SlidingStatusText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (maxW <= 0) return const SizedBox.shrink();
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);
        final textWidth = textPainter.size.width;
        if (textWidth <= maxW) {
          if (_controller.isAnimating) _controller.stop();
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        if (!_controller.isAnimating) _controller.repeat(reverse: true);
        return ClipRect(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final offset = (textWidth - maxW) * _animation.value;
              return Transform.translate(
                offset: Offset(-offset, 0),
                child: child,
              );
            },
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
            ),
          ),
        );
      },
    );
  }
}

/// Assessment card states for consistent, clickable UX.
/// Pre-Test: not started | finished. Post-Test: locked | available | finished.
class _AssessmentCard extends StatelessWidget {
  final String title;
  final bool isPreTest;
  final bool isFinished;
  final int? score;
  final DateTime? availableDate;
  final VoidCallback? onTap;

  const _AssessmentCard({
    required this.title,
    required this.isPreTest,
    required this.isFinished,
    this.score,
    this.availableDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !isPreTest && !isFinished && availableDate == null;
    final isAvailable = !isPreTest && !isFinished && availableDate != null;
    final isPreNotStarted = isPreTest && !isFinished;
    final cardRadius = DesignSystem.s(context, 14);
    final cardPadding = DesignSystem.s(context, 16);

    // Status copy
    final statusText = isFinished
        ? 'Completed · ${score ?? 0}%'
        : isLocked
            ? 'Available after learning'
            : isAvailable
                ? 'Ready to take'
                : isPreNotStarted
                    ? 'Not started'
                    : 'Available ${_formatDate(availableDate!)}';

    // Visual style per state
    final backgroundColor = isAvailable
        ? DesignSystem.primarySoft
        : (isLocked ? DesignSystem.bgSection : DesignSystem.cardSurface);
    final borderColor = isAvailable
        ? DesignSystem.primary
        : (isPreNotStarted ? DesignSystem.primary.withOpacity(0.4) : DesignSystem.border);
    final iconColor = isFinished
        ? DesignSystem.success
        : (isLocked ? DesignSystem.textMuted : DesignSystem.primary);
    final chevronMuted = isLocked;

    final icon = isFinished
        ? Icons.check_circle
        : isLocked
            ? Icons.lock_outline
            : (isAvailable ? Icons.flag_outlined : Icons.quiz_outlined);

    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final statusFontSize = DesignSystem.s(context, 11);
    final smallIconSize = DesignSystem.s(context, 14);

    final child = Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: decoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: DesignSystem.s(context, 15),
                        fontWeight: FontWeight.w600,
                        color: DesignSystem.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: DesignSystem.s(context, 4)),
                    Icon(
                      icon,
                      size: smallIconSize,
                      color: iconColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _SlidingStatusText(
                  statusText,
                  style: TextStyle(
                    fontSize: statusFontSize,
                    color: DesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 24,
            color: chevronMuted ? DesignSystem.textMuted : DesignSystem.textBody,
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: child,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Overlay greeting: auto-dismisses after 5s, slide up to dismiss.
class _GreetingOverlay extends StatefulWidget {
  final GreetingType type;
  final double paddingH;
  final double horizontalMargin;
  final VoidCallback onDismiss;

  const _GreetingOverlay({
    required this.type,
    required this.paddingH,
    required this.horizontalMargin,
    required this.onDismiss,
  });

  @override
  State<_GreetingOverlay> createState() => _GreetingOverlayState();
}

class _GreetingOverlayState extends State<_GreetingOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      _timer?.cancel();
      _timer = null;
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    _timer?.cancel();
    _timer = null;
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 8;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.paddingH + widget.horizontalMargin,
        topPadding,
        widget.paddingH + widget.horizontalMargin,
        0,
      ),
      child: Dismissible(
        key: ValueKey<GreetingType>(widget.type),
        direction: DismissDirection.up,
        onDismissed: (_) => _dismiss(),
        child: buildGreetingsCardWithAction(
          context: context,
          type: widget.type,
          onDismiss: _dismiss,
        ),
      ),
    );
  }
}
