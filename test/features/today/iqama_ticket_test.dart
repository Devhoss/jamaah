import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jamaah/src/app/clock_format.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/theme/theme.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/features/sky/sky_palette.dart';
import 'package:jamaah/src/features/today/iqama_ticket.dart';
import 'package:jamaah/src/features/today/today_text.dart';

final _t = AppLocalizationsEn();
const _clock = ClockFormat(use24Hour: false, locale: 'en');
const _palette = SkyPalette(ink: Color(0xFF15161C), deep: Color(0xFFFBFAF7));
const _thursday = LocalDay(2026, 10, 15);
const _friday = LocalDay(2026, 10, 16);
const _adhan = {
  Prayer.fajr: 261,
  Prayer.sunrise: 342,
  Prayer.dhuhr: 689,
  Prayer.asr: 889,
  Prayer.maghrib: 1035,
  Prayer.isha: 1111,
};

Mosque _mosque({
  Map<Prayer, PrayerIqama> prayers = const {},
  PrayerIqama? jumuah,
}) => Mosque(
  id: 'm',
  name: 'Test Mosque',
  address: '',
  source: MosqueSource.manual,
  schedules: [
    Schedule.empty(mosqueId: 'm').copyWith(
      prayers: {
        for (final p in Prayer.iqamaPrayers)
          p: prayers[p] ?? PrayerIqama(prayer: p),
      },
      jumuah: jumuah,
    ),
  ],
);

String _hm(int h, int m) => _clock.time(LocalTime.of(h, m));

TicketContent _ticket(
  Prayer prayer, {
  Mosque? mosque,
  LocalDay day = _thursday,
  int now = 880,
}) => ticketFor(
  l10n: _t,
  clock: _clock,
  prayer: prayer,
  day: day,
  adhanTimes: _adhan,
  mosque: mosque,
  nowMinute: now,
  onSet: () {},
  onAdd: () {},
);

