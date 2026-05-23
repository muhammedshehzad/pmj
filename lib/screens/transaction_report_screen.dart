import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionReportScreen extends StatefulWidget {
  const TransactionReportScreen({super.key});

  @override
  State<TransactionReportScreen> createState() => _TransactionReportScreenState();
}

class _TransactionReportScreenState extends State<TransactionReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransactionService _service = TransactionService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff1BA3A1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Income & Expense Report',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MonthlyReportTab(service: _service),
          _YearlyReportTab(service: _service),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly Report Tab
// ─────────────────────────────────────────────────────────────────────────────
class _MonthlyReportTab extends StatefulWidget {
  final TransactionService service;
  const _MonthlyReportTab({required this.service});

  @override
  State<_MonthlyReportTab> createState() => _MonthlyReportTabState();
}

class _MonthlyReportTabState extends State<_MonthlyReportTab> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late String _selectedMonth;
  late String _selectedYear;
  late List<String> _years;

  List<TransactionModel>? _transactions;
  // Aggregated donation total for the selected month (counted as income).
  double _donationIncome = 0;
  int _donationCount = 0;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateFormat('MMMM').format(now);
    _selectedYear = now.year.toString();
    final currentYear = now.year;
    _years = List.generate(currentYear - 2010 + 1, (i) => (2010 + i).toString())
      ..sort((a, b) => b.compareTo(a));
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.service.getTransactionsForMonth(_selectedMonth, _selectedYear),
        widget.service.getDonationsForMonth(_selectedMonth, _selectedYear),
      ]);
      final txList = results[0] as List<TransactionModel>;
      final donationDocs = results[1] as List<Map<String, dynamic>>;

      double donationTotal = 0;
      for (final d in donationDocs) {
        donationTotal += (d['amount'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          _transactions = txList;
          _donationIncome = donationTotal;
          _donationCount = donationDocs.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _totalIncome =>
      (_transactions ?? [])
          .where((t) => t.isIncome)
          .fold(0.0, (s, t) => s + t.amount) +
      _donationIncome;

  double get _totalExpense => (_transactions ?? [])
      .where((t) => t.isExpense)
      .fold(0.0, (s, t) => s + t.amount);

  double get _balance => _totalIncome - _totalExpense;

  Future<void> _exportPdf() async {
    final hasTx = _transactions != null && _transactions!.isNotEmpty;
    final hasDonations = _donationIncome > 0;
    if (!hasTx && !hasDonations) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

      final allTx = List<TransactionModel>.from(_transactions ?? [])
        ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('INCOME & EXPENSE REPORT',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text('$_selectedMonth $_selectedYear',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.Text('Generated: $dateStr',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.teal, thickness: 1.5),
            ],
          ),
          footer: (_) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('PMJ App — Income & Expense Report',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.Text('Page ${_.pageNumber} of ${_.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
          build: (_) => [
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal),
                  children: ['Name', 'Date', 'Type', 'Amount'].map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                    child: pw.Text(h,
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                        textAlign: pw.TextAlign.center),
                  )).toList(),
                ),
                ...allTx.map((tx) {
                  final isIncome = tx.isIncome;
                  return pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: pw.Text(tx.name, style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: pw.Text(tx.formattedDate,
                          style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: pw.Text(
                        isIncome ? 'Income' : 'Expense',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: isIncome ? PdfColors.black : PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: pw.Text(
                        tx.formattedAmount,
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: isIncome ? PdfColors.black : PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ]);
                }),
                if (_donationIncome > 0)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text(
                          'Donations ($_donationCount donor${_donationCount == 1 ? '' : 's'})',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text('$_selectedMonth $_selectedYear',
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text(
                          'Income',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.teal,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text(
                          '₹${_donationIncome.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.teal,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfSummaryCell('Total Income', '₹${_totalIncome.toStringAsFixed(0)}', PdfColors.teal),
                  _pdfSummaryCell('Total Expense', '₹${_totalExpense.toStringAsFixed(0)}', PdfColors.red),
                  _pdfSummaryCell(
                    'Balance',
                    '₹${_balance.toStringAsFixed(0)}',
                    _balance >= 0 ? PdfColors.teal : PdfColors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/report_${_selectedMonth}_$_selectedYear.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Income & Expense Report — $_selectedMonth $_selectedYear',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _pdfSummaryCell(String label, String value, PdfColor color) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      pw.SizedBox(height: 3),
      pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Filters
        Container(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: _DropdownField(
                  value: _selectedMonth,
                  items: _months,
                  onChanged: (v) { setState(() => _selectedMonth = v); _load(); },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField(
                  value: _selectedYear,
                  items: _years,
                  onChanged: (v) { setState(() => _selectedYear = v); _load(); },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xff1BA3A1))))
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : (_transactions == null || _transactions!.isEmpty) &&
                          _donationIncome == 0
                      ? const _EmptyReport()
                      : _MonthlyList(
                          transactions: _transactions ?? const [],
                          donationIncome: _donationIncome,
                          donationCount: _donationCount,
                          monthLabel: '$_selectedMonth $_selectedYear',
                        ),
        ),

        // Summary footer
        if ((_transactions != null && _transactions!.isNotEmpty) ||
            _donationIncome > 0)
          _SummaryFooter(
            totalIncome: _totalIncome,
            totalExpense: _totalExpense,
            balance: _balance,
          ),

        // Export button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1BA3A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(
                _isExporting ? 'Exporting…' : 'Export PDF',
                style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlyList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final double donationIncome;
  final int donationCount;
  final String monthLabel;

  const _MonthlyList({
    required this.transactions,
    required this.donationIncome,
    required this.donationCount,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showDonationRow = donationIncome > 0;
    final itemCount = sorted.length + (showDonationRow ? 1 : 0);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      separatorBuilder: (_, __) => Divider(
        height: 1, indent: 16, endIndent: 16,
        color: isDark ? Colors.white10 : Colors.black12,
      ),
      itemBuilder: (_, i) {
        // Donations summary row appears at the end
        if (showDonationRow && i == sorted.length) {
          return Container(
            color: const Color(0xff1BA3A1).withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xff1BA3A1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded,
                      size: 16, color: Color(0xff1BA3A1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donations',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$donationCount ${donationCount == 1 ? 'donor' : 'donors'} · $monthLabel',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xff817D8A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₹${donationIncome.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xff1BA3A1),
                  ),
                ),
              ],
            ),
          );
        }

        final tx = sorted[i];
        final isIncome = tx.isIncome;
        final color = isIncome ? Colors.black87 : const Color(0xffF44336);
        final darkColor = isIncome ? Colors.white : const Color(0xffF44336);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.name,
                        style: TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14,
                          color: isDark ? darkColor : color,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (tx.description != null && tx.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(tx.description!,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff817D8A)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(tx.formattedDate,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff817D8A))),
              const SizedBox(width: 12),
              Text(
                tx.formattedAmount,
                style: TextStyle(
                  fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14,
                  color: isDark ? darkColor : color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yearly Report Tab
// ─────────────────────────────────────────────────────────────────────────────
class _YearlyReportTab extends StatefulWidget {
  final TransactionService service;
  const _YearlyReportTab({required this.service});

  @override
  State<_YearlyReportTab> createState() => _YearlyReportTabState();
}

class _YearlyReportTabState extends State<_YearlyReportTab> {
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late String _selectedYear;
  late List<String> _years;

  Map<String, Map<String, double>>? _summary;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year.toString();
    final current = DateTime.now().year;
    _years = List.generate(current - 2010 + 1, (i) => (2010 + i).toString())
      ..sort((a, b) => b.compareTo(a));
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await widget.service.getYearlySummary(_selectedYear);
      if (mounted) setState(() { _summary = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _grandIncome => (_summary?.values ?? []).fold(0.0, (s, m) => s + (m['income'] ?? 0));
  double get _grandExpense => (_summary?.values ?? []).fold(0.0, (s, m) => s + (m['expense'] ?? 0));
  double get _grandBalance => _grandIncome - _grandExpense;

  Future<void> _exportPdf() async {
    if (_summary == null) return;
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
      final summary = _summary!;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('YEARLY SUMMARY REPORT',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text('Year $_selectedYear',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.Text('Generated: $dateStr',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.teal, thickness: 1.5),
            ],
          ),
          footer: (_) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('PMJ App — Yearly Report',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.Text('Page ${_.pageNumber} of ${_.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
          build: (_) {
            double totalIncome = 0, totalExpense = 0;
            return [
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal),
                    children: ['Month', 'Income', 'Expense', 'Balance'].map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: pw.Text(h,
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center),
                    )).toList(),
                  ),
                  ..._monthNames.map((month) {
                    final m = summary[month]!;
                    final inc = m['income'] ?? 0;
                    final exp = m['expense'] ?? 0;
                    final bal = inc - exp;
                    totalIncome += inc;
                    totalExpense += exp;
                    final hasData = inc > 0 || exp > 0;
                    return pw.TableRow(children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                        child: pw.Text(month,
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                        child: pw.Text(
                          hasData ? '₹${inc.toStringAsFixed(0)}' : '-',
                          style: pw.TextStyle(fontSize: 9, color: inc > 0 ? PdfColors.black : PdfColors.grey),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                        child: pw.Text(
                          hasData ? '₹${exp.toStringAsFixed(0)}' : '-',
                          style: pw.TextStyle(fontSize: 9, color: exp > 0 ? PdfColors.red : PdfColors.grey),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                        child: pw.Text(
                          hasData ? '₹${bal.toStringAsFixed(0)}' : '-',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: hasData ? (bal >= 0 ? PdfColors.teal : PdfColors.red) : PdfColors.grey,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ]);
                  }),
                  // Totals row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: pw.Text('Total',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: pw.Text('₹${totalIncome.toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: pw.Text('₹${totalExpense.toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: pw.Text(
                          '₹${(totalIncome - totalExpense).toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: totalIncome >= totalExpense ? PdfColors.teal : PdfColors.red,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/yearly_report_$_selectedYear.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Yearly Summary Report — $_selectedYear',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Year filter
        Container(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _DropdownField(
            value: _selectedYear,
            items: _years,
            onChanged: (v) { setState(() => _selectedYear = v); _load(); },
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xff1BA3A1))))
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : _summary == null
                      ? const _EmptyReport()
                      : _YearlyTable(summary: _summary!),
        ),

        // Grand total footer
        if (_summary != null)
          _SummaryFooter(
            totalIncome: _grandIncome,
            totalExpense: _grandExpense,
            balance: _grandBalance,
          ),

        // Export button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1BA3A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(
                _isExporting ? 'Exporting…' : 'Export PDF',
                style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _YearlyTable extends StatelessWidget {
  final Map<String, Map<String, double>> summary;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  const _YearlyTable({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header row
          Container(
            decoration: BoxDecoration(
              color: const Color(0xff1BA3A1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: ['Month', 'Income', 'Expense', 'Balance']
                  .map((h) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Text(
                            h,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Month rows
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            ),
            child: Column(
              children: _months.asMap().entries.map((entry) {
                final i = entry.key;
                final month = entry.value;
                final m = summary[month] ?? {};
                final inc = m['income'] ?? 0;
                final exp = m['expense'] ?? 0;
                final bal = inc - exp;
                final hasData = inc > 0 || exp > 0;
                final isEven = i % 2 == 0;

                return Container(
                  color: isEven
                      ? (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.04))
                      : Colors.transparent,
                  child: Row(
                    children: [
                      // Month
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            month,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      // Income
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            hasData ? '₹${inc.toStringAsFixed(0)}' : '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: inc > 0
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : const Color(0xff817D8A),
                            ),
                          ),
                        ),
                      ),
                      // Expense
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            hasData ? '₹${exp.toStringAsFixed(0)}' : '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: exp > 0 ? const Color(0xffF44336) : const Color(0xff817D8A),
                            ),
                          ),
                        ),
                      ),
                      // Balance
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            hasData ? '₹${bal.toStringAsFixed(0)}' : '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: hasData
                                  ? (bal >= 0 ? const Color(0xff1BA3A1) : const Color(0xffF44336))
                                  : const Color(0xff817D8A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final void Function(String) onChanged;

  const _DropdownField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xffF2F2F3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        elevation: 1,
        items: items.map((v) => DropdownMenuItem(
          value: v,
          child: Text(v, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
        )).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class _SummaryFooter extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const _SummaryFooter({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xffF2F2F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff1BA3A1).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryCell(label: 'Income', value: '₹${totalIncome.toStringAsFixed(0)}',
              color: isDark ? Colors.white : Colors.black87),
          Container(width: 1, height: 36, color: isDark ? Colors.white12 : Colors.black12),
          _SummaryCell(label: 'Expense', value: '₹${totalExpense.toStringAsFixed(0)}',
              color: const Color(0xffF44336)),
          Container(width: 1, height: 36, color: isDark ? Colors.white12 : Colors.black12),
          _SummaryCell(
            label: 'Balance',
            value: '₹${balance.toStringAsFixed(0)}',
            color: balance >= 0 ? const Color(0xff1BA3A1) : const Color(0xffF44336),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xff817D8A))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, color: color)),
      ],
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 56, color: Color(0xff817D8A)),
          SizedBox(height: 12),
          Text('No data for this period',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xff817D8A))),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load report',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff817D8A)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1BA3A1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry', style: TextStyle(fontFamily: 'Inter')),
            ),
          ],
        ),
      ),
    );
  }
}
