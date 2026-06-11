import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

part 'app_database.g.dart';

// ============================
// TABLE DEFINITIONS
// ============================

// --- Businesses ---
class Businesses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get taxNumber => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get currencySymbol => text().withDefault(const Constant('\$'))();
  RealColumn get defaultTaxRate => real().withDefault(const Constant(0.0))();
  TextColumn get invoicePrefix => text().withDefault(const Constant('INV-'))();
  TextColumn get estimatePrefix => text().withDefault(const Constant('EST-'))();
  TextColumn get purchaseOrderPrefix => text().withDefault(const Constant('PO-'))();
  TextColumn get creditNotePrefix => text().withDefault(const Constant('CN-'))();
  TextColumn get expensePrefix => text().withDefault(const Constant('EXP-'))();
  TextColumn get notes => text().nullable()();
  TextColumn get dateFormat => text().withDefault(const Constant('yyyy-MM-dd'))();
  TextColumn get numberFormat => text().withDefault(const Constant('en_US'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Customers ---
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get taxNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Suppliers ---
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get taxNumber => text().nullable()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Product Categories ---
class ProductCategories extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Products ---
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get categoryId => text().references(ProductCategories, #id).nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0.0))();
  RealColumn get quantity => real().withDefault(const Constant(0.0))();
  RealColumn get reorderLevel => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Inventory Transactions ---
class InventoryTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get type => text()(); // 'stock_in', 'stock_out', 'adjustment'
  RealColumn get quantity => real()();
  RealColumn get unitCost => real().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get referenceType => text().nullable()(); // 'invoice', 'purchase_order', 'adjustment'
  TextColumn get referenceId => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Invoices ---
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get customerId => text().references(Customers, #id).nullable()();
  TextColumn get invoiceNumber => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  // draft, sent, paid, partial, overdue, cancelled
  IntColumn get invoiceDate => integer()();
  IntColumn get dueDate => integer()();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get balanceDue => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get currencySymbol => text().withDefault(const Constant('\$'))();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();
  TextColumn get notes => text().nullable()();
  TextColumn get termsAndConditions => text().nullable()();
  TextColumn get templateStyle => text().withDefault(const Constant('modern'))();
  // modern, classic, simple
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringInterval => text().nullable()();
  // daily, weekly, biweekly, monthly, quarterly, yearly
  IntColumn get recurringNextDate => integer().nullable()();
  IntColumn get recurringEndDate => integer().nullable()();
  BoolColumn get isPurchaseOrder => boolean().withDefault(const Constant(false))();
  TextColumn get supplierId => text().references(Suppliers, #id).nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Invoice Items ---
class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get productId => text().references(Products, #id).nullable()();
  TextColumn get description => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Payments ---
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get invoiceId => text().references(Invoices, #id).nullable()();
  TextColumn get customerId => text().references(Customers, #id).nullable()();
  TextColumn get paymentNumber => text()();
  RealColumn get amount => real()();
  TextColumn get method => text()(); // cash, bank_transfer, credit_card, debit_card, mobile_wallet, custom
  TextColumn get reference => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isRefund => boolean().withDefault(const Constant(false))();
  IntColumn get paymentDate => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Estimates ---
class Estimates extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get customerId => text().references(Customers, #id).nullable()();
  TextColumn get estimateNumber => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  // draft, sent, approved, rejected
  IntColumn get estimateDate => integer()();
  IntColumn get expiryDate => integer()();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get currencySymbol => text().withDefault(const Constant('\$'))();
  TextColumn get notes => text().nullable()();
  TextColumn get termsAndConditions => text().nullable()();
  TextColumn get convertedInvoiceId => text().references(Invoices, #id).nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Estimate Items ---
class EstimateItems extends Table {
  TextColumn get id => text()();
  TextColumn get estimateId => text().references(Estimates, #id)();
  TextColumn get productId => text().references(Products, #id).nullable()();
  TextColumn get description => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Expenses ---
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get expenseNumber => text()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  IntColumn get expenseDate => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Credit Notes ---
class CreditNotes extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get invoiceId => text().references(Invoices, #id).nullable()();
  TextColumn get customerId => text().references(Customers, #id).nullable()();
  TextColumn get creditNoteNumber => text()();
  TextColumn get reason => text()(); // return, refund, adjustment
  RealColumn get amount => real()();
  IntColumn get creditNoteDate => integer()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Tax Rates ---
class TaxRates extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get name => text()();
  TextColumn get type => text()(); // gst, vat, sales_tax, custom
  RealColumn get rate => real()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Currencies ---
class Currencies extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Audit Logs ---
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get entityType => text()(); // customer, product, invoice, etc.
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // create, update, delete, restore
  TextColumn get changes => text()(); // JSON string of changes
  TextColumn get userId => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Deleted Items (Trash/Recycle Bin) ---
class DeletedItems extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get entityType => text()(); // customer, product, invoice, etc.
  TextColumn get entityId => text()();
  TextColumn get entityData => text()(); // JSON of full entity data
  IntColumn get deletedAt => integer()();
  IntColumn get expiresAt => integer()(); // auto-delete after 30 days

  @override
  Set<Column> get primaryKey => {id};
}

// --- App Settings ---
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

// --- Invoice Numbering Sequence ---
class InvoiceNumbering extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get prefix => text()();
  TextColumn get type => text()(); // invoice, estimate, purchase_order, credit_note, expense
  IntColumn get lastNumber => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================
// DATABASE CLASS
// ============================

@DriftDatabase(
  tables: [
    Businesses,
    Customers,
    Suppliers,
    ProductCategories,
    Products,
    InventoryTransactions,
    Invoices,
    InvoiceItems,
    Payments,
    Estimates,
    EstimateItems,
    Expenses,
    CreditNotes,
    TaxRates,
    Currencies,
    AuditLogs,
    DeletedItems,
    AppSettings,
    InvoiceNumbering,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([String? password]) : super(_openConnection(password));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Handle future migrations here
      },
    );
  }
}

LazyDatabase _openConnection([String? password]) {
  // Use sqlcipher (from sqlcipher_flutter_libs) instead of plain sqlite3
  // This provides the SQLite native library via libsqlcipher.so
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'invoice_pro.db'));
    return NativeDatabase(
      file,
      setup: (rawDb) {
        if (password != null) {
          rawDb.execute("PRAGMA key = '$password';");
        }
      },
    );
  });
}
