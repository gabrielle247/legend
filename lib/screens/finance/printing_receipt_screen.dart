import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/services/auth/auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum ReceiptType { invoice, payment }

class PrintReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final ReceiptType type;

  const PrintReceiptScreen({
    super.key,
    required this.data,
    this.type = ReceiptType.payment,
  });

  @override
  State<PrintReceiptScreen> createState() => _PrintReceiptScreenState();
}

class _PrintReceiptScreenState extends State<PrintReceiptScreen> {
  bool _isGenerating = false;

  String _schoolName() {
    final school = context.read<AuthService>().activeSchool;
    return (widget.data['school'] ?? school?.name ?? "School").toString();
  }

  String _schoolAddress() {
    final school = context.read<AuthService>().activeSchool;
    return (widget.data['address'] ?? school?.address ?? "").toString();
  }

  String _currencySymbol() {
    final school = context.read<AuthService>().activeSchool;
    final currency =
        (widget.data['currency'] ?? school?.currency ?? "USD").toString().toUpperCase();
    switch (currency) {
      case 'USD':
        return '\$';
      case 'ZWL':
        return 'Z\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      default:
        return '\$';
    }
  }

  // ---------------------------------------------------------------------------
  // PROFESSIONAL ACTIONS
  // ---------------------------------------------------------------------------

