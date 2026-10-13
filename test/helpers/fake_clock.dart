import 'package:jamaah/src/app/clock.dart';

/// A clock the test moves by hand, so no case waits for a real minute and no
/// reading depends on when the suite happened to run.
class FixedClock implements AppClock {
  FixedClock(this.instant);

  DateTime instant;

  @override
  DateTime nowUtc() => instant;
}
