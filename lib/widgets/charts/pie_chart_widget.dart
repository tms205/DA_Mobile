import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';

class PieChartWidget extends StatefulWidget {
  final Map<String, double> dataMap;
  final List<Color> colorList;

  const PieChartWidget({
    super.key,
    required this.dataMap,
    required this.colorList,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.dataMap.isEmpty) {
      return Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: AppColors.hint(isDark))));
    }

    final entries = widget.dataMap.entries.toList();
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    return Row(children: [
      Expanded(
        flex: 3,
        child: PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            sections: entries.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final isTouched = i == _touchedIndex;
              final radius = isTouched ? 80.0 : 65.0;
              final pct = total > 0 ? (e.value / total * 100) : 0.0;
              final color = widget.colorList[i % widget.colorList.length];

              return PieChartSectionData(
                value: e.value,
                color: color,
                radius: radius,
                title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                titleStyle: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                badgeWidget: isTouched ? null : null,
              );
            }).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 30,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final color = widget.colorList[i % widget.colorList.length];
            final pct = total > 0 ? (e.value / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${e.key} (${pct.toStringAsFixed(0)}%)',
                      style: TextStyle(fontSize: 11, color: AppColors.txtSec(isDark)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}
