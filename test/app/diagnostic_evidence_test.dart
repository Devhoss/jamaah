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
}
