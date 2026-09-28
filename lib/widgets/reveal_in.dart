import 'package:flutter/material.dart';

/// Cards flip up into place one after another.
class RevealIn extends StatelessWidget {
  final int i;
  final Widget child;
  const RevealIn({super.key, required this.i, required this.child});

  @override
  Widget build(BuildContext context) {
    final total = 500 + i * 110;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval((i * 110) / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, v, child) {
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX((1 - v) * 0.5)
              ..translate(0.0, (1 - v) * 30, 0.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
