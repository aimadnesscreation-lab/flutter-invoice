import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:invoice_pro/database/app_database.dart';
import 'package:invoice_pro/data/models/credit_note_model.dart';
import 'package:invoice_pro/domain/entities/credit_note.dart' as domain;
import 'package:invoice_pro/domain/repositories/credit_note_repository.dart';

class CreditNoteRepositoryImpl implements CreditNoteRepository {
  final AppDatabase _db;

  CreditNoteRepositoryImpl(this._db);

  @override
  Future<List<domain.CreditNote>> getAllCreditNotes(String businessId, {String? invoiceId, int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    final query = _db.select(_db.creditNotes).join([
      leftOuterJoin(_db.invoices, _db.invoices.id.equalsExp(_db.creditNotes.invoiceId)),
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.creditNotes.customerId)),
    ])
      ..where(_db.creditNotes.businessId.equals(businessId));

    if (invoiceId != null) {
      query.where(_db.creditNotes.invoiceId.equals(invoiceId));
    }

    query.orderBy([OrderingTerm(expression: _db.creditNotes.createdAt, mode: OrderingMode.desc)]);
    query.limit(pageSize, offset: offset);

    final rows = await query.get();
    return rows.map((row) {
      final creditNote = row.readTable(_db.creditNotes);
      final invoice = row.readTableOrNull(_db.invoices);
      final customer = row.readTableOrNull(_db.customers);
      
      final map = _rowToMap(creditNote);
      if (invoice != null) {
        map['invoice_number'] = invoice.invoiceNumber;
      }
      if (customer != null) {
        map['customer_name'] = customer.name;
      }
      return CreditNoteModel.fromMap(map).toEntity();
    }).toList();
  }

  @override
  Future<domain.CreditNote?> getCreditNoteById(String id) async {
    final query = _db.select(_db.creditNotes).join([
      leftOuterJoin(_db.invoices, _db.invoices.id.equalsExp(_db.creditNotes.invoiceId)),
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.creditNotes.customerId)),
    ])
      ..where(_db.creditNotes.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final creditNote = row.readTable(_db.creditNotes);
    final invoice = row.readTableOrNull(_db.invoices);
    final customer = row.readTableOrNull(_db.customers);
    
    final map = _rowToMap(creditNote);
    if (invoice != null) {
      map['invoice_number'] = invoice.invoiceNumber;
    }
    if (customer != null) {
      map['customer_name'] = customer.name;
    }
    return CreditNoteModel.fromMap(map).toEntity();
  }

  @override
  Future<domain.CreditNote> createCreditNote(domain.CreditNote creditNote) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    
    await _db.into(_db.creditNotes).insert(CreditNotesCompanion.insert(
      id: id,
      businessId: creditNote.businessId,
      invoiceId: Value(creditNote.invoiceId),
      customerId: Value(creditNote.customerId),
      creditNoteNumber: creditNote.creditNoteNumber,
      reason: creditNote.reason,
      amount: creditNote.amount,
      creditNoteDate: creditNote.creditNoteDate.millisecondsSinceEpoch,
      notes: Value(creditNote.notes),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    ));
    
    final created = await getCreditNoteById(id);
    return created!;
  }

  @override
  Future<void> deleteCreditNote(String id) async {
    await (_db.creditNotes.delete()
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<String> generateCreditNoteNumber(String businessId, String prefix) async {
    final query = _db.selectOnly(_db.creditNotes)
      ..addColumns([_db.creditNotes.id.count()])
      ..where(_db.creditNotes.businessId.equals(businessId));
    final count = await query.map((row) => row.read(_db.creditNotes.id.count())).getSingle();
    final nextNumber = (count ?? 0) + 1;
    return '$prefix${nextNumber.toString().padLeft(6, '0')}';
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
