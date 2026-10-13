import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One reading from the device compass.
class CompassReading {
  const CompassReading({required this.heading, this.accuracy});

  /// Degrees clockwise from magnetic north, where the top of the phone points.
  final double heading;

  /// The platform's error estimate in degrees, when it gives one. On Android
  /// 15 is high accuracy, 30 medium and 45 low; null means unknown.
  final double? accuracy;

  /// Low enough that the user should be asked to calibrate.
  bool get needsCalibration => (accuracy ?? 0) >= 45;
}

/// The device compass, and the magnetic declination that turns its magnetic
/// heading into a true one. Kept behind an interface so the Qibla screen is
/// testable without sensors.
abstract interface class CompassSource {
  /// Headings while listened to. A phone without a compass sends nothing.
  Stream<CompassReading> readings();

  /// Degrees east of true north that magnetic north lies at this place today,
  /// or null when the platform cannot say.
  Future<double?> declination({
    required double latitude,
    required double longitude,
  });
}

class DeviceCompassSource implements CompassSource {
  static const _channel = MethodChannel('dev.jamaah.app/compass');

  @override
  Stream<CompassReading> readings() =>
      (FlutterCompass.events ?? const Stream<CompassEvent>.empty())
          .where((e) => e.heading != null)
          .map(
            (e) => CompassReading(heading: e.heading!, accuracy: e.accuracy),
          );

  @override
  Future<double?> declination({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final value = await _channel.invokeMethod<double>('declination', {
        'latitude': latitude,
        'longitude': longitude,
      });
      return value;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

final compassSourceProvider = Provider<CompassSource>(
  (ref) => DeviceCompassSource(),
);
