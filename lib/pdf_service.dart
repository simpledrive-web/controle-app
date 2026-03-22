import 'dart:html' as html;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

Future gerarPDF(List gastos, List categorias) async {
  final pdf = pw.Document();

  double total = 0;

  // 🔥 CALCULAR TOTAL
  for (var g in gastos) {
    final valor = (g['amount'] ?? 0).toDouble();
    total += valor;
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 🔥 TÍTULO
              pw.Text(
                "Relatório Financeiro",
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),

              pw.SizedBox(height: 10),

              // 🔥 TOTAL
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(8),
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

              // 🔥 LISTA DE GASTOS
              ...gastos.map((g) {
                final valor = (g['amount'] ?? 0).toDouble();

                final cat = categorias.firstWhere(
                  (c) => c['id'].toString() ==
                      g['category_id'].toString(),
                  orElse: () => {'name': 'Sem categoria'},
                );

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            g['description'] ?? '',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            cat['name'] ?? '',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        "R\$ ${valor.toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          color: PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 20),

              // 🔥 RODAPÉ
              pw.Divider(),
              pw.Text(
                "Gerado automaticamente pelo app",
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  final bytes = await pdf.save();

  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "relatorio_financeiro.pdf")
    ..click();

  html.Url.revokeObjectUrl(url);
}