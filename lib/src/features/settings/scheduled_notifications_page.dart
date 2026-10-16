import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../app/clock_format.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/notification_scheduler.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../data/notifications/notification_sync.dart';
import '../../domain/notification_plan.dart';
import '../../domain/time_model.dart';
import 'settings_kit.dart';

Future<void> openScheduledNotifications(BuildContext context) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ScheduledNotificationsPage(),
      ),
    );

/// What the phone has actually been asked to show, read back from the platform
/// (AGENTS.md: a debug view listing scheduled notifications), with the two
/// permissions that decide whether and when they arrive.
class ScheduledNotificationsPage extends ConsumerStatefulWidget {
  const ScheduledNotificationsPage({super.key});

  @override
  ConsumerState<ScheduledNotificationsPage> createState() =>
      _ScheduledNotificationsPageState();
}

class _Snapshot {
  const _Snapshot({
    required this.pending,
    required this.enabled,
    required this.exact,
  });

  final List<PendingItem> pending;
  final bool enabled;
  final bool exact;
}

class _ScheduledNotificationsPageState
    extends ConsumerState<ScheduledNotificationsPage> {
  _Snapshot? _data;
  late final AppLifecycleListener _lifecycle;

  /// Re-reads the permissions every second while one is missing.
  ///
  /// The answer to a permission request does not always reach the app (and a
  /// permission can be granted from system settings without one), so the screen
  /// asks the system directly instead of waiting for a reply. It stops as soon as
  /// both are granted, so it costs nothing in the normal case.
  Timer? _watch;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _reload);
    _reload();
  }

  @override
  void dispose() {
    _watch?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final gateway = ref.read(notificationGatewayProvider);
    final data = _Snapshot(
      // Ordinary notifications, and the Adhans the app plays itself.
      pending: [...await gateway.pending(), ...await gateway.adhanAlarms()],
      enabled: await gateway.notificationsEnabled(),
      exact: await gateway.canScheduleExact(),
    );
    if (!mounted) return;
    final gained =
        _data != null &&
        ((data.enabled && !_data!.enabled) || (data.exact && !_data!.exact));
    setState(() => _data = data);
    _watchWhileMissing(data);
    // A permission that just arrived changes what can be scheduled (exact
    // timing, or anything at all), so the schedule is rebuilt with it.
    if (gained) await _rescheduleNow();
  }

  void _watchWhileMissing(_Snapshot data) {
    final missing = !data.enabled || !data.exact;
    if (!missing) {
      _watch?.cancel();
      _watch = null;
    } else {
      _watch ??= Timer.periodic(const Duration(seconds: 1), (_) => _recheck());
    }
  }

  Future<void> _recheck() async {
    final gateway = ref.read(notificationGatewayProvider);
    final enabled = await gateway.notificationsEnabled();
    final exact = await gateway.canScheduleExact();
    final data = _data;
    if (!mounted || data == null) return;
    if (enabled != data.enabled || exact != data.exact) await _reload();
  }

  Future<void> _rescheduleNow() async {
    await ref.read(notificationSchedulerProvider.notifier).syncNow();
    if (!mounted) return;
    final gateway = ref.read(notificationGatewayProvider);
    final pending = [
      ...await gateway.pending(),
      ...await gateway.adhanAlarms(),
    ];
    final data = _data;
    if (!mounted || data == null) return;
    setState(
      () => _data = _Snapshot(
        pending: pending,
        enabled: data.enabled,
        exact: data.exact,
      ),
    );
  }

  // The requests are started, not awaited: the watch above notices the result.
  void _allowNotifications() => unawaited(
    ref.read(notificationPermissionActionsProvider).requestNotifications(),
  );

  void _allowExact() => unawaited(
    ref.read(notificationPermissionActionsProvider).requestExactAlarms(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = _data;
    // A sync that finishes while the screen is open (a setting changed, the app
    // came back) changes the list, so it is read again.
    ref.listen(notificationSchedulerProvider, (before, after) {
      if (before?.report != after.report) _reload();
    });

    return SettingsScaffold(
      title: l10n.scheduledTitle,
      children: data == null
          ? const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ]
          : _body(context, data, l10n),
    );
  }

  List<Widget> _body(
    BuildContext context,
    _Snapshot data,
    AppLocalizations l10n,
  ) {
    final items = [...data.pending]..sort((a, b) => _at(a).compareTo(_at(b)));
    return [
      // A missing permission is one quiet line and the next useful action
      // (spec §4.10), never a red banner.
      if (!data.enabled) ...[
        SettingsNote(l10n.scheduledNotificationsOff, top: 4),
        const SizedBox(height: 8),
        SettingsButton(
          label: l10n.scheduledAllowNotifications,
          filled: true,
          onPressed: _allowNotifications,
        ),
        const SizedBox(height: 12),
      ],
      if (!data.exact) ...[
        SettingsNote(l10n.scheduledExactOff, top: 4),
        const SizedBox(height: 8),
        SettingsButton(
          label: l10n.scheduledAllowExact,
          onPressed: _allowExact,
        ),
        const SizedBox(height: 12),
      ],
      SettingsHeading(l10n.scheduledCount(items.length), top: 4),
      if (items.isEmpty)
        SettingsNote(l10n.scheduledNothing, top: 0)
      else
        for (final (i, item) in items.indexed)
          _PendingRow(item: item, at: _at(item), divider: i < items.length - 1),
      const SizedBox(height: 18),
      SettingsNote(l10n.scheduledBatteryHint, top: 0),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          SettingsButton(
            label: l10n.scheduledOpenAppSettings,
            onPressed: () => Geolocator.openAppSettings(),
          ),
          SettingsButton(
            label: l10n.scheduledRescheduleNow,
            onPressed: _rescheduleNow,
          ),
        ],
      ),
    ];
  }

  /// The instant the app wrote into the payload when it scheduled the item.
  DateTime _at(PendingItem item) {
    try {
      final map = jsonDecode(item.payload ?? '') as Map<String, Object?>;
      return DateTime.parse(map['at']! as String).toLocal();
    } on Object {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.item,
    required this.at,
    required this.divider,
  });

  final PendingItem item;
  final DateTime at;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final clock = ClockFormat.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when =
        '${DateFormat('EEE d MMM', locale).format(at)} · '
        '${clock.time(LocalTime.of(at.hour, at.minute))}';
    final kind = _kind(item);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: s.divider)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? '',
                    style: type.row.copyWith(color: s.onSurface),
                  ),
                  Text(
                    [
                      if (kind != null)
                        switch (kind) {
                          NotificationKind.adhan => l10n.kindAdhan,
                          NotificationKind.preAdhan => l10n.kindPreAdhan,
                          NotificationKind.iqama => l10n.kindIqama,
                          NotificationKind.extra => l10n.kindExtra,
                        },
                      ?item.body,
                    ].join(' · '),
                    style: type.meta.copyWith(color: s.onSurfaceMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              when,
              style: type.meta.copyWith(color: s.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }

  NotificationKind? _kind(PendingItem item) {
    try {
      final map = jsonDecode(item.payload ?? '') as Map<String, Object?>;
      return NotificationKind.values.byName(map['kind']! as String);
    } on Object {
      return null;
    }
  }
}
