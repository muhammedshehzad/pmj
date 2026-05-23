import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

/// Admin-only screen to approve/reject sign-up requests and manage roles
/// for existing users. Reads from `donorUsers` collection.
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset('lib/assets/images/Back.svg',
                        height: 40, width: 40),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Manage Users',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1BA3A1),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xff1BA3A1),
            unselectedLabelColor: const Color(0xff817D8A),
            indicatorColor: const Color(0xff1BA3A1),
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13),
            unselectedLabelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 13),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _UserList(filterStatus: 'pending'),
                _UserList(filterStatus: 'approved'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String filterStatus;
  const _UserList({required this.filterStatus});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('donorUsers')
        .where('status', isEqualTo: filterStatus);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              ),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filterStatus == 'pending'
                      ? Icons.inbox_outlined
                      : Icons.people_outline,
                  size: 56,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  filterStatus == 'pending'
                      ? 'No pending requests'
                      : 'No approved users yet',
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

        // Sort: newest first by createdAt
        final sorted = docs.toList()
          ..sort((a, b) {
            final ta = (a.data() as Map<String, dynamic>)['createdAt']
                as Timestamp?;
            final tb = (b.data() as Map<String, dynamic>)['createdAt']
                as Timestamp?;
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sorted.length,
          itemBuilder: (_, i) =>
              _UserCard(doc: sorted[i], isPending: filterStatus == 'pending'),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isPending;
  const _UserCard({required this.doc, required this.isPending});

  Future<void> _approve(BuildContext context, String role) async {
    try {
      await doc.reference.update({
        'status': 'approved',
        'role': role,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved as $role'),
            backgroundColor: const Color(0xff1BA3A1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to approve: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request?',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        content: const Text(
            'The user will not be able to sign in. They can be re-approved '
            'from the Approved tab if needed.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style:
                    TextStyle(fontFamily: 'Inter', color: Color(0xff817D8A))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject',
                style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.red,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await doc.reference.update({'status': 'rejected'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User rejected'),
              backgroundColor: Color(0xffF44336)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeRole(BuildContext context, String currentRole) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: const Text('Change Role',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        children: [
          for (final r in const ['admin', 'collector', 'donor'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Row(
                children: [
                  Icon(
                    r == currentRole
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: const Color(0xff1BA3A1),
                  ),
                  const SizedBox(width: 8),
                  Text(_roleLabel(r),
                      style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
    if (newRole == null || newRole == currentRole) return;
    try {
      await doc.reference.update({'role': newRole});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role changed to ${_roleLabel(newRole)}'),
            backgroundColor: const Color(0xff1BA3A1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'collector':
        return 'Donation Collector';
      case 'donor':
        return 'Donor';
      default:
        return role;
    }
  }

  Future<void> _showApproveDialog(
      BuildContext context, String requestedRole) async {
    String selected = (requestedRole == 'admin') ? 'admin' : 'collector';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Approve User',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Requested role: ${_roleLabel(requestedRole)}',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xff817D8A)),
              ),
              const SizedBox(height: 12),
              const Text('Assign role:',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              for (final r in const ['admin', 'collector', 'donor'])
                RadioListTile<String>(
                  title: Text(_roleLabel(r),
                      style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 13)),
                  value: r,
                  groupValue: selected,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xff1BA3A1),
                  onChanged: (v) => setState(() => selected = v ?? selected),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style:
                      TextStyle(fontFamily: 'Inter', color: Color(0xff817D8A))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1BA3A1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      await _approve(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data['email'] as String? ?? '';
    final name = data['name'] as String? ?? '—';
    final role = data['role'] as String? ?? 'donor';
    final requestedRole = data['requestedRole'] as String? ?? role;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final dateLabel = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xff1BA3A1).withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xff1BA3A1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xff817D8A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xff1BA3A1).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPending ? _roleLabel(requestedRole) : _roleLabel(role),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1BA3A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Requested: $dateLabel',
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Color(0xff817D8A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(context, requestedRole),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Approve',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1BA3A1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Reject',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _changeRole(context, role),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Change Role',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff1BA3A1),
                      side: const BorderSide(color: Color(0xff1BA3A1)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Revoke',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
