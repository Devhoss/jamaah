import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import '../sky/sky_palette.dart';

/// The one loud element: a kicker, the Adhan time in a light serif, the
/// prayer's name in italic and "PM · in 50 min" (spec §4.1).
///
/// Everything it says is handed in; Today decides what. A "Back to now" pill
/// sits beside the kicker whenever the view has been moved.
class TodayHero extends StatelessWidget {
  const TodayHero({
    required this.kicker,
    required this.time,
    required this.name,
    required this.meta,
    required this.palette,
    required this.kickerPalette,
    this.onBackToNow,
    super.key,
  });

  /// Already in its final case: Latin kickers are uppercased by the caller.
  final String kicker;
  final String time;
  final String name;

  /// "PM · in 50 min", or "Adhan 5 min ago" while held for the Iqama.
  final String meta;

  /// The hero band's ink (3:1 for the big time).
  final SkyPalette palette;

  /// The kicker and meta are small text, so they take the stricter ink.
  final SkyPalette kickerPalette;
  final VoidCallback? onBackToNow;

  /// The time is already 108 px; past this it would push the rows off the
  /// screen, so larger text sizes wrap the name below it instead.
  static const maxTimeScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final l10n = AppLocalizations.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    return Semantics(
      container: true,
      liveRegion: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    kicker,
                    style: type.kicker.copyWith(color: kickerPalette.mute),
                  ),
                ),
                if (onBackToNow != null)
                  _BackToNow(
                    label: l10n.heroBackToNow,
                    palette: kickerPalette,
                    style: type.meta,
                    onTap: onBackToNow!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            runSpacing: 4,
            children: [
              MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: scaler.clamp(maxScaleFactor: maxTimeScale),
                ),
                child: Text(
                  time,
                  style: type.hero.copyWith(color: palette.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: type.prayerName.copyWith(color: palette.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: type.meta.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kickerPalette.mute,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackToNow extends StatelessWidget {
  const _BackToNow({
    required this.label,
    required this.palette,
    required this.style,
    required this.onTap,
  });

  final String label;
  final SkyPalette palette;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          // The pill is 32 tall; the touch target is 48.
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.line),
              ),
              child: Text(
                label,
                style: style.copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
