import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notification_channels.dart';
import '../../app/diagnostics.dart';
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

  AndroidNotificationSound? _sound(ChannelSpec c) =>
      switch (rawSoundFor(c.sound)) {
        final raw? => RawResourceAndroidNotificationSound(raw),
        null => null,
      };

  AudioAttributesUsage _usage(ChannelSpec c) => c.alarmStream
      ? AudioAttributesUsage.alarm
      : AudioAttributesUsage.notification;

  @override
  Future<void> ensureChannels(Iterable<ChannelSpec> channels) async {
    await _init();
    // Posted every time, existing or not: Android keeps a channel's sound and
    // vibration as they were, but takes the new name, so the names follow the
    // app's language.
    for (final c in channels) {
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
  Future<Set<String>> activeChannelIds() async {
    await _init();
    final active = await _android?.getActiveNotifications() ?? const [];
    return {for (final n in active) ?n.channelId};
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
    unawaited(
      Diagnostics.record('notification_cancel_requested', values: {'id': id}),
    );
    try {
      await _plugin.cancel(id: id);
      unawaited(
        Diagnostics.record('notification_cancel_completed', values: {'id': id}),
      );
    } on Object catch (error) {
      unawaited(
        Diagnostics.record(
          'notification_cancel_failed',
          values: {'id': id, 'errorType': error.runtimeType.toString()},
        ),
      );
      rethrow;
    }
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
    unawaited(
      Diagnostics.record(
        'notification_schedule_requested',
        values: {
          'id': item.id,
          'correlationId': 'notification_${item.id}',
          'kind': item.planned.kind.name,
          'atUtc': item.at.toUtc().toIso8601String(),
          'mechanism': 'platform_notification',
          'exactRequested': exact,
        },
      ),
    );
    try {
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
      unawaited(
        Diagnostics.record(
          'notification_schedule_completed',
          values: {
            'id': item.id,
            'correlationId': 'notification_${item.id}',
            'kind': item.planned.kind.name,
          },
        ),
      );
    } on Object catch (error) {
      unawaited(
        Diagnostics.record(
          'notification_schedule_failed',
          values: {
            'id': item.id,
            'correlationId': 'notification_${item.id}',
            'kind': item.planned.kind.name,
            'errorType': error.runtimeType.toString(),
          },
        ),
      );
      rethrow;
    }
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

  /// The app's own Adhan player: AdhanAlarms / AdhanService in MainActivity.
  static const _adhan = MethodChannel('dev.jamaah.app/adhan');

  @override
  Future<String> acquireSyncLock() async {
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    while (true) {
      final token = await _adhan.invokeMethod<String>('acquireSyncLock');
      if (token != null) return token;
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Timed out waiting for notification sync lock.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> releaseSyncLock(String token) =>
      _adhan.invokeMethod<void>('releaseSyncLock', {'token': token});

  Map<String, Object?> _adhanMap(ScheduledItem item) => {
    'id': item.id,
    'at': item.at.millisecondsSinceEpoch,
    'title': item.title,
    'body': item.body,
    'sound': inAppSound(item.planned).sound,
    'raw': inAppSound(item.planned).raw,
    'recording':
        item.planned.recordingAsset ?? item.planned.customSoundPath ?? '',
    'maxSeconds': maxSecondsFor(item.planned),
    // Which keeps the sound when two fire at once: an Adhan over a reminder.
    'kind': item.planned.kind.name,
    'ringInSilent': item.planned.ringInSilent,
    'fullScreen': item.planned.fullScreen,
    'vibrate': item.planned.vibrate,
    'stopLabel': item.stopLabel,
    'timeLabel': item.timeLabel,
    'screen': ?item.screen,
  };

  @override
  Future<void> replaceAdhanAlarms(List<ScheduledItem> items) =>
      _adhan.invokeMethod('replaceAll', [for (final i in items) _adhanMap(i)]);

  @override
  Future<List<PendingItem>> adhanAlarms() async {
    final list = await _adhan.invokeListMethod<Object?>('stored') ?? const [];
    return [
      for (final entry in list.whereType<Map<Object?, Object?>>())
        PendingItem(
          id: (entry['id']! as num).toInt(),
          title: entry['title'] as String?,
          body: entry['body'] as String?,
          payload: jsonEncode({
            'at': DateTime.fromMillisecondsSinceEpoch(
              (entry['at']! as num).toInt(),
              isUtc: true,
            ).toIso8601String(),
            'kind': entry['kind'] as String? ?? 'adhan',
            'soundMode': entry['soundMode'] as String?,
            'ringInSilent': entry['ringInSilent'] == true,
            'fullScreen': entry['fullScreen'] == true,
          }),
        ),
    ];
  }

  @override
  Future<void> playAdhanNow(ScheduledItem item) =>
      _adhan.invokeMethod('playNow', _adhanMap(item));

  /// Stops an Adhan the app is playing.
  Future<void> stopAdhan() => _adhan.invokeMethod('stop');

  @override
  Future<bool> canUseFullScreen() async =>
      await _adhan.invokeMethod<bool>('canUseFullScreen') ?? true;

  /// Opens the Android 14+ page where full-screen alerts are allowed.
  Future<void> openFullScreenSettings() =>
      _adhan.invokeMethod('openFullScreenSettings');

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
