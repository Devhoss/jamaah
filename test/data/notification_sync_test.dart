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

  test(
    'concurrent syncs are serialized and leave the last desired set',
    () async {
      final gateway = FakeNotificationGateway();
      final sync = NotificationSync(gateway);
      final first = sync.apply(
        plan: [n(1, fromNow: const Duration(hours: 1))],
        now: now,
        textFor: text,
      );
      final second = sync.apply(
        plan: [n(2, fromNow: const Duration(hours: 2))],
        now: now,
        textFor: text,
      );
      final reports = await Future.wait([first, second]);
      expect(gateway.scheduled.keys, [2]);
      expect(reports[0].anotherSyncWasInProgress, isFalse);
      expect(reports[1].anotherSyncWasInProgress, isTrue);
    },
  );

  test(
    'desired counts and sync correlation exclude past plan entries',
    () async {
      final gateway = FakeNotificationGateway();
      final report = await NotificationSync(gateway).apply(
        plan: [
          n(1, fromNow: const Duration(hours: -1), mode: AdhanSoundMode.full),
          n(2, fromNow: const Duration(hours: 1), mode: AdhanSoundMode.full),
          n(3, fromNow: const Duration(hours: -2)),
          n(4, fromNow: const Duration(hours: 2)),
        ],
        now: now,
        textFor: text,
        syncId: 'sync-test-42',
      );

      expect(report.scheduled, 2);
      expect(report.nativeDesired, 1);
      expect(report.platformDesired, 1);
      expect(gateway.adhanAlarmsById[2]?.syncId, 'sync-test-42');
      expect(gateway.scheduled[4]?.syncId, 'sync-test-42');
    },
  );

  test(
    'reconciliation identifies missing and timestamp-mismatched entries',
    () async {
      final gateway = FakeNotificationGateway();
      final report = await NotificationSync(gateway).apply(
        plan: [
          n(1, fromNow: const Duration(hours: 1)),
          n(2, fromNow: const Duration(hours: 2)),
        ],
        now: now,
        textFor: text,
      );
      gateway.pendingReadbackOverride = [
        PendingItem(
          id: 1,
          payload: '{"at":"2026-10-13T14:00:00.000Z","kind":"adhan"}',
        ),
        PendingItem(id: 999, payload: '{"at":"2026-10-13T14:00:00.000Z"}'),
      ];
      final mismatched = await NotificationSync(gateway).apply(
        plan: [
          n(1, fromNow: const Duration(hours: 1)),
          n(2, fromNow: const Duration(hours: 2)),
        ],
        now: now,
        textFor: text,
      );
      final platform = mismatched.reconciliation['platform']! as Map;
      expect(platform['missingIds'], [2]);
      expect(platform['unexpectedIds'], [999]);
      expect(
        (platform['timestampMismatches']! as List).single['reason'],
        'timestamp_mismatch',
      );
      expect(report.scheduled, 2);
    },
  );

  test(
    'native count discrepancy reports the specific missing alarm ID',
    () async {
      final gateway = FakeNotificationGateway()
        ..nativeReadbackOverride = [
          PendingItem(
            id: 10,
            payload: '{"at":"2026-10-13T13:00:00.000Z","kind":"adhan"}',
          ),
        ];
      final report = await NotificationSync(gateway).apply(
        plan: [
          n(10, fromNow: const Duration(hours: 1), mode: AdhanSoundMode.full),
          n(11, fromNow: const Duration(hours: 2), mode: AdhanSoundMode.full),
        ],
        now: now,
        textFor: text,
      );
      final native = report.reconciliation['native']! as Map;
      expect(report.adhanAlarms, 1);
      expect(report.adhanAlarmsMissing, 1);
      expect(native['missingIds'], [11]);
    },
  );

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

    expect(gateway.channels.values.map((c) => c.group).toSet(), {
      ChannelGroup.adhan,
      ChannelGroup.iqama,
    });
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

  test(
    'keeps a channel whose notification is showing, such as a test',
    () async {
      final gateway = FakeNotificationGateway();
      final shown = n(9, fromNow: Duration.zero);
      await gateway.showNow(
        ScheduledItem(
          planned: shown,
          channel: channelFor(shown),
          title: 't',
          body: 'b',
        ),
      );
      // Nothing is planned: every channel of the app is unused.
      await NotificationSync(gateway)
          .apply(plan: const [], now: now, textFor: text);
      expect(await gateway.channelIds(), contains(channelFor(shown).id));
    },
  );

  test(
    'denied exact alarms degrade to inexact timing, and the report says so',
    () async {
      final gateway = FakeNotificationGateway(exact: false);
      final report = await NotificationSync(gateway).apply(
        plan: [n(1, fromNow: const Duration(hours: 1))],
        now: now,
        textFor: text,
      );

      expect(report.exact, isFalse);
      expect(gateway.exactFlags[1], isFalse);
    },
  );

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

  group('Adhans the app plays itself', () {
    test(
      'the full Adhan goes to the app, a short one stays a notification',
      () async {
        final gateway = FakeNotificationGateway();
        await NotificationSync(gateway).apply(
          plan: [
            n(1, fromNow: const Duration(hours: 1), mode: AdhanSoundMode.full),
            n(2, fromNow: const Duration(hours: 2), mode: AdhanSoundMode.short),
          ],
          now: now,
          textFor: text,
          stopLabel: 'Stop',
          timeLabel: (_) => '5:36 AM',
        );

        expect(gateway.adhanAlarmsById.keys, [1]);
        expect(gateway.scheduled.keys, [2]);
        expect(gateway.adhanAlarmsById[1]!.stopLabel, 'Stop');
        expect(gateway.adhanAlarmsById[1]!.timeLabel, '5:36 AM');
      },
    );

    test(
      'changing the sound moves an Adhan between the two, never both',
      () async {
        final gateway = FakeNotificationGateway();
        final sync = NotificationSync(gateway);
        await sync.apply(
          plan: [
            n(1, fromNow: const Duration(hours: 1), mode: AdhanSoundMode.full),
          ],
          now: now,
          textFor: text,
        );
        await sync.apply(
          plan: [
            n(1, fromNow: const Duration(hours: 1), mode: AdhanSoundMode.short),
          ],
          now: now,
          textFor: text,
        );
        expect(gateway.adhanAlarmsById, isEmpty);
        expect(gateway.scheduled.keys, [1]);

        await sync.apply(
          plan: [
            n(1, fromNow: const Duration(hours: 1), mode: AdhanSoundMode.full),
          ],
          now: now,
          textFor: text,
        );
        expect(gateway.adhanAlarmsById.keys, [1]);
        expect(gateway.scheduled, isEmpty);
      },
    );

    test('nothing in the past is handed to the app', () async {
      final gateway = FakeNotificationGateway();
      await NotificationSync(gateway).apply(
        plan: [
          n(1, fromNow: const Duration(minutes: -1), mode: AdhanSoundMode.full),
        ],
        now: now,
        textFor: text,
      );
      expect(gateway.adhanAlarmsById, isEmpty);
    });
  });
}
