import 'dart:async';

import 'package:emc_core/emc_core.dart';
import 'package:emc_web/core/browser/clipboard.dart';
import 'package:emc_web/core/browser/key_value_store.dart';
import 'package:emc_web/core/providers.dart';
import 'package:emc_web/features/home/home_strings.dart';
import 'package:emc_web/features/home/ui/home_page.dart';
import 'package:emc_web/features/reminders/reminders_strings.dart';
import 'package:emc_web/features/reminders/ui/reminders_page.dart';
import 'package:emc_web/shared/app_button.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:jaspr_test/jaspr_test.dart';

// FAKE data only.
const _headers = [
  'Day',
  'Class',
  'Subject',
  'Teacher',
  'Phone numbers',
  'Start Time',
];
const _rows = [
  [
    'Saturday',
    'JSS 3',
    'English',
    'Bro Yusuf Adebayo',
    '08000000001',
    '10:00 AM',
  ],
  [
    'Saturday',
    'SSS 1',
    'English',
    'Bro Yusuf Adebayo',
    '08000000001',
    '12:00 PM',
  ],
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
    'JSS 2',
    'Mathematics',
    'Sis Maryam Lawal',
    '080000012',
    '12:00 PM',
  ],
  ['Saturday', 'SSS 1', 'Chemistry', 'Bro Ibrahim Salami', '08000000007', ''],
  [
    'Monday',
    'JSS 1',
    'Mathematics',
    'Sis Halima Bello',
    '08000000002',
    '4:00 PM',
  ],
];

Timetable _timetable({List<List<String>> rows = _rows}) =>
    switch (parseContactsSheet(SheetTable(headers: _headers, rows: rows))) {
      Ok(:final value) => value,
      Err(:final failure) => throw StateError('$failure'),
    };

/// 08:15 in Lagos on Saturday 14 Nov 2026.
final _saturday = FixedClock(DateTime.utc(2026, 11, 14, 7, 15));

/// 08:15 in Lagos on Friday 13 Nov 2026.
final _friday = FixedClock(DateTime.utc(2026, 11, 13, 7, 15));

const _yusufKey = 'emc.sent.2026-11-14.tel:2348000000001';

class _FakeRepository implements TimetableRepository {
  _FakeRepository(this.results);

  /// Returned in order; the last one repeats.
  final List<FutureOr<Result<Timetable>> Function()> results;
  int calls = 0;

  @override
  Future<Result<Timetable>> loadTimetable() async {
    final next = results[calls < results.length ? calls : results.length - 1];
    calls++;
    return next();
  }
}

class _FakeClipboard implements ClipboardWriter {
  final copied = <String>[];

  @override
  Future<bool> writeText(String text) async {
    copied.add(text);
    return true;
  }
}

Component _app(
  Component page, {
  required TimetableRepository? repository,
  Clock? clock,
  KeyValueStore? store,
  ClipboardWriter? clipboard,
}) => ProviderScope(
  overrides: [
    timetableRepositoryProvider.overrideWithValue(repository),
    clockProvider.overrideWithValue(clock ?? _saturday),
    keyValueStoreProvider.overrideWithValue(store ?? MemoryKeyValueStore()),
    clipboardProvider.overrideWithValue(clipboard ?? _FakeClipboard()),
  ],
  child: Router(
    routes: [
      Route(path: '/', builder: (context, state) => page),
      Route(path: '/reminders', builder: (context, state) => page),
    ],
  ),
);

Finder _button(String label) => find.byComponentPredicate(
  (c) => c is AppButton && c.label == label,
  description: 'AppButton "$label"',
);

/// The `<button>` rendered for a disabled AppButton, else null.
button? _disabledButtonIn(Finder card) {
  final buttons = find
      .descendant(of: card, matching: find.byType(button))
      .evaluate()
      .map((e) => e.component as button)
      .where((btn) => btn.disabled);
  return buttons.isEmpty ? null : buttons.first;
}

Finder _cardOf(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(article));

