import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/data/notifications/notification_sync.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/notification_channels.dart';
import 'package:jamaah/src/domain/notification_plan.dart';
import 'package:jamaah/src/domain/prayer.dart';
import '../helpers/fake_notification_gateway.dart';

/// Making the platform's scheduled set match a plan: only the future, nothing
/// left over, nothing doubled, and only this app's channels touched.
void main() {
  final now = DateTime.utc(2026, 10, 13, 12);

  PlannedNotification n(
    int id, {
    required Duration fromNow,
    NotificationKind kind = NotificationKind.adhan,
    AdhanSoundMode? mode = AdhanSoundMode.short,
  }) => PlannedNotification(
    id: id,
    kind: kind,
    prayer: Prayer.asr,
    at: now.add(fromNow),
    soundMode: kind == NotificationKind.adhan ? mode : null,
    mosqueId: kind == NotificationKind.iqama ? 'm1' : '',
    minutesBefore: kind == NotificationKind.adhan ? null : 10,
  );

  ({String title, String body}) text(PlannedNotification p) =>
      (title: 'title ${p.id}', body: 'body');

  test('schedules only what is still ahead', () async {
    final gateway = FakeNotificationGateway();
    final report = await NotificationSync(gateway).apply(
      plan: [
        n(1, fromNow: const Duration(minutes: -5)),
        n(2, fromNow: const Duration(minutes: 30)),
      ],
      now: now,
      textFor: text,
    );

    expect(gateway.scheduled.keys, [2]);
    expect(report.scheduled, 1);
    expect(gateway.scheduled[2]!.title, 'title 2');
  });

  test('cancels what the plan no longer has', () async {
    final gateway = FakeNotificationGateway();
    final sync = NotificationSync(gateway);
    await sync.apply(
      plan: [
        n(1, fromNow: const Duration(hours: 1)),
        n(2, fromNow: const Duration(hours: 2)),
      ],
      now: now,
      textFor: text,
    );

    final report = await sync.apply(
      plan: [n(2, fromNow: const Duration(hours: 2))],
      now: now,
      textFor: text,
    );

    expect(gateway.scheduled.keys, [2]);
    expect(report.cancelled, 1);
  });

  test('running it again changes nothing and doubles nothing', () async {
    final gateway = FakeNotificationGateway();
    final sync = NotificationSync(gateway);
    final plan = [
      n(1, fromNow: const Duration(hours: 1)),
      n(2, fromNow: const Duration(hours: 2), kind: NotificationKind.iqama),
    ];
    await sync.apply(plan: plan, now: now, textFor: text);
    final before = {...gateway.scheduled};
    await sync.apply(plan: plan, now: now, textFor: text);

    expect(gateway.scheduled.keys, before.keys);
    expect(gateway.scheduled, hasLength(2));
  });

  test('creates the channels the plan uses', () async {
    final gateway = FakeNotificationGateway();
    await NotificationSync(gateway).apply(
      plan: [
        n(1, fromNow: const Duration(hours: 1)),
        n(2, fromNow: const Duration(hours: 2), kind: NotificationKind.iqama),
      ],
      now: now,
      textFor: text,
    );

    expect(
      gateway.channels.values.map((c) => c.group).toSet(),
      {ChannelGroup.adhan, ChannelGroup.iqama},
    );
  });

  test('retires its own unused channels, never anyone else\'s', () async {
    final gateway = FakeNotificationGateway()
      ..foreignChannels.addAll({
        '${kChannelPrefix}adhan_short_vib_t0',
        'miscellaneous',
      });
    await NotificationSync(gateway).apply(
      plan: [n(1, fromNow: const Duration(hours: 1))],
      now: now,
      textFor: text,
    );

    final ids = await gateway.channelIds();
    expect(ids, isNot(contains('${kChannelPrefix}adhan_short_vib_t0')));
    expect(ids, contains('miscellaneous'));
  });

  test('denied exact alarms degrade to inexact timing, and the report says so',
      () async {
    final gateway = FakeNotificationGateway(exact: false);
    final report = await NotificationSync(gateway).apply(
      plan: [n(1, fromNow: const Duration(hours: 1))],
      now: now,
      textFor: text,
    );

    expect(report.exact, isFalse);
    expect(gateway.exactFlags[1], isFalse);
  });

  test('an empty plan clears everything', () async {
    final gateway = FakeNotificationGateway();
    final sync = NotificationSync(gateway);
    await sync.apply(
      plan: [n(1, fromNow: const Duration(hours: 1))],
      now: now,
      textFor: text,
    );
    await sync.apply(plan: const [], now: now, textFor: text);

    expect(gateway.scheduled, isEmpty);
  });
}
