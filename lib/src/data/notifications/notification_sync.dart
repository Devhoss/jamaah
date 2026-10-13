import '../../domain/notification_channels.dart';
import '../../domain/notification_plan.dart';

/// One notification as the platform shows it.
class ScheduledItem {
  const ScheduledItem({
    required this.planned,
    required this.channel,
    required this.title,
    required this.body,
  });

  final PlannedNotification planned;
  final ChannelSpec channel;
  final String title;
  final String body;

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

/// The platform side, small enough to fake in tests.
abstract interface class NotificationGateway {
  /// Creates any of [channels] that do not exist yet. A channel that exists keeps
  /// the user's own changes to it in system settings.
  Future<void> ensureChannels(Iterable<ChannelSpec> channels);

  /// Ids of every channel this app has created.
  Future<Set<String>> channelIds();

  Future<void> deleteChannel(String id);

  Future<List<PendingItem>> pending();

  Future<void> cancel(int id);

  /// Schedules or replaces the notification with this id.
  Future<void> schedule(ScheduledItem item, {required bool exact});

  /// False when Android denies exact alarms: notifications then use inexact
  /// timing, and the UI must say so (AGENTS.md).
  Future<bool> canScheduleExact();

  Future<bool> notificationsEnabled();
}

/// What one sync did, for logs and the debug screen.
class SyncReport {
  const SyncReport({
    required this.scheduled,
    required this.cancelled,
    required this.exact,
    required this.notificationsEnabled,
  });

  final int scheduled;
  final int cancelled;
  final bool exact;
  final bool notificationsEnabled;

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
  }) async {
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
          );
        }(),
    ];
    final wanted = {for (final i in items) i.id};
    final channels = {for (final i in items) i.channel};

    await _gateway.ensureChannels(channels);

    var cancelled = 0;
    for (final p in await _gateway.pending()) {
      if (!wanted.contains(p.id)) {
        await _gateway.cancel(p.id);
        cancelled++;
      }
    }

    final exact = await _gateway.canScheduleExact();
    for (final item in items) {
      await _gateway.schedule(item, exact: exact);
    }

    // Channels nothing uses any more: a retired tone version, or a mode no
    // prayer uses. Removing them keeps the system settings list honest.
    final inUse = {for (final c in channels) c.id};
    for (final id in await _gateway.channelIds()) {
      if (id.startsWith(kChannelPrefix) && !inUse.contains(id)) {
        await _gateway.deleteChannel(id);
      }
    }

    return SyncReport(
      scheduled: items.length,
      cancelled: cancelled,
      exact: exact,
      notificationsEnabled: await _gateway.notificationsEnabled(),
    );
  }
}
