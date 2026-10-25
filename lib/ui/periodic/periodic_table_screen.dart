import 'package:flutter/material.dart';

import '../../core/chem/element.dart';
import '../common.dart';
import '../layout/adaptive.dart';
import '../strings.dart';
import '../theme.dart';
import '../tools/molar_mass_screen.dart';
import '../tools/registry.dart';

class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> {
  bool _listMode = false;
  ElementCategory? _category;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(ChemElement e) {
    if (_category != null && e.category != _category) return false;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.symbol.toLowerCase() == q ||
        '${e.number}' == q ||
        e.nameEn.toLowerCase().contains(q) ||
        e.nameTr.toLowerCase().contains(q) ||
        (q.length > 1 && e.symbol.toLowerCase().startsWith(q));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(S.navPeriodic)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.grid_view_rounded),
                  tooltip: context.t(S.table),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.view_list_rounded),
                  tooltip: context.t(S.list),
                ),
              ],
              selected: {_listMode},
              onSelectionChanged: (s) => setState(() => _listMode = s.first),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, c) {
            // Little room (e.g. keyboard open in landscape): drop the category
            // chips and show search results as a list.
            final short = c.maxHeight < 260;
            final list = _listMode || (short && _search.text.isNotEmpty);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.t(S.searchElement),
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                  ),
                ),
                if (!short)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Text(context.t(S.allCategories)),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                        ),
                        for (final c in ElementCategory.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              avatar: CircleAvatar(
                                backgroundColor: categoryColor(
                                  c,
                                  Theme.of(context).brightness,
                                ),
                              ),
                              label: Text(context.t(S.categoryName(c))),
                              selected: _category == c,
                              onSelected: (sel) =>
                                  setState(() => _category = sel ? c : null),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (!short) const SizedBox(height: 8),
                Expanded(child: list ? _list() : _table()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list() {
    final items = PeriodicTable.elements.where(_matches).toList();
    final b = Theme.of(context).brightness;
    return MaxWidth(
      maxWidth: 760,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final e = items[i];
          return ListTile(
            onTap: () => showElementDetail(context, e),
            leading: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: categoryColor(e.category, b),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                e.symbol,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: onCategoryColor(b),
                ),
              ),
            ),
            title: Text(
              e.name(context.lang),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${e.number} · ${formatAtomicMass(context, e)} · ${context.t(S.categoryName(e.category))}',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          );
        },
      ),
    );
  }

  Widget _table() {
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 18;
        const gap = 3.0;
        // Fit the table to the width when possible, otherwise scroll.
        final fit = (c.maxWidth - 24 - gap * (cols - 1)) / cols;
        final byHeight = (c.maxHeight - 32 - gap * 10) / 10.4;
        // Phones scroll sideways, so let cells grow with the height there.
        final cell =
            (fit > byHeight.clamp(0.0, 64.0) ? fit : byHeight.clamp(40.0, 64.0))
                .clamp(40.0, 92.0);
        final width = cell * cols + gap * (cols - 1);
        final height = cell * 9.4 + gap * 9;
        final grid = SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              for (final e in PeriodicTable.elements) _positioned(e, cell, gap),
              _placeholder(6, '57–71', cell, gap),
              _placeholder(7, '89–103', cell, gap),
            ],
          ),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: grid,
            ),
          ),
        );
      },
    );
  }

  double _top(int row, double cell, double gap) =>
      (row - 1) * (cell + gap) + (row >= 8 ? cell * 0.4 : 0);

  Widget _placeholder(int period, String text, double cell, double gap) {
    final b = Theme.of(context).brightness;
    final cat = period == 6
        ? ElementCategory.lanthanide
        : ElementCategory.actinide;
    return Positioned(
      left: 2 * (cell + gap),
      top: _top(period, cell, gap),
      width: cell,
      height: cell,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: categoryColor(cat, b).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(cell * 0.16),
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: onCategoryColor(b),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _positioned(ChemElement e, double cell, double gap) {
    final pos = e.tablePosition;
    final row = pos.row >= 9 ? pos.row - 1 : pos.row; // rows 8 and 9 in view
    return Positioned(
      left: (pos.column - 1) * (cell + gap),
      top: _top(row, cell, gap),
      width: cell,
      height: cell,
      child: ElementTile(
        element: e,
        size: cell,
        dimmed: !_matches(e),
        onTap: () => showElementDetail(context, e),
      ),
    );
  }
}

String formatAtomicMass(BuildContext context, ChemElement e) {
  final v = context.nf.format(e.atomicMass, digits: e.massIsMassNumber ? 3 : 7);
  return e.massIsMassNumber ? '[$v]' : v;
}

class ElementTile extends StatelessWidget {
  const ElementTile({
    super.key,
    required this.element,
    required this.size,
    this.dimmed = false,
    this.onTap,
  });

  final ChemElement element;
  final double size;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final e = element;
    final fg = onCategoryColor(b);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.18 : 1,
      child: Material(
        color: categoryColor(e.category, b),
        borderRadius: BorderRadius.circular(size * 0.16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            label: '${e.number} ${e.name(context.lang)}',
            excludeSemantics: true,
            button: true,
            child: Padding(
              padding: EdgeInsets.all(size * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${e.number}',
                    style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.w700,
                      color: fg,
                      height: 1,
                    ),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        e.symbol,
                        style: TextStyle(
                          fontSize: size * 0.42,
                          fontWeight: FontWeight.w900,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
                  if (size >= 56)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.nf.format(
                          e.atomicMass,
                          digits: e.massIsMassNumber ? 3 : 5,
                        ),
                        style: TextStyle(
                          fontSize: size * 0.16,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
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

void showElementDetail(BuildContext context, ChemElement e) {
  final wide = windowSizeOf(context) != WindowSize.compact;
  final content = _ElementDetail(element: e);
  if (wide) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: content,
        ),
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
        ),
        child: content,
      ),
    );
  }
}

class _ElementDetail extends StatelessWidget {
  const _ElementDetail({required this.element});

  final ChemElement element;

  @override
  Widget build(BuildContext context) {
    final e = element;
    final b = Theme.of(context).brightness;
    final bg = categoryColor(e.category, b);
    final fg = onCategoryColor(b);
    final lang = context.lang;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.number}',
                    style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        e.symbol,
                        style: TextStyle(
                          color: fg,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name(lang),
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (e.nameEn != e.nameTr)
                    Text(
                      lang == 'tr' ? e.nameEn : e.nameTr,
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    context.t(S.categoryName(e.category)),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        InfoRow(context.t(S.atomicNumber), '${e.number}'),
        InfoRow(
          context.t(S.atomicMass),
          '${formatAtomicMass(context, e)} g/mol',
        ),
        InfoRow(context.t(S.electronConfig), e.electronConfiguration),
        InfoRow(
          context.t(S.electronegativity),
          e.electronegativity == null
              ? '—'
              : context.nf.format(e.electronegativity!),
        ),
        InfoRow(context.t(S.group), e.group == null ? '—' : '${e.group}'),
        InfoRow(context.t(S.period), '${e.period}'),
        InfoRow(context.t(S.block), e.block.name),
        if (e.valenceElectrons != null)
          InfoRow(context.t(S.valence), '${e.valenceElectrons}'),
        InfoRow(context.t(S.state), context.t(S.stateName(e.state))),
        if (e.massIsMassNumber)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.t(S.radioactiveNote),
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: () =>
                  copyText(context, context.nf.plain(e.atomicMass, digits: 10)),
              icon: const Icon(Icons.copy_rounded),
              label: Text('${context.t(S.copy)}: ${context.t(S.atomicMass)}'),
            ),
            FilledButton.icon(
              onPressed: () {
                final tool = toolById('molarMass')!;
                final sheet = Navigator.of(context);
                final root = Navigator.of(context, rootNavigator: true);
                sheet.pop();
                root.push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        MolarMassScreen(tool: tool, initialFormula: e.symbol),
                  ),
                );
              },
              icon: const Icon(Icons.scale_rounded),
              label: Text(context.t(S.useInMolarMass)),
            ),
          ],
        ),
      ],
    );
  }
}
