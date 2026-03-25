import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphsPage extends StatefulWidget {
  const GraphsPage({super.key});

  @override
  State<GraphsPage> createState() => _GraphsPageState();
}

class _GraphsPageState extends State<GraphsPage> {
  final supabase = Supabase.instance.client;

  Map<String, double> dataMap = {};

  final List<Color> cores = [
    Colors.deepPurple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final user = supabase.auth.currentUser;

    final response = await supabase
        .from('expenses')
        .select()
        .eq('user_id', user!.id);

    final list = List<Map<String, dynamic>>.from(response);

    Map<String, double> temp = {};

    for (var item in list) {
      final name = item['name'] ?? 'Outros';
      final value = (item['amount'] as num).toDouble();

      temp[name] = (temp[name] ?? 0) + value;
    }

    setState(() {
      dataMap = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = dataMap.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gráficos"),
        backgroundColor: Colors.deepPurple,
      ),
      body: dataMap.isEmpty
          ? const Center(child: Text("Sem dados ainda"))
          : Column(
              children: [
                const SizedBox(height: 20),

                // 🔥 TOTAL
                Text(
                  "Total: R\$ ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                // 🔥 GRÁFICO
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 80,
                      sections: dataMap.entries.toList().asMap().entries.map((e) {
                        final index = e.key;
                        final entry = e.value;

                        final porcentagem = (entry.value / total) * 100;

                        return PieChartSectionData(
                          color: cores[index % cores.length],
                          value: entry.value,
                          title: "${porcentagem.toStringAsFixed(0)}%",
                          radius: 90,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                    swapAnimationDuration:
                        const Duration(milliseconds: 800), // 🔥 animação
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 LEGENDA
                Expanded(
                  child: ListView(
                    children: dataMap.entries.toList().asMap().entries.map((e) {
                      final index = e.key;
                      final entry = e.value;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cores[index % cores.length],
                        ),
                        title: Text(entry.key),
                        trailing:
                            Text("R\$ ${entry.value.toStringAsFixed(2)}"),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
    );
  }
}