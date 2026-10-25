import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/app_state.dart';
import '../common.dart';
import '../layout/adaptive.dart';
import '../strings.dart';
import '../theme.dart';
import '../tools/registry.dart';

/// Icon, color and name for the tool that produced a history entry.
({IconData icon, Color color, String name}) historyToolStyle(BuildContext context, String toolId) {
  if (toolId == calculatorToolId) {
    return (icon: Icons.calculate_rounded, color: Palette.violet, name: context.t(S.navCalculator));
  }
  final t = toolById(toolId);
  return (
    icon: t?.icon ?? Icons.history_rounded,
    color: t?.color ?? Palette.blue,
    name: t == null ? toolId : context.t(t.title),
  );
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded),
        title: Text(ctx.t(S.clearHistory)),
        content: Text(ctx.t(S.clearHistoryConfirm)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t(S.cancel))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t(S.delete))),
        ],
      ),
    );
    if (ok == true && context.mounted) context.app.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final items = app.history;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(S.navHistory)),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: context.t(S.clearHistory),
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: items.isEmpty
            ? const _Empty()
            : MaxWidth(
                maxWidth: 820,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: items.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          context.t(S.historyCount(items.length, app.historyLimit)),
                          style: TextStyle(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    final e = items[i - 1];
                    final prev = i >= 2 ? items[i - 2] : null;
                    final newDay = prev == null || !_sameDay(prev.time, e.time);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (newDay)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                            child: Text(_dayLabel(context, e.time),
                                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          ),
                        HistoryTile(entry: e),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dayLabel(BuildContext context, DateTime t) {
    final now = DateTime.now();
    if (_sameDay(now, t)) return context.t(S.today);
    if (_sameDay(now.subtract(const Duration(days: 1)), t)) return context.t(S.yesterday);
    return DateFormat.yMMMMd(context.lang).format(t);
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry, this.dismissible = true});

  final HistoryEntry entry;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final style = historyToolStyle(context, entry.toolId);
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => copyText(context, entry.result),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: accentGradient(style.color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(style.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: style.color,
                                  fontSize: 13)),
                        ),
                        Text(DateFormat.Hm(context.lang).format(entry.time),
                            style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(entry.input,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(entry.result,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!dismissible) return card;
    return Dismissible(
      key: ValueKey(entry.id),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(Icons.delete_rounded, color: context.colors.onErrorContainer),
      ),
      onDismissed: (_) {
        final app = context.app;
        app.removeHistory(entry.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(context.t(S.entryDeleted)),
            action: SnackBarAction(
              label: context.t(S.undo),
              onPressed: () => app.restoreHistory(entry),
            ),
          ));
      },
      child: card,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: accentGradient(Palette.violet),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_edu_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(context.t(S.historyEmpty),
                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(context.t(S.historyEmptyHint),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
