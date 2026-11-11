import 'package:emc_core/emc_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/app_button.dart';
import '../../../shared/app_icon.dart';
import '../../../shared/notice.dart';
import '../../../shared/status_badge.dart';
import '../reminders_strings.dart';
import '../state/drafts_controller.dart';
import '../state/reminders_providers.dart';
import '../state/sent_controller.dart';
import '../state/toast_controller.dart';
import 'message_preview.dart';

/// One teacher's reminder. Unsent: full card with classes, message and
/// Send/Copy. Sent: compact card with "Mark as not sent".
class ReminderCard extends StatelessComponent {
  const ReminderCard(this.reminder, {super.key});

  final TeacherReminder reminder;

  @override
  Component build(BuildContext context) {
    final classDate = context.watch(classDateProvider);
    final isSent = context
        .watch(sentProvider)
        .contains(sentStorageKey(classDate, reminder));
    return isSent
        ? _SentCard(reminder, classDate: classDate)
        : _UnsentCard(reminder, classDate: classDate);
  }
}

String _domId(String prefix, TeacherReminder r) =>
    '$prefix-${r.id.replaceAll(RegExp('[^A-Za-z0-9]'), '-')}';

class _UnsentCard extends StatelessComponent {
  const _UnsentCard(this.reminder, {required this.classDate});

  final TeacherReminder reminder;
  final CalendarDate classDate;

  @override
  Component build(BuildContext context) {
    final drafts = context.watch(draftsProvider);
    final message = currentMessage(
      reminder,
      drafts: drafts,
      classDate: classDate,
      today: context.watch(todayProvider),
    );
    final phone = reminder.phone;
    final blankTime = messageHasBlankStartTime(message);
    final headingId = _domId('t', reminder);
    final reasonId = _domId('why', reminder);

    final StatusBadge badge;
    if (phone is InvalidPhone) {
      badge = const StatusBadge(
        BadgeKind.danger,
        RemindersStrings.invalidPhone,
      );
    } else if (blankTime) {
      badge = const StatusBadge(
        BadgeKind.warning,
        RemindersStrings.startTimeMissing,
      );
    } else {
      badge = const StatusBadge(BadgeKind.notSent, RemindersStrings.notSent);
    }

    return article(
      classes: 'card',
      attributes: {'aria-labelledby': headingId},
      [
        div(classes: 'card-head', [
          div([
            h2(id: headingId, classes: 'card-name', [
              Component.text(reminder.displayName),
            ]),
            p(classes: 'card-sub', [
              Component.text(switch (phone) {
                ValidPhone() => phone.display,
                InvalidPhone(:final raw) => raw.trim(),
              }),
            ]),
          ]),
          badge,
        ]),
        ClassList(reminder),
        if (phone is InvalidPhone)
          Notice(
            id: reasonId,
            tone: NoticeTone.danger,
            children: [
              Component.text(RemindersStrings.invalidPhoneReason(phone)),
            ],
          )
        else if (blankTime)
          Notice(
            id: reasonId,
            tone: NoticeTone.warning,
            children: [
              Component.text(RemindersStrings.missingTimeNoticeBefore),
              Component.text(
                RemindersStrings.missingTimeNoticeWhat(reminder.classes.length),
              ),
              Component.text(RemindersStrings.missingTimeNoticeAfter),
              strong([Component.text(RemindersStrings.startTimeLabel)]),
              Component.text(RemindersStrings.missingTimeNoticeEnd),
            ],
          ),
        MessagePreview(
          id: _domId('msg', reminder),
          message: message,
          initiallyOpen: reminder.hasMissingStartTime,
          invalid: blankTime,
          describedBy: blankTime ? reasonId : null,
          onChanged: (text) => context
              .read(draftsProvider.notifier)
              .update(draftKey(classDate, reminder), text),
        ),
        div(classes: 'card-actions', [
          AppButton(
            label: RemindersStrings.sendOnWhatsApp,
            icon: AppIcon.send,
            href: phone is ValidPhone && !blankTime
                ? whatsAppLink(phone, message).toString()
                : null,
            openInNewTab: true,
            disabled: phone is! ValidPhone || blankTime,
            describedBy: phone is! ValidPhone || blankTime ? reasonId : null,
            onPressed: () => context
                .read(sentProvider.notifier)
                .setSent(reminder, classDate, sent: true),
          ),
          if (phone is ValidPhone && blankTime)
            p(classes: 'btn-reason', [
              Component.text(RemindersStrings.addStartTimeToSend),
            ]),
          AppButton(
            label: RemindersStrings.copyMessage,
            icon: AppIcon.copy,
            variant: ButtonVariant.secondary,
            onPressed: () async {
              // Read before awaiting: the card may rebuild meanwhile.
              final toast = context.read(toastProvider.notifier);
              final clipboard = context.read(clipboardProvider);
              final copied = await clipboard.writeText(message);
              toast.show(
                copied ? RemindersStrings.copied : RemindersStrings.copyFailed,
                success: copied,
              );
            },
          ),
        ]),
        if (phone is InvalidPhone)
          div([
            AppButton(
              label: RemindersStrings.markSentManually,
              icon: AppIcon.notSent,
              variant: ButtonVariant.ghost,
              onPressed: () => context
                  .read(sentProvider.notifier)
                  .setSent(reminder, classDate, sent: true),
            ),
          ]),
      ],
    );
  }
}

class _SentCard extends StatelessComponent {
  const _SentCard(this.reminder, {required this.classDate});

  final TeacherReminder reminder;
  final CalendarDate classDate;

  @override
  Component build(BuildContext context) {
    final headingId = _domId('t', reminder);
    return article(
      classes: 'card card-compact',
      attributes: {'aria-labelledby': headingId},
      [
        div(classes: 'card-head', [
          h2(id: headingId, classes: 'card-name', [
            Component.text(reminder.displayName),
          ]),
          const StatusBadge(BadgeKind.sent, RemindersStrings.sent),
        ]),
        for (final c in reminder.classes)
          p(classes: 'class-line', [
            span([
              strong([Component.text(c.className)]),
              Component.text(' · ${c.subject}'),
            ]),
            _TimeText(c),
          ]),
        div([
          AppButton(
            label: RemindersStrings.markNotSent,
            icon: AppIcon.undo,
            variant: ButtonVariant.ghost,
            onPressed: () => context
                .read(sentProvider.notifier)
                .setSent(reminder, classDate, sent: false),
          ),
        ]),
      ],
    );
  }
}

/// The classes of a reminder: class · subject, start time.
class ClassList extends StatelessComponent {
  const ClassList(this.reminder, {super.key});

  final TeacherReminder reminder;

  @override
  Component build(BuildContext context) {
    return ul(classes: 'classes', [
      for (final c in reminder.classes)
        li([
          span([
            strong([Component.text(c.className)]),
            Component.text(' · ${c.subject}'),
          ]),
          _TimeText(c),
        ]),
    ]);
  }
}

class _TimeText extends StatelessComponent {
  const _TimeText(this.session);

  final ClassSession session;

  @override
  Component build(BuildContext context) {
    if (session.isStartTimeMissing) {
      return span(classes: 'time-missing', [
        const Icon(AppIcon.warning, size: 14),
        Component.text(RemindersStrings.noTime),
      ]);
    }
    return span(classes: 'time', [Component.text(session.rawStartTime)]);
  }
}
