import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categorias = [];

  String? filtroCategoria = "TODOS";

  double salario = 0;
  double totalGastos = 0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    loadData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  Future<void> loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final cat = await supabase
        .from('categories')
        .select()
        .eq('user_id', user.id);

    final exp = await supabase
        .from('expenses')
        .select('*, categories(name)')
        .eq('user_id', user.id);

    double total = 0;

    for (var e in exp) {
      total += (e['valor'] ?? 0);
    }

    setState(() {
      categorias = List<Map<String, dynamic>>.from(cat);
      expenses = List<Map<String, dynamic>>.from(exp);
      totalGastos = total;
    });
  }

  /// 💰 SALÁRIO
  void openSalaryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _glassDialog(
        title: "Definir salário",
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        onSave: () {
          setState(() {
            salario = double.tryParse(controller.text) ?? 0;
          });
        },
      ),
    );
  }

  /// ➕ NOVO GASTO + CATEGORIA
  void openExpenseDialog() {
    final desc = TextEditingController();
    final valor = TextEditingController();
    String? categoriaId;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return _glassDialog(
            title: "Novo gasto",
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: desc, decoration: const InputDecoration(labelText: "Descrição")),
                TextField(controller: valor, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Valor")),

                DropdownButtonFormField<String>(
                  hint: const Text("Categoria"),
                  items: categorias.map<DropdownMenuItem<String>>((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'].toString(),
                      child: Text(c['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) => categoriaId = v,
                ),

                TextButton(
                  onPressed: () async {
                    final controller = TextEditingController();

                    await showDialog(
                      context: context,
                      builder: (_) => _glassDialog(
                        title: "Nova categoria",
                        child: TextField(controller: controller),
                        onSave: () async {
                          final user = supabase.auth.currentUser;
                          await supabase.from('categories').insert({
                            'name': controller.text,
                            'user_id': user!.id,
                          });
                        },
                      ),
                    );

                    loadData();
                  },
                  child: const Text("+ Nova categoria"),
                ),
              ],
            ),
            onSave: () async {
              final user = supabase.auth.currentUser;
              if (user == null || categoriaId == null) return;

              await supabase.from('expenses').insert({
                'descricao': desc.text,
                'valor': double.tryParse(valor.text) ?? 0,
                'category_id': categoriaId,
                'user_id': user.id,
              });

              loadData();
            },
          );
        },
      ),
    );
  }

  /// 🧊 DIALOG GLASS
  Widget _glassDialog({
    required String title,
    required Widget child,
    required VoidCallback onSave,
  }) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.white)),
                child,
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    onSave();
                    Navigator.pop(context);
                  },
                  child: const Text("Salvar"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 CORES
  Color getColor(int index) {
    final colors = [
      Colors.cyan,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }

  /// 📊 DADOS
  Map<String, double> getChartData() {
    final Map<String, double> data = {};

    for (var e in expenses) {
      final cat = e['categories']?['name'] ?? 'Outros';

      if (filtroCategoria != "TODOS" && filtroCategoria != null && cat != filtroCategoria) continue;

      data[cat] = (data[cat] ?? 0) + (e['valor'] ?? 0);
    }

    return data;
  }

  /// 🔽 FILTRO
  Widget buildFiltro() {
    return DropdownButton<String>(
      value: filtroCategoria,
      dropdownColor: Colors.black,
      items: [
        const DropdownMenuItem(value: "TODOS", child: Text("Todos", style: TextStyle(color: Colors.white))),
        ...categorias.map((c) => DropdownMenuItem(
              value: c['name'],
              child: Text(c['name'], style: const TextStyle(color: Colors.white)),
            ))
      ],
      onChanged: (v) => setState(() => filtroCategoria = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saldo = salario - totalGastos;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Controle 💰"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Gastos"),
              Tab(text: "Gráficos"),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: openExpenseDialog,
          child: const Icon(Icons.add),
        ),

        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          child: TabBarView(
            children: [
              /// 💸 GASTOS
              Column(
                children: [
                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _controller,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          const Text("Saldo", style: TextStyle(color: Colors.white70)),
                          Text("R\$ ${saldo.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.white, fontSize: 26)),
                        ],
                      ),
                    ),
                  ),

                  buildFiltro(),

                  Expanded(
                    child: ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (_, i) {
                        final e = expenses[i];

                        return ListTile(
                          title: Text(e['descricao'] ?? '', style: const TextStyle(color: Colors.white)),
                          trailing: Text("R\$ ${e['valor']}", style: const TextStyle(color: Colors.green)),
                        );
                      },
                    ),
                  )
                ],
              ),

              /// 📊 GRÁFICO
              Center(
                child: PieChart(
                  PieChartData(
                    sections: getChartData().entries.map((e) {
                      final index = getChartData().keys.toList().indexOf(e.key);
                      return PieChartSectionData(
                        color: getColor(index),
                        value: e.value,
                        title: "R\$ ${e.value.toStringAsFixed(0)}",
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}