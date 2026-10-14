import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/services/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushNotificationService without Firebase configured', () {
    test('constructing the service does not throw', () {
      expect(PushNotificationService.new, returnsNormally);
    });

    test('initialize() completes normally and leaves it unavailable', () async {
      final service = PushNotificationService();

      await expectLater(service.initialize(), completes);

      expect(service.isAvailable, isFalse);
    });

    test(
      'requestPermissionAndRegisterToken() is a no-op when unavailable',
      () async {
        final service = PushNotificationService();
        await service.initialize();

        await expectLater(
          service.requestPermissionAndRegisterToken(),
          completes,
        );

        expect(service.isAvailable, isFalse);
      },
    );

    test('dispose() completes when nothing was attached', () async {
      final service = PushNotificationService();
      await service.initialize();

      await expectLater(service.dispose(), completes);

      expect(service.isAvailable, isFalse);
    });
  });
}
