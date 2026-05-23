import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Centralised role + capability source of truth.
///
/// Updated by:
///  - [AppAuthRouter] on app start (splash)
///  - [LoginProvider] after successful sign-in
///  - The Firestore stream this class binds to once a role is set, so role
///    changes made by an admin in "Manage Users" reflect in the running app
///    without requiring the user to log out and back in.
///
/// Roles:
///  - `admin`     — full access
///  - `collector` — donation-collector: Donor list (view-only), Payments tab
///  - `donor`     — end-user (their own data only, separate dashboard)
///  - `none`      — signed out / unknown
class Permissions extends ChangeNotifier {
  String _role = 'none';
  String get role => _role;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;
  bool _disposed = false;

  bool get isAdmin => _role == 'admin';
  bool get isCollector => _role == 'collector';
  bool get isDonor => _role == 'donor';

  // ── Bottom-nav tab visibility ───────────────────────────────────────────
  bool get canSeeHomeTab => _role == 'admin' || _role == 'collector';
  bool get canSeeDonorTab => _role == 'admin' || _role == 'collector';
  bool get canSeePaymentsTab => _role == 'admin' || _role == 'collector';
  bool get canSeeAccountsTab => _role == 'admin';
  bool get canSeeSettingsTab => _role == 'admin' || _role == 'collector';

  // ── Donor module actions ────────────────────────────────────────────────
  bool get canAddDonor => _role == 'admin';
  bool get canEditDonor => _role == 'admin';
  bool get canDeleteDonor => _role == 'admin';

  // ── Payment / donation actions ──────────────────────────────────────────
  bool get canRecordPayment => _role == 'admin' || _role == 'collector';
  bool get canEditPayment => _role == 'admin';
  bool get canDeletePayment => _role == 'admin';

  // ── Accounts / transactions ─────────────────────────────────────────────
  bool get canManageTransactions => _role == 'admin';

  // ── Admin-only configuration ────────────────────────────────────────────
  bool get canManageUsers => _role == 'admin';
  bool get canManageUpi => _role == 'admin';
  bool get canViewDeletionHistory => _role == 'admin';

  /// Set the role explicitly (used right after login while the Firestore
  /// listener is still spinning up).
  void setRole(String role) {
    if (_role != role) {
      _role = role;
      if (!_disposed) notifyListeners();
    }
  }

  /// Bind to the current user's `donorUsers/{uid}` doc so role changes
  /// applied by an admin (e.g. demotion / promotion) take effect immediately.
  ///
  /// Safe to call repeatedly — the previous subscription is cancelled first.
  /// If the user is signed out or no record exists, the listener is a no-op.
  void bindToCurrentUser() {
    _docSub?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _docSub = FirebaseFirestore.instance
        .collection('donorUsers')
        .doc(user.uid)
        .snapshots()
        .listen(
      (doc) {
        if (!doc.exists) return; // legacy admin accounts have no doc — leave role as-is
        final data = doc.data();
        if (data == null) return;
        final liveRole = (data['role'] as String?) ?? _role;
        final liveStatus = (data['status'] as String?) ?? 'approved';

        if (liveStatus != 'approved') {
          // Account got revoked/suspended while user is logged in.
          // Drop the role; the next user action that gates on it will be
          // hidden, and the next app launch will route them through the
          // approval gate in AppAuthRouter.
          if (_role != 'none') {
            _role = 'none';
            if (!_disposed) notifyListeners();
          }
          return;
        }
        setRole(liveRole);
      },
      onError: (e) {
        debugPrint('Permissions stream error: $e');
      },
    );
  }

  void clear() {
    _docSub?.cancel();
    _docSub = null;
    if (_role != 'none') {
      _role = 'none';
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _docSub?.cancel();
    super.dispose();
  }
}
