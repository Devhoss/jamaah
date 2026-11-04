/// Merges Flutter scheduling operations and Android delivery events for a
/// user-triggered diagnostics report.
List<Map<String, Object?>> recentNotificationEvidence({
  required Iterable<Map<String, Object?>> flutterEvents,
  Object? nativeEvents,
  int limit = 360,
}) {
  final merged = <Map<String, Object?>>[];

  void add(Map<String, Object?> event, String source) {
    final name = event['event'];
    if (name is! String || !_isEvidenceEvent(name, source)) return;
    final entry = <String, Object?>{...event, 'source': source};
    entry.putIfAbsent('correlationId', () {
      final id = event['alarmId'] ?? event['notificationId'] ?? event['id'];
      return id == null ? null : 'notification_$id';
    });
    merged.add(entry);
  }

  for (final event in flutterEvents) {
    add(event, 'flutter');
  }
  if (nativeEvents is Iterable) {
    for (final raw in nativeEvents) {
      if (raw is Map) {
        add(Map<String, Object?>.from(raw), 'android_native');
      }
    }
  }

  merged.sort((a, b) => _eventTime(b).compareTo(_eventTime(a)));
  return merged.take(limit).toList(growable: false);
}

bool _isEvidenceEvent(String event, String source) {
  if (source == 'android_native') {
    return event.startsWith('adhan_alarm_receiver_') ||
        event.startsWith('adhan_alarm_replace_') ||
        event.startsWith('adhan_service_') ||
        event.startsWith('adhan_audio_') ||
        event.startsWith('adhan_playback_') ||
        event.startsWith('adhan_full_screen_') ||
        event.contains('notification_post') ||
        event.contains('notification_state') ||
        event.contains('notification_cancel') ||
        event.contains('notification_replaced');
  }
  return event.startsWith('notification_schedule_') ||
      event.startsWith('notification_cancel_') ||
      event.startsWith('notification_post_') ||
      event.startsWith('notification_sync_');
}

DateTime _eventTime(Map<String, Object?> event) {
  final value = event['at'] ?? event['atUtc'] ?? event['timestamp'];
  return value is String
      ? DateTime.tryParse(value) ?? DateTime(0)
      : DateTime(0);
}

/// Native alarm delivery, in one glance: how far the phone's handover came
/// off the planned instant, measured by the receiver itself (`entryDeltaMs` on
/// `adhan_alarm_receiver_fired`, stamped at entry — 2026-10-31). A few minutes
/// late on a phone that batches alarms is the OnePlus report, answered.
///
/// Returns alarms (how many were measured), the worst lateness and worst
/// earliness in milliseconds, and the last delta; nulls when nothing has been
/// measured yet. Works with events in either age order — sorted by time.
Map<String, Object?> deliverySummary(Object? nativeEvents) {
  if (nativeEvents is! Iterable) return const {'alarms': 'unknown'};
  final measured = <(DateTime, int)>[];
  for (final raw in nativeEvents) {
    if (raw is! Map) continue;
    final event = Map<String, Object?>.from(raw);
    if (event['event'] != 'adhan_alarm_receiver_fired') continue;
    final delta = event['entryDeltaMs'];
    if (delta is! num) continue;
    measured.add((_eventTime(event), delta.toInt()));
  }
  if (measured.isEmpty) return const {'alarms': 0};
  measured.sort((a, b) => a.$1.compareTo(b.$1));
  int maxLate = 0;
  int maxEarly = 0;
  for (final (_, delta) in measured) {
    maxLate = delta > maxLate ? delta : maxLate;
    maxEarly = delta < maxEarly ? delta : maxEarly;
  }
  return {
    'alarms': measured.length,
    'maxLateMs': maxLate,
    'maxEarlyMs': maxEarly,
    'lastDeltaMs': measured.last.$2,
  };
}
