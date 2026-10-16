import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/clock_format.dart';
import '../../app/date_labels.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/place.dart';
import '../../domain/prayer.dart';
import '../../domain/prayer_times_calculator.dart';
import '../../domain/time_model.dart';
import '../../domain/today.dart';
import '../../domain/zone_offsets.dart';
import '../settings/settings_kit.dart';
import 'city_list_page.dart';
import 'place_copy.dart';

/// Picks a city and shows its times, without touching the saved place.
Future<void> previewAnotherCity(BuildContext context) async {
  final city = await Navigator.of(context)
      .push<Place>(MaterialPageRoute(builder: (_) => const CityListPage()));
  if (city == null || !context.mounted) return;
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => PreviewCityPage(city: city)));
}

/// Today's times somewhere else, for planning a trip or a layover. Read-only:
/// nothing is stored, no notification changes, and the user's own place stays.
/// Iqama times belong to a mosque, so none are shown here.
class PreviewCityPage extends ConsumerWidget {
  const PreviewCityPage({required this.city, super.key});

  final Place city;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final zone = zoneOffsetsFor(city.ianaZone);
    final calculator = PrayerTimesCalculator(
      latitude: city.latitude,
      longitude: city.longitude,
      zone: zone,
      // Auto detect picks the method used in the previewed city.
      method: settings.calculationMethod.resolvedFor(city.ianaZone),
      madhab: settings.madhab,
      highLatitudeRule: settings.highLatitudeRule,
      minuteOffsets: settings.minuteOffsets,
      customAngles: settings.customAngles,
      hijriAdjustDays: settings.hijriAdjustDays,
    );
    final today = readToday(
      calculator: calculator,
      moment: LocalMoment.inZone(
        zone: zone,
        utcInstant: ref.watch(minuteClockProvider),
      ),
    );
    final clock = ClockFormat.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final day = today.day.day;
    final current = ref.watch(currentPlaceProvider);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final date = DateLabels.gregorian(
      DateTime(day.year, day.month, day.day),
      locale,
    );

    return SettingsScaffold(
      title: l10n.previewTitle(city.displayName),
      lead: current == null
          ? date
          : [
              date,
              l10n.previewNote(city.displayName, placeLabel(l10n, current)),
            ].join('\n'),
      children: [
        SettingsHeading(l10n.todaySectionTimes, top: 4),
        for (final (i, prayer) in Prayer.adhanPrayers.indexed)
          Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              // The prayer in force sits in a well, as on Today.
              color: prayer == today.inForce?.prayer ? s.well : null,
              borderRadius: BorderRadius.circular(14),
              border:
                  prayer != today.inForce?.prayer &&
                      i < Prayer.adhanPrayers.length - 1
                  ? Border(bottom: BorderSide(color: s.divider))
                  : null,
            ),
            child: MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prayerName(l10n, prayer),
                      style: type.row.copyWith(
                        color: prayer == Prayer.sunrise
                            ? s.onSurfaceMuted
                            : s.onSurface,
                        fontWeight: prayer == today.next?.prayer
                            ? FontWeight.w700
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    switch (today.day.timeOf(prayer)) {
                      final m? => clock.time(LocalTime(m)),
                      null => l10n.noTimeToday,
                    },
                    style: type.row.copyWith(
                      color: s.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
