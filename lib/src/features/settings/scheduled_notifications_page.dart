import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../app/clock_format.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/notification_scheduler.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/notifications/notification_sync.dart';
import '../../domain/notification_plan.dart';
import '../../domain/time_model.dart';
import '../components/app_widgets.dart';

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
    extends ConsumerState<ScheduledNotificationsPage>
    with WidgetsBindingObserver {
  late Future<_Snapshot> _snapshot = _read();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the system settings page: read the permissions again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<_Snapshot> _read() async {
    final gateway = ref.read(notificationGatewayProvider);
    return _Snapshot(
      pending: await gateway.pending(),
      enabled: await gateway.notificationsEnabled(),
      exact: await gateway.canScheduleExact(),
    );
  }

  void _refresh() => setState(() => _snapshot = _read());

  Future<void> _rescheduleNow() async {
    await ref.read(notificationSchedulerProvider.notifier).syncNow();
    _refresh();
  }

  Future<void> _allowNotifications() async {
    await ref
        .read(localNotificationsGatewayProvider)
        .requestNotificationPermission();
    await _rescheduleNow();
  }

  Future<void> _allowExact() async {
    await ref.read(localNotificationsGatewayProvider).requestExactAlarms();
    await _rescheduleNow();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduledTitle)),
      body: FutureBuilder<_Snapshot>(
        future: _snapshot,
        builder: (context, snap) {
          final data = snap.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = [...data.pending]
            ..sort((a, b) => _at(a).compareTo(_at(b)));
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xxl,
              AppSpace.sm,
              AppSpace.xxl,
              AppSpace.xxl,
            ),
            children: [
              if (!data.enabled) ...[
                AppPrompt(
                  children: [
                    Text(
                      l10n.scheduledNotificationsOff,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                FilledButton(
                  onPressed: _allowNotifications,
                  child: Text(l10n.scheduledAllowNotifications),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              if (!data.exact) ...[
                AppPrompt(
                  children: [
                    Text(
                      l10n.scheduledExactOff,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                OutlinedButton(
                  onPressed: _allowExact,
                  child: Text(l10n.scheduledAllowExact),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              Text(
                l10n.scheduledCount(items.length),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpace.md),
              if (items.isEmpty)
                AppPrompt(
                  children: [
                    Text(
                      l10n.scheduledNothing,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                )
              else
                AppRows(
                  children: [
                    for (final item in items)
                      _PendingRow(item: item, at: _at(item)),
                  ],
                ),
              const SizedBox(height: AppSpace.lg),
              Text(
                l10n.scheduledBatteryHint,
                style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.sm,
                children: [
                  OutlinedButton(
                    onPressed: () => Geolocator.openAppSettings(),
                    child: Text(l10n.scheduledOpenAppSettings),
                  ),
                  TextButton(
                    onPressed: _rescheduleNow,
                    child: Text(l10n.scheduledRescheduleNow),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
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
  const _PendingRow({required this.item, required this.at});

  final PendingItem item;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);
    final clock = ClockFormat.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when =
        '${DateFormat('EEE d MMM', locale).format(at)} · '
        '${clock.time(LocalTime.of(at.hour, at.minute))}';
    final kind = _kind(item);

    return AppRow(
      leading: null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title ?? '',
            style: const TextStyle(
              fontSize: AppType.bodySize + 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            [
              if (kind != null)
                switch (kind) {
                  NotificationKind.adhan => l10n.kindAdhan,
                  NotificationKind.preAdhan => l10n.kindPreAdhan,
                  NotificationKind.iqama => l10n.kindIqama,
                },
              ?item.body,
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: ink.muted),
          ),
        ],
      ),
      trailing: Text(when, style: TextStyle(fontSize: 13, color: ink.muted)),
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
