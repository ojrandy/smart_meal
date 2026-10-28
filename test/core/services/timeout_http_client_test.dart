import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_meal/core/services/network_errors.dart';
import 'package:smart_meal/core/services/timeout_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final url = Uri.parse('https://example.test/rest/v1/profiles');

  test('passes a prompt response through unchanged', () async {
    final client = TimeoutHttpClient(
      inner: MockClient((_) async => http.Response('{"ok":true}', 200)),
    );

    final response = await client.get(url);

    expect(response.statusCode, 200);
    expect(response.body, '{"ok":true}');
  });

  test('a server that never answers ends in a TimeoutException', () {
    final client = TimeoutHttpClient(
      inner: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 50),
    );

    expect(client.get(url), throwsA(isA<TimeoutException>()));
  });

  test('a body that stalls halfway ends in a TimeoutException', () {
    final client = TimeoutHttpClient(
      inner: MockClient.streaming((request, _) async {
        // Never closed on purpose: the body stalls after its first chunk.
        // ignore: close_sinks
        final body = StreamController<List<int>>()..add([1, 2, 3]);
        return http.StreamedResponse(body.stream, 200);
      }),
      timeout: const Duration(milliseconds: 50),
    );

    expect(client.get(url), throwsA(isA<TimeoutException>()));
  });

  group('isConnectionError', () {
    test('is true for offline, dropped and timed-out requests', () {
      expect(isConnectionError(const SocketException('down')), isTrue);
      expect(isConnectionError(TimeoutException('slow')), isTrue);
      expect(isConnectionError(http.ClientException('reset')), isTrue);
      expect(isConnectionError(AuthRetryableFetchException()), isTrue);
    });

    test('is false when the server answered with an error', () {
      expect(
        isConnectionError(const PostgrestException(message: 'denied')),
        isFalse,
      );
      expect(isConnectionError(const AuthException('bad')), isFalse);
      expect(isConnectionError(StateError('bug')), isFalse);
      expect(isConnectionError(null), isFalse);
    });
  });
}
