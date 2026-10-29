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
        event.startsWith('adhan_alarm_cancel_') ||
        event.startsWith('adhan_alarm_replace_') ||
        event.startsWith('adhan_service_') ||
        event.startsWith('adhan_audio_') ||
        event.startsWith('adhan_playback_') ||
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
