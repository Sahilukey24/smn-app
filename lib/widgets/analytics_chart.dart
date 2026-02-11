import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Simple bar chart for last N posts (e.g. views or engagement).
class AnalyticsChart extends StatelessWidget {
  const AnalyticsChart({
    super.key,
    required this.values,
    this.label,
    this.barColor,
  });

  final List<double> values;
  final String? label;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('No data')));
    }
    final theme = Theme.of(context);
    final color = barColor ?? theme.colorScheme.primary;
    final maxY = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final spots = values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(label!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (values.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY * 1.1 + 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.2)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text(v.toInt().toString()))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text('${v.toInt() + 1}'))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                ),
                duration: const Duration(milliseconds: 250),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