  Future<void> _handlePrintOrOpen() async {
    setState(() => _isGenerating = true);

    try {
      final Uint8List pdfBytes = widget.type == ReceiptType.invoice
          ? await _generateProfessionalInvoicePDF()
          : await _generateThermalReceiptPDF();

      final dir = await getTemporaryDirectory();
      final filename =
          "${widget.type == ReceiptType.invoice ? 'INV' : 'RCT'}-${widget.data['id'] ?? 'DRAFT'}.pdf";
      final file = File(p.join(dir.path, filename));
      await file.writeAsBytes(pdfBytes);

      final uri = Uri.file(file.path);

      bool opened = false;
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("LaunchURL error: $e");
      }

      if (mounted) {
        setState(() => _isGenerating = false);
        if (opened) {
          _showSnack("Document opened. Use system menu to Print.", isError: false);
        } else {
          _showSnack("Saved to: ${file.path}", isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        _showSnack("Generation Failed: $e", isError: true);
      }
    }
  }

  void _handleShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text("Copy Details", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: _buildOutgoingMessage()));
                _showSnack("Copied to clipboard", isError: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text("Send via WhatsApp", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _launchWhatsApp();
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.white),
              title: const Text("Send via Email", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _launchEmail();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF GENERATOR: INVOICE (A4 Professional)
  // ---------------------------------------------------------------------------
  Future<Uint8List> _generateProfessionalInvoicePDF() async {
    final pdf = pw.Document();

    final PdfColor primaryColor = PdfColor.fromInt(0xFF2196F3);
    final PdfColor accentColor = PdfColor.fromInt(0xFFEEEEEE);

    final id = widget.data['id']?.toString() ?? "INV-000";
    final date = _formatDate(widget.data['date']);
    final student = widget.data['student']?.toString() ?? "Student";
    final total = (widget.data['total'] as num?)?.toDouble() ?? 0.0;
    final items = (widget.data['items'] as List?) ?? [];
    final school = _schoolName();
    final address = _schoolAddress();
    final currency = _currencySymbol();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      school,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    if (address.isNotEmpty)
                      pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("INVOICE",
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text("Invoice #: $id"),
                    pw.Text("Date: $date"),
                  ],
                )
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: accentColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "BILL TO",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(student,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Description', 'Qty', 'Unit Price', 'Total'],
              data: items.isEmpty
                  ? [
                      ['Tuition Fees', '1', '$currency${total.toStringAsFixed(2)}', '$currency${total.toStringAsFixed(2)}']
                    ]
                  : items.map((item) {
                      final desc = item['desc'] ?? item['description'] ?? "Item";
                      final qtyNum = item['qty'] ?? item['quantity'] ?? 1;
                      final qty = (qtyNum is num) ? qtyNum.toInt() : 1;
                      final amtNum = item['amt'] ?? item['amount'] ?? 0.0;
                      final amt = (amtNum is num) ? amtNum.toDouble() : 0.0;
                      final lineTotal = amt * qty;
                      return [
                        desc.toString(),
                        qty.toString(),
                        '$currency${amt.toStringAsFixed(2)}',
                        '$currency${lineTotal.toStringAsFixed(2)}'
                      ];
                    }).toList(),
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
            pw.Divider(),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Text("Total: $currency${total.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                "Thank you for your business. Please pay within 30 days.",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // PDF GENERATOR: RECEIPT (Thermal / Slip)
  // ---------------------------------------------------------------------------
  Future<Uint8List> _generateThermalReceiptPDF() async {
    final pdf = pw.Document();
    final total = (widget.data['total'] as num?)?.toDouble() ?? 0.0;
    final items = (widget.data['items'] as List?) ?? [];
    final school = _schoolName();
    final address = _schoolAddress();
    final currency = _currencySymbol();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(school,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 10),
              pw.Text("PAYMENT RECEIPT",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Date:", style: const pw.TextStyle(fontSize: 8)),
                pw.Text(_formatDate(widget.data['date']), style: const pw.TextStyle(fontSize: 8)),
              ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Ref:", style: const pw.TextStyle(fontSize: 8)),
                pw.Text(widget.data['id']?.toString() ?? "-", style: const pw.TextStyle(fontSize: 8)),
              ]),
              pw.Divider(),
              ...items.map((item) {
                final desc = item['desc']?.toString() ?? item['description']?.toString() ?? "Item";
                final amtNum = item['amt'] ?? item['amount'] ?? 0.0;
                final amt = (amtNum is num) ? amtNum.toDouble() : 0.0;
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(desc, style: const pw.TextStyle(fontSize: 9))),
                    pw.Text("$currency${amt.toStringAsFixed(2)}",
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                );
              }),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("TOTAL PAID", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("$currency${total.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
              pw.SizedBox(height: 20),
              pw.Text("Retain for your records", style: const pw.TextStyle(fontSize: 8)),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
    ));
  }

  String _formatDate(dynamic date) {
    if (date == null) return DateFormat('dd MMM yyyy').format(DateTime.now());
    if (date is DateTime) return DateFormat('dd MMM yyyy').format(date);
    if (date is int) return DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(date));
    if (date is String) {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
      return date;
    }
    return DateFormat('dd MMM yyyy').format(DateTime.now());
  }

  String _buildOutgoingMessage() {
    final total = (widget.data['total'] as num?)?.toDouble() ?? 0.0;
    final id = widget.data['id']?.toString() ?? "---";
    final date = _formatDate(widget.data['date']);
    final student = widget.data['student']?.toString() ?? "Customer";
    final items = (widget.data['items'] as List?) ?? [];
    final school = _schoolName();
    final currency = _currencySymbol();

    final buffer = StringBuffer()
      ..writeln("Hello $student,")
      ..writeln()
      ..writeln("Thank you for your transaction with $school.")
      ..writeln("Below are your receipt details:")
      ..writeln()
      ..writeln("Ref: $id")
      ..writeln("Date: $date")
      ..writeln("Total: $currency${total.toStringAsFixed(2)}")
      ..writeln()
      ..writeln("Items:");

    if (items.isEmpty) {
      buffer.writeln("- No items listed");
    } else {
      for (final item in items) {
        final desc = item['desc'] ?? item['description'] ?? 'Item';
        final amtNum = item['amt'] ?? item['amount'] ?? 0.0;
        final amt = (amtNum is num) ? amtNum.toDouble() : 0.0;
        buffer.writeln("- $desc: $currency${amt.toStringAsFixed(2)}");
      }
    }

    buffer
      ..writeln()
      ..writeln("If you need a PDF copy, it is available in-app.")
      ..writeln()
      ..writeln("Regards,")
      ..writeln(school);

    return buffer.toString();
  }

  Future<void> _launchWhatsApp() async {
    final text = Uri.encodeComponent(_buildOutgoingMessage());
    final url = Uri.parse("https://wa.me/?text=$text");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack("Could not launch WhatsApp", isError: true);
    }
  }

