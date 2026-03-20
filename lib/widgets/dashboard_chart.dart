import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle/features/dashboard/presentation/providers/dashboard_provider.dart';

class DashboardChart extends ConsumerWidget {
  const DashboardChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('Sem dados'));
        }

        final colors = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.orange,
          Colors.purple,
        ];

        int index = 0;

        final sections = data.entries.map((entry) {
          final section = PieChartSectionData(
            value: entry.value,
            title: '',
            radius: 50,
            color: colors[index % colors.length],
          );
          index++;
          return section;
        }).toList();

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(sections: sections),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: data.entries.map((entry) {
                final i = data.keys.toList().indexOf(entry.key);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: colors[i % colors.length],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key} - R\$ ${entry.value.toStringAsFixed(2)}',
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }
}