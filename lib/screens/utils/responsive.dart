import 'dart:math' as math;
import 'package:flutter/widgets.dart';

enum SizeClass { compact, medium, expanded }

class Responsive {
  static SizeClass sizeClass(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return SizeClass.compact;       // phones
    if (w < 1024) return SizeClass.medium;       // tablets / small landscape
    return SizeClass.expanded;                   // large tablets / desktop
  }

  static bool isCompact(BuildContext c) => sizeClass(c) == SizeClass.compact;
  static bool isMedium(BuildContext c) => sizeClass(c) == SizeClass.medium;
  static bool isExpanded(BuildContext c) => sizeClass(c) == SizeClass.expanded;

  /// Standard page padding (gutter)
  static EdgeInsets pagePadding(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    final h = MediaQuery.sizeOf(c).height;
    final base = math.max(16.0, math.min(24.0, w * 0.05));
    // a bit more breathing room on tall displays
    return EdgeInsets.symmetric(horizontal: base, vertical: math.min(24.0, h * 0.03));
  }

  /// Keeps content readable on wide screens (not “desktop specific”, just max width)
  static double maxContentWidth(BuildContext c) {
    final sc = sizeClass(c);
    if (sc == SizeClass.compact) return double.infinity;
    if (sc == SizeClass.medium) return 760;
    return 920;
  }
}

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  const ResponsiveCenter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);
    final maxW = Responsive.maxContentWidth(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(padding: pad, child: child),
      ),
    );
  }
}
