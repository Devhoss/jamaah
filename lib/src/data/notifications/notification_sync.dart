import 'dart:convert';

import '../../domain/notification_channels.dart';
import '../../domain/notification_plan.dart';

/// One notification as the platform shows it.
class ScheduledItem {
  const ScheduledItem({
    required this.planned,
    required this.channel,
    required this.title,
    required this.body,
    this.stopLabel = 'Stop',
    this.timeLabel = '',
    this.screen,
    this.syncId,
  });

  final PlannedNotification planned;
  final ChannelSpec channel;
  final String title;
  final String body;

  /// For an Adhan the app plays itself: the Stop button's words and the time as
  /// the user's clock shows it, for the full-screen page.
  final String stopLabel;
  final String timeLabel;

  /// For a full-screen Adhan: what its page shows (the sky, the sun path and
  /// the words), worked out when scheduling (app/adhan_screen.dart).
  final Map<String, Object?>? screen;
  final String? syncId;

  int get id => planned.id;
  DateTime get at => planned.at;
}

/// A notification the platform reports as scheduled, for the debug list.
class PendingItem {
  const PendingItem({required this.id, this.title, this.body, this.payload});

  final int id;
  final String? title;
  final String? body;

  /// The planned instant (UTC, ISO 8601) and channel, written by the app at
  /// scheduling time, because the platform does not report a pending time.
  final String? payload;
}

class NotificationSyncLock {
  const NotificationSyncLock({required this.token, required this.contended});

  final String token;
  final bool contended;
}

/// The platform side, small enough to fake in tests.
abstract interface class NotificationGateway {
  /// Serializes all scheduling work across the foreground and background
  /// Flutter engines. [contended] is true only if an earlier attempt found the
  /// lock owned by another sync.
  Future<NotificationSyncLock> acquireSyncLock();

  Future<void> releaseSyncLock(String token);

  /// Creates any of [channels] that do not exist yet. A channel that exists keeps
  /// the user's own changes to it in system settings.
  Future<void> ensureChannels(Iterable<ChannelSpec> channels);

  /// Ids of every channel this app has created.
  Future<Set<String>> channelIds();

  /// Ids of the channels with a notification on screen or in the shade now.
  Future<Set<String>> activeChannelIds();

  Future<void> deleteChannel(String id);

  Future<List<PendingItem>> pending();

  Future<void> cancel(
    int id, {
    PendingItem? pending,
    String? syncId,
    String reason = 'sync_reconciliation',
  });

  /// Schedules or replaces the notification with this id.
  Future<void> schedule(ScheduledItem item, {required bool exact});

  /// Shows [item] straight away on its channel, for "send a test notification".
  Future<void> showNow(ScheduledItem item);

  /// Replaces every Adhan the app plays itself (the native AdhanService) with
  /// [items]. Those are not notifications the platform schedules for us.
  Future<void> replaceAdhanAlarms(List<ScheduledItem> items, {String? syncId});

  /// The Adhans the app will play itself, for the debug list.
  Future<List<PendingItem>> adhanAlarms();

  /// Plays an Adhan through the app now ("send a test notification").
  Future<void> playAdhanNow(ScheduledItem item);

  /// Android 14+ lets the user withdraw full-screen alerts.
  Future<bool> canUseFullScreen();

  /// False when Android denies exact alarms: notifications then use inexact
  /// timing, and the UI must say so (AGENTS.md).
  Future<bool> canScheduleExact();

  Future<bool> notificationsEnabled();
}

/// What one sync did, for logs and the debug screen.
class SyncReport {
  const SyncReport({
    required this.scheduled,
    required this.nativeDesired,
    required this.platformDesired,
    required this.cancelled,
    required this.exact,
    required this.notificationsEnabled,
    required this.platformPending,
    required this.platformPendingDuplicatesBefore,
    required this.platformPendingDuplicates,
    required this.platformPendingUnexpected,
    required this.platformPendingMissing,
    required this.adhanAlarms,
    required this.adhanAlarmDuplicates,
    required this.adhanAlarmsMissing,
    required this.plannedDuplicateIds,
    required this.adhanTimeCollisions,
    required this.reconciliation,
    required this.lockWaitMs,
    required this.anotherSyncWasInProgress,
  });

  /// Number of future plan entries, not the platform queue size.
  final int scheduled;
  final int nativeDesired;
  final int platformDesired;
  final int cancelled;
  final bool exact;
  final bool notificationsEnabled;

  /// Read back from Android after scheduling. This is a queue count, not proof
  /// that Android displayed the notifications.
  final int platformPending;
  final int platformPendingDuplicatesBefore;
  final int platformPendingDuplicates;
  final int platformPendingUnexpected;
  final int platformPendingMissing;
  final int adhanAlarms;
  final int adhanAlarmDuplicates;
  final int adhanAlarmsMissing;
  final int plannedDuplicateIds;

  /// Extra Adhan alarms sharing a minute with another Adhan alarm. This is a
  /// count only; the report never contains the minute or prayer identity.
  final int adhanTimeCollisions;

