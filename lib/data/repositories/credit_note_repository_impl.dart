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
    
    return await _db.transaction(() async {
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

      // If linked to an invoice, apply the credit note to reduce the balance due
      if (creditNote.invoiceId != null) {
        final invoiceRow = await (_db.invoices.select()
          ..where((t) => t.id.equals(creditNote.invoiceId!))).getSingleOrNull();
        if (invoiceRow != null) {
          final newBalance = invoiceRow.balanceDue - creditNote.amount;
          final adjustedBalance = newBalance > 0 ? newBalance : 0.0;
          final newStatus = adjustedBalance <= 0
              ? 'paid'
              : (invoiceRow.paidAmount > 0 ? 'partial' : 'sent');
          await (_db.invoices.update()
            ..where((t) => t.id.equals(creditNote.invoiceId!))).write(InvoicesCompanion(
              balanceDue: Value(adjustedBalance),
              status: Value(newStatus),
            ));
        }
      }

      await _logAudit(creditNote.businessId, 'credit_note', id, 'create',
          'Credit note ${creditNote.creditNoteNumber}: ${creditNote.amount} (${creditNote.reason})');

      final created = await getCreditNoteById(id);
      return created!;
    });
  }

  @override
  Future<void> deleteCreditNote(String id) async {
    final note = await getCreditNoteById(id);
    await (_db.creditNotes.delete()
      ..where((t) => t.id.equals(id))).go();
    if (note != null) {
      await _logAudit(note.businessId, 'credit_note', id, 'delete', 'Deleted credit note ${note.creditNoteNumber}');
    }
  }

  @override
  Future<String> generateCreditNoteNumber(String businessId, String prefix) async {
    return await _db.transaction(() async {
      final query = _db.select(_db.invoiceNumbering)
        ..where((t) => t.businessId.equals(businessId))
        ..where((t) => t.type.equals('credit_note'))
        ..where((t) => t.prefix.equals(prefix));
      
      final existing = await query.getSingleOrNull();
      int nextNumber = 1;

      if (existing != null) {
        nextNumber = existing.lastNumber + 1;
        await (_db.invoiceNumbering.update()..where((t) => t.id.equals(existing.id))).write(
          InvoiceNumberingCompanion(lastNumber: Value(nextNumber))
        );
      } else {
        await _db.into(_db.invoiceNumbering).insert(InvoiceNumberingCompanion.insert(
          id: const Uuid().v4(),
          businessId: businessId,
          prefix: prefix,
          type: 'credit_note',
          lastNumber: Value(nextNumber),
        ));
      }

      return '$prefix${nextNumber.toString().padLeft(6, '0')}';
    });
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

  Future<void> _logAudit(String businessId, String entityType, String entityId, String action, String changes) async {
    await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
      id: const Uuid().v4(),
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      changes: changes,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}
