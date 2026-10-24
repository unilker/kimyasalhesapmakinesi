import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/bi.dart';
import '../core/format.dart';
import '../core/units.dart';
import '../state/app_state.dart';
import 'layout/adaptive.dart';
import 'strings.dart';
import 'theme.dart';

extension AppContext on BuildContext {
  /// `tr` or `en`.
  String get lang =>
      Localizations.localeOf(this).languageCode == 'tr' ? 'tr' : 'en';

  String t(Bi text) => text.of(lang);

  AppState get app => AppScope.of(this);

  NumberFormatter get nf => NumberFormatter(
        significantDigits: AppScope.of(this).significantDigits,
        decimalSeparator: lang == 'tr' ? ',' : '.',
      );

  /// Locale aware percent: `%12,5` in Turkish, `12.5%` in English.
  String percent(double v, {int digits = 4}) {
    final n = nf.format(v, digits: digits);
    return lang == 'tr' ? '%$n' : '$n%';
  }

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

void copyText(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(context.t(S.copied)),
      duration: const Duration(milliseconds: 1400),
    ));
}

void showInfo(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      duration: const Duration(milliseconds: 1400),
    ));
}

/// Standard scaffold for a tool. On wide screens (or across a vertical
/// hinge) the [inputs] and [results] are shown side by side.
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.inputs,
    this.results = const [],
    this.actions,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<Widget> inputs;
  final List<Widget> results;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    Widget list(List<Widget> children, {bool top = true}) => ListView(
          padding: EdgeInsets.fromLTRB(16, top ? 8 : 0, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            for (final c in children) ...[c, const SizedBox(height: 14)],
          ],
        );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: accentGradient(color),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: results.isEmpty
            ? MaxWidth(child: list(inputs))
            : TwoPane(
                minSplitWidth: 760,
                first: list(inputs),
                second: list(results),
                compact: MaxWidth(child: list([...inputs, ...results])),
              ),
      ),
    );
  }
}

/// Colorful banner that shows an equation.
class FormulaBanner extends StatelessWidget {
  const FormulaBanner({
    super.key,
    required this.color,
    required this.formula,
    this.title,
    this.note,
  });

  final Color color;
  final String formula;
  final String? title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: accentGradient(color),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: context.text.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          if (title != null) const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formula,
              style: context.text.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note!,
              style: context.text.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Big, friendly result display with a copy button.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    this.copyValue,
    this.trailing,
    this.children = const [],
  });

  final Color color;
  final String label;
  final String value;

  /// Text copied to the clipboard; defaults to [value].
  final String? copyValue;

  /// Usually a unit selector.
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: 0.12), scheme.surface),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: context.text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.t(S.copy),
                  onPressed: () => copyText(context, copyValue ?? value),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: context.text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                  const SizedBox(width: 8),
                ],
              ],
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            ?trailing,
          ],
        ),
      );
}

class UnitDropdown extends StatelessWidget {
  const UnitDropdown({
    super.key,
    required this.quantity,
    required this.unit,
    required this.onChanged,
  });

  final Quantity quantity;
  final Unit unit;
  final ValueChanged<Unit> onChanged;

  @override
  Widget build(BuildContext context) {
    final list = units[quantity]!;
    if (list.length == 1) {
      return list.first.symbol.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(list.first.symbol,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: unit.id,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: context.colors.onSecondaryContainer,
          ),
          items: [
            for (final u in list)
              DropdownMenuItem(value: u.id, child: Text(u.symbol)),
          ],
          onChanged: (id) {
            if (id != null) onChanged(unitById(quantity, id));
          },
        ),
      ),
    );
  }
}

/// Text field for numbers; accepts `,` or `.` and simple expressions.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            decoration: InputDecoration(
              labelText: label,
              helperText: helper,
              errorText: errorText,
              helperMaxLines: 2,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Padding(padding: const EdgeInsets.only(top: 10), child: trailing!),
        ],
      ],
    );
  }
}

/// A row of small buttons that insert characters into a text field –
/// handy for symbols missing from mobile keyboards (·, →, ^ …).
class InsertBar extends StatelessWidget {
  const InsertBar({super.key, required this.controller, required this.items, this.onChanged});

  final TextEditingController controller;
  final List<String> items;
  final VoidCallback? onChanged;

  void _insert(String s) {
    final sel = controller.selection;
    final text = controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, s),
      selection: TextSelection.collapsed(offset: start + s.length),
    );
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in items)
          ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            visualDensity: VisualDensity.compact,
            onPressed: () => _insert(s),
          ),
      ],
    );
  }
}

/// A key/value row used inside result cards.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap ?? () => copyText(context, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                label,
                style: TextStyle(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
