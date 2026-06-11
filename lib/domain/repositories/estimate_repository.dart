import 'package:invoice_pro/domain/entities/estimate.dart';

abstract class EstimateRepository {
  Future<List<Estimate>> getAllEstimates(String businessId, {String? status, String? searchQuery, int page = 1, int pageSize = 20});
  Future<Estimate?> getEstimateById(String id);
  Future<Estimate> createEstimate(Estimate estimate, List<EstimateItem> items);
  Future<Estimate> updateEstimate(Estimate estimate, List<EstimateItem> items);
  Future<void> deleteEstimate(String id);
  Future<String> generateEstimateNumber(String businessId, String prefix);
  Future<String?> convertEstimateToInvoice(String estimateId);
}
