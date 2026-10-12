# Tests

`flutter test` runs everything here; there is no separate suite or tag to remember.

| Folder | What it proves |
| --- | --- |
| `domain/` | Prayer-time wrappers, today-in-the-place's-zone math, Iqama and reminder math, Qibla bearings, the bundled city list. Pure Dart, no Flutter. |
| `data/` | The drift schema, migrations (against the exported snapshots in `drift_schemas/app/`), and both repositories reading back what they wrote. |
| `app/` | Providers and the app shell: the foreground-only clock, the bottom navigation, honest later-step states. |
| `features/` | Widget tests for the screens — every location failure, the Today states, large text sizes, semantics. |
| `helpers/` | The fakes (`FakePlaceSource`, `FixedClock`) and `testApp`. Nothing in `lib/` refers to them. |
| `tool/`, `manifest_test.dart` | Branding sync and the Android manifest guard. |

## The drift note

Widget tests use the real database (`AppDatabase(NativeDatabase.memory())`) rather
than a fake repository, so the storage layer is exercised with the widgets. That has
one consequence worth knowing before a test looks like it hangs:

Unmounting the `ProviderScope` cancels the settings stream, and closing a drift
stream schedules a **zero-duration cleanup timer**. Widget-test time is fake and only
runs a timer once time moves, so leaving the cleanup to framework teardown fails the
test with "A Timer is still pending" — after the assertions have already passed.

`helpers/test_app.dart` handles it: `testApp(...)` is `testWidgets(...)` plus a final
`pumpWidget(SizedBox.shrink())` and `pump(Duration(seconds: 1))`. Use it for anything
that mounts the app; plain `testWidgets` is fine when nothing holds a drift stream.

The same pause applies inside a test: Riverpod 3 suspends a stream subscription that
has no listener, so a test that waits for a setting to change must actually watch it.

## Adding a test

- Strings come from `AppLocalizations`, so tests read them off the generated
  `AppLocalizationsEn()` instead of typing literals — a copy change then fails loudly
  at the copy, not in twelve tests.
- Dates and clocks are injected. A test that depends on when it ran is a bug.
- Anything the user can reach by tapping a permission denial needs the failure path
  tested with a fake behind the interface, never with a real plugin call.
