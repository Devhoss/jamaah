import '../../app/l10n/generated/app_localizations.dart';
import '../../domain/mosque.dart';
import '../../domain/prayer.dart';

/// Where a mosque came from. There is no verification mechanic, so found
/// mosques say they are not verified (AGENTS.md).
String mosqueSourceLine(AppLocalizations l10n, MosqueSource source) =>
    switch (source) {
      MosqueSource.manual => l10n.mosqueSourceManual,
      MosqueSource.google => l10n.mosqueSourceGoogleUnverified,
      MosqueSource.osm => l10n.mosqueSourceOsmUnverified,
    };

/// The six Iqama a mosque can have, in order: the five prayers, then
/// Jumu'ah. True where the user has set one.
List<bool> iqamaSlots(Schedule? schedule) => [
  for (final p in Prayer.iqamaPrayers)
    schedule?.iqamaFor(p).isConfigured ?? false,
  schedule?.jumuah.isConfigured ?? false,
];

/// "4 of 6 Iqama set", or "No Iqama set yet".
String iqamaCountLine(AppLocalizations l10n, Schedule? schedule) {
  final set = iqamaSlots(schedule).where((s) => s).length;
  return set == 0 ? l10n.mosqueNoIqamaYet : l10n.iqamaStatusPartial(set, 6);
}
