import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/utils/helpers.dart';

void main() {
  group('Helpers', () {
    test('formatCurrency formats correctly', () {
      expect(Helpers.formatCurrency(1234.56), equals('\$1,234.56'));
      expect(Helpers.formatCurrency(0), equals('\$0.00'));
      expect(Helpers.formatCurrency(1000, symbol: '€'), equals('€1,000.00'));
    });

    test('formatDate formats correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(Helpers.formatDate(date), equals('2024-01-15'));
      expect(Helpers.formatDate(date, format: 'MM/dd/yyyy'), equals('01/15/2024'));
    });

    test('generateInvoiceNumber formats correctly', () {
      expect(Helpers.generateInvoiceNumber('INV-', 1), equals('INV-000001'));
      expect(Helpers.generateInvoiceNumber('EST-', 123, digits: 4), equals('EST-0123'));
    });

    test('calculateTax calculates correctly', () {
      expect(Helpers.calculateTax(100, 10), equals(10.0));
      expect(Helpers.calculateTax(200, 5), equals(10.0));
    });

    test('calculateDiscount calculates correctly', () {
      expect(Helpers.calculateDiscount(200, 10), equals(20.0));
    });

    test('calculateGrandTotal calculates correctly', () {
      expect(Helpers.calculateGrandTotal(100, 10, 9), equals(99.0));
    });

    test('isValidEmail validates correctly', () {
      expect(Helpers.isValidEmail('test@example.com'), isTrue);
      expect(Helpers.isValidEmail('invalid'), isFalse);
      expect(Helpers.isValidEmail(''), isFalse);
    });

    test('isValidPhone validates correctly', () {
      expect(Helpers.isValidPhone('+1234567890'), isTrue);
      expect(Helpers.isValidPhone('123'), isFalse);
    });

    test('truncate truncates correctly', () {
      expect(Helpers.truncate('Hello World', 5), equals('Hello...'));
      expect(Helpers.truncate('Hi', 5), equals('Hi'));
    });
  });
}
