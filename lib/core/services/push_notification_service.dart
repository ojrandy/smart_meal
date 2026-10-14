import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_logger.dart';

const _logName = 'PushNotificationService';

/// Handles FCM messages received while the app is backgrounded or
/// terminated. Must stay a top-level function: on Android, FCM runs it in
/// its own isolate, where nothing from `main()` has run.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  } catch (error) {
    AppLogger.log(
      'Firebase failed to initialize for a background message.',
      name: _logName,
      error: error,
    );
    return;
  }
  AppLogger.log(
    'Background message received: ${message.messageId}',
    name: _logName,
  );
}

/// Thin wrapper around Firebase Cloud Messaging. Create one instance in
/// `main()` and start [initialize] there: it never throws and never prompts
/// the user, so it does not need to be awaited.
///
/// Notification permission is a separate step,
/// [requestPermissionAndRegisterToken], which nothing calls yet. The FCM
/// token is not stored anywhere, foreground messages show no UI, and
/// notification taps do not navigate (tracked in
/// `context/progress-tracker.md`).
///
/// ── SETUP REQUIRED — push stays disabled until all of the below are done ──
/// 1. Create a project at https://console.firebase.google.com
/// 2. Register the Android app (applicationId from
///    `android/app/build.gradle.kts`) and download `google-services.json`
///    into `android/app/`.
/// 3. Apply the Google Services Gradle plugin — add
///    `id("com.google.gms.google-services") version "4.4.2" apply false`
///    to `android/settings.gradle.kts`'s `plugins {}` block, and
///    `id("com.google.gms.google-services")` (no version) to
///    `android/app/build.gradle.kts`'s `plugins {}` block.
///    Do this in the **same change** as adding `google-services.json` —
///    applying the plugin without the file present breaks the Android
///    build for everyone.
/// 4. Register the iOS app and add `GoogleService-Info.plist` to
///    `ios/Runner` via Xcode ("Add Files to Runner", not just dropping it
///    in the filesystem) so it's bundled into the target. Also enable the
///    "Background Modes" → "Remote notifications" capability in Xcode's
///    Signing & Capabilities tab.
/// 5. Run `flutterfire configure` to generate `lib/firebase_options.dart`,
///    then pass `options: DefaultFirebaseOptions.currentPlatform` to both
///    `Firebase.initializeApp()` calls in this file.
/// 6. Enable Cloud Messaging for the project in the Firebase console.
///
/// Until then, [initialize] fails at `Firebase.initializeApp()`, logs a
/// debug message and leaves [isAvailable] false, and
/// [requestPermissionAndRegisterToken] returns without doing anything.
class PushNotificationService {
  final List<StreamSubscription<RemoteMessage>> _messageSubscriptions = [];
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isAvailable = false;

  /// Whether Firebase started and the message listeners are attached.
  bool get isAvailable => _isAvailable;

  Future<void> initialize() async {
    if (_isAvailable) return;

    try {
      await Firebase.initializeApp();
    } catch (error) {
      AppLogger.log(
        'Firebase not configured — push notifications disabled.',
        name: _logName,
        error: error,
      );
      return;
    }

    try {
      // Registering the background handler also installs the platform
      // channel handler that feeds onMessage and onMessageOpenedApp.
      // Without it, those streams stay silent.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _messageSubscriptions.addAll([
        FirebaseMessaging.onMessage.listen(_onForegroundMessage),
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp),
      ]);
      _isAvailable = true;
    } catch (error) {
      AppLogger.log(
        'Push message listeners failed to attach.',
        name: _logName,
        error: error,
      );
      await dispose();
    }
  }

  /// Shows the system notification-permission prompt, then fetches the FCM
  /// token and listens for refreshes. Call it at a moment where the user
  /// understands why notifications help, never during startup. Returns
  /// without doing anything when [isAvailable] is false. Never throws.
  Future<void> requestPermissionAndRegisterToken() async {
    if (!_isAvailable) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.log('Push notification permission denied.', name: _logName);
        return;
      }

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      AppLogger.log(
        token == null ? 'FCM token unavailable.' : 'FCM token received.',
        name: _logName,
      );

      _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen(
        (_) => AppLogger.log('FCM token refreshed.', name: _logName),
      );
    } catch (error) {
      AppLogger.log(
        'Push notification registration failed.',
        name: _logName,
        error: error,
      );
    }
  }

  /// Cancels every subscription this service holds and marks it
  /// unavailable. [initialize] can attach the listeners again afterwards.
  Future<void> dispose() async {
    _isAvailable = false;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    for (final subscription in _messageSubscriptions) {
      await subscription.cancel();
    }
    _messageSubscriptions.clear();
  }

  void _onForegroundMessage(RemoteMessage message) {
    AppLogger.log(
      'Foreground message received: ${message.messageId}',
      name: _logName,
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    AppLogger.log('Notification opened: ${message.messageId}', name: _logName);
  }
}
