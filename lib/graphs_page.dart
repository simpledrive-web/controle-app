import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphsPage extends StatelessWidget {
  final List gastos;
  final List categorias;

  const GraphsPage(this.gastos, this.categorias, {super.key});

  Color getColor(String? color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> dados = {};
    Map<String, Color> cores = {};

    // 🔥 AGRUPAR DADOS
    for (var g in gastos) {
      final valor = (g['amount'] ?? 0).toDouble();

      final cat = categorias.firstWhere(
        (c) => c['id'].toString() ==
            g['category_id'].toString(),
        orElse: () => {
          'name': 'Outros',
          'color': 'blue'
        },
      );

      final nome = cat['name'] ?? 'Outros';

      dados[nome] = (dados[nome] ?? 0) + valor;
      cores[nome] = getColor(cat['color']);
    }

    final total = dados.values.fold(0.0, (a, b) => a + b);

    final sections = dados.entries.map((e) {
      final porcentagem =
          total == 0 ? 0 : (e.value / total * 100);

      return PieChartSectionData(
        value: e.value,
        title: "${porcentagem.toStringAsFixed(0)}%",
        color: cores[e.key],
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard 📊"),
      ),
      body: Container(
        color: const Color(0xFFD6EAF8), // azul bebê
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔥 TOTAL
            Text(
              "Total gasto: R\$ ${total.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 GRÁFICO PIZZA
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 LEGENDA BONITA
            Expanded(
              child: ListView(
                children: dados.entries.map((e) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cores[e.key],
                    ),
                    title: Text(e.key),
                    trailing: Text(
                      "R\$ ${e.value.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 GRÁFICO DE BARRAS
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: dados.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final value = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value.value,
                          color: cores[value.key],
                          width: 18,
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}