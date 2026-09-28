import 'package:flutter/material.dart';

/// Touch-tilt: the card leans away from your finger in 3D and shows a
/// moving light reflection. Uses raw pointer events, so scrolling still works.
class TiltCard extends StatefulWidget {
  final Widget child;
  final double max;
  final double radius;
  const TiltCard({required this.child, this.max = 0.2, this.radius = 24});

  @override
  State<TiltCard> createState() => _TiltState();
}

class _TiltState extends State<TiltCard> {
  Offset _n = Offset.zero;
  bool _down = false;

  void _set(Offset p) {
    final s = context.size;
    if (s == null || s.isEmpty) return;
    setState(() {
      _n = Offset(
        ((p.dx / s.width) * 2 - 1).clamp(-1.0, 1.0),
        ((p.dy / s.height) * 2 - 1).clamp(-1.0, 1.0),
      );
      _down = true;
    });
  }

  void _reset() => setState(() {
        _n = Offset.zero;
        _down = false;
      });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _set(e.localPosition),
      onPointerMove: (e) => _set(e.localPosition),
      onPointerUp: (_) => _reset(),
      onPointerCancel: (_) => _reset(),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(end: _n),
        duration: Duration(milliseconds: _down ? 80 : 520),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        builder: (context, v, child) {
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(v.dy * widget.max)
            ..rotateY(-v.dx * widget.max);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.radius),
                      child: Opacity(
                        opacity: (v.distance).clamp(0.0, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(v.dx, v.dy),
                              radius: 0.9,
                              colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
