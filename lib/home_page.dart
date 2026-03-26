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

  // 🔥 NOVO: selecionar data
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

    // 🔥 filtro por DIA
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

  Future<void> excluirGasto(String id, double valor) async {
    final confirmar = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir gasto"),
        content: const Text("Tem certeza que deseja excluir?"),
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

    await supabase.from('balance').upsert(
      {
        'user_id': user.id,
        'amount': atual + valor,
      },
      onConflict: 'user_id',
    );

    loadData();
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
        title: const Text("Controle 💜",
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // 🔥 BOTÕES NOVOS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: selecionarData,
                child: Text(
                  dataSelecionada == null
                      ? "Selecionar data"
                      : "${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}",
                ),
              ),
              const SizedBox(width: 10),
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

                final cat = categorias.firstWhere(
                    (c) =>
                        c['id'].toString() ==
                        item['category_id'].toString(),
                    orElse: () => {});

                return ListTile(
                  title: Text(item['name'] ?? ""),
                  subtitle: Text(cat['name'] ?? ""),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'excluir') {
                        excluirGasto(
                          item['id'].toString(),
                          (item['amount'] as num).toDouble(),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'excluir',
                        child: Text('Excluir'),
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