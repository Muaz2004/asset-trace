/// Core application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Asset Trace';
  static const String appTagline = 'Campus PC Ownership Registration & Verification';
  static const String institutionName = 'Addis Ababa University';

  // Firestore collection names
  static const String staffCollection = 'staff';
  static const String registrationsCollection = 'registrations';
  static const String activeSerialsCollection = 'active_serials';
  static const String verificationLogsCollection = 'verification_logs';

  // Cloudinary configuration (Unsigned upload)
  static const String cloudinaryCloudName = 'cyk4nxfd';
  static const String cloudinaryUploadPreset = 'aau_pc_verify';
  static const String cloudinaryFolder = 'aau-pc-verify';
  static const String cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // UI Strings
  static const String loginTitle = 'Staff Portal';
  static const String loginSubtitle = 'Sign in with your authorized university credentials';
}
