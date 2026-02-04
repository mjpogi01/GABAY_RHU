import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/module_model.dart';
import '../core/app_routes.dart';
import '../core/design_system.dart';
import '../providers/app_provider.dart';

/// Home - Standardized layout matching design
class DashboardScreen extends StatelessWidget {
  final VoidCallback? onAvatarTap;

  const DashboardScreen({super.key, this.onAvatarTap});

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
          final postTestAvailable = provider.canAccessPostTest;
          final postTestDate = provider.preTestResult?.completedAt
                  .add(const Duration(days: 60));

          // Build module tabs list
          final allModules = provider.assignedModules;
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignSystem.s(context, 24),
                    MediaQuery.of(context).padding.top + DesignSystem.s(context, 16),
                    DesignSystem.s(context, 24),
                    DesignSystem.s(context, 4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Hello [Name], Welcome To GABAY
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $userName',
                                  style: TextStyle(
                                    fontSize: DesignSystem.s(context, 28),
                                    fontWeight: FontWeight.bold,
                                    color: DesignSystem.textPrimary,
                                  ),
                                ),
                                SizedBox(height: DesignSystem.s(context, 4)),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: DesignSystem.sectionTitleSize(context),
                                      color: DesignSystem.textSecondary,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Welcome To '),
                                      TextSpan(
                                        text: 'GABAY',
                                        style: TextStyle(
                                          color: DesignSystem.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: DesignSystem.s(context, 12)),
                          GestureDetector(
                            onTap: onAvatarTap,
                            child: CircleAvatar(
                              radius: DesignSystem.s(context, 24),
                              backgroundColor: Colors.amber.shade200,
                              child: Icon(
                                Icons.person,
                                color: Colors.grey.shade700,
                                size: DesignSystem.s(context, 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: DesignSystem.spacingMedium(context)),
                      // GabayAI search bar
                      Container(
                        padding: DesignSystem.inputPadding,
                        decoration: BoxDecoration(
                          color: DesignSystem.cardSurface,
                          borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
                          border: Border.all(color: DesignSystem.inputBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ask GabayAI your questions.',
                                style: TextStyle(
                                  fontSize: DesignSystem.inputTextSize(context),
                                  color: DesignSystem.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            SizedBox(width: DesignSystem.s(context, 8)),
                            Icon(
                              Icons.send,
                              color: DesignSystem.textMuted,
                              size: DesignSystem.s(context, 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: DesignSystem.spacingSmall(context)),
              ),
              // Assessment section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: DesignSystem.s(context, 24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessment',
                        style: TextStyle(
                          fontSize: DesignSystem.sectionTitleSize(context),
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.textPrimary,
                        ),
                      ),
                      SizedBox(height: DesignSystem.spacingSmall(context)),
                      _AssessmentCard(
                        title: 'Pre-Test',
                        isFinished: provider.hasCompletedPreTest,
                        score: preTestScore,
                      ),
                      SizedBox(height: DesignSystem.spacingSmall(context)),
                      _AssessmentCard(
                        title: 'Post-Test',
                        isFinished: provider.hasCompletedPostTest,
                        availableDate: postTestAvailable ? postTestDate : null,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: DesignSystem.spacingLarge(context)),
              ),
              // Modules section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: DesignSystem.s(context, 24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modules',
                        style: TextStyle(
                          fontSize: DesignSystem.sectionTitleSize(context),
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.textPrimary,
                        ),
                      ),
                      SizedBox(height: DesignSystem.spacingSmall(context)),
                    ],
                  ),
                ),
              ),
              // Module tabs (horizontal scroll)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: DesignSystem.s(context, 44),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: DesignSystem.s(context, 24)),
                    itemCount: 5, // Module 1-5
                    itemBuilder: (context, i) {
                      final moduleNumber = i + 1;
                      final isSelected = moduleNumber == 2; // Module 2 is selected
                      
                      return Padding(
                        padding: EdgeInsets.only(right: DesignSystem.s(context, 8)),
                        child: Material(
                          color: isSelected ? DesignSystem.textPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(DesignSystem.s(context, 8)),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(DesignSystem.s(context, 8)),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: DesignSystem.s(context, 16),
                                vertical: DesignSystem.s(context, 12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Module $moduleNumber',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: DesignSystem.bodyTextSize(context),
                                  color: isSelected ? Colors.white : DesignSystem.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: DesignSystem.spacingMedium(context)),
              ),
              // Module cards (horizontal scrollable)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: DesignSystem.s(context, 200),
                  child: allModules.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: DesignSystem.s(context, 24)),
                          child: Container(
                            padding: EdgeInsets.all(DesignSystem.spacingLarge(context)),
                            decoration: BoxDecoration(
                              color: DesignSystem.cardSurface,
                              borderRadius: BorderRadius.circular(DesignSystem.s(context, 16)),
                            ),
                            child: Center(
                              child: Text(
                                'No modules assigned yet.',
                                style: TextStyle(
                                  color: DesignSystem.textMuted,
                                  fontSize: DesignSystem.bodyTextSize(context),
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: DesignSystem.s(context, 24)),
                          itemCount: allModules.length,
                          itemBuilder: (context, i) {
                            final module = allModules[i];
                            final isCompleted = provider.completedModuleIds.contains(module.id);
                            return Padding(
                              padding: EdgeInsets.only(right: DesignSystem.spacingMedium(context)),
                              child: _buildModuleDetailCard(
                                context,
                                module,
                                isCompleted,
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.module,
                                  arguments: {'moduleId': module.id},
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
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
    final previewText = module.cards.isNotEmpty
        ? module.cards.first.content
        : '';
    final shortPreview = previewText.length > 80
        ? '${previewText.substring(0, 80)}...'
        : previewText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: DesignSystem.s(context, 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignSystem.s(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, DesignSystem.s(context, 4)),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignSystem.s(context, 16)),
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
                borderRadius: BorderRadius.circular(DesignSystem.s(context, 16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(DesignSystem.spacingMedium(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Module ${module.order}',
                    style: TextStyle(
                      fontSize: DesignSystem.captionSize(context),
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: TextStyle(
                          fontSize: DesignSystem.s(context, 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (shortPreview.isNotEmpty) ...[
                        SizedBox(height: DesignSystem.s(context, 4)),
                        Text(
                          shortPreview,
                          style: TextStyle(
                            fontSize: DesignSystem.captionSize(context),
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: DesignSystem.s(context, 8)),
                      Text(
                        'Read more',
                        style: TextStyle(
                          fontSize: DesignSystem.bodyTextSize(context),
                          color: DesignSystem.primary,
                          fontWeight: FontWeight.w600,
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

class _AssessmentCard extends StatelessWidget {
  final String title;
  final bool isFinished;
  final int? score;
  final DateTime? availableDate;

  const _AssessmentCard({
    required this.title,
    required this.isFinished,
    this.score,
    this.availableDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacingMedium(context)),
      decoration: BoxDecoration(
        color: DesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(DesignSystem.s(context, 16)),
        border: Border.all(color: DesignSystem.inputBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: DesignSystem.buttonTextSize(context),
              fontWeight: FontWeight.bold,
              color: DesignSystem.textPrimary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: DesignSystem.s(context, 20),
                backgroundColor: isFinished ? Colors.green.shade100 : Colors.purple.shade100,
                child: Icon(
                  isFinished ? Icons.check : Icons.schedule,
                  color: isFinished ? Colors.green.shade700 : Colors.purple.shade700,
                  size: DesignSystem.s(context, 24),
                ),
              ),
              SizedBox(width: DesignSystem.spacingSmall(context)),
              Text(
                isFinished
                    ? 'Finished | ${score ?? 0}%'
                    : availableDate != null
                        ? 'Available at ${_formatDate(availableDate!)}'
                        : 'Not available',
                style: TextStyle(
                  fontSize: DesignSystem.bodyTextSize(context),
                  color: DesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
