import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../models/donation_model.dart';
import '../providers/transaction_provider.dart';
import '../services/local_database_service.dart';
import '../assets/custom widgets/transition.dart';
import 'add_edit_transaction_screen.dart';
import 'attachment_viewer_screen.dart';
import 'transaction_report_screen.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  // Donation state lifted up so All / Income tabs share it.
  final LocalDatabaseService _localDb = LocalDatabaseService();
  List<Donation> _donations = [];
  bool _donationsLoaded = false;
  StreamSubscription<List<Donation>>? _donationSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _subscribeDonations();
  }

  void _subscribeDonations() {
    _donationSub?.cancel();
    _donationSub = _localDb.watchDonations().listen((list) {
      if (mounted) {
        setState(() {
          _donations = list
              .where((d) => d.status == 'paid' && d.hideFromHistory != true)
              .toList();
          _donationsLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _donationSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    Provider.of<TransactionProvider>(context, listen: false).init();
    setState(() => _donationsLoaded = false);
    _subscribeDonations();
    // Give the indicator something to show.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Aggregate paid donations by month/year into a single bucket per month.
  List<_DonationGroup> _aggregateDonations() {
    if (_donations.isEmpty) return const [];

    const monthsOrder = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12,
    };

    final grouped = <String, List<Donation>>{};
    for (final d in _donations) {
      final key = '${d.month}_${d.year}';
      grouped.putIfAbsent(key, () => []).add(d);
    }

    final out = <_DonationGroup>[];
    for (final entry in grouped.entries) {
      final list = entry.value;
      final first = list.first;
      final total = list.fold<double>(
          0, (s, d) => s + (d.totalDonationAmount ?? d.amount));
      final monthIdx = monthsOrder[first.month] ?? 1;
      final year = int.tryParse(first.year) ?? 2000;
      // Sort key: end-of-month so the group sits at the end of its month
      // section (transactions for that month appear above it).
      final sortDate = DateTime(year, monthIdx + 1, 0, 23, 59);
      out.add(_DonationGroup(
        month: first.month,
        year: first.year,
        total: total,
        donations: list,
        sortDate: sortDate,
      ));
    }
    out.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return out;
  }

  Future<bool> _confirmDelete(BuildContext ctx, TransactionModel tx) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: Theme.of(ctx).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Text(
              'Delete Transaction',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
            ),
            content: Text(
              'Delete "${tx.name}"? This cannot be undone.',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel',
                    style: TextStyle(fontFamily: 'Inter', color: Color(0xff817D8A))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Delete',
                    style: TextStyle(
                        fontFamily: 'Inter', color: Colors.red, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _openAddScreen() {
    Navigator.push(
      context,
      SlidingPageTransitionRL(page: const AddEditTransactionScreen()),
    );
  }

  void _openEditScreen(TransactionModel tx) {
    Navigator.push(
      context,
      SlidingPageTransitionRL(page: AddEditTransactionScreen(transaction: tx)),
    );
  }

  void _openReport() {
    Navigator.push(
      context,
      SlidingPageTransitionRL(page: const TransactionReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Tab bar + report button
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xff1BA3A1),
                  unselectedLabelColor: const Color(0xff817D8A),
                  indicatorColor: const Color(0xff1BA3A1),
                  indicatorWeight: 2,
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
                    Tab(text: 'All'),
                    Tab(text: 'Income'),
                    Tab(text: 'Expense'),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openReport,
                icon: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xff1BA3A1), size: 22),
                tooltip: 'Reports',
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
                  ),
                );
              }

              if (provider.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load transactions',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xff817D8A)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.init(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1BA3A1),
                            foregroundColor: Colors.white,
                          ),
                          child:
                              const Text('Retry', style: TextStyle(fontFamily: 'Inter')),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final donationGroups = _aggregateDonations();

              Future<void> handleDelete(TransactionModel tx) async {
                final confirmed = await _confirmDelete(context, tx);
                if (!confirmed) return;
                try {
                  await provider.deleteTransaction(tx.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction deleted'),
                        backgroundColor: Color(0xff1BA3A1),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not delete. Try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }

              return Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _AllTab(
                        transactions: provider.transactions,
                        donationGroups: donationGroups,
                        donationsLoaded: _donationsLoaded,
                        onRefresh: _refreshAll,
                        onEdit: _openEditScreen,
                        onDelete: handleDelete,
                      ),
                      _TransactionList(
                        transactions: provider.incomeTransactions,
                        donationGroups: donationGroups,
                        donationsLoaded: _donationsLoaded,
                        onRefresh: _refreshAll,
                        onEdit: _openEditScreen,
                        onDelete: handleDelete,
                      ),
                      _TransactionList(
                        transactions: provider.expenseTransactions,
                        donationGroups: const [],
                        donationsLoaded: true,
                        onRefresh: _refreshAll,
                        onEdit: _openEditScreen,
                        onDelete: handleDelete,
                      ),
                    ],
                  ),
                  // FAB
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'transactions_fab',
                      onPressed: _openAddScreen,
                      backgroundColor: const Color(0xff1BA3A1),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Per-month donation aggregate. One bucket per (month, year).
// ──────────────────────────────────────────────────────────────────────────────
class _DonationGroup {
  final String month;
  final String year;
  final double total;
  final List<Donation> donations;
  final DateTime sortDate;

  _DonationGroup({
    required this.month,
    required this.year,
    required this.total,
    required this.donations,
    required this.sortDate,
  });

  String get monthYearLabel => '$month $year';
}

// ──────────────────────────────────────────────────────────────────────────────
// Flat list row — either a month header or an item
// ──────────────────────────────────────────────────────────────────────────────
sealed class _Row {}

class _HeaderRow extends _Row {
  final String label; // "April 2026"
  final double net;   // positive = net income, negative = net expense
  _HeaderRow(this.label, this.net);
}

class _FeedRow extends _Row {
  final _FeedItem item;
  _FeedRow(this.item);
}

// ──────────────────────────────────────────────────────────────────────────────
// Feed item (used by All / Income tabs)
// ──────────────────────────────────────────────────────────────────────────────
class _FeedItem {
  final TransactionModel? transaction;
  final _DonationGroup? donationGroup;
  final DateTime date;
  final bool isDonationGroup;

  _FeedItem.transaction(this.transaction)
      : donationGroup = null,
        isDonationGroup = false,
        date = transaction!.entryDate;

  _FeedItem.donationGroup(this.donationGroup)
      : transaction = null,
        isDonationGroup = true,
        date = donationGroup!.sortDate;
}

// ──────────────────────────────────────────────────────────────────────────────
// Groups a flat list into [header, item, item, header, item …]
// ──────────────────────────────────────────────────────────────────────────────
List<_Row> _groupFeedByMonth(List<_FeedItem> feed) {
  // feed is already sorted descending by date
  final rows = <_Row>[];
  String? currentLabel;

  for (final item in feed) {
    final label = DateFormat('MMMM yyyy').format(item.date);
    if (label != currentLabel) {
      double net = 0;
      for (final i in feed.where(
          (e) => DateFormat('MMMM yyyy').format(e.date) == label)) {
        if (i.isDonationGroup) {
          net += i.donationGroup!.total;
        } else {
          final tx = i.transaction!;
          net += tx.isIncome ? tx.amount : -tx.amount;
        }
      }
      rows.add(_HeaderRow(label, net));
      currentLabel = label;
    }
    rows.add(_FeedRow(item));
  }
  return rows;
}

// ──────────────────────────────────────────────────────────────────────────────
// Month header widget
// ──────────────────────────────────────────────────────────────────────────────
class _MonthHeader extends StatelessWidget {
  final String label;
  final double net;

  const _MonthHeader({required this.label, required this.net});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final netColor = net >= 0 ? const Color(0xff1BA3A1) : const Color(0xffF44336);
    final netPrefix = net >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xff555555),
            ),
          ),
          Text(
            '$netPrefix₹${net.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: netColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// "All" tab: transactions + per-month donation totals, grouped by month
// ──────────────────────────────────────────────────────────────────────────────
class _AllTab extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<_DonationGroup> donationGroups;
  final bool donationsLoaded;
  final Future<void> Function() onRefresh;
  final void Function(TransactionModel) onEdit;
  final void Function(TransactionModel) onDelete;

  const _AllTab({
    required this.transactions,
    required this.donationGroups,
    required this.donationsLoaded,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AllTab> createState() => _AllTabState();
}

class _AllTabState extends State<_AllTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<_FeedItem> _buildFeed() {
    final items = <_FeedItem>[
      for (final tx in widget.transactions) _FeedItem.transaction(tx),
      for (final g in widget.donationGroups) _FeedItem.donationGroup(g),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.donationsLoaded && widget.transactions.isEmpty) {
      return _LoadingShimmerList();
    }

    final feed = _buildFeed();
    if (feed.isEmpty) return const _EmptyState(message: 'No transactions yet');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = _groupFeedByMonth(feed);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: const Color(0xff1BA3A1),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length + (widget.donationsLoaded ? 0 : 1),
        itemBuilder: (context, index) {
          if (!widget.donationsLoaded && index == 0) {
            return const _DonationsLoadingIndicator();
          }

          final rowIndex = widget.donationsLoaded ? index : index - 1;
          final row = rows[rowIndex];

          if (row is _HeaderRow) {
            return _MonthHeader(label: row.label, net: row.net);
          }

          final feedRow = row as _FeedRow;
          final item = feedRow.item;
          final showDivider = rowIndex > 0 && rows[rowIndex - 1] is! _HeaderRow;

          final tile = item.isDonationGroup
              ? _DonationGroupTile(group: item.donationGroup!)
              : _TransactionTile(
                  tx: item.transaction!,
                  onEdit: () => widget.onEdit(item.transaction!),
                  onDelete: () => widget.onDelete(item.transaction!),
                );

          if (showDivider) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                tile,
              ],
            );
          }
          return tile;
        },
      ),
    );
  }
}

