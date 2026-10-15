import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/features/settings/adhan_recordings_page.dart';
import 'package:jamaah/src/domain/adhan_recordings.dart';
import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/build_info.dart';
import 'package:jamaah/src/app/audio_preview.dart';
import 'package:jamaah/src/app/custom_sound_actions.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/arabic_digits_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/custom_sounds.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/notification_channels.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/mosques/mosque_detail_page.dart';
import 'package:jamaah/src/features/settings/prayer_alert_page.dart';
import 'package:jamaah/src/features/settings/settings_page.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_notification_gateway.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// The Adhan sound settings (AGENTS.md quality bar), driven through the real app
/// and database. Audio and the platform are fakes.
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;
  late MosqueRepository mosques;
  late FakeNotificationGateway gateway;
  late _FakePreview preview;
  late int permissionRequests;
  ({String path, String name})? picked;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    mosques = MosqueRepository(db);
    gateway = FakeNotificationGateway();
    preview = _FakePreview();
    permissionRequests = 0;
    picked = null;
    addTearDown(db.close);
  });

  Future<void> open(WidgetTester tester, {double textScale = 1.0}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 10, 12, 7, 0)),
          ),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          notificationGatewayProvider.overrideWithValue(gateway),
          notificationPermissionRequestProvider.overrideWithValue(
            () async => permissionRequests++,
          ),
          audioPreviewProvider.overrideWithValue(preview),
          soundPickerProvider.overrideWithValue(() async => picked),
        ],
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: const JamaahApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls the page until [finder] is built and on screen, as a user would.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) =>
      tap(tester, find.text(text));

  Future<void> openSettingsPage(WidgetTester tester) =>
      tap(tester, find.byIcon(Icons.settings_outlined));

  Future<void> openPrayer(WidgetTester tester, Prayer prayer) async {
    await openSettingsPage(tester);
    await tapText(tester, switch (prayer) {
      Prayer.fajr => t.prayerFajr,
      Prayer.sunrise => t.prayerSunrise,
      Prayer.dhuhr => t.prayerDhuhr,
      Prayer.asr => t.prayerAsr,
      Prayer.maghrib => t.prayerMaghrib,
      Prayer.isha => t.prayerIsha,
    });
    expect(find.byType(PrayerAlertPage), findsOneWidget);
  }

  Future<AdhanAlertSettings> stored() async =>
      (await settings.read()).adhanAlerts;

  Finder switchTile(String title) => find.widgetWithText(SwitchListTile, title);

  group('the settings page', () {
    testApp('lists all six times, every one off on a fresh install', (
      tester,
    ) async {
      await open(tester);
      await openSettingsPage(tester);

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text(t.settingsAlertOff), findsNWidgets(6));
      expect(find.text(t.soundModeStandard), findsOneWidget);
    });

    testApp('the default sound is chosen once for every prayer', (
      tester,
    ) async {
      await open(tester);
      await openSettingsPage(tester);
      await tapText(tester, t.settingsDefaultSound);
      await tapText(tester, t.soundModeSilent);

      expect((await stored()).defaultSoundMode, AdhanSoundMode.silent);
      expect(find.text(t.soundModeSilent), findsOneWidget);
    });

    testApp('Iqama reminders are set on the mosque, and the page says so', (
      tester,
    ) async {
      await open(tester);
      await openSettingsPage(tester);
      await reveal(tester, find.text(t.settingsIqamaNoMosque));
      expect(find.text(t.settingsIqamaNoMosque), findsOneWidget);
    });

    testApp(
      'with a mosque, Settings leads to it instead of copying its controls',
      (tester) async {
        await mosques.add(
          name: 'Masjid al-Nour',
          address: '',
          source: MosqueSource.manual,
        );
        await open(tester);
        await openSettingsPage(tester);
        await tapText(tester, t.settingsIqamaOpenActive('Masjid al-Nour'));
        expect(find.byType(MosqueDetailPage), findsOneWidget);
      },
    );
  });

  group('one prayer', () {
    testApp(
      'turning the Adhan alert on stores it, asks for permission, and shows',
      (tester) async {
        await open(tester);
        await openPrayer(tester, Prayer.fajr);
        await tap(tester, switchTile(t.alertAdhanSwitch));

        expect((await stored()).alertFor(Prayer.fajr).enabled, isTrue);
        expect(permissionRequests, 1);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          find.text(t.settingsAlertOn(t.soundModeStandard)),
          findsOneWidget,
        );
      },
    );

    testApp('a prayer can choose its own sound, or go back to the default', (
      tester,
    ) async {
      await open(tester);
      await openPrayer(tester, Prayer.fajr);
      await tapText(tester, t.soundModeShort);
      expect(
        (await stored()).alertFor(Prayer.fajr).soundModeOverride,
        AdhanSoundMode.short,
      );

      await tapText(tester, t.alertUseDefault(t.soundModeStandard));
      expect((await stored()).alertFor(Prayer.fajr).soundModeOverride, isNull);
    });

    testApp('silent and off stay different things', (tester) async {
      await open(tester);
      await openPrayer(tester, Prayer.dhuhr);
      await tap(tester, switchTile(t.alertAdhanSwitch));
      await tapText(tester, t.soundModeSilent);

      final alert = (await stored()).alertFor(Prayer.dhuhr);
      expect(alert.enabled, isTrue, reason: 'silent is still shown');
      expect(alert.soundModeOverride, AdhanSoundMode.silent);
      expect(find.text(t.alertSilentHint), findsOneWidget);
    });

    testApp('the bundled sounds can be previewed and stopped', (tester) async {
      await open(tester);
      await openPrayer(tester, Prayer.fajr);

      expect(
        find.text(t.alertPreview),
        findsNWidgets(2),
        reason:
            'full and short have a sound of their own; standard and silent '
            'do not',
      );
      await tap(tester, find.text(t.alertPreview).first);
      expect(preview.played.single, previewAssetFor(AdhanSoundMode.full));
      expect(find.text(t.alertStopPreview), findsOneWidget);

      await tapText(tester, t.alertStopPreview);
      expect(preview.stops, greaterThan(0));
      expect(find.text(t.alertStopPreview), findsNothing);
    });

    testApp('ring in silent needs a sound, the standard one included', (
      tester,
    ) async {
      await open(tester);
      await openPrayer(tester, Prayer.isha);

      final ring = switchTile(t.alertRingInSilent);
      await tap(tester, ring);
      expect(
        (await stored()).alertFor(Prayer.isha).ringInSilent,
        isTrue,
        reason: 'the standard sound can ring on silent too',
      );

      await tester.scrollUntilVisible(
        find.text(t.soundModeSilent),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tapText(tester, t.soundModeSilent);
      await reveal(tester, ring);
      expect(tester.widget<SwitchListTile>(ring).onChanged, isNull);
      expect(find.text(t.alertRingInSilentNeedsSound), findsOneWidget);
    });

    testApp('the reminder before the Adhan rings on silent on its own', (
      tester,
    ) async {
      await open(tester);
      await openPrayer(tester, Prayer.maghrib);
      await tapText(tester, t.reminderMinutesChip(10));
      await tap(tester, switchTile(t.alertPreAdhanRingInSilent));
      final alert = (await stored()).alertFor(Prayer.maghrib);
      expect(alert.preAdhanRingInSilent, isTrue);
      expect(alert.ringInSilent, isFalse);
    });

    testApp('Settings rings every Adhan on silent with one switch', (
      tester,
    ) async {
      await open(tester);
      await openSettingsPage(tester);
      await tap(tester, switchTile(t.settingsAdhanRingInSilent));
      expect(
        (await stored()).ringInSilentFor(RingTarget.adhan),
        RingCoverage.all,
      );
      expect(
        (await stored()).ringInSilentFor(RingTarget.preAdhan),
        RingCoverage.none,
        reason: 'the reminders before have their own switch',
      );
      await tap(tester, switchTile(t.settingsPreAdhanRingInSilent));
      expect(
        (await stored()).ringInSilentFor(RingTarget.preAdhan),
        RingCoverage.all,
      );
    });

    testApp('a mix of prayers is said, and one tap rings them all', (
      tester,
    ) async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(enabled: true, ringInSilent: true),
        ),
      );
      await open(tester);
      await openSettingsPage(tester);
      await reveal(tester, find.text(t.ringInSilentSome));
      expect(find.text(t.ringInSilentSome), findsOneWidget);
      await tap(tester, switchTile(t.settingsAdhanRingInSilent));
      expect(
        (await stored()).ringInSilentFor(RingTarget.adhan),
        RingCoverage.all,
      );
    });

    testApp('the build is named at the bottom, for testers', (tester) async {
      await open(tester);
      await openSettingsPage(tester);
      await reveal(tester, find.text(buildLabel()));
      expect(find.text(buildLabel()), findsOneWidget);
      expect(buildLabel(), contains(kGitCommit));
    });

    testApp('Jama’ah reminders can ring on silent', (tester) async {
      await open(tester);
      await openSettingsPage(tester);
      await tap(tester, switchTile(t.alertRingInSilent));
      expect((await settings.read()).jamaahReminders.ringInSilent, isTrue);
    });

    testApp('a test reminder that rings on silent is played by the app', (
      tester,
    ) async {
      await settings.saveJamaahReminders(
        const JamaahReminderSettings(ringInSilent: true),
      );
      await open(tester);
      await openSettingsPage(tester);
      await tapText(tester, t.settingsReminderTest);
      expect(gateway.playedNow, hasLength(1));
      expect(gateway.shownNow, isEmpty);
    });

    testApp('vibration can be turned off', (tester) async {
      await open(tester);
      await openPrayer(tester, Prayer.asr);
      await tap(tester, switchTile(t.alertVibrate));
      expect((await stored()).alertFor(Prayer.asr).vibrate, isFalse);
    });

    testApp(
      'the reminder before the Adhan: a preset, none, or a checked custom',
      (tester) async {
        await open(tester);
        await openPrayer(tester, Prayer.fajr);

        await tapText(tester, t.reminderMinutesChip(15));
        expect((await stored()).alertFor(Prayer.fajr).preAdhanMinutes, 15);
        expect(
          (await stored()).alertFor(Prayer.fajr).enabled,
          isFalse,
          reason: 'the reminder stands on its own',
        );

        await tapText(tester, t.alertReminderNone);
        expect((await stored()).alertFor(Prayer.fajr).preAdhanMinutes, isNull);

        await tapText(tester, t.reminderCustom);
        final field = find.widgetWithText(TextField, t.reminderCustomLabel);
        await tester.enterText(field, '7.5');
        await tester.pump();
        expect(find.text(t.reminderCustomNotWhole), findsOneWidget);
        await tester.enterText(field, '20');
        await tester.pump();
        await tapText(tester, t.save);
        expect((await stored()).alertFor(Prayer.fajr).preAdhanMinutes, 20);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text(t.settingsAlertReminderOnly(20)), findsOneWidget);
      },
    );

    testApp('sunrise explains that it is not a prayer', (tester) async {
      await open(tester);
      await openPrayer(tester, Prayer.sunrise);
      expect(find.text(t.alertSunriseHint), findsOneWidget);
    });

    testApp('a test notification sounds the way the alert is set up', (
      tester,
    ) async {
      await open(tester);
      await openPrayer(tester, Prayer.maghrib);
      await tapText(tester, t.soundModeShort);
      await tap(tester, switchTile(t.alertVibrate));
      await tapText(tester, t.alertTryIt);

      final shown = gateway.shownNow.single;
      expect(shown.channel.sound, ChannelSound.adhanShort);
      expect(shown.channel.vibrate, isFalse);
      expect(shown.title, t.notifTestTitle(t.prayerMaghrib));
      expect(find.text(t.alertTrySent), findsOneWidget);
    });
  });

  group('full screen and the full Adhan', () {
    testApp('full screen is one switch for every Adhan, and is stored', (
      tester,
    ) async {
      await open(tester);
      await openSettingsPage(tester);
      await tap(tester, switchTile(t.settingsFullScreen));
      expect((await stored()).fullScreen, isTrue);
      expect(find.text(t.settingsFullScreenDenied), findsNothing);
    });

    testApp('when Android withholds full screen, Settings says so', (
      tester,
    ) async {
      gateway.fullScreenAllowed = false;
      await open(tester);
      await openSettingsPage(tester);
      await tap(tester, switchTile(t.settingsFullScreen));
      await reveal(tester, find.text(t.settingsFullScreenDenied));
      expect(find.text(t.settingsFullScreenDenied), findsOneWidget);
      expect(find.text(t.settingsFullScreenAllow), findsOneWidget);
    });

    testApp(
      'testing a full Adhan plays it through the app, not a notification',
      (tester) async {
        await open(tester);
        await openPrayer(tester, Prayer.fajr);
        await tapText(tester, t.soundModeFull);
        await tapText(tester, t.alertTryIt);

        expect(gateway.playedNow.single.planned.soundMode, AdhanSoundMode.full);
        expect(gateway.playedNow.single.stopLabel, t.adhanStop);
        expect(gateway.shownNow, isEmpty);
      },
    );

    testApp('a full Adhan is handed to the app, and the list shows it', (
      tester,
    ) async {
      await open(tester);
      await openPrayer(tester, Prayer.fajr);
      await tap(tester, switchTile(t.alertAdhanSwitch));
      await tapText(tester, t.soundModeFull);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(gateway.adhanAlarmsById, isNotEmpty);
      expect(gateway.scheduled, isEmpty);
    });
  });

  group('your own sounds (2026-10-15)', () {
    const mine = CustomSound(
      id: 'custom:x1',
      name: 'My Fajr',
      path: '/sounds/x1.mp3',
    );

    testApp('a recording from the phone can be added, chosen and played', (
      tester,
    ) async {
      picked = (path: '/sounds/new.mp3', name: 'My Fajr');
      await open(tester);
      await openSettingsPage(tester);
      await tapText(tester, t.settingsFullRecording);
      await tapText(tester, t.soundAddFromPhone);
      final added = (await settings.read()).customSounds.single;
      expect(added.name, 'My Fajr');
      expect(added.path, '/sounds/new.mp3');

      await tapText(tester, 'My Fajr');
      expect((await stored()).fullRecording, added.id);
      await tap(tester, find.byTooltip(t.recordingPlayLabel('My Fajr')));
      expect(preview.played.last, '/sounds/new.mp3');
    });

    testApp('deleting one puts the built-in recording back', (tester) async {
      await settings.addCustomSound(mine);
      await settings.saveAdhanAlerts(
        (await stored()).copyWith(fullRecording: mine.id),
      );
      await open(tester);
      await openSettingsPage(tester);
      await tapText(tester, t.settingsFullRecording);
      await tap(tester, find.byTooltip(t.soundOptions('My Fajr')));
      await tapText(tester, t.soundDelete);
      await tapText(tester, t.soundDelete); // the confirmation
      expect((await settings.read()).customSounds, isEmpty);
      expect((await stored()).fullRecording, kDefaultAdhanRecording);
    });

    testApp('a prayer can have its own recording, or the one for all', (
      tester,
    ) async {
      await settings.addCustomSound(mine);
      await open(tester);
      await openPrayer(tester, Prayer.fajr);
      await tapText(tester, t.prayerRecording);
      expect(find.text(t.recordingsForPrayer(t.prayerFajr)), findsOneWidget);
      await tapText(tester, 'My Fajr');
      expect((await stored()).alertFor(Prayer.fajr).recording, mine.id);
      expect((await stored()).alertFor(Prayer.dhuhr).recording, isNull);

      await tapText(tester, t.prayerRecordingSame('Naghshbandi'));
      expect((await stored()).alertFor(Prayer.fajr).recording, isNull);
    });

    testApp('the Jama’ah reminder can use your own sound', (tester) async {
      picked = (path: '/sounds/bell.ogg', name: 'Bell');
      await open(tester);
      await openSettingsPage(tester);
      await tapText(tester, t.settingsReminderSound);
      await tapText(tester, t.reminderSoundCustom);
      final r = (await settings.read()).jamaahReminders;
      expect(r.sound, ReminderSound.custom);
      expect(r.customSound?.name, 'Bell');
      expect(r.customSoundPath, '/sounds/bell.ogg');
      expect(find.text(t.reminderSoundCustomNamed('Bell')), findsOneWidget);
    });

    testApp('Arabic at a large text size', (tester) async {
      final ar = AppLocalizationsArDigits();
      await settings.addCustomSound(mine);
      await settings.setLanguage(AppLanguage.ar);
      await open(tester, textScale: 2.0);
      await openSettingsPage(tester);
      await tapText(tester, ar.settingsFullRecording);
      expect(tester.takeException(), isNull);
      expect(find.text(ar.recordingsYours), findsOneWidget);
      expect(find.text('My Fajr'), findsOneWidget);
    });

    testApp('nothing picked changes nothing', (tester) async {
      await open(tester);
      await openSettingsPage(tester);
      await tapText(tester, t.settingsReminderSound);
      await tapText(tester, t.reminderSoundCustom);
      expect(
        (await settings.read()).jamaahReminders.sound,
        ReminderSound.chime,
      );
    });
  });

  group('the full Adhan recording', () {
    testApp('each recording plays here, and choosing one saves it', (
      tester,
    ) async {
      await open(tester);
      await openSettingsPage(tester);
      await tapText(tester, t.settingsFullRecording);
      expect(find.byType(AdhanRecordingsPage), findsOneWidget);

      await tap(tester, find.byTooltip(t.recordingPlayLabel('Makkah')));
      expect(preview.played.last, adhanRecordingById('makkah').asset);
      expect(find.byTooltip(t.recordingStopLabel('Makkah')), findsOneWidget);

      await tapText(tester, 'Makkah');
      expect((await settings.read()).adhanAlerts.fullRecording, 'makkah');

      final stopsBefore = preview.stops;
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(preview.stops, greaterThan(stopsBefore),
          reason: 'leaving the page stops a recording it started');
      expect(find.text('Makkah'), findsOneWidget,
          reason: 'Settings names the chosen recording');
    });

    testApp('the full Adhan preview plays the chosen recording', (
      tester,
    ) async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().copyWith(fullRecording: 'saber'),
      );
      await open(tester);
      await openPrayer(tester, Prayer.fajr);
      await tap(tester, find.text(t.alertPreview).first);
      expect(preview.played.single, adhanRecordingById('saber').asset);
    });
  });

  group('Jama’ah reminder sound', () {
    testApp('the chime is the default, previewed, and can be changed', (
      tester,
    ) async {
      await open(tester);
      await openSettingsPage(tester);
      await reveal(tester, find.text(t.settingsReminderSound));
      expect(find.text(t.reminderSoundChime), findsOneWidget);

      await tapText(tester, t.settingsReminderSound);
      await tap(tester, find.text(t.alertPreview).first);
      expect(preview.played.last, 'assets/audio/chime/reminder_chime.wav');
      await tap(tester, find.text(t.alertPreview).last);
      expect(preview.played.last, kHayyaAsset);

      await tapText(tester, t.soundModeStandard);
      expect(
        (await settings.read()).jamaahReminders.sound,
        ReminderSound.standard,
      );
      expect(preview.stops, greaterThan(0),
          reason: 'closing the sheet stops the preview');

      final vibrate = switchTile(t.settingsReminderVibrate);
      await reveal(tester, vibrate);
      await tap(tester, vibrate);
      expect((await settings.read()).jamaahReminders.vibrate, isFalse);
    });

    testApp('a test reminder says حيّ على الصلاة, on the chosen channel', (
      tester,
    ) async {
      await settings.saveJamaahReminders(
        const JamaahReminderSettings(sound: ReminderSound.silent),
      );
      await open(tester);
      await openSettingsPage(tester);
      await tapText(tester, t.settingsReminderTest);

      final shown = gateway.shownNow.single;
      expect(shown.title, 'حيّ على الصلاة');
      expect(shown.channel.sound, ChannelSound.none);
      expect(find.text(t.settingsReminderTestSent), findsOneWidget);
    });
  });

  group('short Adhan', () {
    testApp('حيّ على الصلاة can be chosen, previewed, and reaches the channel', (
      tester,
    ) async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(
            enabled: true,
            soundModeOverride: AdhanSoundMode.short,
          ),
        ),
      );
      await open(tester);
      await openSettingsPage(tester);
      expect(find.text(t.shortAdhanNaghshbandi), findsOneWidget);

      await tapText(tester, t.settingsShortAdhan);
      await tap(tester, find.text(t.alertPreview).last);
      expect(preview.played.last, kHayyaAsset);
      await tapText(tester, t.soundHayya);

      expect(
        (await settings.read()).adhanAlerts.shortAdhan,
        ShortAdhan.hayya,
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      final channels = {
        for (final item in gateway.scheduled.values) item.channel,
      };
      expect(channels.map((c) => c.sound).toSet(), {ChannelSound.hayya});
    });
  });

  group('appearance', () {
    testApp('the theme follows the phone until the user picks one', (
      tester,
    ) async {
      ThemeMode applied() =>
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

      await open(tester);
      expect(applied(), ThemeMode.system);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp))
            .themeAnimationDuration,
        Duration.zero,
        reason: 'the switch is instant, not a 200 ms blend of every colour',
      );
      await openSettingsPage(tester);

      await tapText(tester, t.settingsTheme);
      await tapText(tester, t.themeLight);
      expect((await settings.read()).themeMode, AppThemeMode.light);
      expect(applied(), ThemeMode.light);
      expect(find.text(t.themeLight), findsOneWidget);

      await tapText(tester, t.settingsTheme);
      await tapText(tester, t.themeDark);
      expect(applied(), ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(SettingsPage))).brightness,
        Brightness.dark,
      );
    });
  });

  group('pausing Iqama reminders', () {
    testApp('pause all is one switch, and Today says it is on', (
      tester,
    ) async {
      await mosques.add(
        name: 'Masjid al-Nour',
        address: '',
        source: MosqueSource.manual,
      );
      await open(tester);
      await openSettingsPage(tester);

      final pause = switchTile(t.settingsPauseAllIqama);
      await reveal(tester, pause);
      await tap(tester, pause);
      expect((await settings.read()).travel.pauseAllIqamaReminders, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(t.pausedAllNote), findsOneWidget);
    });
  });
  testApp('both pages and the sound sheet survive a large text size', (
    tester,
  ) async {
    await open(tester, textScale: 2.0);
    await openSettingsPage(tester);
    expect(tester.takeException(), isNull);

    await tapText(tester, t.settingsDefaultSound);
    expect(tester.takeException(), isNull);
    // Choosing a sound closes the sheet.
    await tapText(tester, t.soundModeShort);
    expect(tester.takeException(), isNull);

    await tapText(tester, t.prayerFajr);
    await tapText(tester, t.reminderCustom);
    expect(tester.takeException(), isNull);
  });
}

class _FakePreview implements AudioPreview {
  final played = <String>[];
  int stops = 0;
  Completer<void>? _playing;

  /// Plays until stopped, like a long recording.
  @override
  Future<void> play(String asset) {
    played.add(asset);
    return (_playing = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    final playing = _playing;
    _playing = null;
    if (playing != null && !playing.isCompleted) playing.complete();
  }
}
