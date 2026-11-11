import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

void main() {
  test('Ok and Err compare by content', () {
    expect(const Ok(1), const Ok(1));
    expect(const Ok(1), isNot(const Ok(2)));
    expect(const Ok(1).hashCode, const Ok(1).hashCode);
    expect(
      const Err<int>(UnauthorizedFailure()),
      const Err<int>(UnauthorizedFailure()),
    );
    expect(
      const Err<int>(UnauthorizedFailure()).hashCode,
      const Err<int>(UnauthorizedFailure()).hashCode,
    );
    expect(const Ok(1).toString(), 'Ok(1)');
    expect(
      const Err<int>(SheetNotFoundFailure()).toString(),
      'Err(SheetNotFoundFailure())',
    );
  });

  test('pattern matching is exhaustive', () {
    String describe(Result<int> result) => switch (result) {
      Ok(:final value) => 'ok $value',
      Err(:final failure) => 'err $failure',
    };

    expect(describe(const Ok(3)), 'ok 3');
    expect(describe(const Err(NetworkFailure())), 'err NetworkFailure(null)');
  });

  group('failures', () {
    test('compare by type and detail', () {
      expect(const NetworkFailure('timeout'), const NetworkFailure('timeout'));
      expect(const NetworkFailure('a'), isNot(const NetworkFailure('b')));
      expect(
        const NetworkFailure('a').hashCode,
        const NetworkFailure('a').hashCode,
      );
      expect(const UnauthorizedFailure(), const UnauthorizedFailure());
      expect(
        const UnauthorizedFailure().hashCode,
        const UnauthorizedFailure().hashCode,
      );
      expect(const SheetNotFoundFailure(), const SheetNotFoundFailure());
      expect(
        const SheetNotFoundFailure().hashCode,
        const SheetNotFoundFailure().hashCode,
      );
      expect(
        const MissingColumnsFailure(['Day']),
        const MissingColumnsFailure(['Day']),
      );
      expect(
        const MissingColumnsFailure(['Day']),
        isNot(const MissingColumnsFailure(['Day', 'Class'])),
      );
      expect(
        const MissingColumnsFailure(['Day']),
        isNot(const MissingColumnsFailure(['Class'])),
      );
      expect(
        const MissingColumnsFailure(['Day']).hashCode,
        const MissingColumnsFailure(['Day']).hashCode,
      );
      expect(
        const UnexpectedResponseFailure('x'),
        const UnexpectedResponseFailure('x'),
      );
      expect(
        const UnexpectedResponseFailure('x').hashCode,
        const UnexpectedResponseFailure('x').hashCode,
      );
      expect(const UnauthorizedFailure(), isNot(const SheetNotFoundFailure()));
    });

    test('describe themselves for logs', () {
      expect(const UnauthorizedFailure().toString(), 'UnauthorizedFailure()');
      expect(
        const MissingColumnsFailure(['Day']).toString(),
        'MissingColumnsFailure([Day])',
      );
      expect(
        const UnexpectedResponseFailure('bad json').toString(),
        'UnexpectedResponseFailure(bad json)',
      );
    });
  });
}
