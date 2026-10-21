import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'build_info.dart';

/// Small, bounded on-device history of notification health events.
///
/// Entries intentionally contain only event codes, counts, permission state,
/// and timestamps. Never add prayer names/times, notification text, or place
/// data here: this file is included in a report a tester chooses to send.
class Diagnostics {
  Diagnostics._();

  static const _preferenceKey = 'diagnostics.sentryOptIn';
  static const _maxEntries = 200;
  static const _dsn = String.fromEnvironment('SENTRY_DSN');
  static bool _sentryEnabled = false;
  static bool _initialized = false;
  static Future<void> _writeQueue = Future<void>.value();

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
        await file.writeAsString(jsonEncode(entries), flush: true);
      } on Object {
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

  static Future<String> createReport() async {
    final entries = await recent();
    final report = {
      'format': 2,
      'appBuild': buildLabel(),
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'recentEvents': entries,
    };
    return const JsonEncoder.withIndent('  ').convert(report);
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
