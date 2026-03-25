import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future gerarPDF(List lista, List categorias) async {
  final pdf = pw.Document();

  double total = 0;
  for (var g in lista) {
    total += (g['amount'] ?? 0).toDouble();
  }

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Relatório Financeiro",
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                "Total gasto: R\$ ${total.toStringAsFixed(2)}",
                style: pw.TextStyle(fontSize: 16),
              ),
            ),

            pw.SizedBox(height: 20),

            ...lista.map((g) {
              final cat = categorias.firstWhere(
                (c) => c['id'].toString() ==
                    g['category_id'].toString(),
                orElse: () => <String, dynamic>{},
              );

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
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
                        pw.Text(g['description'] ?? ''),
                        pw.Text(
                          cat['name'] ?? '',
                          style: pw.TextStyle(
                              color: PdfColors.grey),
                        ),
                      ],
                    ),
                    pw.Text(
                      "R\$ ${g['amount']}",
                      style: pw.TextStyle(
                        color: PdfColors.red,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    )
                  ],
                ),
              );
            })
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