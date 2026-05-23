/// Single source of truth for all environment-level configuration.
/// In production, replace hardcoded values with Firebase Remote Config
/// or a build-time --dart-define so nothing sensitive lives in source.
class AppConfig {
  AppConfig._();

  // ── Cloudinary ──────────────────────────────────────────────────────────────
  static const cloudinaryCloudName = 'dfcehequr';
  static const cloudinaryUploadPreset = 'images';
  static String get cloudinaryUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/upload';

  // ── Firestore collection names ───────────────────────────────────────────────
  static const colDonors = 'donors';
  static const colDonations = 'donations';
  static const colTransactions = 'transactions';
  static const colDonorUsers = 'donorUsers';
  static const subColPaymentStatus = 'paymentStatus';

  // ── Pagination ───────────────────────────────────────────────────────────────
  static const donorPageSize = 30;
  static const donationPageSize = 30;

  // ── Sync throttle (seconds) ──────────────────────────────────────────────────
  static const homeRefreshThrottleSeconds = 30;
}
