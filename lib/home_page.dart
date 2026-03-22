import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'graphs_page.dart';
import 'pdf_service.dart';

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> categorias = [];
  List<Map<String, dynamic>> gastos = [];

  String filtroCategoria = "Todos";
  double saldo = 0;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  // ================= LOAD =================
  Future carregar() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final cat = await supabase
        .from('categories')
        .select()
        .eq('user_id', user.id);

    final exp = await supabase
        .from('expenses')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    var saldoData = await supabase
        .from('user_data')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (saldoData == null) {
      await supabase.from('user_data').insert({
        'user_id': user.id,
        'saldo': 0,
      });
      saldoData = {'saldo': 0};
    }

    setState(() {
      categorias = List<Map<String, dynamic>>.from(cat);
      gastos = List<Map<String, dynamic>>.from(exp);
      saldo = (saldoData?['saldo'] ?? 0).toDouble();
    });
  }

  // ================= ICON MAP =================
  IconData getIcon(String? name) {
    switch (name) {
      case 'food':
        return Icons.restaurant;
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }

  Color getColor(String? color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ================= NOVO GASTO =================
  void novoGasto() {
    final desc = TextEditingController();
    final valor = TextEditingController();
    String? categoriaSelecionada;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text("Novo gasto"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: desc, decoration: const InputDecoration(labelText: "Descrição")),
                TextField(controller: valor, keyboardType: TextInputType.number),
                DropdownButton<String>(
                  hint: const Text("Categoria"),
                  value: categoriaSelecionada,
                  isExpanded: true,
                  items: categorias.map<DropdownMenuItem<String>>((c) {
                    return DropdownMenuItem(
                      value: c['id'].toString(),
                      child: Text(c['name']),
                    );
                  }).toList(),
                  onChanged: (v) => setModalState(() => categoriaSelecionada = v),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final user = supabase.auth.currentUser;
                  final v = double.tryParse(valor.text) ?? 0;

                  if (categoriaSelecionada == null) return;

                  await supabase.from('expenses').insert({
                    'description': desc.text,
                    'amount': v,
                    'category_id': categoriaSelecionada,
                    'user_id': user!.id,
                  });

                  await supabase.from('user_data').update({
                    'saldo': saldo - v,
                  }).eq('user_id', user.id);

                  Navigator.pop(context);
                  carregar();
                },
                child: const Text("Salvar"),
              )
            ],
          );
        },
      ),
    );
  }

  // ================= SALDO =================
  void adicionarSaldo() {
    final valor = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Adicionar saldo"),
        content: TextField(controller: valor),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final user = supabase.auth.currentUser;
              final v = double.tryParse(valor.text) ?? 0;

              await supabase.from('user_data').update({
                'saldo': saldo + v,
              }).eq('user_id', user!.id);

              Navigator.pop(context);
              carregar();
            },
            child: const Text("Salvar"),
          )
        ],
      ),
    );
  }

  // ================= NOVA CATEGORIA =================
  void novaCategoria() {
    final nome = TextEditingController();
    String cor = 'blue';
    String icone = 'money';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) {
          return AlertDialog(
            title: const Text("Nova categoria"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nome, decoration: const InputDecoration(labelText: "Nome")),
                DropdownButton<String>(
                  value: cor,
                  items: ['blue', 'red', 'green', 'orange']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setModal(() => cor = v!),
                ),
                DropdownButton<String>(
                  value: icone,
                  items: ['money', 'food', 'car', 'home']
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  onChanged: (v) => setModal(() => icone = v!),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final user = supabase.auth.currentUser;

                  await supabase.from('categories').insert({
                    'name': nome.text,
                    'color': cor,
                    'icon': icone,
                    'user_id': user!.id,
                  });

                  Navigator.pop(context);
                  carregar();
                },
                child: const Text("Salvar"),
              )
            ],
          );
        },
      ),
    );
  }

  // ================= FILTRO =================
  List listaFiltrada() {
    if (filtroCategoria == "Todos") return gastos;

    return gastos.where((g) {
      final cat = categorias.firstWhere(
        (c) => c['id'].toString() == g['category_id'].toString(),
        orElse: () => {'name': ''},
      );
      return cat['name'] == filtroCategoria;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = listaFiltrada();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle Financeiro 💰"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => gerarPDF(lista, categorias),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GraphsPage(gastos, categorias)));
            },
          ),
        ],
      ),

      // ================= BOTÕES =================
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: adicionarSaldo,
            backgroundColor: Colors.green,
            child: const Icon(Icons.attach_money),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: novaCategoria,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.category),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: novoGasto,
            child: const Icon(Icons.add),
          ),
        ],
      ),

      // ================= UI =================
      body: Container(
        color: const Color(0xFFD6EAF8),
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // SALDO
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.blue, Colors.indigo]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text("Saldo", style: TextStyle(color: Colors.white70)),
                      Text(
                        "R\$ ${saldo.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // DROPDOWN
                DropdownButton<String>(
                  value: categorias.any((c) => c['name'] == filtroCategoria)
                      ? filtroCategoria
                      : "Todos",
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: "Todos", child: Text("Todos")),
                    ...categorias.map((c) {
                      final nome = c['name'] ?? '';
                      return DropdownMenuItem(value: nome, child: Text(nome));
                    })
                  ],
                  onChanged: (v) => setState(() => filtroCategoria = v!),
                ),

                const SizedBox(height: 20),

                // LISTA
                Expanded(
                  child: lista.isEmpty
                      ? const Center(child: Text("Sem gastos"))
                      : ListView.builder(
                          itemCount: lista.length,
                          itemBuilder: (_, i) {
                            final g = lista[i];

                            final cat = categorias.firstWhere(
                              (c) => c['id'].toString() ==
                                  g['category_id'].toString(),
                              orElse: () => {'name': '', 'color': 'blue', 'icon': 'money'},
                            );

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: getColor(cat['color']),
                                  child: Icon(getIcon(cat['icon']), color: Colors.white),
                                ),
                                title: Text(g['description'] ?? ''),
                                subtitle: Text(cat['name'] ?? ''),
                                trailing: Text(
                                  "- R\$ ${g['amount']}",
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}