  Future<void> _launchEmail() async {
    final text = _buildOutgoingMessage();
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': widget.type == ReceiptType.invoice ? 'Invoice Receipt' : 'Payment Receipt',
        'body': text,
      },
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _showSnack("Could not open Email", isError: true);
  }

  // ---------------------------------------------------------------------------
  // UI BUILDER
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool isA4 = widget.type == ReceiptType.invoice;
    final school = _schoolName();
    final address = _schoolAddress();
    final currency = _currencySymbol();
    final total = (widget.data['total'] as num?)?.toDouble() ?? 0.0;
    final items = (widget.data['items'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: Text(isA4 ? "Invoice Preview" : "Receipt Preview",
            style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _handleShareOptions,
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Center(
              child: Column(
                children: [
                  _buildStatusBadge(),
                  const SizedBox(height: 20),
                  Container(
                    width: isA4 ? double.infinity : 300,
                    constraints: BoxConstraints(
                      minHeight: 400,
                      maxWidth: isA4 ? 500 : 350,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
          color: Colors.black.withAlpha(128),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: isA4
                        ? _buildA4Preview(school, address, currency, total, items)
                        : _buildSlipPreview(school, currency, total),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _handlePrintOrOpen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                ),
                child: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.print_outlined),
                          SizedBox(width: 12),
                          Text("PRINT / SAVE PDF",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_isGenerating ? Icons.hourglass_top : Icons.check_circle,
              color: _isGenerating ? Colors.orange : AppColors.successGreen, size: 14),
          const SizedBox(width: 8),
          Text(
            _isGenerating ? "Generating PDF..." : "Ready to Generate",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN PREVIEWS (Visual approximation of the PDF)
  // ---------------------------------------------------------------------------

  Widget _buildA4Preview(
    String school,
    String address,
    String currency,
    double total,
    List items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(school,
                    style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                if (address.isNotEmpty)
                  Text(address, style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("INVOICE",
                    style: TextStyle(
                        color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text("#${widget.data['id'] ?? '---'}",
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text("BILL TO:",
            style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(widget.data['student']?.toString() ?? "N/A",
            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: AppColors.primaryBlue.withAlpha(26),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Description",
                  style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("Total",
                  style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tuition & Fees", style: TextStyle(color: Colors.black, fontSize: 12)),
              Text("$currency${total.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.black, fontSize: 12)),
            ],
          )
        else
          ...items.map<Widget>((item) {
            final desc = item['desc'] ?? item['description'] ?? 'Item';
            final amtNum = item['amt'] ?? item['amount'] ?? 0.0;
            final amt = (amtNum is num) ? amtNum.toDouble() : 0.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(desc.toString(), style: const TextStyle(color: Colors.black, fontSize: 12)),
                Text("$currency${amt.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.black, fontSize: 12)),
              ],
            );
          }),
        const Divider(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Total: $currency${total.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildSlipPreview(String school, String currency, double total) {
    return Column(
      children: [
        const Icon(Icons.school, color: Colors.black, size: 40),
        const SizedBox(height: 8),
        Text(school, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        const Text("Official Receipt", style: TextStyle(color: Colors.black54, fontSize: 10)),
        const SizedBox(height: 16),
        const Divider(color: Colors.black12, thickness: 1),
        _row("Date", _formatDate(widget.data['date'])),
        _row("Ref", widget.data['id']?.toString() ?? "-"),
        const Divider(color: Colors.black12),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("TOTAL PAID",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
            Text("$currency${total.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 30,
          width: double.infinity,
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Text("||| || ||| |||", style: TextStyle(color: Colors.black38, letterSpacing: 5)),
        )
      ],
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          Text(val, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
