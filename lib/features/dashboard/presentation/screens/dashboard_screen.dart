import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: dataAsync.when(
        data: (data) {
          final sections = data.entries.map((entry) {
            return PieChartSectionData(
              value: entry.value,
              title: entry.key,
              radius: 60,
            );
          }).toList();

          return Center(
            child: PieChart(
              PieChartData(sections: sections),
            ),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Text('Erro: $e'),
      ),
    );
  }
}