import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notification_channels.dart';
import 'notification_sync.dart';

/// [NotificationGateway] on flutter_local_notifications (Android).
///
/// Thin on purpose: every decision about what to schedule is made by the pure
/// planner and [NotificationSync], which are tested without a device.
class LocalNotificationsGateway implements NotificationGateway {
  LocalNotificationsGateway({
    required this.channelName,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// The name Android shows for a channel in the app's notification settings.
  final String Function(ChannelSpec) channelName;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// The bundled short Adhan, in android/app/src/main/res/raw.
  static const adhanShortRaw = 'adhan_short_placeholder';

  /// A plain status-bar icon, in android/app/src/main/res/drawable.
  static const statusIcon = 'ic_stat_jamaah';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(statusIcon),
      ),
    );
    _ready = true;
  }

  AndroidNotificationSound? _sound(ChannelSpec c) => switch (c.sound) {
    ChannelSound.adhanShort => const RawResourceAndroidNotificationSound(
      adhanShortRaw,
    ),
    ChannelSound.platformDefault || ChannelSound.none => null,
  };

  AudioAttributesUsage _usage(ChannelSpec c) => c.alarmStream
      ? AudioAttributesUsage.alarm
      : AudioAttributesUsage.notification;

  @override
  Future<void> ensureChannels(Iterable<ChannelSpec> channels) async {
    await _init();
    final existing = await channelIds();
    for (final c in channels) {
      if (existing.contains(c.id)) continue;
      await _android?.createNotificationChannel(
        AndroidNotificationChannel(
          c.id,
          channelName(c),
          importance: c.sound == ChannelSound.none && !c.vibrate
              ? Importance.defaultImportance
              : Importance.high,
          playSound: c.sound != ChannelSound.none,
          sound: _sound(c),
          enableVibration: c.vibrate,
          audioAttributesUsage: _usage(c),
        ),
      );
    }
  }

  @override
  Future<Set<String>> channelIds() async {
    await _init();
    final channels = await _android?.getNotificationChannels() ?? const [];
    return {for (final c in channels) c.id};
  }

  @override
  Future<void> deleteChannel(String id) async {
    await _init();
    await _android?.deleteNotificationChannel(channelId: id);
  }

  @override
  Future<List<PendingItem>> pending() async {
    await _init();
    final requests = await _plugin.pendingNotificationRequests();
    return [
      for (final r in requests)
        PendingItem(id: r.id, title: r.title, body: r.body, payload: r.payload),
    ];
  }

  @override
  Future<void> cancel(int id) async {
    await _init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> showNow(ScheduledItem item) async {
    await ensureChannels([item.channel]);
    await _plugin.show(
      id: item.id,
      title: item.title,
      body: item.body,
      notificationDetails: _details(item.channel),
    );
  }

  @override
  Future<void> schedule(ScheduledItem item, {required bool exact}) async {
    await _init();
    final c = item.channel;
    await _plugin.zonedSchedule(
      id: item.id,
      title: item.title,
      body: item.body,
      scheduledDate: tz.TZDateTime.from(item.at, tz.UTC),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode({
        'at': item.at.toUtc().toIso8601String(),
        'channel': c.id,
        'kind': item.planned.kind.name,
      }),
      notificationDetails: _details(c),
    );
  }

  NotificationDetails _details(ChannelSpec c) => NotificationDetails(
    android: AndroidNotificationDetails(
      c.id,
      channelName(c),
      icon: statusIcon,
      importance: Importance.high,
      priority: Priority.high,
      playSound: c.sound != ChannelSound.none,
      sound: _sound(c),
      enableVibration: c.vibrate,
      audioAttributesUsage: _usage(c),
      category: c.group == ChannelGroup.adhan
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
  );

  @override
  Future<bool> canScheduleExact() async {
    await _init();
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<bool> notificationsEnabled() async {
    await _init();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  /// Shows the Android 13+ notification permission dialog. Call only in
  /// response to the user turning something on.
  Future<bool> requestNotificationPermission() async {
    await _init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  /// Opens the system page where exact alarms are allowed.
  Future<bool> requestExactAlarms() async {
    await _init();
    return await _android?.requestExactAlarmsPermission() ?? false;
  }
}
