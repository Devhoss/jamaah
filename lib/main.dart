import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/app/notification_scheduler.dart';
import 'src/domain/zone_offsets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Prayer times are local wall-clock times, so the IANA database has to be loaded
  // before anything asks for an offset.
  loadTimeZoneDatabase();
  runApp(const ProviderScope(child: JamaahApp()));
}

/// The daily background refresh (2026-10-14): Android's DailyRefreshJob starts
/// this with no screen, to renew the notification plan from what is stored.
@pragma('vm:entry-point')
Future<void> backgroundRefresh() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  loadTimeZoneDatabase();
  final container = ProviderContainer();
  try {
    await refreshNotifications(container);
  } on Object catch (error) {
    debugPrint('Background refresh failed: $error');
  } finally {
    container.dispose();
    await const MethodChannel('dev.jamaah.app/background')
        .invokeMethod<void>('done');
  }
}
