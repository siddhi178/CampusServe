// ignore_for_file: unnecessary_to_list_in_spreads, unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoiceService {
  static Future<void> generateAndOpenInvoice(
      Map<String, dynamic> orderData) async {
    final pdf = pw.Document();

    String token = orderData['tokenNumber'] ?? '--';
    String orderId = orderData['orderId'] ?? 'UNKNOWN';
    String paymentMethod = orderData['paymentMethod'] ?? 'Online';
    double totalAmount = (orderData['totalAmount'] ?? 0).toDouble();
    List items = orderData['items'] ?? [];
    List<dynamic> activityLogs = orderData['activityLogs'] ?? [];

    String status = orderData['status'] ?? 'Completed';
    bool isRefunded = status == 'Cancelled' ||
        status.contains('Refund') ||
        status.contains('Disputed');
    String displayStatus = status.toUpperCase();

    Timestamp? ts = orderData['timestamp'];
    String dateStr = ts != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
        : 'Unknown Date';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("CampusServe Canteen",
                                style: pw.TextStyle(
                                    fontSize: 24,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green800)),
                            pw.Text("Official Order Receipt",
                                style: const pw.TextStyle(
                                    fontSize: 14, color: PdfColors.grey700)),
                          ],
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: pw.BoxDecoration(
                              color: PdfColors.green50,
                              borderRadius: pw.BorderRadius.circular(10)),
                          child: pw.Text("Token: $token",
                              style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green900)),
                        )
                      ]),
                  pw.SizedBox(height: 25),

                  // --- ORDER DETAILS ---
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Order ID: $orderId",
                                  style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.normal)),
                              pw.SizedBox(height: 3),
                              pw.Text("Date: $dateStr",
                                  style: const pw.TextStyle(fontSize: 12)),
                              pw.SizedBox(height: 3),
                              pw.Text("Payment Method: $paymentMethod",
                                  style: const pw.TextStyle(fontSize: 12)),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("Order Status:",
                                  style: const pw.TextStyle(
                                      fontSize: 10, color: PdfColors.grey600)),
                              pw.SizedBox(height: 2),
                              pw.Text(displayStatus,
                                  style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                      color: isRefunded
                                          ? PdfColors.red800
                                          : PdfColors.green800)),
                            ])
                      ]),

                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey400, thickness: 1.5),
                  pw.SizedBox(height: 10),

                  // --- TABLE HEADER ---
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                            flex: 3,
                            child: pw.Text("Item",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13))),
                        pw.Expanded(
                            flex: 1,
                            child: pw.Text("Qty",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13))),
                        pw.Expanded(
                            flex: 1,
                            child: pw.Text("Price",
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13))),
                        pw.Expanded(
                            flex: 1,
                            child: pw.Text("Subtotal",
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13))),
                      ]),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 5),

                  // --- ITEMS ---
                  ...items.map((item) {
                    int q = item['quantity'] ?? 1;
                    String title = item['title'] ?? item['name'] ?? 'Item';

                    // Safely strip rupee symbol
                    double priceVal = double.tryParse(item['price']
                            .toString()
                            .replaceAll('₹', '')
                            .trim()) ??
                        0;
                    double subtotal = priceVal * q;

                    return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(title,
                                      style: const pw.TextStyle(fontSize: 12))),
                              pw.Expanded(
                                  flex: 1,
                                  child: pw.Text("x$q",
                                      textAlign: pw.TextAlign.center,
                                      style: const pw.TextStyle(fontSize: 12))),
                              pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                      "Rs ${priceVal.toStringAsFixed(0)}",
                                      textAlign: pw.TextAlign.right,
                                      style: const pw.TextStyle(fontSize: 12))),
                              pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                      "Rs ${subtotal.toStringAsFixed(0)}",
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(
                                          fontSize: 12,
                                          fontWeight: pw.FontWeight.bold))),
                            ]));
                  }).toList(),

                  pw.SizedBox(height: 15),
                  pw.Divider(color: PdfColors.grey400, thickness: 1.5),
                  pw.SizedBox(height: 15),

                  // --- TOTAL ---
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Grand Total",
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Rs ${totalAmount.toStringAsFixed(0)}",
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800)),
                      ]),

                  // --- TIMELINE / ACTIVITY LOGS ---
                  if (activityLogs.isNotEmpty || isRefunded) ...[
                    pw.SizedBox(height: 30),
                    pw.Text("Action History:",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                            fontSize: 13)),
                    pw.SizedBox(height: 8),
                    if (isRefunded)
                      pw.Text("- System Status: $displayStatus",
                          style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.red700,
                              fontWeight: pw.FontWeight.bold)),
                    ...activityLogs
                        .map((log) => pw.Text("- $log",
                            style: const pw.TextStyle(
                                fontSize: 11, color: PdfColors.grey700)))
                        .toList()
                  ]
                ],
              ),

              // --- WATERMARK ---
              if (isRefunded)
                pw.Positioned(
                  top: 250,
                  left: 30,
                  child: pw.Transform.rotate(
                    angle: -0.5,
                    child: pw.Text(
                      displayStatus.contains('CANCELLED')
                          ? "CANCELLED"
                          : "REFUNDED",
                      style: pw.TextStyle(
                        color: PdfColors.red.shade(100), // Very light red
                        fontSize: 90,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${token}_${orderId}.pdf');
  }
}
