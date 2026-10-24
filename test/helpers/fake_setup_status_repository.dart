import 'package:smart_meal/features/setup/data/setup_status_repository.dart';

/// Hand-written setup-status repository: [serverComplete] answers fetches
/// (or [onFetch] when set), and the per-user cache is an in-memory map.
class FakeSetupStatusRepository implements SetupStatusRepository {
  FakeSetupStatusRepository({
    this.serverComplete = false,
    Map<String, bool>? cached,
  }) : cached = cached ?? {};

  bool serverComplete;
  final Map<String, bool> cached;
  Future<bool> Function(String userId)? onFetch;
  int fetchCount = 0;

  @override
  Future<bool> fetchIsComplete(String userId) {
    fetchCount++;
    return onFetch?.call(userId) ?? Future.value(serverComplete);
  }

  @override
  bool? cachedIsComplete(String userId) => cached[userId];

  @override
  Future<void> cache(String userId, {required bool isComplete}) async =>
      cached[userId] = isComplete;

  @override
  Future<void> clearCache(String userId) async => cached.remove(userId);
}
