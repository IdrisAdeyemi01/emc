import 'dart:async';
import 'dart:convert';

import 'package:emc_core/emc_core.dart';
import 'package:http/http.dart' as http;

/// Loads the timetable from the Apps Script web app (backend/apps_script).
///
/// One plain GET with no custom headers, so the browser makes no CORS
/// preflight. Every problem becomes a [Failure]; nothing throws.
///
/// Never logs the URL (it carries the key) or the body (it holds phones).
final class AppsScriptTimetableRepository implements TimetableRepository {
  AppsScriptTimetableRepository({
    required this.baseUrl,
    required String apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _apiKey = apiKey,
       _client = client ?? http.Client();

  /// The web app's `/exec` URL.
  final Uri baseUrl;

  /// Apps Script cold starts can take several seconds.
  final Duration timeout;

  final String _apiKey;
  final http.Client _client;

  static const _log = Logger('timetable');

  /// [baseUrl] plus `action=contacts` and `key`, keeping any existing query.
  Uri get requestUri => baseUrl.replace(
    queryParameters: {
      ...baseUrl.queryParameters,
      'action': 'contacts',
      'key': _apiKey,
    },
  );

  @override
  Future<Result<Timetable>> loadTimetable() async {
    final http.Response response;
    try {
      response = await _client.get(requestUri).timeout(timeout);
    } on TimeoutException {
      return _network('timed out after ${timeout.inSeconds}s');
    } on Exception catch (error) {
      // The exception message can include the URL (and so the key): log the
      // type only.
      return _network('request failed (${error.runtimeType})');
    }

    if (response.statusCode != 200) {
      return _network('HTTP ${response.statusCode}');
    }

    final result = timetableFromResponse(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );
    if (result case Err(:final failure)) {
      _log.warning('Load failed: $failure');
    }
    return result;
  }

  /// Releases the HTTP client.
  void close() => _client.close();

  Result<Timetable> _network(String detail) {
    _log.warning('Load failed: network ($detail)');
    return Err(NetworkFailure(detail));
  }
}
