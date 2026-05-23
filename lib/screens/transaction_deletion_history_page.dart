import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class TransactionDeletionHistoryPage extends StatefulWidget {
  const TransactionDeletionHistoryPage({super.key});

  @override
  State<TransactionDeletionHistoryPage> createState() =>
      _TransactionDeletionHistoryPageState();
}

class _TransactionDeletionHistoryPageState
    extends State<TransactionDeletionHistoryPage> {
  List<_DeletedTransaction> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('deleted_transactions')
          .orderBy('deletedAt', descending: true)
          .get();

      setState(() {
        _items = snap.docs.map((doc) {
          final d = doc.data();
          return _DeletedTransaction(
            id: doc.id,
            name: d['name'] ?? '',
            type: d['type'] ?? 'income',
            amount: (d['amount'] as num?)?.toDouble() ?? 0,
            entryDate: d['entryDate'] is Timestamp
                ? (d['entryDate'] as Timestamp).toDate()
                : null,
            description: d['description'] as String?,
            month: d['month'] ?? '',
            year: d['year'] ?? '',
            deletedAt: d['deletedAt'] is Timestamp
                ? (d['deletedAt'] as Timestamp).toDate()
                : null,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load history. Check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff1BA3A1),
          automaticallyImplyLeading: false,
          flexibleSpace: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: [
                  Image.asset('lib/assets/images/pmj white.png', height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset(
                      'lib/assets/images/Back.svg',
                      height: 40,
                      width: 40,
                    ),
                  ),
                ),
                const Text(
                  'Transaction Deletion History',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1BA3A1),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_items.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _fetch,
      color: const Color(0xff1BA3A1),
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) => _DeletedTransactionTile(item: _items[i]),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        height: 76,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading History',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: Color(0xff817D8A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1BA3A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xff1BA3A1).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 50, color: Color(0xff1BA3A1)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Deletion History',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff1BA3A1),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deleted transactions will appear here.',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: Color(0xff817D8A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Go Back',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1BA3A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────────────
class _DeletedTransaction {
  final String id;
  final String name;
  final String type;
  final double amount;
  final DateTime? entryDate;
  final String? description;
  final String month;
  final String year;
  final DateTime? deletedAt;

  bool get isIncome => type == 'income';

  _DeletedTransaction({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.entryDate,
    this.description,
    required this.month,
    required this.year,
    this.deletedAt,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile
// ─────────────────────────────────────────────────────────────────────────────
class _DeletedTransactionTile extends StatelessWidget {
  final _DeletedTransaction item;
  const _DeletedTransactionTile({required this.item});

  String _fmt(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor =
        item.isIncome ? const Color(0xff1BA3A1) : const Color(0xffF44336);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 20,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + DELETED badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.30)),
                        ),
                        child: const Text(
                          'DELETED',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Type label
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.isIncome ? 'Income' : 'Expense',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Entry date
                  Text(
                    'Date: ${_fmt(item.entryDate)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xff817D8A),
                    ),
                  ),

                  // Description
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xff817D8A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Deleted at
                  Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          size: 11, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        'Deleted: ${_fmt(item.deletedAt)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Amount + period
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${item.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.month} ${item.year}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xff817D8A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
