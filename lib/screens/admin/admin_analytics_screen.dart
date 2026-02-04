import 'package:flutter/material.dart';
import '../../core/design_system.dart';

/// Admin Analytics: assessment completion, pre/post by domain, engagement.
class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

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
              'Analytics',
              style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textPrimary, fontSize: DesignSystem.appTitleSize(context)),
            ),
          ),
        ),
        backgroundColor: DesignSystem.cardSurface,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: DesignSystem.s(context, 12)),
            child: IconButton(icon: Icon(Icons.filter_list, color: DesignSystem.textSecondary, size: DesignSystem.s(context, 24)), onPressed: () {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              context,
              'Assessment Completion Overview',
              metrics: [
                _MetricRow('200 Pre-Post Test Completers', '20%', true),
                _MetricRow('50% Pre-Test Average Score(%)', null, false),
                _MetricRow('90% Post-Test Average Score(%)', null, false),
                _MetricRow('40% Knowledge Improvement', '↑', true),
              ],
            ),
            SizedBox(height: DesignSystem.adminSectionGap(context)),
            _buildCard(
              context,
              'Pre-Test vs Post-Test (Domain)',
              subtitle: 'Comparison of average scores across learning modules.',
              child: SizedBox(
                height: DesignSystem.adminChartHeight(context),
                child: _BarChartPlaceholder(
                  labels: const ['Module 1', 'Module 2', 'Module 3', 'Module 4'],
                  preValues: const [40.0, 55.0, 50.0, 45.0],
                  postValues: const [85.0, 90.0, 88.0, 82.0],
                ),
              ),
            ),
            SizedBox(height: DesignSystem.adminSectionGap(context)),
            _buildCard(
              context,
              'Engagement Metrics',
              metrics: [
                _MetricRow('12 Average Module per User', null, false),
                _MetricRow('38 Average Time Spent per Module(min)', null, false),
                _MetricRow('189 Total Modules Completed', null, false),
                _MetricRow('70% Module Completion Rate', null, false),
              ],
            ),
            SizedBox(height: DesignSystem.adminSectionGap(context)),
            _buildCard(
              context,
              'Engagement vs Learning',
              child: SizedBox(
                height: DesignSystem.adminChartHeight(context) * 0.9,
                child: CustomPaint(
                  painter: _ScatterPlaceholderPainter(),
                  size: Size(DesignSystem.width(context), DesignSystem.adminChartHeight(context) * 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title, {
    List<_MetricRow>? metrics,
    String? subtitle,
    Widget? child,
  }) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: DesignSystem.sectionTitleSize(context),
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.filter_list, size: 20, color: DesignSystem.textMuted),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: DesignSystem.s(context, 4)),
            Text(subtitle, style: TextStyle(fontSize: DesignSystem.captionSize(context), color: DesignSystem.textSecondary)),
          ],
          if (metrics != null) ...[
            SizedBox(height: DesignSystem.adminGridGap(context)),
            ...metrics.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m.label, style: TextStyle(fontSize: DesignSystem.bodyTextSize(context), color: DesignSystem.textPrimary)),
                      if (m.trend != null)
                        Text(
                          m.trend!,
                          style: TextStyle(
                            fontSize: DesignSystem.captionSize(context),
                            color: m.positive == true ? Colors.green : DesignSystem.textMuted,
                          ),
                        ),
                    ],
                  ),
                )),
          ],
          if (child != null) ...[
            SizedBox(height: DesignSystem.adminGridGap(context)),
            child,
          ],
        ],
      ),
    );
  }
}

class _MetricRow {
  final String label;
  final String? trend;
  final bool positive;
  _MetricRow(this.label, this.trend, this.positive);
}

class _BarChartPlaceholder extends StatelessWidget {
  final List<String> labels;
  final List<double> preValues;
  final List<double> postValues;

  const _BarChartPlaceholder({required this.labels, required this.preValues, required this.postValues});

  @override
  Widget build(BuildContext context) {
    final maxVal = 100.0;
    final barW = DesignSystem.s(context, 12);
    return LayoutBuilder(
      builder: (_, constraints) {
        final chartH = constraints.maxHeight;
        final barMaxH = chartH * 0.5;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(labels.length, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignSystem.s(context, 4)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: barW,
                          height: (preValues[i] / maxVal) * barMaxH,
                          margin: EdgeInsets.only(right: DesignSystem.s(context, 2)),
                          decoration: BoxDecoration(
                            color: DesignSystem.secondary.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Container(
                          width: barW,
                          height: (postValues[i] / maxVal) * barMaxH,
                          decoration: BoxDecoration(
                            color: DesignSystem.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignSystem.adminGridGap(context) * 0.5),
                    Text(
                      labels[i],
                      style: TextStyle(fontSize: DesignSystem.captionSize(context), color: DesignSystem.textSecondary),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ScatterPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignSystem.secondary.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 24; i++) {
      final x = (i % 6) * (size.width / 6) + size.width / 12;
      final y = size.height - (i * 0.04 * size.height).clamp(20.0, size.height - 20);
      canvas.drawCircle(Offset(x, y), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
