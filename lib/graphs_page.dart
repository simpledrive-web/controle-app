import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

Color getCategoryColor(String nome) {
  final colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];
  return colors[nome.hashCode % colors.length];
}

class GraphsPage extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;

  const GraphsPage({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    Map<String, double> data = {};

    for (var e in expenses) {
      final nome = e['categories']?['nome'] ?? 'Sem categoria';
      data[nome] = (data[nome] ?? 0) + (e['valor'] ?? 0);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Gráficos 📊")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// GRAFICO ANIMADO
          Expanded(
            child: PieChart(
              PieChartData(
                sections: data.entries.map((e) {
                  return PieChartSectionData(
                    value: e.value,
                    title: "",
                    radius: 80,
                    color: getCategoryColor(e.key),
                  );
                }).toList(),
                centerSpaceRadius: 40,
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),

          /// LEGENDA COLORIDA
          ...data.entries.map((e) {
            final cor = getCategoryColor(e.key);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: cor),
                      const SizedBox(width: 8),
                      Text(e.key, style: TextStyle(color: cor)),
                    ],
                  ),
                  Text("R\$ ${e.value.toStringAsFixed(2)}"),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}