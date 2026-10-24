import 'package:flutter/material.dart';

import '../../core/solver.dart';
import '../common.dart';
import '../strings.dart';

/// Universal-indicator style pH bar for acid–base results.
Widget? phScaleForValues(BuildContext context, SolverEquation eq, Values v) {
  final ph = v['pH'] ?? (v['pOH'] != null ? 14 - v['pOH']! : null);
  if (ph == null || !ph.isFinite) return null;
  return PhScale(ph: ph);
}

class PhScale extends StatelessWidget {
  const PhScale({super.key, required this.ph});

  final double ph;

  static const _colors = [
    Color(0xFFE53935), // 0
    Color(0xFFF4511E),
    Color(0xFFFB8C00),
    Color(0xFFFFB300),
    Color(0xFFFDD835),
    Color(0xFFC0CA33),
    Color(0xFF7CB342),
    Color(0xFF43A047), // 7
    Color(0xFF00897B),
    Color(0xFF00ACC1),
    Color(0xFF039BE5),
    Color(0xFF1E88E5),
    Color(0xFF3949AB),
    Color(0xFF5E35B1),
    Color(0xFF8E24AA), // 14
  ];

  @override
  Widget build(BuildContext context) {
    final clamped = ph.clamp(0.0, 14.0);
    final label = ph < 6.995
        ? S.acidic
        : ph > 7.005
            ? S.basic
            : S.neutral;
    final color = _colors[clamped.round()];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'pH ${context.nf.format(ph, digits: 3)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t(label),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final x = c.maxWidth * clamped / 14;
              return SizedBox(
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 8,
                      height: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: const LinearGradient(colors: _colors),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (x - 9).clamp(-2, c.maxWidth - 16),
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: color, width: 4),
                          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final n in [0, 7, 14])
                  Text('$n', style: TextStyle(color: context.colors.onSurfaceVariant)),
              ],
            ),
            Text(
              context.t(S.at25C),
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
