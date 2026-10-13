import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/domain/zone_offsets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Prayer times are local wall-clock times, so the IANA database has to be loaded
  // before anything asks for an offset.
  loadTimeZoneDatabase();
  runApp(const ProviderScope(child: JamaahApp()));
}
