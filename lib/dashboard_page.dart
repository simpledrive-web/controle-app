import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:controle/utils/ui_helpers.dart';

class DashboardPage extends StatelessWidget {
  final List gastos;
  final List categorias;
  final double saldo;

  const DashboardPage(this.gastos, this.categorias, this.saldo, {super.key});

  Map<String, double> porCategoria() {
    Map<String, double> data = {};

    for (var g in gastos) {
      final cat = categorias.firstWhere(
        (c) => c['id'].toString() == g['category_id'].toString(),
        orElse: () => {'name': 'Outros'},
      );

      data[cat['name']] = (data[cat['name']] ?? 0) + (g['amount'] ?? 0);
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final data = porCategoria();
    final total = data.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔥 CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.indigo],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("Total gasto",
                      style: TextStyle(color: Colors.white70)),
                  Text(
                    "R\$ ${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔥 PIZZA COLORIDA
            Expanded(
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 60,
                  sections: data.entries.map((e) {
                    final percent = (e.value / total) * 100;
                    final cor = getCategoriaCor(e.key);

                    return PieChartSectionData(
                      color: cor,
                      value: e.value,
                      title: "${percent.toStringAsFixed(0)}%",
                      radius: 90,
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 LEGENDA BONITA
            ...data.entries.map((e) {
              final cor = getCategoriaCor(e.key);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 6,
                      backgroundColor: cor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key)),
                    Text("R\$ ${e.value.toStringAsFixed(2)}"),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}