import 'package:flutter/material.dart';

/// Motion vocabulary for the whole app. Three durations, one curve family,
/// no bounce anywhere. Honors the system reduce-motion setting.
abstract final class M {
  static const press = Duration(milliseconds: 110);
  static const swap = Duration(milliseconds: 200); // state/icon changes
  static const enter = Duration(milliseconds: 350); // entrances
  static const stagger = Duration(milliseconds: 70); // per-item delay
  static const curve = Cubic(0.2, 0, 0, 1); // emphasized decelerate
}

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Tactile press feedback: scales to 0.96 while pressed, interruptible.
/// For custom tap surfaces (cards, chips, tiles); Material buttons keep
/// their own ink feedback.
class Pressable extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const Pressable({super.key, required this.child, this.enabled = true});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _reduceMotion(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: M.press,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Staggered entrance: fade + a 12px rise, delayed by [index] steps.
/// Runs once when the surrounding State is created, so theme or language
/// rebuilds never replay it.
class Entrance extends StatefulWidget {
  final int index;
  final Widget child;

  const Entrance({super.key, this.index = 0, required this.child});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: M.enter,
  );
  late final CurvedAnimation _a = CurvedAnimation(parent: _c, curve: M.curve);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_reduceMotion(context)) {
      _c.value = 1;
    } else {
      Future.delayed(M.stagger * widget.index, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - _a.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Cross-fade + gentle scale between states (icons, short labels).
/// Wrap the changing widget and give it a ValueKey per state.
class FadeSwap extends StatelessWidget {
  final Widget child;

  const FadeSwap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    return AnimatedSwitcher(
      duration: M.swap,
      switchInCurve: M.curve,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
