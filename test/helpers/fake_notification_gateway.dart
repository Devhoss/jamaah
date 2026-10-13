import 'package:jamaah/src/data/notifications/notification_sync.dart';
import 'package:jamaah/src/domain/notification_channels.dart';

/// The platform's notification state, in memory: what is scheduled, which
/// channels exist, and whether the two permissions are granted.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.exact = true, this.enabled = true});

  bool exact;
  bool enabled;

  final scheduled = <int, ScheduledItem>{};
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
  Future<void> deleteChannel(String id) async {
    channels.remove(id);
    foreignChannels.remove(id);
  }

  @override
  Future<List<PendingItem>> pending() async => [
    for (final item in scheduled.values)
      PendingItem(id: item.id, title: item.title, body: item.body),
  ];

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<void> schedule(ScheduledItem item, {required bool exact}) async {
    scheduleCalls++;
    scheduled[item.id] = item;
    exactFlags[item.id] = exact;
  }

  @override
  Future<bool> canScheduleExact() async => exact;

  @override
  Future<bool> notificationsEnabled() async => enabled;
}
