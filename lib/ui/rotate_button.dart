import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/bi.dart';
import '../state/app_state.dart';
import 'common.dart';
import 'strings.dart';

/// Whether the app can lock the orientation on this device. Phones (and
/// folded foldables) can; tablets and unfolded foldables are managed by
/// the system (Android 16+ ignores locks there, iPad multitasking too).
bool orientationLockSupported(BuildContext context) =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) &&
    MediaQuery.sizeOf(context).shortestSide < 600;

/// A small tab docked to the screen edge that switches between portrait
/// and landscape. Tap to rotate, long-press for options, drag to move.
class RotateButton extends StatefulWidget {
  const RotateButton({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<RotateButton> createState() => _RotateButtonState();
}

class _RotateButtonState extends State<RotateButton> {
  static const _w = 40.0;
  static const _h = 56.0;

  /// Position while dragging (top-left, global).
  Offset? _drag;

  void _rotate() {
    HapticFeedback.selectionClick();
    final app = AppScope.read(context);
    final portraitNow = MediaQuery.orientationOf(context) == Orientation.portrait;
    final target = portraitNow ? OrientationPref.landscape : OrientationPref.portrait;
    app.setOrientation(target);
    _announce(target == OrientationPref.portrait ? S.lockedPortrait : S.lockedLandscape);
  }

  void _announce(Bi text) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.t(text)),
        duration: const Duration(milliseconds: 2200),
      ));
  }

  Future<void> _showOptions() async {
    HapticFeedback.mediumImpact();
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;
    final app = AppScope.read(context);
    await showModalBottomSheet<void>(
      context: ctx,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(sheet.t(S.orientation),
                    style: sheet.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
              for (final (pref, icon, label) in [
                (OrientationPref.auto, Icons.screen_rotation_rounded, S.autoRotate),
                (OrientationPref.portrait, Icons.stay_current_portrait_rounded, S.portrait),
                (OrientationPref.landscape, Icons.stay_current_landscape_rounded, S.landscape),
              ])
                ListTile(
                  leading: Icon(icon),
                  title: Text(sheet.t(label), style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: app.orientation == pref ? const Icon(Icons.check_rounded) : null,
                  onTap: () {
                    app.setOrientation(pref);
                    Navigator.pop(sheet);
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility_off_rounded),
                title: Text(sheet.t(S.hideButton)),
                subtitle: Text(sheet.t(S.hiddenHint)),
                onTap: () {
                  app.setShowRotateButton(false);
                  Navigator.pop(sheet);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mq = MediaQuery.of(context);
    if (!app.showRotateButton ||
        !orientationLockSupported(context) ||
        mq.viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }
    final size = mq.size;
    final pad = mq.padding;
    final minTop = pad.top + 8;
    final maxTop = (size.height - pad.bottom - _h - 8).clamp(minTop, double.infinity);
    final dockedTop = minTop + (maxTop - minTop) * app.rotateButtonY;
    final left = app.rotateButtonLeft;
    final dockedLeft = left ? 0.0 : size.width - _w;
    final pos = _drag ?? Offset(dockedLeft, dockedTop);
    final scheme = context.colors;
    final locked = app.orientation != OrientationPref.auto;

    final radius = BorderRadius.horizontal(
      left: Radius.circular(left && _drag == null ? 0 : 18),
      right: Radius.circular(!left && _drag == null ? 0 : 18),
    );

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Semantics(
        container: true,
        button: true,
        label: context.t(S.rotateScreen),
        hint: context.t(S.rotateButtonHint),
        child: GestureDetector(
          onTap: _rotate,
          onLongPress: _showOptions,
          onPanUpdate: (d) => setState(() {
            final p = (_drag ?? pos) + d.delta;
            _drag = Offset(
              p.dx.clamp(0, size.width - _w),
              p.dy.clamp(minTop, maxTop),
            );
          }),
          onPanEnd: (_) {
            final p = _drag ?? pos;
            final range = maxTop - minTop;
            app.setRotateButtonPosition(
              y: range <= 0 ? 0 : (p.dy - minTop) / range,
              left: p.dx + _w / 2 < size.width / 2,
            );
            setState(() => _drag = null);
          },
          child: Material(
            key: const ValueKey('rotateButton'),
            color: scheme.primaryContainer.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
            ),
            child: SizedBox(
              width: _w,
              height: _h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.screen_rotation_rounded, color: scheme.onPrimaryContainer, size: 22),
                  if (locked)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Icon(Icons.lock_rounded, size: 12, color: scheme.onPrimaryContainer),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
