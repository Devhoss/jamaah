import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/clock_format.dart';
import '../../app/date_labels.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/place.dart';
import '../../domain/prayer.dart';
import '../../domain/prayer_times_calculator.dart';
import '../../domain/time_model.dart';
import '../../domain/today.dart';
import '../../domain/zone_offsets.dart';
import '../components/app_widgets.dart';
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
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.previewTitle(city.displayName))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          Text(
            DateLabels.gregorian(
              DateTime(day.year, day.month, day.day),
              locale,
            ),
            style: theme.textTheme.titleLarge,
          ),
          if (current != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.previewNote(city.displayName, placeLabel(l10n, current)),
              style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
            ),
          ],
          AppSectionHeader(l10n.todaySectionTimes),
          AppRows(
            children: [
              for (final prayer in Prayer.adhanPrayers)
                AppRow(
                  muted: prayer == Prayer.sunrise,
                  selected: prayer == today.inForce?.prayer,
                  leading: Icon(
                    Icons.circle,
                    size: 8,
                    color: prayer == today.next?.prayer
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  title: Text(
                    prayerName(l10n, prayer),
                    style: const TextStyle(fontSize: AppType.rowSize),
                  ),
                  trailing: Text(switch (today.day.timeOf(prayer)) {
                    final m? => clock.time(LocalTime(m)),
                    null => l10n.noTimeToday,
                  }, style: const TextStyle(fontSize: AppType.rowSize)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
