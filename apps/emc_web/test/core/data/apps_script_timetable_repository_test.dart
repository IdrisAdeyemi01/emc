import 'dart:async';
import 'dart:convert';

import 'package:emc_core/emc_core.dart';
import 'package:emc_web/core/data/apps_script_timetable_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// FAKE data only.
const _key = 'test-key-123';
final _url = Uri.parse('https://script.google.com/macros/s/FAKE_ID/exec');

const _headers = [
  'Day',
  'Class',
  'Subject',
  'Teacher',
  'Phone numbers',
  'Start Time',
];

String _okBody({List<String> headers = _headers}) => jsonEncode({
  'ok': true,
  'fetchedAt': '2026-11-14T07:15:00Z',
  'sheet': "Teachers' Contacts",
  'headers': headers,
  'rows': [
    [
      'Saturday',
      'SSS 1',
      'Literature',
      'Bro Yusuf Adebayo',
      '08000000001',
      '2:00 PM',
    ],
    [
      'Saturday',
      'JSS 1',
      'Arabic',
      'Sis Halima Bello',
      '08000000002',
      '10:00 AM',
    ],
  ],
});

http.Response _json(String body, [int status = 200]) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {'content-type': 'application/json'},
);

AppsScriptTimetableRepository _repo(
  MockClientHandler handler, {
  Uri? url,
  Duration timeout = const Duration(seconds: 5),
}) => AppsScriptTimetableRepository(
  baseUrl: url ?? _url,
  apiKey: _key,
  client: MockClient(handler),
  timeout: timeout,
);

void main() {
  late List<String> logged;
  late LogSink originalSink;

  setUp(() {
    logged = [];
    originalSink = Logger.sink;
    Logger.sink = (level, name, message, error, stackTrace) =>
        logged.add(message);
  });
  tearDown(() => Logger.sink = originalSink);

  test('GETs the URL with action=contacts and the key', () async {
    late http.Request seen;
    final repo = _repo((request) async {
      seen = request;
      return _json(_okBody());
    });

    await repo.loadTimetable();

    expect(seen.method, 'GET');
    expect(seen.url.origin, 'https://script.google.com');
    expect(seen.url.path, '/macros/s/FAKE_ID/exec');
    expect(seen.url.queryParameters, {'action': 'contacts', 'key': _key});
    // No custom headers, so browsers send it without a CORS preflight.
    expect(
      seen.headers.keys.map((k) => k.toLowerCase()),
      isNot(contains('authorization')),
    );
  });

  test('keeps query parameters already on the base URL', () {
    final repo = _repo(
      (_) async => _json(_okBody()),
      url: Uri.parse('https://example.test/exec?v=2&action=old'),
    );

    expect(repo.requestUri.queryParameters, {
      'v': '2',
      'action': 'contacts',
      'key': _key,
    });
  });

  test('a good response becomes a timetable', () async {
    final result = await _repo((_) async => _json(_okBody())).loadTimetable();

    final timetable = (result as Ok<Timetable>).value;
    expect(timetable.sessions, hasLength(2));
    expect(timetable.fetchedAt, DateTime.utc(2026, 11, 14, 7, 15));
    expect(logged, isEmpty);
  });

  test('decodes UTF-8 even without a charset', () async {
    final body = _okBody().replaceFirst('Bro Yusuf Adebayo', 'Bro Yusuf ’Dayo');
    final result = await _repo(
      (_) async => http.Response.bytes(utf8.encode(body), 200),
    ).loadTimetable();

    expect(
      (result as Ok<Timetable>).value.sessions.first.teacherName,
      'Bro Yusuf ’Dayo',
    );
  });

  group('failures', () {
    Future<Result<Timetable>> load(MockClientHandler handler) =>
        _repo(handler).loadTimetable();

    test('unauthorized', () async {
      expect(
        await load((_) async => _json('{"ok":false,"error":"unauthorized"}')),
        const Err<Timetable>(UnauthorizedFailure()),
      );
    });

    test('sheet not found', () async {
      expect(
        await load(
          (_) async => _json('{"ok":false,"error":"sheet_not_found"}'),
        ),
        const Err<Timetable>(SheetNotFoundFailure()),
      );
    });

    test('other backend errors', () async {
      expect(
        await load((_) async => _json('{"ok":false,"error":"internal"}')),
        const Err<Timetable>(
          UnexpectedResponseFailure('backend error: internal'),
        ),
      );
    });

    test('HTML instead of JSON', () async {
      final result = await load(
        (_) async => http.Response('<!DOCTYPE html><html></html>', 200),
      );

      expect(
        (result as Err<Timetable>).failure,
        isA<UnexpectedResponseFailure>(),
      );
    });

    test('missing columns', () async {
      expect(
        await load(
          (_) async => _json(_okBody(headers: _headers.sublist(0, 5))),
        ),
        const Err<Timetable>(MissingColumnsFailure(['Start Time'])),
      );
    });

    test('non-200 status is a network failure', () async {
      expect(
        await load((_) async => http.Response('oops', 503)),
        const Err<Timetable>(NetworkFailure('HTTP 503')),
      );
    });

    test('connection errors are network failures', () async {
      expect(
        await load(
          (request) async =>
              throw http.ClientException('no route', request.url),
        ),
        const Err<Timetable>(
          NetworkFailure('request failed (ClientException)'),
        ),
      );
    });

    test('timeouts are network failures', () async {
      final result = await _repo((_) {
        final never = Completer<http.Response>();
        return never.future;
      }, timeout: const Duration(milliseconds: 20)).loadTimetable();

      expect(
        result,
        const Err<Timetable>(NetworkFailure('timed out after 0s')),
      );
    });

    test('logs never contain the key, URL or phone numbers', () async {
      await load(
        (request) async =>
            throw http.ClientException('failed: ${request.url}', request.url),
      );
      await load(
        (_) async =>
            _json('{"ok":true,"headers":[],"rows":[["08000000001",1]]}'),
      );

      expect(logged, hasLength(2));
      for (final line in logged) {
        expect(line, isNot(contains(_key)));
        expect(line, isNot(contains('script.google.com')));
        expect(line, isNot(contains('0800')));
      }
    });
  });

  test('close releases the client', () {
    var closed = false;
    final client = _ClosingClient(() => closed = true);

    AppsScriptTimetableRepository(
      baseUrl: _url,
      apiKey: _key,
      client: client,
    ).close();

    expect(closed, isTrue);
  });
}

class _ClosingClient extends http.BaseClient {
  _ClosingClient(this.onClose);

  final void Function() onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() => onClose();
}
