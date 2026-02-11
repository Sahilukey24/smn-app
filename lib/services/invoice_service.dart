import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../core/constants.dart';
import '../models/order_model.dart';

/// Generate order invoice PDF.
class InvoiceService {
  Future<File> generateOrderInvoice(OrderModel order) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SMN – Invoice', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
              pw.Text('Date: ${order.createdAt.toIso8601String().substring(0, 10)}'),
              pw.Text('Status: ${order.status}'),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.Text('Items', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...order.items.map((i) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(child: pw.Text('${i.serviceName} × ${i.quantity}')),
                        pw.Text('₹${(i.priceInr * i.quantity).toStringAsFixed(0)}'),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Platform charge'),
                  pw.Text('₹${AppConstants.platformChargePerOrderInr.toInt()}'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('₹${order.totalInr.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/smn_invoice_${order.id.substring(0, 8)}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> openInvoice(File file) async {
    await OpenFilex.open(file.path);
  }
}
