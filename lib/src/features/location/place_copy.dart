import '../../app/l10n/generated/app_localizations.dart';
import '../../domain/place.dart';

/// The copy for a place: what it is called, and what each failure says.
///
/// The sheet and the Today screen both answer the same two questions, so the words
/// live once. A failure the user cannot read is a silent failure (AGENTS.md), and
/// every message here ends at the manual city list rather than at a dead end.
String placeLabel(AppLocalizations l10n, Place place) =>
    place.userName ??
    (place.fromDevice && place.displayName == place.ianaZone
        ? l10n.locationCurrentPlace
        : place.displayName);

/// The place as Today's top bar names it: the user's own name, a chosen city,
/// or the device's reverse-geocoded area. Without a result it says
/// "Current location" instead of inventing a nearby city.
String placeShortLabel(AppLocalizations l10n, Place place) {
  if (place.userName case final name?) return name;
  if (!place.fromDevice || place.displayName != place.ianaZone) {
    return place.displayName;
  }
  return l10n.locationCurrentPlace;
}

String placeFailureMessage(AppLocalizations l10n, PlaceFailure failure) =>
    switch (failure) {
      PlaceFailure.denied => l10n.locationDenied,
      PlaceFailure.permanentlyDenied => l10n.locationPermanentlyDenied,
      PlaceFailure.serviceDisabled => l10n.locationServiceDisabled,
      PlaceFailure.timeout => l10n.locationTimeout,
      PlaceFailure.unavailable => l10n.locationUnavailable,
    };

/// The place label for the location sheet.
String placeDescription(AppLocalizations l10n, Place place) {
  return placeLabel(l10n, place);
}