class _DonationsLoadingIndicator extends StatelessWidget {
  const _DonationsLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Loading donations…',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xff817D8A),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 120, color: Colors.grey[200]),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 180, color: Colors.grey[200]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(height: 14, width: 50, color: Colors.grey[200]),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Income / Expense tab — grouped by month. Income tab also receives
// per-month donation totals; Expense tab passes an empty list.
// ──────────────────────────────────────────────────────────────────────────────
class _TransactionList extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<_DonationGroup> donationGroups;
  final bool donationsLoaded;
  final Future<void> Function() onRefresh;
  final void Function(TransactionModel) onEdit;
  final void Function(TransactionModel) onDelete;

  const _TransactionList({
    required this.transactions,
    required this.donationGroups,
    required this.donationsLoaded,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<_TransactionList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<_FeedItem> _buildFeed() {
    final items = <_FeedItem>[
      for (final tx in widget.transactions) _FeedItem.transaction(tx),
      for (final g in widget.donationGroups) _FeedItem.donationGroup(g),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final feed = _buildFeed();

    if (feed.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: const Color(0xff1BA3A1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            _EmptyState(message: 'No entries yet'),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = _groupFeedByMonth(feed);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: const Color(0xff1BA3A1),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length + (widget.donationsLoaded ? 0 : 1),
        itemBuilder: (context, index) {
          if (!widget.donationsLoaded && index == 0) {
            return const _DonationsLoadingIndicator();
          }

          final rowIndex = widget.donationsLoaded ? index : index - 1;
          final row = rows[rowIndex];

          if (row is _HeaderRow) {
            return _MonthHeader(label: row.label, net: row.net);
          }

          final feedRow = row as _FeedRow;
          final item = feedRow.item;
          final showDivider = rowIndex > 0 && rows[rowIndex - 1] is! _HeaderRow;

          final tile = item.isDonationGroup
              ? _DonationGroupTile(group: item.donationGroup!)
              : _TransactionTile(
                  tx: item.transaction!,
                  onEdit: () => widget.onEdit(item.transaction!),
                  onDelete: () => widget.onDelete(item.transaction!),
                );

          if (showDivider) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                tile,
              ],
            );
          }
          return tile;
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Transaction tile — swipe-to-delete + tap to open detail sheet
// ──────────────────────────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionTile({required this.tx, required this.onEdit, required this.onDelete});

  void _openDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(
        tx: tx,
        onEdit: () {
          Navigator.pop(context);
          onEdit();
        },
        onDelete: () {
          Navigator.pop(context);
          onDelete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final amountColor = isIncome ? const Color(0xff1BA3A1) : const Color(0xffF44336);
    final hasAttachment = tx.attachmentUrl != null && tx.attachmentUrl!.isNotEmpty;

    return Dismissible(
      key: Key('tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: () => _openDetailSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 20,
                  color: amountColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.formattedDate,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xff817D8A),
                      ),
                    ),
                    if (tx.description != null && tx.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tx.description!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xff817D8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx.formattedAmount,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: amountColor,
                    ),
                  ),
                  if (hasAttachment)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.attach_file_rounded,
                          size: 12, color: Color(0xff817D8A)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Transaction detail bottom sheet
// ──────────────────────────────────────────────────────────────────────────────
class _TransactionDetailSheet extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionDetailSheet({
    required this.tx,
    required this.onEdit,
    required this.onDelete,
  });

  void _openFullScreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttachmentViewerScreen(url: url, label: tx.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = tx.isIncome;
    final amountColor = isIncome ? const Color(0xff1BA3A1) : const Color(0xffF44336);
    final hasAttachment = tx.attachmentUrl != null && tx.attachmentUrl!.isNotEmpty;
    final isImage = hasAttachment && AttachmentViewerScreen.isImage(tx.attachmentUrl!);
    final isVideo = hasAttachment && AttachmentViewerScreen.isVideo(tx.attachmentUrl!);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Type badge + amount row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 24,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: amountColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isIncome ? 'Income' : 'Expense',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: amountColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      tx.formattedAmount,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),

                // Date
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: tx.formattedDate,
                  isDark: isDark,
                ),

                // Description
                if (tx.description != null && tx.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Note',
                    value: tx.description!,
                    isDark: isDark,
                    multiline: true,
                  ),
                ],

                // Attachment section
                if (hasAttachment) ...[
                  const SizedBox(height: 16),
                  Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.black12),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.attach_file_rounded,
                          size: 14, color: const Color(0xff817D8A)),
                      const SizedBox(width: 6),
                      const Text(
                        'Attachment',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff817D8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (isImage)
                    GestureDetector(
                      onTap: () => _openFullScreen(context, tx.attachmentUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Image.network(
                              tx.attachmentUrl!,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : Container(
                                          height: 220,
                                          color: isDark
                                              ? const Color(0xFF2A2A2A)
                                              : const Color(0xffF2F2F3),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Color(0xff1BA3A1)),
                                            ),
                                          ),
                                        ),
                              errorBuilder: (_, __, ___) => Container(
                                height: 100,
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xffF2F2F3),
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      color: Color(0xff817D8A), size: 32),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_out_map_rounded,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tap to expand',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => _openFullScreen(context, tx.attachmentUrl!),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xff1BA3A1).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xff1BA3A1).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xff1BA3A1)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isVideo
                                    ? Icons.play_circle_outline_rounded
                                    : Icons.insert_drive_file_outlined,
                                color: const Color(0xff1BA3A1),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'View attachment',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff1BA3A1),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Opens with your device\'s default app',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: Color(0xff817D8A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded,
                                size: 16, color: Color(0xff1BA3A1)),
                          ],
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                // Edit + Delete buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff1BA3A1),
                          side: const BorderSide(color: Color(0xff1BA3A1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffF44336),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool multiline;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: const Color(0xff817D8A)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xff817D8A),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xff101011),
            ),
            maxLines: multiline ? 5 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Per-month donation aggregate tile — single row showing the month's total.
