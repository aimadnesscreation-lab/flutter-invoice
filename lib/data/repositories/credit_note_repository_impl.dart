import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/credit_note_model.dart';
import 'package:invoice_pro/domain/entities/credit_note.dart' as domain;
import 'package:invoice_pro/domain/repositories/credit_note_repository.dart';

class CreditNoteRepositoryImpl implements CreditNoteRepository {
  final AppDatabase _db;
  final Map<String, int> _counters = {};

  CreditNoteRepositoryImpl(this._db);

  @override
  Future<List<domain.CreditNote>> getAllCreditNotes(String businessId, {String? invoiceId, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    var allRows = await (_db.creditNotes.select()
      ..where((t) => t.businessId.equals(businessId))).get();
    var rows = allRows;

    if (invoiceId != null) {
      rows = rows.where((r) => r.invoiceId == invoiceId).toList();
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paged = rows.skip(offset).take(pageSize).toList();

    final result = <domain.CreditNote>[];
    for (final r in paged) {
      result.add(await _toEntity(r));
    }
    return result;
  }

  @override
  Future<domain.CreditNote?> getCreditNoteById(String id) async {
    final row = await (_db.creditNotes.select()
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<domain.CreditNote> createCreditNote(domain.CreditNote creditNote) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final model = CreditNoteModel(
      id: id,
      businessId: creditNote.businessId,
      invoiceId: creditNote.invoiceId,
      invoiceNumber: creditNote.invoiceNumber,
      customerId: creditNote.customerId,
      customerName: creditNote.customerName,
      creditNoteNumber: creditNote.creditNoteNumber,
      reason: creditNote.reason,
      amount: creditNote.amount,
      creditNoteDate: creditNote.creditNoteDate,
      notes: creditNote.notes,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.creditNotes).insert(CreditNotesCompanion.insert(
      id: model.id,
      businessId: model.businessId,
      invoiceId: Value(model.invoiceId),
      customerId: Value(model.customerId),
      creditNoteNumber: model.creditNoteNumber,
      reason: model.reason,
      amount: model.amount,
      creditNoteDate: model.creditNoteDate.millisecondsSinceEpoch,
      notes: Value(model.notes),
      createdAt: model.createdAt.millisecondsSinceEpoch,
      updatedAt: model.updatedAt.millisecondsSinceEpoch,
    ));
    return model.toEntity();
  }

  @override
  Future<void> deleteCreditNote(String id) async {
    await (_db.creditNotes.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<String> generateCreditNoteNumber(String businessId, String prefix) async {
    _counters[businessId] = (_counters[businessId] ?? 0) + 1;
    return '$prefix${_counters[businessId]!.toString().padLeft(6, '0')}';
  }

  Future<domain.CreditNote> _toEntity(CreditNote row) async {
    final map = _rowToMap(row);
    // Populate denormalized fields from related tables
    if (row.invoiceId != null) {
      final invoice = await (_db.invoices.select()
        ..where((t) => t.id.equals(row.invoiceId!))).getSingleOrNull();
      if (invoice != null) {
        map['invoice_number'] = invoice.invoiceNumber;
      }
    }
    if (row.customerId != null) {
      final customer = await (_db.customers.select()
        ..where((t) => t.id.equals(row.customerId!))).getSingleOrNull();
      if (customer != null) {
        map['customer_name'] = customer.name;
      }
    }
    return CreditNoteModel.fromMap(map).toEntity();
  }

  Map<String, dynamic> _rowToMap(CreditNote row) {
    return {
      'id': row.id,
      'business_id': row.businessId,
      'invoice_id': row.invoiceId,
      'invoice_number': null,
      'customer_id': row.customerId,
      'customer_name': null,
      'credit_note_number': row.creditNoteNumber,
      'reason': row.reason,
      'amount': row.amount,
      'credit_note_date': row.creditNoteDate,
      'notes': row.notes,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
    };
  }
}
