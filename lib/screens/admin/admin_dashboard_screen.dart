import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system.dart';
import '../../core/app_routes.dart';
import '../../providers/app_provider.dart';

/// Admin dashboard: KPIs, User Status Breakdown, action buttons.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: DesignSystem.s(context, 12)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textPrimary, fontSize: DesignSystem.appTitleSize(context)),
            ),
          ),
        ),
        backgroundColor: DesignSystem.cardSurface,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: DesignSystem.s(context, 12)),
            child: PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: DesignSystem.wRatio(context, 18 / 375),
              backgroundColor: DesignSystem.accentYellow,
              child: Icon(Icons.person, color: Colors.grey.shade700, size: DesignSystem.wRatio(context, 24 / 375)),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AppProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
              }
            },
            itemBuilder: (_) => [const PopupMenuItem(value: 'logout', child: Text('Logout'))],
          ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKpiGrid(context),
            SizedBox(height: DesignSystem.adminSectionGap(context)),
            _buildUserStatusCard(context),
            SizedBox(height: DesignSystem.adminSectionGap(context)),
            _buildActionGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context) {
    final kpis = [
      _Kpi('Total Users', '200', '+10%', true),
      _Kpi('Pre-Test Participation', '75%', null, false),
      _Kpi('Post-Test Completion', '75%', null, false),
      _Kpi('Pre-Test vs Post-Test Scores(%)', '40%', '↑', true),
      _Kpi('Average Time Spent/Module', '58mins', null, false),
      _Kpi('User Feedback', '4.5', '★', false),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: DesignSystem.adminGridGap(context),
      crossAxisSpacing: DesignSystem.adminGridGap(context),
      childAspectRatio: DesignSystem.adminKpiAspectRatio,
      children: kpis.map((k) => _kpiCard(context, k)).toList(),
    );
  }

  Widget _kpiCard(BuildContext context, _Kpi k) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.adminContentPadding(context) * 0.7),
      decoration: BoxDecoration(
        color: DesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            k.label,
            style: TextStyle(fontSize: DesignSystem.captionSize(context), color: DesignSystem.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                k.value,
                style: TextStyle(
                  fontSize: DesignSystem.sectionTitleSize(context),
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textPrimary,
                ),
              ),
              if (k.trend != null) ...[
                const SizedBox(width: 4),
                Text(
                  k.trend!,
                  style: TextStyle(
                    fontSize: DesignSystem.captionSize(context),
                    color: k.positive == true ? Colors.green : DesignSystem.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusCard(BuildContext context) {
    final chartSize = DesignSystem.adminPieChartSize(context);
    return Container(
      padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
      decoration: BoxDecoration(
        color: DesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Status Breakdown',
            style: TextStyle(
              fontSize: DesignSystem.sectionTitleSize(context),
              fontWeight: FontWeight.bold,
              color: DesignSystem.textPrimary,
            ),
          ),
          SizedBox(height: DesignSystem.adminGridGap(context)),
          Row(
            children: [
              SizedBox(
                width: chartSize,
                height: chartSize,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    segments: [
                      (0.5, const Color(0xFF6B4E9E)),
                      (0.3, const Color(0xFF4A90D9)),
                      (0.2, const Color(0xFF5CB85C)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: DesignSystem.adminContentPadding(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendRow(context, 'Expecting Mother', const Color(0xFF6B4E9E)),
                    _legendRow(context, 'New Mother', const Color(0xFF4A90D9)),
                    _legendRow(context, 'Caregiver/Guardian', const Color(0xFF5CB85C)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(BuildContext context, String label, Color color) {
    final dot = DesignSystem.s(context, 12);
    return Padding(
      padding: EdgeInsets.only(bottom: DesignSystem.s(context, 6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: dot, height: dot, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: DesignSystem.s(context, 8)),
          Flexible(child: Text(label, style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), color: DesignSystem.textSecondary), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      _ActionItem(Icons.add_box_outlined, 'Create a New Card', () {}),
      _ActionItem(Icons.edit_outlined, 'Edit Pre/Post Tests', () {}),
      _ActionItem(Icons.bar_chart_outlined, 'View Test Results', () {}),
      _ActionItem(Icons.smart_toy_outlined, 'Ask GabayAI', () {}),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: DesignSystem.adminGridGap(context),
      crossAxisSpacing: DesignSystem.adminGridGap(context),
      childAspectRatio: DesignSystem.adminActionAspectRatio,
      children: actions.map((a) => _actionCard(context, a)).toList(),
    );
  }

  Widget _actionCard(BuildContext context, _ActionItem a) {
    return Material(
      color: DesignSystem.cardSurface,
      borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context)),
      child: InkWell(
        onTap: a.onTap,
        borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context)),
        child: Container(
          padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context)),
            border: Border.all(color: DesignSystem.inputBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(a.icon, size: DesignSystem.s(context, 32), color: DesignSystem.primary),
              SizedBox(height: DesignSystem.adminGridGap(context)),
              Text(
                a.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: DesignSystem.bodyTextSize(context),
                  fontWeight: FontWeight.w600,
                  color: DesignSystem.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final String? trend;
  final bool? positive;
  _Kpi(this.label, this.value, this.trend, this.positive);
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ActionItem(this.icon, this.label, this.onTap);
}

class _PieChartPainter extends CustomPainter {
  final List<(double, Color)> segments;

  _PieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, size.height / 2);
    double start = -0.25 * 3.14159;
    for (final s in segments) {
      final sweep = s.$1 * 2 * 3.14159;
      final paint = Paint()..color = s.$2..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, sweep, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
