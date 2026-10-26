import 'package:smart_meal/features/setup/data/setup_repository.dart';
import 'package:smart_meal/features/setup/domain/setup_draft.dart';

const testCuisines = [
  Cuisine(slug: 'cameroonian', name: 'Cameroonian food'),
  Cuisine(slug: 'italian', name: 'Italian food'),
];

/// Hand-written setup repository: serves [cuisines] and records every
/// draft saved; [onComplete] can make saving fail or wait.
class FakeSetupRepository implements SetupRepository {
  FakeSetupRepository({this.cuisines = testCuisines, this.onSaved});

  final List<Cuisine> cuisines;

  /// Runs after a successful save, e.g. to make a fake server report the
  /// setup as complete, as the real `complete_setup` does.
  final void Function()? onSaved;
  final saved = <SetupDraft>[];
  Future<void> Function(SetupDraft draft)? onComplete;

  @override
  Future<List<Cuisine>> fetchCuisines() async => cuisines;

  @override
  Future<void> completeSetup(SetupDraft draft) async {
    await onComplete?.call(draft);
    saved.add(draft);
    onSaved?.call();
  }
}