void main() {
  testComponents('loading shows skeletons and a status message', (
    tester,
  ) async {
    final never = Completer<Result<Timetable>>();
    tester.pumpComponent(
      _app(
        const RemindersPage(),
        repository: _FakeRepository([() => never.future]),
      ),
    );
    await tester.pump();

    expect(find.text(RemindersStrings.loading), findsOneComponent);
    expect(find.byType(article), findsNothing);
  });

  testComponents('missing config shows the setup message', (tester) async {
    tester.pumpComponent(_app(const RemindersPage(), repository: null));
    await tester.pump();

    expect(find.text(RemindersStrings.notConfiguredTitle), findsOneComponent);
  });

  testComponents('error shows the reason and Try again reloads', (
    tester,
  ) async {
    final repository = _FakeRepository([
      () => const Err(NetworkFailure('offline')),
      () => Ok(_timetable()),
    ]);
    tester.pumpComponent(_app(const RemindersPage(), repository: repository));
    await tester.pump();

    expect(find.text(RemindersStrings.errorTitle), findsOneComponent);
    expect(
      find.text(RemindersStrings.errorBody(const NetworkFailure())),
      findsOneComponent,
    );

    await tester.click(_button(RemindersStrings.tryAgain));
    await tester.pump();

    expect(repository.calls, 2);
    expect(find.text('Bro Yusuf Adebayo'), findsOneComponent);
  });

  testComponents('each failure has its own message', (tester) async {
    expect(
      RemindersStrings.errorBody(const MissingColumnsFailure(['Start Time'])),
      contains('Start Time'),
    );
    expect(
      RemindersStrings.errorBody(const UnauthorizedFailure()),
      contains('access key'),
    );
    expect(
      RemindersStrings.errorBody(const SheetNotFoundFailure()),
      contains('Teachers’ Contacts'),
    );
    expect(
      RemindersStrings.errorBody(const UnexpectedResponseFailure()),
      contains('unexpected'),
    );
  });

  group('list (Saturday)', () {
    testComponents('shows today\'s teachers in order with progress', (
      tester,
    ) async {
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
        ),
      );
      await tester.pump();

      final names = find
          .byComponentPredicate((c) => c is h2 && c.classes == 'card-name')
          .evaluate()
          .map((e) => ((e.component as h2).children.single as Text).text);
      expect(names, [
        'Bro Yusuf Adebayo',
        'Sis Maryam Lawal',
        'Bro Ibrahim Salami',
      ]);
      expect(find.text(RemindersStrings.sentOf(0, 3)), findsOneComponent);
      expect(find.text('Sat'), findsOneComponent);
      expect(find.text('Mon'), findsOneComponent);
      expect(find.text(RemindersStrings.today), findsOneComponent);
    });

    testComponents('3-class teacher lists every class', (tester) async {
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
        ),
      );
      await tester.pump();

      final yusuf = _cardOf('Bro Yusuf Adebayo');
      for (final time in ['10:00 AM', '12:00 PM', '2:00 PM']) {
        expect(
          find.descendant(of: yusuf, matching: find.text(time)),
          findsOneComponent,
        );
      }
      expect(_disabledButtonIn(yusuf), isNull);
    });

    testComponents('invalid phone: Send disabled with the reason', (
      tester,
    ) async {
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
        ),
      );
      await tester.pump();

      final maryam = _cardOf('Sis Maryam Lawal');
      expect(
        find.descendant(
          of: maryam,
          matching: find.text(RemindersStrings.invalidPhone),
        ),
        findsOneComponent,
      );
      expect(
        find.descendant(
          of: maryam,
          matching: find.textContaining('has 9 digits'),
        ),
        findsOneComponent,
      );
      expect(_disabledButtonIn(maryam), isNotNull);
      expect(
        find.descendant(of: maryam, matching: find.byType(a)),
        findsNothing,
      );
    });

    testComponents('missing start time: Send disabled until edited', (
      tester,
    ) async {
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
        ),
      );
      await tester.pump();

      final ibrahim = _cardOf('Bro Ibrahim Salami');
      expect(
        find.descendant(
          of: ibrahim,
          matching: find.text(RemindersStrings.startTimeMissing),
        ),
        findsOneComponent,
      );
      expect(
        find.descendant(
          of: ibrahim,
          matching: find.text(RemindersStrings.addStartTimeToSend),
        ),
        findsOneComponent,
      );
      expect(_disabledButtonIn(ibrahim), isNotNull);
    });

    testComponents('Send marks the card sent and stores it', (tester) async {
      final store = MemoryKeyValueStore();
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
          store: store,
        ),
      );
      await tester.pump();

      await tester.click(
        find.descendant(
          of: _cardOf('Bro Yusuf Adebayo'),
          matching: _button(RemindersStrings.sendOnWhatsApp),
        ),
      );

      expect(store.read(_yusufKey), '1');
      expect(find.text(RemindersStrings.sentOf(1, 3)), findsOneComponent);
      expect(
        find.descendant(
          of: _cardOf('Bro Yusuf Adebayo'),
          matching: find.text(RemindersStrings.markNotSent),
        ),
        findsOneComponent,
      );
    });

    testComponents('Mark as not sent clears the stored mark', (tester) async {
      final store = MemoryKeyValueStore({_yusufKey: '1'});
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
          store: store,
        ),
      );
      await tester.pump();
      expect(find.text(RemindersStrings.sentOf(1, 3)), findsOneComponent);

      await tester.click(_button(RemindersStrings.markNotSent));

      expect(store.read(_yusufKey), isNull);
      expect(find.text(RemindersStrings.sentOf(0, 3)), findsOneComponent);
    });

    testComponents('Copy copies the message and confirms', (tester) async {
      final clipboard = _FakeClipboard();
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
          clipboard: clipboard,
        ),
      );
      await tester.pump();

      await tester.click(
        find.descendant(
          of: _cardOf('Bro Yusuf Adebayo'),
          matching: _button(RemindersStrings.copyMessage),
        ),
      );
      await tester.pump();

      expect(clipboard.copied.single, contains('your classes at EMC today. '));
      expect(find.text(RemindersStrings.copied), findsOneComponent);
    });

    testComponents('all sent shows the completion panel', (tester) async {
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
          store: MemoryKeyValueStore({
            _yusufKey: '1',
            'emc.sent.2026-11-14.raw:080000012': '1',
            'emc.sent.2026-11-14.tel:2348000000007': '1',
          }),
        ),
      );
      await tester.pump();

      expect(find.text(RemindersStrings.allSentTitle(3)), findsOneComponent);
    });

    testComponents('invalid-phone card can be marked sent manually', (
      tester,
    ) async {
      final store = MemoryKeyValueStore();
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
          store: store,
        ),
      );
      await tester.pump();

      await tester.click(_button(RemindersStrings.markSentManually));

      expect(store.read('emc.sent.2026-11-14.raw:080000012'), '1');
    });

    testComponents('marks older than 14 days are cleaned up', (tester) async {
      final store = MemoryKeyValueStore({
        'emc.sent.2026-10-01.tel:2348000000001': '1',
        'emc.sent.2026-11-10.tel:2348000000001': '1',
        'unrelated': 'x',
      });
      tester.pumpComponent(
        _app(
          const RemindersPage(),
          repository: _FakeRepository([() => Ok(_timetable())]),
          store: store,
        ),
      );
      await tester.pump();

      expect(
        store.keys(),
        unorderedEquals(['emc.sent.2026-11-10.tel:2348000000001', 'unrelated']),
      );
    });
  });

  testComponents('empty day offers the next day with classes', (tester) async {
    tester.pumpComponent(
      _app(
        const RemindersPage(),
        repository: _FakeRepository([() => Ok(_timetable())]),
        clock: _friday,
      ),
    );
    await tester.pump();

    expect(
      find.text(RemindersStrings.emptyTitle(Weekday.friday)),
      findsOneComponent,
    );
    expect(find.text('Fri'), findsOneComponent); // today is offered as a chip

    await tester.click(_button(RemindersStrings.seeDay(Weekday.saturday)));

    expect(find.text('Bro Yusuf Adebayo'), findsOneComponent);
  });

  testComponents('a sheet with unreadable rows says so', (tester) async {
    tester.pumpComponent(
      _app(
        const RemindersPage(),
        repository: _FakeRepository([
          () => Ok(
            _timetable(
              rows: [
                ..._rows,
                [
                  'Satday',
                  'SSS 2',
                  'Biology',
                  'Sis Ruqayyah Bakare',
                  '08000000008',
                  '10:00 AM',
                ],
              ],
            ),
          ),
        ]),
      ),
    );
    await tester.pump();

    expect(find.text(RemindersStrings.skippedRows(1)), findsOneComponent);
  });

  testComponents('Home tile shows today\'s count', (tester) async {
    tester.pumpComponent(
      _app(
        const HomePage(),
        repository: _FakeRepository([() => Ok(_timetable())]),
        store: MemoryKeyValueStore({_yusufKey: '1'}),
      ),
    );
    await tester.pump();

    expect(find.text('Saturday, 14 November'), findsOneComponent);
    expect(find.text(HomeStrings.teachersToday(3)), findsOneComponent);
    expect(find.text(HomeStrings.sentCount(1)), findsOneComponent);
    expect(find.text(HomeStrings.ctaSend), findsOneComponent);
  });

  testComponents('Home tile on a day without classes', (tester) async {
    tester.pumpComponent(
      _app(
        const HomePage(),
        repository: _FakeRepository([() => Ok(_timetable())]),
        clock: _friday,
      ),
    );
    await tester.pump();

    expect(find.text(HomeStrings.noClassesToday), findsOneComponent);
  });
}
