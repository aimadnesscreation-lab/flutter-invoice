class AppConstants {
  AppConstants._();

  static const String appName = 'Invoice Pro';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Invoice Pro';

  // Database
  static const String databaseName = 'invoice_pro.db';
  static const int databaseVersion = 1;

  // Invoice
  static const String defaultInvoicePrefix = 'INV-';
  static const String defaultEstimatePrefix = 'EST-';
  static const String defaultPurchaseOrderPrefix = 'PO-';
  static const String defaultExpensePrefix = 'EXP-';
  static const String defaultCreditNotePrefix = 'CN-';
  static const int defaultInvoiceNumberDigits = 6;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Charts
  static const int chartAnimationDurationMs = 500;

  // Security
  static const String pinCodeKey = 'app_pin_code';
  static const String isBiometricEnabledKey = 'is_biometric_enabled';
  static const String autoLockDurationKey = 'auto_lock_duration';

  // Theme
  static const String themeModeKey = 'theme_mode';

  // Backup
  static const String backupFileNamePattern = 'invoice_pro_backup_';

  // Currency
  static const String defaultCurrency = 'USD';
  static const String defaultCurrencySymbol = '\$';

  // Date formats
  static const String defaultDateFormat = 'yyyy-MM-dd';
  static const String defaultDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String defaultTimeFormat = 'HH:mm:ss';

  // Recurring invoice intervals
  static const List<String> recurringIntervals = [
    'Daily',
    'Weekly',
    'Biweekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];
}
