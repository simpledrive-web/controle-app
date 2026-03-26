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

  DateTime? dataSelecionada;
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
        .or('user_id.is.null,user_id.eq.${user.id}');

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

  Future selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dataSelecionada = picked;
        aplicarFiltro();
      });
    }
  }

  void aplicarFiltro() {
    List<Map<String, dynamic>> filtrados = expenses;

    if (dataSelecionada != null) {
      filtrados = filtrados.where((e) {
        final d = DateTime.parse(e['created_at']);
        return d.year == dataSelecionada!.year &&
            d.month == dataSelecionada!.month &&
            d.day == dataSelecionada!.day;
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

  void editarGasto(Map<String, dynamic> item) {
    final nome = TextEditingController(text: item['name']);
    final valor =
        TextEditingController(text: item['amount'].toString());
    String catId = item['category_id'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nome),
            TextField(controller: valor, keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              value: catId,
              items: categorias.map((c) {
                return DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text("${c['emoji']} ${c['name']}"),
                );
              }).toList(),
              onChanged: (v) => catId = v!,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final novoValor = double.tryParse(valor.text);
              if (novoValor == null) return;

              await supabase.from('expenses').update({
                'name': nome.text,
                'amount': novoValor,
                'category_id': catId,
              }).eq('id', item['id']);

              Navigator.pop(context);
              loadData();
            },
            child: const Text("Salvar"),
          )
        ],
      ),
    );
  }
    Future<void> excluirGasto(String id, double valor) async {
    final confirmar = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir gasto"),
        content: const Text("Tem certeza?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final user = supabase.auth.currentUser;

    await supabase.from('expenses').delete().eq('id', id);

    final existing = await supabase
        .from('balance')
        .select()
        .eq('user_id', user!.id)
        .maybeSingle();

    final atual = existing?['amount']?.toDouble() ?? 0;

    await supabase.from('balance').upsert({
      'user_id': user.id,
      'amount': atual + valor,
    }, onConflict: 'user_id');

    loadData();
  }

  Future logout() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.pop(context);
  }

  // 🔥 NOVO: MENU DE SALDO
  void adicionarSaldo() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text("Adicionar saldo"),
              onTap: () {
                Navigator.pop(context);
                _dialogAdicionarRemover(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove, color: Colors.red),
              title: const Text("Remover saldo"),
              onTap: () {
                Navigator.pop(context);
                _dialogAdicionarRemover(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 NOVO: LÓGICA DE SALDO
  void _dialogAdicionarRemover(bool isAdicionar) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAdicionar ? "Adicionar saldo" : "Remover saldo"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Digite o valor",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final valor = double.tryParse(controller.text);
              if (valor == null) return;

              final user = supabase.auth.currentUser;

              final existing = await supabase
                  .from('balance')
                  .select()
                  .eq('user_id', user!.id)
                  .maybeSingle();

              final atual = existing?['amount']?.toDouble() ?? 0;

              double novoSaldo;

              if (isAdicionar) {
                novoSaldo = atual + valor;
              } else {
                if (valor > atual) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Saldo insuficiente"),
                    ),
                  );
                  return;
                }
                novoSaldo = atual - valor;
              }

              await supabase.from('balance').upsert({
                'user_id': user.id,
                'amount': novoSaldo,
              }, onConflict: 'user_id');

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

              await supabase.from('balance').upsert({
                'user_id': user.id,
                'amount': atual - v,
              }, onConflict: 'user_id');

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

    if (dataSelecionada != null) {
      listaFiltrada = listaFiltrada.where((e) {
        final d = DateTime.parse(e['created_at']);
        return d.year == dataSelecionada!.year &&
            d.month == dataSelecionada!.month &&
            d.day == dataSelecionada!.day;
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
        title: const Text("Controle",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
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
              ElevatedButton(
                onPressed: selecionarData,
                child: Text(
                  dataSelecionada == null
                      ? "Selecionar data"
                      : "${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}",
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    dataSelecionada = null;
                    aplicarFiltro();
                  });
                },
                child: const Text("Limpar"),
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
                    ),
                    child: Row(
                      children: [
                        Text(cat['emoji'] ?? "💰"),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item['name'] ?? "")),
                        Text("- R\$ ${item['amount']}",
                            style: const TextStyle(color: Colors.red)),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') {
                              editarGasto(item);
                            } else if (value == 'excluir') {
                              excluirGasto(
                                item['id'].toString(),
                                (item['amount'] as num).toDouble(),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                            const PopupMenuItem(
                              value: 'excluir',
                              child: Text('Excluir'),
                            ),
                          ],
                        ),
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