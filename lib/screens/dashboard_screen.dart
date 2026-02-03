import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/module_model.dart';
import '../core/app_routes.dart';
import '../core/design_system.dart';
import '../providers/app_provider.dart';
import '../services/adaptive_learning_service.dart';

/// Home/Dashboard - Design: Hello [Name], GabayAI, Modules tabs, Assessment cards
class DashboardScreen extends StatelessWidget {
  final VoidCallback? onAvatarTap;

  const DashboardScreen({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final userName = provider.user?.displayName ?? 'User';
          final preTestScore = provider.preTestResult != null
              ? (provider.preTestResult!.overallScore * 100).round()
              : null;
          final postTestAvailable = provider.canAccessPostTest;
          final postTestDate = provider.preTestResult != null
              ? provider.preTestResult!.completedAt
                  .add(const Duration(days: 60))
              : null;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: DesignSystem.maxContentWidth),
              child: CustomScrollView(
                slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Hello [Name], Welcome To GABAY
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $userName',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome To GABAY',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: onAvatarTap,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.amber.shade200,
                              child: Icon(
                                Icons.person,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // GabayAI search bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ask GabayAI your questions.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            Icon(Icons.send, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Modules section
                      const Text(
                        'Modules',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // Module tabs (horizontal scroll)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: provider.assignedModules.isEmpty
                        ? 1
                        : provider.assignedModules.length + 1,
                    itemBuilder: (context, i) {
                      final label = i == 0
                          ? 'All'
                          : 'Module ${provider.assignedModules[i - 1].order}';
                      final isSelected = i == 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: isSelected
                              ? Colors.grey.shade700
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black87,
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
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Module cards (horizontal carousel)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: provider.assignedModules.isEmpty
                      ? Center(
                          child: Text(
                            'No modules assigned. Complete pre-test first.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: provider.assignedModules.length,
                          itemBuilder: (context, i) {
                            final m = provider.assignedModules[i];
                            final done = provider.completedModuleIds.contains(m.id);
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: _ModuleCard(
                                module: m,
                                isCompleted: done,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.module,
                                  arguments: {'moduleId': m.id},
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              // Assessments section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assessments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _AssessmentCard(
                              title: 'Pre-Test',
                              isFinished: provider.hasCompletedPreTest,
                              score: preTestScore,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _AssessmentCard(
                              title: 'Post-Test',
                              isFinished: provider.hasCompletedPostTest,
                              availableDate: postTestAvailable ? postTestDate : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (provider.canAccessPostTest && provider.postTestResult == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.postTest,
                            ),
                            icon: const Icon(Icons.quiz),
                            label: const Text('Take Post-Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      if (provider.hasCompletedPostTest &&
                          AdaptiveLearningService.meetsCertificateBenchmark(
                              provider.postTestResult!))
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.certificate,
                            ),
                            icon: const Icon(Icons.workspace_premium),
                            label: const Text('View Certificate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Module ${module.order}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Read More',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: isFinished ? Colors.green.shade100 : Colors.purple.shade100,
            child: Icon(
              isFinished ? Icons.check : Icons.schedule,
              color: isFinished ? Colors.green.shade700 : Colors.purple.shade700,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFinished
                ? 'Finished | ${score ?? 0}%'
                : availableDate != null
                    ? 'Available at ${availableDate!.toString().substring(0, 10)}'
                    : 'Not available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