  /// Exact ID and timestamp differences observed after scheduling. These are
  /// queue readbacks, not evidence that Android delivered an alert.
  final Map<String, Object?> reconciliation;
  final int lockWaitMs;
  final bool anotherSyncWasInProgress;

  @override
  String toString() =>
      'SyncReport(scheduled: $scheduled, cancelled: $cancelled, '
      'exact: $exact, enabled: $notificationsEnabled)';
}

/// Makes the platform's scheduled notifications match a plan exactly.
///
/// Idempotent: run it after any change (app start and resume, settings, Iqama
/// edits, the active mosque, place or time zone) and the result is the same set,
/// never a duplicate — every notification has a stable id (AGENTS.md).
class NotificationSync {
  const NotificationSync(this._gateway);

  final NotificationGateway _gateway;

  Future<SyncReport> apply({
    required List<PlannedNotification> plan,
    required DateTime now,
    required ({String title, String body}) Function(PlannedNotification)
    textFor,
    String stopLabel = 'Stop',
    String Function(DateTime at)? timeLabel,
    Map<String, Object?>? Function(PlannedNotification n)? screenFor,
    String? syncId,
  }) async {
    final lockTimer = Stopwatch()..start();
    final lock = await _gateway.acquireSyncLock();
    final lockToken = lock.token;
    final lockWaitMs = lockTimer.elapsedMilliseconds;
    try {
      final future = [
        for (final n in plan)
          if (n.at.isAfter(now)) n,
      ];
      final items = [
        for (final n in future)
          () {
            final text = textFor(n);
            return ScheduledItem(
              planned: n,
              channel: channelFor(n),
              title: text.title,
              body: text.body,
              stopLabel: stopLabel,
              timeLabel: timeLabel?.call(n.at) ?? '',
              // Only an Adhan that fills the screen has a page to draw.
              screen: n.fullScreen && n.kind == NotificationKind.adhan
                  ? screenFor?.call(n)
                  : null,
              syncId: syncId,
            );
          }(),
      ];
      // The full Adhan and the full-screen Adhan are played by the app itself;
      // everything else is a notification the platform schedules.
      final inApp = [
        for (final i in items)
          if (playsInApp(i.planned)) i,
      ];
      final notifications = [
        for (final i in items)
          if (!playsInApp(i.planned)) i,
      ];
      final wanted = {for (final i in notifications) i.id};
      final channels = {for (final i in notifications) i.channel};

      await _gateway.ensureChannels(channels);

      final before = await _gateway.pending();
      final beforeIds = before.map((p) => p.id).toList();
      final beforeCounts = <int, int>{};
      for (final id in beforeIds) {
        beforeCounts.update(id, (n) => n + 1, ifAbsent: () => 1);
      }
      final pendingDuplicates = beforeCounts.values.fold<int>(
        0,
        (sum, count) => sum + (count > 1 ? count - 1 : 0),
      );

      var cancelled = 0;
      for (final p in before) {
        if (!wanted.contains(p.id)) {
          await _gateway.cancel(
            p.id,
            pending: p,
            syncId: syncId,
            reason: 'sync_reconciliation',
          );
          cancelled++;
        }
      }

      final exact = await _gateway.canScheduleExact();
      for (final item in notifications) {
        await _gateway.schedule(item, exact: exact);
      }
      await _gateway.replaceAdhanAlarms(inApp, syncId: syncId);

      // Read back both platform-owned queues. Counts and duplicate checks only:
      // never include ids, notification text, prayer names, or scheduled times
      // in the user-submitted diagnostics report.
      final after = await _gateway.pending();
      final afterAdhan = await _gateway.adhanAlarms();
      final actualPendingIds = after.map((p) => p.id).toSet();
      final actualAdhanIds = afterAdhan.map((p) => p.id).toSet();
      int duplicateCount(Iterable<PendingItem> entries) {
        final counts = <int, int>{};
        for (final entry in entries) {
          counts.update(entry.id, (n) => n + 1, ifAbsent: () => 1);
        }
        return counts.values.fold<int>(
          0,
          (sum, count) => sum + (count > 1 ? count - 1 : 0),
        );
      }

      int adhanCollisionCount(Iterable<PendingItem> entries) {
        final byMinute = <int, int>{};
        for (final entry in entries) {
          try {
            final payload =
                jsonDecode(entry.payload ?? '') as Map<String, dynamic>;
            if (payload['kind'] != NotificationKind.adhan.name) continue;
            final at = DateTime.parse(payload['at'] as String).toUtc();
            final minute =
                at.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute;
            byMinute.update(minute, (count) => count + 1, ifAbsent: () => 1);
          } on Object {
            // Ignore an unreadable platform item; it is counted in the queue
            // reconciliation fields instead.
          }
        }
        return byMinute.values.fold<int>(
          0,
          (sum, count) => sum + (count > 1 ? count - 1 : 0),
        );
      }

      final planCounts = <int, int>{};
      for (final item in items) {
        planCounts.update(item.id, (n) => n + 1, ifAbsent: () => 1);
      }

      // Channels nothing uses any more: a retired tone version, or a mode no
      // prayer uses. Removing them keeps the system settings list honest.
      // A channel with a notification showing is kept too: deleting it would
      // take that notification away (a test sent a moment ago, 2026-10-16).
      final inUse = {
        for (final c in channels) c.id,
        ...await _gateway.activeChannelIds(),
      };
      for (final id in await _gateway.channelIds()) {
        if (id.startsWith(kChannelPrefix) && !inUse.contains(id)) {
          await _gateway.deleteChannel(id);
        }
      }

      final desiredPlatform = {for (final item in notifications) item.id: item};
      final desiredNative = {for (final item in inApp) item.id: item};
      List<Map<String, Object?>> mismatches(
        Iterable<PendingItem> actual,
        Map<int, ScheduledItem> desired,
      ) => [
        for (final item in actual)
          if (desired.containsKey(item.id))
            () {
              final expected = desired[item.id]!;
              DateTime? observedAt;
              try {
                final payload =
                    jsonDecode(item.payload ?? '') as Map<String, dynamic>;
                if (payload['at'] is String) {
                  observedAt = DateTime.parse(payload['at'] as String).toUtc();
                }
              } on Object {
                // Invalid metadata remains a timestamp-unavailable mismatch.
              }
              if (observedAt == null || observedAt != expected.at.toUtc()) {
                return {
                  'id': item.id,
                  'expectedAtUtc': expected.at.toUtc().toIso8601String(),
                  'observedAtUtc': observedAt?.toIso8601String(),
                  'reason': observedAt == null
                      ? 'timestamp_unavailable'
                      : 'timestamp_mismatch',
                };
              }
              return null;
            }(),
      ].whereType<Map<String, Object?>>().toList();
      List<int> duplicateIds(Iterable<PendingItem> entries) {
        final counts = <int, int>{};
        for (final entry in entries) {
          counts.update(entry.id, (n) => n + 1, ifAbsent: () => 1);
        }
        return counts.entries
            .where((e) => e.value > 1)
            .map((e) => e.key)
            .toList();
      }

      List<Map<String, Object?>> observedEntries(
        Iterable<PendingItem> entries,
      ) => [
        for (final entry in entries)
          {
            'id': entry.id,
            'metadata': () {
              try {
                final decoded = jsonDecode(entry.payload ?? '');
                if (decoded is Map) {
                  return {
                    for (final key in [
                      'at',
                      'kind',
                      'channel',
                      'soundMode',
                      'ringInSilent',
                      'fullScreen',
                    ])
                      if (decoded.containsKey(key)) key: decoded[key],
                  };
                }
              } on Object {
                // Keep the queue entry visible even if its payload is unreadable.
              }
              return 'unavailable';
            }(),
          },
      ];

      return SyncReport(
        scheduled: items.length,
        nativeDesired: inApp.length,
        platformDesired: notifications.length,
        cancelled: cancelled,
        exact: exact,
        notificationsEnabled: await _gateway.notificationsEnabled(),
        platformPending: after.length,
        platformPendingDuplicatesBefore: pendingDuplicates,
        platformPendingDuplicates: duplicateCount(after),
        platformPendingUnexpected: after
            .where((item) => !wanted.contains(item.id))
            .length,
        platformPendingMissing: notifications
            .where((item) => !actualPendingIds.contains(item.id))
            .length,
        adhanAlarms: afterAdhan.length,
        adhanAlarmDuplicates: duplicateCount(afterAdhan),
        adhanAlarmsMissing: inApp
            .where((item) => !actualAdhanIds.contains(item.id))
            .length,
        plannedDuplicateIds: planCounts.values.fold<int>(
          0,
          (sum, count) => sum + (count > 1 ? count - 1 : 0),
        ),
        adhanTimeCollisions: adhanCollisionCount([...after, ...afterAdhan]),
        reconciliation: {
          'platform': {
            'missingIds': notifications
                .where((i) => !actualPendingIds.contains(i.id))
                .map((i) => i.id)
                .toList(),
            'unexpectedIds': after
                .where((i) => !wanted.contains(i.id))
                .map((i) => i.id)
                .toList(),
            'duplicateIds': duplicateIds(after),
            'timestampMismatches': mismatches(after, desiredPlatform),
            'observedEntries': observedEntries(after),
          },
          'native': {
            'missingIds': inApp
                .where((i) => !actualAdhanIds.contains(i.id))
                .map((i) => i.id)
                .toList(),
            'unexpectedIds': afterAdhan
                .where((i) => !desiredNative.containsKey(i.id))
                .map((i) => i.id)
                .toList(),
            'duplicateIds': duplicateIds(afterAdhan),
            'timestampMismatches': mismatches(afterAdhan, desiredNative),
            'observedEntries': observedEntries(afterAdhan),
          },
        },
        lockWaitMs: lockWaitMs,
        anotherSyncWasInProgress: lock.contended,
      );
    } finally {
      await _gateway.releaseSyncLock(lockToken);
    }
  }
}
