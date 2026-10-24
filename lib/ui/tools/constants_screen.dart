import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../common.dart';
import '../strings.dart';
import '../theme.dart';
import 'registry.dart';

class ConstantsScreen extends StatelessWidget {
  const ConstantsScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: [
        Text(context.t(S.tapToCopy),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        for (final c in physicalConstants) ConstantTile(constant: c),
      ],
    );
  }
}

class ConstantTile extends StatelessWidget {
  const ConstantTile({super.key, required this.constant, this.onTap});

  final PhysicalConstant constant;

  /// Defaults to copying the value.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = constant;
    final nf = context.nf;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => copyText(context, nf.plain(c.value, digits: 12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: accentGradient(Palette.brown),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      c.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name(context.lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${nf.format(c.value, digits: 12)} ${c.unit}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (c.exact)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.t(S.exact),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onTertiaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