void main() {
  setUpAll(() => initializeDateFormatting());

  group('what the ticket says', () {
    test('Sunrise has no Iqama, whatever the mosque', () {
      expect(_ticket(Prayer.sunrise, mosque: _mosque()), isA<TicketSunrise>());
    });

    test('no mosque asks for one', () {
      expect(_ticket(Prayer.asr), isA<TicketNoMosque>());
    });

    test('nothing entered is "Not configured", never a guessed time', () {
      final t = _ticket(Prayer.asr, mosque: _mosque());
      expect(t, isA<TicketNotConfigured>());
    });

    test('minutes after the Adhan: the user\'s minutes, added to the day', () {
      final t = _ticket(
        Prayer.asr,
        mosque: _mosque(
          prayers: {
            Prayer.asr: const PrayerIqama(
              prayer: Prayer.asr,
              afterAdhanMinutes: 20,
              reminderEnabled: true,
            ),
          },
        ),
      ) as TicketSet;
      expect(t.time, _hm(15, 9));
      expect(t.relative, _t.countdownMinutes(29));
      expect(t.rule, _t.ticketRuleAfter(20));
      expect(t.reminderOn, isTrue);
      expect(t.reminder, _t.ticketReminder(_hm(14, 59)));
      expect(t.note, isNull);
    });

    test('a fixed time says so; a reminder that is off says so', () {
      final t = _ticket(
        Prayer.maghrib,
        mosque: _mosque(
          prayers: {
            Prayer.maghrib: PrayerIqama(
              prayer: Prayer.maghrib,
              iqama: LocalTime.of(17, 25),
            ),
          },
        ),
      ) as TicketSet;
      expect(t.time, _hm(17, 25));
      expect(t.rule, _t.ticketRuleFixed);
      expect(t.reminderOn, isFalse);
      expect(t.reminder, _t.ticketNoReminder);
    });

    test('a passed Iqama reads as "ago" (held prayers after the Adhan)', () {
      final t = _ticket(
        Prayer.dhuhr,
        mosque: _mosque(
          prayers: {
            Prayer.dhuhr: const PrayerIqama(
              prayer: Prayer.dhuhr,
              afterAdhanMinutes: 15,
            ),
          },
        ),
        now: 714,
      ) as TicketSet;
      expect(t.relative, _t.agoMinutes(10));
    });

    test('Friday: the Jumu\'ah Iqama replaces Dhuhr\'s', () {
      final t = _ticket(
        Prayer.dhuhr,
        day: _friday,
        mosque: _mosque(
          prayers: {
            Prayer.dhuhr: const PrayerIqama(
              prayer: Prayer.dhuhr,
              afterAdhanMinutes: 15,
            ),
          },
          jumuah: PrayerIqama(prayer: Prayer.dhuhr, iqama: LocalTime.of(12, 0)),
        ),
      ) as TicketSet;
      expect(t.time, _hm(12, 0));
      expect(t.note, isNull);
    });

    test('Friday with no Jumu\'ah time: Dhuhr\'s own, with the note', () {
      final t = _ticket(
        Prayer.dhuhr,
        day: _friday,
        mosque: _mosque(
          prayers: {
            Prayer.dhuhr: const PrayerIqama(
              prayer: Prayer.dhuhr,
              afterAdhanMinutes: 15,
            ),
          },
        ),
      ) as TicketSet;
      expect(t.time, _hm(11, 44));
      expect(t.note, _t.ticketJumuahNotSet(_hm(11, 44)));
    });

    test('relative text: ahead, behind, now', () {
      expect(relativeText(_t, 50), _t.countdownMinutes(50));
      expect(relativeText(_t, 70), _t.countdownHours(1, 10));
      expect(relativeText(_t, -5), _t.agoMinutes(5));
      expect(relativeText(_t, -130), _t.agoHours(2));
      expect(relativeText(_t, 0), _t.agoJustNow);
    });
  });

  group('the ticket', () {
    Future<void> pump(WidgetTester tester, TicketContent content) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: IqamaTicket(content: content, palette: _palette),
              ),
            ),
          ),
        );

    const set = TicketSet(
      mosque: 'Test Mosque',
      time: '3:09 PM',
      relative: 'in 29 min',
      rule: 'Adhan + 20 min · set by you',
      reminder: 'Reminder 2:59 PM',
      reminderOn: true,
    );

    testWidgets('set: a solid ink box, read as one sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, set);
      // The label in capitals, the mosque's name as the user typed it.
      expect(find.text('IQAMA · Test Mosque', findRichText: true), findsOneWidget);
      expect(find.text('Adhan + 20 min · set by you'), findsOneWidget);
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(IqamaTicket),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((box.decoration! as BoxDecoration).color, _palette.ink);
      expect(
        find.bySemanticsLabel(
          _t.ticketSemantics(
            'Test Mosque',
            '3:09 PM',
            'in 29 min',
            'Adhan + 20 min · set by you',
            'Reminder 2:59 PM',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(IqamaTicket)).height,
        greaterThanOrEqualTo(62),
      );
      handle.dispose();
    });

    testWidgets('not configured: dashed, calm, and Set time opens the mosque', (
      tester,
    ) async {
      var opened = 0;
      await pump(
        tester,
        TicketNotConfigured(mosque: 'Test Mosque', onSet: () => opened++),
      );
      expect(find.text(_t.notConfigured), findsOneWidget);
      expect(find.text(_t.ticketSetTime), findsOneWidget);
      // No time is shown: the app never fills one in.
      expect(find.textContaining(RegExp(r'\d:\d\d')), findsNothing);
      await tester.tap(find.text(_t.ticketSetTime));
      expect(opened, 1);
    });

    testWidgets('Sunrise: the plain admission, no Iqama', (tester) async {
      await pump(tester, const TicketSunrise());
      expect(find.text(_t.ticketSunrise), findsOneWidget);
    });

    testWidgets('no mosque: one tap to add one', (tester) async {
      var added = 0;
      await pump(tester, TicketNoMosque(onAdd: () => added++));
      await tester.tap(find.text(_t.addMosqueTitle));
      expect(added, 1);
    });

    testWidgets('Arabic kickers are not uppercased', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: IqamaTicket(content: set, palette: _palette),
          ),
        ),
      );
      expect(find.textContaining('Test Mosque'), findsOneWidget);
      expect(find.textContaining('TEST MOSQUE'), findsNothing);
    });
  });
}
