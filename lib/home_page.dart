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

  // 🔥 EDITAR GASTO (NOVO)
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
        title: const Text("Controle", // 🔥 sem coração
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
      body: Column(
        children: [
          const SizedBox(height: 20),

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
            ],
          ),

          Expanded(
            child: ListView.builder(
              itemCount: listaFiltrada.length,
              itemBuilder: (_, i) {
                final item = listaFiltrada[i];

                return ListTile(
                  title: Text(item['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                );
              },
            ),
          )
        ],
      ),
    );
  }
}