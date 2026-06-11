abstract class TrashRepository {
  Future<void> moveToTrash(String businessId, String entityType, String entityId, String entityData);
  Future<List<Map<String, dynamic>>> getTrashItems(String businessId, {int page = 1, int pageSize = 20});
  Future<void> restoreFromTrash(String id);
  Future<void> permanentlyDelete(String id);
  Future<void> emptyTrash(String businessId);
}
