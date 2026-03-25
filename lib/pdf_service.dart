import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> gerarPDF(
  List<Map<String, dynamic>> lista,
  List<Map<String, dynamic>> categorias,
) async {
  final pdf = pw.Document();

  double total = 0;

  for (var g in lista) {
    final value = g['amount'];
    if (value != null) {
      total += (value as num).toDouble();
    }
  }

  // 🔥 Agrupar por categoria
  Map<String, List<Map<String, dynamic>>> agrupado = {};

  for (var g in lista) {
    final cat = categorias.firstWhere(
      (c) => c['id'].toString() == g['category_id'].toString(),
      orElse: () => <String, dynamic>{},
    );

    final nomeCategoria = cat['name'] ?? 'Outros';

    if (!agrupado.containsKey(nomeCategoria)) {
      agrupado[nomeCategoria] = [];
    }

    agrupado[nomeCategoria]!.add(g);
  }

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // TÍTULO
            pw.Center(
              child: pw.Text(
                "Relatório Financeiro",
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // TOTAL GERAL
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue100,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                "Total gasto: R\$ ${total.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // LISTA POR CATEGORIA
            ...agrupado.entries.map((entry) {
              final nomeCategoria = entry.key;
              final itens = entry.value;

              double totalCategoria = 0;
              for (var i in itens) {
                final value = i['amount'];
                if (value != null) {
                  totalCategoria += (value as num).toDouble();
                }
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // CABEÇALHO DA CATEGORIA
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 6, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      "$nomeCategoria  •  Total: R\$ ${totalCategoria.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // ITENS DA CATEGORIA
                  ...itens.map((g) {
                    final descricao = g['name'] ?? ''; // 🔥 corrigido aqui
                    final valor =
                        (g['amount'] ?? 0).toDouble().toStringAsFixed(2);

                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              descricao,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            "R\$ $valor",
                            style: pw.TextStyle(
                              color: PdfColors.red,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  pw.SizedBox(height: 15),
                ],
              );
            }).toList(),

            pw.Spacer(),

            // RODAPÉ
            pw.Center(
              child: pw.Text(
                "Gerado pelo app Controle 💜",
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            )
          ],
        );
      },
    ),
  );

  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'relatorio_financeiro.pdf',
  );
}