import 'dart:async';

import 'package:http/http.dart' as http;

/// The HTTP client Supabase uses for every request (auth, database, RPC,
/// storage). A dropped or stalled connection ends in a [TimeoutException]
/// after [timeout] instead of hanging, so every screen can tell the user
/// there is no connection rather than wait forever (owner request,
/// 2026-10-28).
///
/// [timeout] bounds both the wait for the response to start and each pause
/// while its body arrives. Realtime uses a WebSocket and is not affected.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({http.Client? inner, this.timeout = defaultTimeout})
    : _inner = inner ?? http.Client();

  static const defaultTimeout = Duration(seconds: 20);

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request).timeout(timeout);
    return http.StreamedResponse(
      response.stream.timeout(timeout),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
