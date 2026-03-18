import 'package:flutter/material.dart';

void main() {
  runApp(const ControleApp());
}

class ControleApp extends StatelessWidget {
  const ControleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

// MODELO
class Expense {
  final String descricao;
  final double valor;
  final String categoria;

  Expense(this.descricao, this.valor, this.categoria);
}

// HOME
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> gastos = [];

  void adicionarGasto(Expense gasto) {
    setState(() {
      gastos.add(gasto);
    });
  }

  double get total {
    return gastos.fold(0, (soma, item) => soma + item.valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Gastos 💸'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.green[100],
            child: Text(
              'Total: R\$ ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Expanded(
            child: gastos.isEmpty
                ? const Center(
                    child: Text('Nenhum gasto ainda'),
                  )
                : ListView.builder(
                    itemCount: gastos.length,
                    itemBuilder: (context, index) {
                      final gasto = gastos[index];
                      return ListTile(
                        title: Text(gasto.descricao),
                        subtitle: Text(gasto.categoria),
                        trailing: Text(
                          'R\$ ${gasto.valor.toStringAsFixed(2)}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final novoGasto = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpensePage(),
            ),
          );

          if (novoGasto != null) {
            adicionarGasto(novoGasto);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ADD PAGE
class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController valorController = TextEditingController();

  String categoriaSelecionada = 'Comida';

  final List<String> categorias = [
    'Comida',
    'Transporte',
    'Lazer',
    'Outros'
  ];

  void salvar() {
    final descricao = descricaoController.text;
    final valor = double.tryParse(valorController.text) ?? 0;

    if (descricao.isEmpty || valor == 0) return;

    final gasto = Expense(descricao, valor, categoriaSelecionada);

    Navigator.pop(context, gasto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Gasto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
              ),
            ),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            DropdownButton<String>(
              value: categoriaSelecionada,
              isExpanded: true,
              items: categorias.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    categoriaSelecionada = value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: salvar,
              child: const Text('Salvar'),
            )
          ],
        ),
      ),
    );
  }
}