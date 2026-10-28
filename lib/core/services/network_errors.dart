import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether [error] means the server could not be reached (offline, a
/// dropped connection, or a request past its time limit), as opposed to
/// the server answering with an error. Screens use it to say "No
/// connection" instead of a generic failure.
bool isConnectionError(Object? error) => switch (error) {
  SocketException() ||
  TimeoutException() ||
  HandshakeException() ||
  http.ClientException() ||
  AuthRetryableFetchException() => true,
  _ => false,
};
