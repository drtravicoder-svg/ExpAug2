import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../business_logic/services/analytics_service.dart';
import '../../../core/utils/formatters.dart';

/// Pie chart for expense categories
class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final Map<String, String> categoryNames;
  final double size;

  const CategoryPieChart({
    super.key,
    required this.categoryData,
    required this.categoryNames,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (categoryData.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            'No data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);
    final colors = _generateColors(categoryData.length);
    
    return SizedBox(
      width: size,
      height: size,
      child: PieChart(
        PieChartData(
          sections: categoryData.entries.map((entry) {
            final index = categoryData.keys.toList().indexOf(entry.key);
            final percentage = (entry.value / total) * 100;
            
            return PieChartSectionData(
              value: entry.value,
              title: '${percentage.toStringAsFixed(1)}%',
              color: colors[index % colors.length],
              radius: size * 0.3,
              titleStyle: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: size * 0.15,
          startDegreeOffset: -90,
        ),
      ),
    );
  }

  List<Color> _generateColors(int count) {
    return [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFECA57),
      const Color(0xFFFF9FF3),
      const Color(0xFF54A0FF),
      const Color(0xFF5F27CD),
    ];
  }
}

/// Line chart for daily spending
class DailySpendingChart extends StatelessWidget {
  final Map<DateTime, double> dailyData;
  final double height;

  const DailySpendingChart({
    super.key,
    required this.dailyData,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (dailyData.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No spending data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final maxY = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedEntries.length) {
                    final date = sortedEntries[index].key;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        '${date.day}/${date.month}',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: maxY / 5,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      CurrencyFormatter.formatCompact(value),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          minX: 0,
          maxX: (sortedEntries.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: sortedEntries.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar chart for member spending
class MemberSpendingChart extends StatelessWidget {
  final Map<String, double> memberData;
  final Map<String, String> memberNames;
  final double height;

  const MemberSpendingChart({
    super.key,
    required this.memberData,
    required this.memberNames,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (memberData.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No member data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final sortedEntries = memberData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxY = sortedEntries.first.value;
    
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: theme.colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final memberName = memberNames[sortedEntries[group.x].key] ?? 'Unknown';
                return BarTooltipItem(
                  '$memberName\n${CurrencyFormatter.format(rod.toY)}',
                  theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedEntries.length) {
                    final memberId = sortedEntries[index].key;
                    final memberName = memberNames[memberId] ?? 'Unknown';
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        memberName.length > 8 ? '${memberName.substring(0, 8)}...' : memberName,
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: maxY / 5,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      CurrencyFormatter.formatCompact(value),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: sortedEntries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: theme.colorScheme.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Spending trend indicator
class SpendingTrendIndicator extends StatelessWidget {
  final SpendingTrend trend;
  final double confidence;

  const SpendingTrendIndicator({
    super.key,
    required this.trend,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    IconData icon;
    Color color;
    String text;
    
    switch (trend) {
      case SpendingTrend.increasing:
        icon = Icons.trending_up;
        color = theme.colorScheme.error;
        text = 'Spending is increasing';
        break;
      case SpendingTrend.decreasing:
        icon = Icons.trending_down;
        color = Colors.green;
        text = 'Spending is decreasing';
        break;
      case SpendingTrend.stable:
        icon = Icons.trending_flat;
        color = theme.colorScheme.primary;
        text = 'Spending is stable';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Budget progress indicator
class BudgetProgressIndicator extends StatelessWidget {
  final BudgetAnalysis budgetAnalysis;

  const BudgetProgressIndicator({
    super.key,
    required this.budgetAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color progressColor;
    switch (budgetAnalysis.status) {
      case BudgetStatus.onTrack:
        progressColor = Colors.green;
        break;
      case BudgetStatus.nearLimit:
        progressColor = Colors.orange;
        break;
      case BudgetStatus.overBudget:
        progressColor = theme.colorScheme.error;
        break;
    }
    
    final progress = (budgetAnalysis.percentageUsed / 100).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${budgetAnalysis.percentageUsed.toStringAsFixed(1)}%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ${CurrencyFormatter.format(budgetAnalysis.spent)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Budget: ${CurrencyFormatter.format(budgetAnalysis.budget)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (budgetAnalysis.remaining > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Remaining: ${CurrencyFormatter.format(budgetAnalysis.remaining)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
            ),
          ),
        ] else if (budgetAnalysis.remaining < 0) ...[
          const SizedBox(height: 4),
          Text(
            'Over budget by: ${CurrencyFormatter.format(-budgetAnalysis.remaining)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
