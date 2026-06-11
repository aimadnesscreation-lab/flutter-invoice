import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static String formatCurrency(double amount, {String symbol = '\$', int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(date);
  }

  static String formatDateTime(DateTime date, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    return DateFormat(format).format(date);
  }

  static String generateInvoiceNumber(String prefix, int number, {int digits = 6}) {
    return '$prefix${number.toString().padLeft(digits, '0')}';
  }

  static double calculateTax(double amount, double taxRate) {
    return amount * (taxRate / 100);
  }

  static double calculateDiscount(double amount, double discountRate) {
    return amount * (discountRate / 100);
  }

  static double calculateGrandTotal(
    double subtotal,
    double discountAmount,
    double taxAmount,
  ) {
    return subtotal - discountAmount + taxAmount;
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s-]{7,15}$').hasMatch(phone);
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
