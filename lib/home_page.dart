import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'graphs_page.dart';
import 'pdf_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categorias = [];

  double saldo = 0;
  double totalDespesas = 0;

  String mesSelecionado = "Todos";
  String categoriaSelecionada = "Todas";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future loadData() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('expenses')
        .select()
        .eq('user_id', user!.id);

    final cats = await supabase
        .from('categories')
        .select()
        .eq('user_id', user.id);

    expenses = List<Map<String, dynamic>>.from(data);
    categorias = List<Map<String, dynamic>>.from(cats);

    final balance = await supabase
        .from('balance')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    saldo = balance?['amount']?.toDouble() ?? 0;

    aplicarFiltro();

    setState(() {});
  }

  void aplicarFiltro() {
    List<Map<String, dynamic>> filtrados = expenses;

    if (mesSelecionado != "Todos") {
      filtrados = filtrados.where((e) {
        final d = DateTime.parse(e['created_at']);
        return d.month.toString() == mesSelecionado;
      }).toList();
    }

    if (categoriaSelecionada != "Todas") {
      filtrados = filtrados.where((e) {
        final cat = categorias.firstWhere(
          (c) => c['id'].toString() == e['category_id'].toString(),
          orElse: () => {},
        );
        return cat['name'] == categoriaSelecionada;
      }).toList();
    }

    totalDespesas = filtrados.fold(
        0, (sum, e) => sum + (e['amount'] as num).toDouble());
  }

  void adicionarSaldo() {
    final valor = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Adicionar saldo"),
        content: TextField(
          controller: valor,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final v = double.tryParse(valor.text) ?? 0;
              final user = supabase.auth.currentUser;

              final existing = await supabase
                  .from('balance')
                  .select()
                  .eq('user_id', user!.id)
                  .maybeSingle();

              final atual = existing?['amount']?.toDouble() ?? 0;

              await supabase.from('balance').upsert(
                {
                  'user_id': user.id,
                  'amount': atual + v,
                },
                onConflict: 'user_id',
              );

              Navigator.pop(context);
              loadData();
            },
            child: const Text("Salvar"),
          )
        ],
      ),
    );
  }

  void novaCategoria() {
    final nome = TextEditingController();
    String cor = "blue";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nova categoria"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nome),
            DropdownButtonFormField<String>(
              value: cor,
              items: ["blue", "red", "green", "orange", "purple"]
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (v) => cor = v!,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await supabase.from('categories').insert({
                'name': nome.text,
                'color': cor,
                'emoji': '💰',
                'user_id': supabase.auth.currentUser!.id,
              });

              Navigator.pop(context);
              loadData();
            },
            child: const Text("Salvar"),
          )
        ],
      ),
    );
  }

  void novoGasto() {
    final nome = TextEditingController();
    final valor = TextEditingController();
    String? catId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Novo gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nome),
            TextField(controller: valor, keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              items: categorias.map((c) {
                return DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text("${c['emoji']} ${c['name']}"),
                );
              }).toList(),
              onChanged: (v) => catId = v,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final v = double.tryParse(valor.text);
              if (v == null || catId == null) return;

              final user = supabase.auth.currentUser;

              await supabase.from('expenses').insert({
                'name': nome.text,
                'amount': v,
                'category_id': catId,
                'user_id': user!.id,
                'created_at': DateTime.now().toIso8601String(),
              });

              final existing = await supabase
                  .from('balance')
                  .select()
                  .eq('user_id', user.id)
                  .maybeSingle();

              final atual = existing?['amount']?.toDouble() ?? 0;

              await supabase.from('balance').upsert(
                {
                  'user_id': user.id,
                  'amount': atual - v,
                },
                onConflict: 'user_id',
              );

              Navigator.pop(context);
              loadData();
            },
            child: const Text("Salvar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> listaFiltrada = expenses;

    if (mesSelecionado != "Todos") {
      listaFiltrada = listaFiltrada.where((e) {
        final d = DateTime.parse(e['created_at']);
        return d.month.toString() == mesSelecionado;
      }).toList();
    }

    if (categoriaSelecionada != "Todas") {
      listaFiltrada = listaFiltrada.where((e) {
        final cat = categorias.firstWhere(
          (c) => c['id'].toString() == e['category_id'].toString(),
          orElse: () => {},
        );
        return cat['name'] == categoriaSelecionada;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Controle 💜",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => gerarPDF(listaFiltrada, categorias),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GraphsPage()));
            },
          ),

          // 🔥 LOGOUT ADICIONADO
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirmar = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Sair"),
                  content: const Text("Deseja sair da conta?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Sair"),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                await supabase.auth.signOut();
              }
            },
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: adicionarSaldo,
              child: const Icon(Icons.attach_money)),
          const SizedBox(height: 10),
          FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: novaCategoria,
              child: const Icon(Icons.category)),
          const SizedBox(height: 10),
          FloatingActionButton(
              onPressed: novoGasto, child: const Icon(Icons.add)),
        ],
      ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff6a11cb), Color(0xff2575fc)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text("Saldo: R\$ ${saldo.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white)),
                Text("Despesas: R\$ ${totalDespesas.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton(
                value: mesSelecionado,
                items: ["Todos", "1", "2", "3", "4", "5", "6"]
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text("Mês $m")))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    mesSelecionado = v!;
                    aplicarFiltro();
                  });
                },
              ),
              DropdownButton(
                value: categoriaSelecionada,
                items: [
                  "Todas",
                  ...categorias.map((c) => c['name'] as String)
                ]
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    categoriaSelecionada = v!;
                    aplicarFiltro();
                  });
                },
              ),
            ],
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: listaFiltrada.length,
              itemBuilder: (_, i) {
                final item = listaFiltrada[i];

                final cat = categorias.firstWhere(
                    (c) =>
                        c['id'].toString() ==
                        item['category_id'].toString(),
                    orElse: () => {});

                return Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(cat['emoji'] ?? "💰"),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item['name'] ?? "")),
                        Text("- R\$ ${item['amount']}",
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}