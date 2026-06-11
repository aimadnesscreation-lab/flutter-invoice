import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:invoice_pro/domain/entities/invoice.dart';
import 'package:invoice_pro/domain/entities/business.dart';
import 'package:invoice_pro/core/utils/helpers.dart';

class PdfService {
  Future<Uint8List> generateInvoicePdf(Invoice invoice, Business business) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(invoice, business),
          pw.SizedBox(height: 20),
          _buildCustomerSection(invoice),
          pw.SizedBox(height: 20),
          _buildItemsTable(invoice),
          pw.SizedBox(height: 20),
          _buildTotals(invoice),
          pw.SizedBox(height: 20),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            _buildNotes(invoice),
            pw.SizedBox(height: 20),
          ],
          _buildFooter(business),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> saveInvoicePdf(Invoice invoice, Business business) async {
    final pdfBytes = await generateInvoicePdf(invoice, business);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  Future<void> printInvoice(Invoice invoice, Business business) async {
    final pdfBytes = await generateInvoicePdf(invoice, business);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  pw.Widget _buildHeader(Invoice invoice, Business business) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              business.name,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            if (business.address != null) pw.Text(business.address!, style: const pw.TextStyle(fontSize: 10)),
            if (business.phone != null) pw.Text('Phone: ${business.phone}', style: const pw.TextStyle(fontSize: 10)),
            if (business.email != null) pw.Text('Email: ${business.email}', style: const pw.TextStyle(fontSize: 10)),
            if (business.taxNumber != null) pw.Text('Tax: ${business.taxNumber}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              invoice.isPurchaseOrder ? 'PURCHASE ORDER' : 'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('${invoice.isPurchaseOrder ? "PO" : "Invoice"} #: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Date: ${Helpers.formatDate(invoice.invoiceDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Due Date: ${Helpers.formatDate(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Status: ${invoice.status.toUpperCase()}', style: pw.TextStyle(fontSize: 10, color: _getStatusColor(invoice.status))),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerSection(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            invoice.isPurchaseOrder ? 'Supplier' : 'Bill To',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            invoice.customerName ?? invoice.supplierName ?? 'N/A',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice) {
    final headers = ['#', 'Description', 'Qty', 'Price', 'Tax', 'Total'];
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: headers.map((h) => pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        )).toList(),
      ),
    ];

    int index = 1;
    for (final item in invoice.items) {
      rows.add(pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('$index', style: const pw.TextStyle(fontSize: 10))),
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 10))),
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 10))),
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(Helpers.formatCurrency(item.unitPrice, symbol: invoice.currencySymbol), style: const pw.TextStyle(fontSize: 10))),
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.taxPercent}%', style: const pw.TextStyle(fontSize: 10))),
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(Helpers.formatCurrency(item.subtotal, symbol: invoice.currencySymbol), style: const pw.TextStyle(fontSize: 10))),
        ],
      ));
      index++;
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: rows,
    );
  }

  pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Subtotal:', Helpers.formatCurrency(invoice.subtotal, symbol: invoice.currencySymbol)),
          if (invoice.discountAmount > 0)
            _buildTotalRow('Discount (${invoice.discountPercent}%):', '-${Helpers.formatCurrency(invoice.discountAmount, symbol: invoice.currencySymbol)}'),
          _buildTotalRow('Tax (${invoice.taxPercent}%):', Helpers.formatCurrency(invoice.taxAmount, symbol: invoice.currencySymbol)),
          pw.Divider(),
          _buildTotalRow('Grand Total:', Helpers.formatCurrency(invoice.grandTotal, symbol: invoice.currencySymbol), bold: true, fontSize: 14),
          if (invoice.paidAmount > 0)
            _buildTotalRow('Paid:', Helpers.formatCurrency(invoice.paidAmount, symbol: invoice.currencySymbol)),
          if (invoice.balanceDue > 0)
            _buildTotalRow('Balance Due:', Helpers.formatCurrency(invoice.balanceDue, symbol: invoice.currencySymbol), bold: true, color: PdfColors.red700),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {bool bold = false, double fontSize = 12, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(width: 150, alignment: pw.Alignment.centerRight, child: pw.Text(label, style: pw.TextStyle(fontSize: fontSize - 2, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
        pw.Container(width: 120, alignment: pw.Alignment.centerRight, child: pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color))),
      ],
    );
  }

  pw.Widget _buildNotes(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Business business) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(business.name, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        if (business.email != null) pw.Text(business.email!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        if (business.phone != null) pw.Text(business.phone!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
      ],
    );
  }

  PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return PdfColors.green700;
      case 'overdue':
        return PdfColors.red700;
      case 'draft':
        return PdfColors.grey700;
      case 'sent':
        return PdfColors.blue700;
      case 'cancelled':
        return PdfColors.orange700;
      default:
        return PdfColors.grey700;
    }
  }

  // Report generation
  Future<Uint8List> generateReportPdf({
    required String title,
    required String businessName,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    required List<String> columnLabels,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(businessName, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
          _buildReportTable(data, columns, columnLabels),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildReportTable(List<Map<String, dynamic>> data, List<String> columns, List<String> columnLabels) {
    final headers = columnLabels;
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: headers.map((h) => pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        )).toList(),
      ),
    ];

    for (final row in data) {
      rows.add(pw.TableRow(
        children: columns.map((col) => pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text('${row[col] ?? ''}', style: const pw.TextStyle(fontSize: 10)),
        )).toList(),
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: rows,
    );
  }
}
