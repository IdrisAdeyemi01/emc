import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

import '../fixtures/contacts_sheet.dart';

void main() {
  test('wa.me link with the international number and encoded message', () {
    final phone = PhoneNumber.parse('0800 000 0001') as ValidPhone;
    const message = 'Hope you’re well.\n*Class* : SSS 1 & more';

    final link = whatsAppLink(phone, message);

    expect(
      link.toString(),
      'https://wa.me/2348000000001?text=${Uri.encodeComponent(message)}',
    );
    expect(link.host, 'wa.me');
    expect(link.path, '/2348000000001');
    expect(link.queryParameters['text'], message);
    expect(link.toString(), isNot(contains(' ')));
    expect(link.toString(), contains('%0A')); // newline encoded
  });

  test('a full reminder survives the round trip unchanged', () {
    final yusuf = buildReminders(contactsTimetable(), Weekday.saturday).first;
    final message = buildReminderMessage(yusuf, isToday: true);

    final link = whatsAppLink(yusuf.phone as ValidPhone, message);

    expect(link.queryParameters['text'], message);
  });
}
