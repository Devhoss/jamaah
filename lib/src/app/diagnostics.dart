import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'build_info.dart';
import 'diagnostic_evidence.dart';

/// Small, bounded on-device history of notification health events.
///
/// Entries stay on device until a user-triggered report is shared. Scheduling
/// records include the notification ID, prayer, and scheduled time so a tester
/// can correlate a missing alert with its delivery path. Never add notification
/// text or place data.
class Diagnostics {
  Diagnostics._();

  static const _preferenceKey = 'diagnostics.sentryOptIn';
  static const _maxEntries = 200;
  static const _maxReportBytes = 1024 * 1024;
  static const _maxHistoryBytes = 2 * 1024 * 1024;
  static const _dsn = String.fromEnvironment('SENTRY_DSN');
  static bool _sentryEnabled = false;
  static bool _initialized = false;
  static Future<void> _writeQueue = Future<void>.value();
  static int _writeFailures = 0;

  static bool get canUpload => _dsn.isNotEmpty;
  static bool get sentryEnabled => _sentryEnabled;

  static Future<void> initialize({bool enableSentry = true}) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _sentryEnabled = preferences.getBool(_preferenceKey) ?? false;
    } on Object {
      _sentryEnabled = false;
    }
    _initialized = true;
    if (enableSentry && _sentryEnabled && canUpload) {
      try {
        await _startSentry();
      } on Object {
        _sentryEnabled = false;
      }
    }
    await record('app_started');
  }

  static Future<void> setSentryEnabled(bool enabled) async {
    if (!_initialized) await initialize();
    _sentryEnabled = enabled && canUpload;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_preferenceKey, _sentryEnabled);
      if (_sentryEnabled) {
        await _startSentry();
      } else {
        // Gate events immediately; closing also discards queued SDK work.
        await Sentry.close();
      }
    } on Object {
      _sentryEnabled = false;
    }
  }

  static Future<void> _startSentry() async {
    if (!canUpload) return;
    await SentryFlutter.init((options) {
      options.dsn = _dsn;
      options.sendDefaultPii = false;
      options.enableAutoSessionTracking = false;
      options.enableAutoNativeBreadcrumbs = false;
      options.enablePrintBreadcrumbs = false;
      options.maxBreadcrumbs = 0;
      options.tracesSampleRate = 0;
      options.attachScreenshot = false;
      options.beforeBreadcrumb = (breadcrumb, hint) => null;
      options.beforeSend = (event, hint) => _sentryEnabled ? event : null;
    });
  }

  static Future<void> record(
    String code, {
    Map<String, Object?> values = const {},
  }) async {
    final entry = <String, Object?>{
      'at': DateTime.now().toUtc().toIso8601String(),
      'event': code,
      ...values,
    };
    _writeQueue = _writeQueue.catchError((_) {}).then((_) async {
      try {
        final file = await _file();
        List<Object?> entries = [];
        if (await file.exists()) {
          try {
            final decoded = jsonDecode(await file.readAsString());
            if (decoded is List) entries = decoded;
          } on Object {
            // A partial write should not prevent future diagnostics from working.
          }
        }
        entries.add(entry);
        if (entries.length > _maxEntries) {
          entries = entries.sublist(entries.length - _maxEntries);
        }
        var serialized = jsonEncode(entries);
        while (entries.length > 1 &&
            utf8.encode(serialized).length > _maxHistoryBytes) {
          entries.removeAt(0);
          serialized = jsonEncode(entries);
        }
        await file.writeAsString(serialized, flush: true);
      } on Object {
        _writeFailures++;
        // Diagnostics must never interfere with prayer alerts or reminders.
      }
    });
    await _writeQueue;
  }

  static Future<List<Map<String, Object?>>> recent() async {
    final file = await _file();
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return [
        for (final item in decoded.reversed)
          if (item is Map)
            Map<String, Object?>.from(item.cast<String, Object?>()),
      ];
    } on Object {
      return const [];
    }
  }

  static Future<String> createReport({
    Object? nativeEnvironment,
    Object? nativeEvents,
    Object? nativeStoredAlarms,
  }) async {
    final entries = await recent();
    final report = <String, Object?>{
      'format': 3,
      'schemaVersion': 3,
      'appBuild': buildLabel(),
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'sessionId': _sessionId,
      'createdAtUtc': DateTime.now().toUtc().toIso8601String(),
      'summary': {
        ..._summary(entries, nativeEvents),
        'build': buildLabel(),
        ..._environmentSummary(nativeEnvironment, nativeStoredAlarms),
      },
      'diagnosticWriteFailures': _writeFailures,
      'environment': {
        'android':
            nativeEnvironment ??
            'unknown (native diagnostic channel unavailable)',
        'nativeEvents': nativeEvents ?? const [],
        'nativeStoredAlarms':
            nativeStoredAlarms ??
            'unknown (native diagnostic channel unavailable)',
        'lifecycleLimitations': 'Android does not expose reliable force-stop detection. Plugin pending requests do not prove delivery or display.',
      },
      'recentEvents': entries,
    };
    var encoded = const JsonEncoder.withIndent('  ').convert(report);
    while (utf8.encode(encoded).length > _maxReportBytes &&
        (report['recentEvents'] as List).isNotEmpty) {
      final events = report['recentEvents'] as List;
      events.removeAt(0);
      report['eventsTrimmedForSize'] =
          (report['eventsTrimmedForSize'] as int? ?? 0) + 1;
      encoded = const JsonEncoder.withIndent('  ').convert(report);
    }
    return encoded;
  }

  static final String _sessionId = DateTime.now()
      .toUtc()
      .microsecondsSinceEpoch
      .toString();

  static Map<String, Object?> _summary(
    List<Map<String, Object?>> entries,
    Object? nativeEvents,
  ) {
    final syncs = entries.where(
      (e) => e['event'] == 'notification_sync_completed',
    );
    final latest = syncs.isEmpty ? null : syncs.first;
    final lastSync = latest == null
        ? null
        : {
            for (final key in [
              'syncId',
              'trigger',
              'startedAtUtc',
              'durationMs',
              'lockWaitMs',
              'anotherSyncWasInProgress',
              'scheduled',
              'nativeDesired',
              'platformDesired',
              'app_adhan_alarms_pending',
              'platform_pending',
              'exact_alarm',
              'notifications_enabled',
              'reconciliation',
            ])
              if (latest.containsKey(key)) key: latest[key],
          };
    final lifecycle = recentNotificationEvidence(
      flutterEvents: entries,
      nativeEvents: nativeEvents,
    );
    final reconciliation = latest?['reconciliation'];
    final platform = reconciliation is Map ? reconciliation['platform'] : null;
    final native = reconciliation is Map ? reconciliation['native'] : null;
    int reconciliationCount(Object? section, String key) =>
        section is Map && section[key] is List
        ? (section[key] as List).length
        : 0;
    return {
      'lastSync': lastSync,
      'reconciliationTotals': {
        'missing':
            reconciliationCount(platform, 'missingIds') +
            reconciliationCount(native, 'missingIds'),
        'unexpected':
            reconciliationCount(platform, 'unexpectedIds') +
            reconciliationCount(native, 'unexpectedIds'),
        'duplicates':
            reconciliationCount(platform, 'duplicateIds') +
            reconciliationCount(native, 'duplicateIds'),
        'timestampMismatches':
            reconciliationCount(platform, 'timestampMismatches') +
            reconciliationCount(native, 'timestampMismatches'),
      },
      'recentReceiverPlaybackEvidence': lifecycle,
      'deliveryLimit': 'Platform scheduling and pending state do not prove that ScheduledNotificationReceiver posted or displayed an alert. Android active-notification snapshots show state only when queried; they cannot confirm heads-up/banner presentation.',
    };
  }

  static Map<String, Object?> _environmentSummary(
    Object? raw,
    Object? storedAlarms,
  ) {
    if (raw is! Map) return {'device': 'unknown', 'permissions': 'unknown'};
    final environment = Map<Object?, Object?>.from(raw);
    return {
      'device': {
        'manufacturer': environment['manufacturer'] ?? 'unknown',
        'model': environment['model'] ?? 'unknown',
        'androidVersion': environment['androidVersion'] ?? 'unknown',
        'androidApiLevel': environment['androidApiLevel'] ?? 'unknown',
        'osBuild': environment['osBuild'] ?? 'unknown',
      },
      'permissions': {
        'notificationsEnabled':
            environment['notificationsEnabled'] ?? 'unknown',
        'postNotificationsPermission':
            environment['postNotificationsPermission'] ?? 'unknown',
        'exactAlarmCapability':
            environment['exactAlarmCapability'] ?? 'unknown',
        'fullScreenIntentCapability':
            environment['fullScreenIntentCapability'] ?? 'unknown',
      },
      'nativeQueueCount': (storedAlarms is List)
          ? storedAlarms.length
          : 'unknown',
    };
  }

  static Future<String> uploadReport(String report) async {
    if (!canUpload || !_sentryEnabled) {
      throw StateError('Diagnostic upload is not enabled.');
    }
    final eventId = await Sentry.captureMessage(
      'Tester submitted a Jama\u2019ah diagnostics report',
      level: SentryLevel.error,
      withScope: (scope) {
        scope.setTag('report_type', 'user_diagnostics');
        scope.addAttachment(
          SentryAttachment.fromIntList(
            utf8.encode(report),
            'jamaah-diagnostics.json',
            contentType: 'application/json',
          ),
        );
      },
    );
    // The Sentry SDK returns an empty id when the transport fails, the event
    // is dropped by a callback, or the SDK is not active. Do not let the UI
    // report success for any of those cases.
    if (eventId == SentryId.empty()) {
      throw StateError('Sentry did not accept the diagnostic report.');
    }
    return eventId.toString();
  }

  static Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}diagnostics.json');
  }
}
