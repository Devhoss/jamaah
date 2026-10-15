import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import '../components/line_icon.dart';
import '../components/travel_switch.dart';
import '../sky/sky_palette.dart';

/// Today's top bar on the sky: the place button ("Kuwait City ▾" with the
/// date or the follow line under it) and the travel switch (spec §4.1).
class TodayTopBar extends StatelessWidget {
  const TodayTopBar({
    required this.place,
    required this.subline,
    required this.onPlace,
    required this.travelOn,
    required this.onTravel,
    required this.palette,
    super.key,
  });

  final String place;

  /// "Thu 15 Oct · 4 Jumada al-Awwal 1448", or "Following your location ·
  /// updated 2 min ago" in travel mode.
  final String subline;
  final VoidCallback onPlace;
  final bool travelOn;
  final ValueChanged<bool> onTravel;
  final SkyPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.placeButtonSemantics(place),
              value: subline,
              excludeSemantics: true,
              child: InkWell(
                onTap: onPlace,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              place,
                              overflow: TextOverflow.ellipsis,
                              style: type.row.copyWith(
                                fontSize: 15,
                                color: palette.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          LineIcon(
                            LineIcons.chevronDown,
                            size: 14,
                            strokeWidth: 2.2,
                            color: palette.ink,
                          ),
                        ],
                      ),
                      Text(
                        subline,
                        style: type.meta.copyWith(
                          fontSize: 12,
                          color: palette.mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TravelSwitch(
            value: travelOn,
            onChanged: onTravel,
            label: l10n.settingsTravelMode,
            colors: TravelSwitchColors(
              ink: palette.ink,
              deep: palette.deep,
              outline: palette.line,
              fill: palette.fill,
            ),
          ),
        ],
      ),
    );
  }
}