// Tapping it opens a sheet listing the individual donations.
// ──────────────────────────────────────────────────────────────────────────────
class _DonationGroupTile extends StatelessWidget {
  final _DonationGroup group;

  const _DonationGroupTile({required this.group});

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MonthDonationsSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donorCount = group.donations.length;

    return InkWell(
      onTap: () => _openSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xff1BA3A1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.volunteer_activism_rounded,
                  size: 20, color: Color(0xff1BA3A1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donations · ${group.monthYearLabel}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$donorCount ${donorCount == 1 ? 'donor' : 'donors'} · tap to view',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xff817D8A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${group.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xff1BA3A1),
                  ),
                ),
                const Text(
                  'Total',
                  style: TextStyle(
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

// ──────────────────────────────────────────────────────────────────────────────
// Bottom sheet — lists all individual donations for a month group.
// ──────────────────────────────────────────────────────────────────────────────
class _MonthDonationsSheet extends StatelessWidget {
  final _DonationGroup group;

  const _MonthDonationsSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    // Sort donations: most recent first (by parsed date or fallback by name)
    final sorted = List<Donation>.from(group.donations)
      ..sort((a, b) => b.date.compareTo(a.date));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xff1BA3A1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded,
                          color: Color(0xff1BA3A1)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Donations · ${group.monthYearLabel}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${sorted.length} ${sorted.length == 1 ? 'donor' : 'donors'}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xff817D8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${group.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xff1BA3A1),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1, color: isDark ? Colors.white12 : Colors.black12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark ? Colors.white10 : Colors.black12),
                  itemBuilder: (_, i) {
                    final d = sorted[i];
                    final amount = d.totalDonationAmount ?? d.amount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xff1BA3A1),
                            backgroundImage: (d.imageUrl != null &&
                                    d.imageUrl!.isNotEmpty)
                                ? NetworkImage(d.imageUrl!)
                                : null,
                            child:
                                (d.imageUrl == null || d.imageUrl!.isEmpty)
                                    ? Text(
                                        d.name.isNotEmpty
                                            ? d.name[0].toUpperCase()
                                            : '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (d.date.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    d.date,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: Color(0xff817D8A),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '₹${amount.toStringAsFixed(0)}',
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xff817D8A),
            ),
          ),
        ],
      ),
    );
  }
}
