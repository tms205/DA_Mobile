import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

class BarChartWidget extends StatelessWidget {
  final List<double> expenses;
  final List<double> incomes;

  const BarChartWidget({
    super.key,
    required this.expenses,
    required this.incomes,
  });

  @override
  Widget build(BuildContext context) {
    final allValues = [...expenses, ...incomes];
    final maxY = allValues.isEmpty ? 1.0
        : (allValues.reduce((a, b) => a > b ? a : b) * 1.2).clamp(1.0, double.infinity);

    return Column(children: [
      Row(children: [
        const SizedBox(width: 8),
        _buildLegend(AppColors.income, 'Thu nhập'),
        const SizedBox(width: 16),
        _buildLegend(AppColors.expense, 'Chi tiêu'),
      ]),
      const SizedBox(height: 12),
      Expanded(
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barGroups: List.generate(12, (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: incomes[i],
                  color: AppColors.income,
                  width: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: expenses[i],
                  color: AppColors.expense,
                  width: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 2,
            )),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, _) => Text(
                    CurrencyFormatter.compact(value),
                    style: const TextStyle(fontSize: 9, color: AppColors.textHint),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) => Text(
                    'T${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.surfaceVariant, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  CurrencyFormatter.compact(rod.toY),
                  TextStyle(
                    color: rodIndex == 0 ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700, fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildLegend(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}
