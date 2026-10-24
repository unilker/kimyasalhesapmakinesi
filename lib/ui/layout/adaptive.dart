import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';

/// Material 3 window size classes.
enum WindowSize { compact, medium, expanded }

WindowSize windowSizeOf(BuildContext context) =>
    windowSizeForWidth(MediaQuery.sizeOf(context).width);

WindowSize windowSizeForWidth(double width) {
  if (width < 600) return WindowSize.compact;
  if (width < 840) return WindowSize.medium;
  return WindowSize.expanded;
}

/// A hinge or fold that separates the screen into two areas, in global
/// (screen) coordinates.
class Hinge {
  const Hinge(this.bounds, this.axis);

  final Rect bounds;

  /// [Axis.vertical] for a vertical hinge (left | right panes, book
  /// posture); [Axis.horizontal] for a horizontal fold (top / bottom panes,
  /// tabletop posture).
  final Axis axis;
}

/// Returns the separating display feature (hinge, or a fold that is
/// half-opened or has a physical width), if any.
Hinge? hingeOf(BuildContext context) {
  final mq = MediaQuery.of(context);
  final size = mq.size;
  for (final f in mq.displayFeatures) {
    if (f.type == DisplayFeatureType.cutout) continue;
    final b = f.bounds;
    final separating = f.type == DisplayFeatureType.hinge ||
        f.state == DisplayFeatureState.postureHalfOpened ||
        b.width > 0 && b.height > 0;
    if (!separating) continue;
    if (b.height >= size.height - 1 && b.left > 0 && b.right < size.width) {
      return Hinge(b, Axis.vertical);
    }
    if (b.width >= size.width - 1 && b.top > 0 && b.bottom < size.height) {
      return Hinge(b, Axis.horizontal);
    }
  }
  return null;
}

/// Lays out two panes side by side (or top/bottom) and keeps them clear of
/// a hinge or fold on foldable devices. Without a hinge, panes are placed
/// side by side when there is enough width ([minSplitWidth]); otherwise
/// [compactBuilder] (or a single scrolling column) is used.
class TwoPane extends StatefulWidget {
  const TwoPane({
    super.key,
    required this.first,
    required this.second,
    this.minSplitWidth = 720,
    this.firstFraction = 0.5,
    this.compact,
    this.allowTabletop = false,
  });

  final Widget first;
  final Widget second;
  final double minSplitWidth;

  /// Width share of [first] when splitting without a hinge.
  final double firstFraction;

  /// Layout used when the panes do not fit side by side.
  final Widget? compact;

  /// Whether to split top/bottom along a horizontal fold (tabletop mode).
  final bool allowTabletop;

  @override
  State<TwoPane> createState() => _TwoPaneState();
}

class _TwoPaneState extends State<TwoPane> {
  Offset _origin = Offset.zero;

  void _checkOrigin() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final o = box.localToGlobal(Offset.zero);
    if ((o - _origin).distance > 0.5) setState(() => _origin = o);
  }

  @override
  Widget build(BuildContext context) {
    final hinge = hingeOf(context);
    if (hinge != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOrigin());
    }
    return LayoutBuilder(builder: (context, c) {
      if (hinge != null) {
        final local = hinge.bounds.shift(-_origin);
        if (hinge.axis == Axis.vertical &&
            local.left > 80 &&
            local.right < c.maxWidth - 80) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: local.left, child: widget.first),
              SizedBox(width: local.width),
              Expanded(child: widget.second),
            ],
          );
        }
        if (hinge.axis == Axis.horizontal &&
            widget.allowTabletop &&
            local.top > 120 &&
            local.bottom < c.maxHeight - 120) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: local.top, child: widget.first),
              SizedBox(height: local.height),
              Expanded(child: widget.second),
            ],
          );
        }
      }
      if (c.maxWidth >= widget.minSplitWidth) {
        final w = (c.maxWidth * widget.firstFraction).roundToDouble();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: w, child: widget.first),
            VerticalDivider(
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(child: widget.second),
          ],
        );
      }
      return widget.compact ??
          Column(children: [Expanded(child: widget.first), Expanded(child: widget.second)]);
    });
  }
}

/// Centers content and limits its width so text stays readable on large
/// tablets.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}
