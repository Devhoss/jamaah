import 'dart:async';
import 'dart:convert';

import 'package:jamaah/src/data/notifications/notification_sync.dart';
import 'package:jamaah/src/domain/notification_channels.dart';

/// The platform's notification state, in memory: what is scheduled, which
/// channels exist, and whether the two permissions are granted.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.exact = true, this.enabled = true});

  bool exact;
  bool enabled;
  bool _syncLocked = false;
  int _nextLockToken = 0;
  Future<void>? scheduleGate;
  Completer<void>? scheduleStarted;

  @override
  Future<NotificationSyncLock> acquireSyncLock() async {
    final contended = _syncLocked;
    while (_syncLocked) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    _syncLocked = true;
    return NotificationSyncLock(
      token: 'fake-lock-${_nextLockToken++}',
      contended: contended,
    );
  }

  @override
  Future<void> releaseSyncLock(String token) async {
    _syncLocked = false;
  }

  final scheduled = <int, ScheduledItem>{};
  List<PendingItem>? pendingReadbackOverride;
  final channels = <String, ChannelSpec>{};

  /// Channels another app or an older install left behind.
  final foreignChannels = <String>{};

  final exactFlags = <int, bool>{};
  int scheduleCalls = 0;

  @override
  Future<void> ensureChannels(Iterable<ChannelSpec> specs) async {
    for (final c in specs) {
      channels.putIfAbsent(c.id, () => c);
    }
  }

  @override
  Future<Set<String>> channelIds() async => {
    ...channels.keys,
    ...foreignChannels,
  };

  @override
  Future<Set<String>> activeChannelIds() async => {
    for (final item in shownNow) item.channel.id,
  };

  @override
  Future<void> deleteChannel(String id) async {
    channels.remove(id);
    foreignChannels.remove(id);
  }

  @override
  Future<List<PendingItem>> pending() async =>
      pendingReadbackOverride ??
      [
        for (final item in scheduled.values)
          PendingItem(
            id: item.id,
            title: item.title,
            body: item.body,
            // What the real gateway writes, so screens can read time and kind.
            payload: jsonEncode({
              'at': item.at.toUtc().toIso8601String(),
              'kind': item.planned.kind.name,
            }),
          ),
      ];

  @override
  Future<void> cancel(
    int id, {
    PendingItem? pending,
    String? syncId,
    String reason = 'sync_reconciliation',
  }) async => scheduled.remove(id);

  @override
  Future<void> schedule(ScheduledItem item, {required bool exact}) async {
    scheduleCalls++;
    final started = scheduleStarted;
    if (started != null && !started.isCompleted) started.complete();
    await scheduleGate;
    scheduled[item.id] = item;
    exactFlags[item.id] = exact;
  }

  /// Adhans the app plays itself (native), by id.
  final adhanAlarmsById = <int, ScheduledItem>{};
  List<PendingItem>? nativeReadbackOverride;
  final playedNow = <ScheduledItem>[];
  bool fullScreenAllowed = true;

  @override
  Future<void> replaceAdhanAlarms(
    List<ScheduledItem> items, {
    String? syncId,
  }) async {
    adhanAlarmsById
      ..clear()
      ..addAll({for (final i in items) i.id: i});
  }

  @override
  Future<List<PendingItem>> adhanAlarms() async =>
      nativeReadbackOverride ??
      [
        for (final item in adhanAlarmsById.values)
          PendingItem(
            id: item.id,
            title: item.title,
            body: item.body,
            payload: jsonEncode({
              'at': item.at.toUtc().toIso8601String(),
              'kind': item.planned.kind.name,
            }),
          ),
      ];

  @override
  Future<void> playAdhanNow(ScheduledItem item) async => playedNow.add(item);

  @override
  Future<bool> canUseFullScreen() async => fullScreenAllowed;

  /// Notifications shown immediately ("send a test notification").
  final shownNow = <ScheduledItem>[];

  @override
  Future<void> showNow(ScheduledItem item) async {
    await ensureChannels([item.channel]);
    shownNow.add(item);
  }

  @override
  Future<bool> canScheduleExact() async => exact;

  @override
  Future<bool> notificationsEnabled() async => enabled;
}
