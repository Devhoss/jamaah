import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/app/diagnostic_evidence.dart';

void main() {
  test('summary evidence includes correlated Android delivery lifecycle', () {
    final result = recentNotificationEvidence(
      flutterEvents: [
        {'at': '2026-10-27T04:00:00Z', 'event': 'notification_sync_completed'},
        {
          'at': '2026-10-27T04:01:00Z',
          'event': 'notification_schedule_completed',
          'id': 2207001,
        },
      ],
      nativeEvents: [
        {
          'at': '2026-10-27T04:01:01Z',
          'event': 'adhan_alarm_receiver_entered',
          'notificationId': 2207001,
          'prayer': 'fajr',
        },
        {
          'at': '2026-10-27T04:01:02Z',
          'event': 'adhan_notification_state_observed',
          'notificationId': 7300,
          'alarmId': 2207001,
          'active': true,
        },
        {
          'at': '2026-10-27T04:01:03Z',
          'event': 'adhan_playback_started',
          'notificationId': 2207001,
        },
      ],
    );

    expect(result, hasLength(5));
    expect(result.first['event'], 'adhan_playback_started');
    expect(result.first['source'], 'android_native');
    expect(result.first['correlationId'], 'notification_2207001');
    expect(result.last['event'], 'notification_sync_completed');
  });

  test('platform schedule return remains distinct from delivery evidence', () {
    final result = recentNotificationEvidence(
      flutterEvents: [
        {
          'at': '2026-10-27T04:00:00Z',
          'event': 'notification_schedule_completed',
          'id': 42,
        },
      ],
    );

    expect(result.single['event'], 'notification_schedule_completed');
    expect(result.single['source'], 'flutter');
    expect(result.single, isNot(contains('displayed')));
  });

  test('delivery summary counts measured alarms and reports worst deltas', () {
    final summary = deliverySummary([
      {
        'at': '2026-10-29T01:42:42Z',
        'event': 'adhan_alarm_receiver_fired',
        'entryDeltaMs': 222000, // delivered late: 3m42s, the OnePlus report
      },
      {
        'at': '2026-10-28T01:39:02Z',
        'event': 'adhan_alarm_receiver_fired',
        'entryDeltaMs': -1800, // delivered a touch early
      },
      // Not a fired event: never measured.
      {
        'at': '2026-10-28T01:38:59Z',
        'event': 'adhan_alarm_receiver_entered',
        'entryDeltaMs': 999999,
      },
    ]);

    expect(summary, {
      'alarms': 2,
      'maxLateMs': 222000,
      'maxEarlyMs': -1800,
      'lastDeltaMs': 222000, // newest by 'at', not list position
    });
  });

  test('delivery summary with nothing measured yet says so quietly', () {
    expect(deliverySummary(const []), {'alarms': 0});
    expect(deliverySummary(null), {'alarms': 'unknown'});
    expect(deliverySummary([
      {'at': '2026-10-29T01:42:42Z', 'event': 'adhan_alarm_receiver_fired'},
    ]), {'alarms': 0}, reason: 'a receiver event without a delta is not evidence of delivery');
  });
}
