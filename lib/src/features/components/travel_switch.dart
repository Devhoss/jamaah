import 'package:flutter/material.dart';

import 'line_icon.dart';

/// The switch's colours: sky ink on Today, `accent`/`onAccent` on surfaces.
@immutable
class TravelSwitchColors {
  const TravelSwitchColors({
    required this.ink,
    required this.deep,
    required this.outline,
  });

  /// The knob when off, and the track when on.
  final Color ink;

  /// The knob when on, and the icon on the knob when off.
  final Color deep;

  /// The track's outline when off.
  final Color outline;
}

/// Travel mode: a calm 72 × 40 pill whose knob carries a house (off) or a
/// plane (on) (spec §2.5). The knob springs across (440 ms, slight overshoot)
/// and stretches to 44 px for a moment while it moves; the icons swap with a
/// scale and turn. Under reduce motion it simply changes.
class TravelSwitch extends StatefulWidget {
  const TravelSwitch({
    required this.value,
    required this.onChanged,
    required this.colors,
    required this.label,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final TravelSwitchColors colors;

  /// Read by TalkBack: "Travel mode".
  final String label;

  static const width = 72.0;
  static const height = 40.0;
  static const spring = Cubic(0.34, 1.56, 0.64, 1);

  @override
  State<TravelSwitch> createState() => _TravelSwitchState();
}

class _TravelSwitchState extends State<TravelSwitch>
    with TickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
    value: widget.value ? 1 : 0,
  );
  late final AnimationController _stretch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void didUpdateWidget(TravelSwitch old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _move.value = widget.value ? 1 : 0;
      return;
    }
    widget.value ? _move.forward() : _move.reverse();
    _stretch.forward(from: 0).then((_) {
      if (mounted) _stretch.reverse();
    });
  }

  @override
  void dispose() {
    _move.dispose();
    _stretch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final onChanged = widget.onChanged;
    return Semantics(
      toggled: widget.value,
      label: widget.label,
      button: false,
      onTap: onChanged == null ? null : () => onChanged(!widget.value),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged(!widget.value),
          child: SizedBox(
            // A 48 dp target around the 40 dp pill.
            width: TravelSwitch.width,
            height: 48,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_move, _stretch]),
                builder: (context, _) {
                  final t = TravelSwitch.spring.transform(_move.value);
                  final on = _move.value > 0.5;
                  final knob =
                      32 + 12 * Curves.easeOut.transform(_stretch.value);
                  // Inside the 1.5 px border the track is 69 wide; 2.5 px each side.
                  final travel = TravelSwitch.width - 3 - 5 - knob;
                  return AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 260),
                    width: TravelSwitch.width,
                    height: TravelSwitch.height,
                    decoration: BoxDecoration(
                      color: widget.value ? c.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.value ? c.ink : c.outline,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 2.5,
                          // Physical left, as in the design: the knob's side
                          // means on or off whatever the language.
                          left: 2.5 + travel * t,
                          child: Container(
                            width: knob,
                            height: 32,
                            decoration: BoxDecoration(
                              color: widget.value ? c.deep : c.ink,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: _icon(on),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(bool on) {
    final color = widget.value ? widget.colors.ink : widget.colors.deep;
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 400),
      switchInCurve: TravelSwitch.spring,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.4, end: 1.0).animate(animation),
          child: RotationTransition(
            turns: Tween(
              begin: on ? 45 / 360 : -30 / 360,
              end: 0.0,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
      child: LineIcon(
        on ? LineIcons.plane : LineIcons.home,
        key: ValueKey(on),
        size: 16,
        strokeWidth: 2,
        color: color,
      ),
    );
  }
}
