import 'package:invoice_pro/domain/entities/credit_note.dart';

abstract class CreditNoteRepository {
  Future<List<CreditNote>> getAllCreditNotes(String businessId, {String? invoiceId, int page = 1, int pageSize = 20});
  Future<CreditNote?> getCreditNoteById(String id);
  Future<CreditNote> createCreditNote(CreditNote creditNote);
  Future<void> deleteCreditNote(String id);
  Future<String> generateCreditNoteNumber(String businessId, String prefix);
}
