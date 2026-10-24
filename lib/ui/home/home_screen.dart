import 'package:flutter/material.dart';

import '../../core/chem/element.dart';
import '../common.dart';
import '../history/history_screen.dart';
import '../periodic/periodic_table_screen.dart';
import '../settings/settings_screen.dart';
import '../strings.dart';
import '../theme.dart';
import '../tools/registry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTool,
    required this.onShowHistory,
    this.selectedToolId,
  });

  final ValueChanged<ToolInfo> onOpenTool;
  final VoidCallback onShowHistory;

  /// Highlighted tool in list–detail layouts.
  final String? selectedToolId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int get _dayIndex {
    final now = DateTime.now();
    return now.difference(DateTime(now.year)).inDays;
  }

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    if (h < 12) return context.t(S.goodMorning);
    if (h < 18) return context.t(S.goodAfternoon);
    return context.t(S.goodEvening);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final query = _search.text;
    final filtered = tools.where((t) => t.matches(query, lang)).toList();
    final recent = context.app.history.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_greeting(context)} 👋',
                style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            Text(context.t(S.homeSubtitle),
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.t(S.settings),
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.t(S.searchTools),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
              ),
            ),
            if (query.isEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _highlights(context)),
              ),
              if (recent.isNotEmpty) ...[
                _sectionHeader(
                  context,
                  context.t(S.recent),
                  trailing: TextButton(onPressed: widget.onShowHistory, child: Text(context.t(S.seeAll))),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: recent.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => HistoryTile(entry: recent[i], dismissible: false),
                  ),
                ),
              ],
              for (final cat in ToolCategory.values) ...[
                _sectionHeader(context, context.t(categoryTitle(cat))),
                _grid(tools.where((t) => t.category == cat).toList()),
              ],
            ] else ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(context.t(S.noToolsFound))),
                  ),
                )
              else
                _grid(filtered),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, {Widget? trailing}) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
        sliver: SliverToBoxAdapter(child: SectionTitle(title, trailing: trailing)),
      );

  Widget _grid(List<ToolInfo> list) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 132,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => ToolCard(
              tool: list[i],
              selected: list[i].id == widget.selectedToolId,
              onTap: () => widget.onOpenTool(list[i]),
            ),
            childCount: list.length,
          ),
        ),
      );

  Widget _highlights(BuildContext context) {
    final element = PeriodicTable.elements[_dayIndex % PeriodicTable.elements.length];
    final fact = S.facts[_dayIndex % S.facts.length];
    final elementCard = _ElementOfDay(element: element);
    final factCard = _FactCard(text: context.t(fact));
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 560) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: elementCard),
              const SizedBox(width: 12),
              Expanded(child: factCard),
            ],
          ),
        );
      }
      return Column(children: [elementCard, const SizedBox(height: 12), factCard]);
    });
  }
}

class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.tool, required this.onTap, this.selected = false});

  final ToolInfo tool;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: accentGradient(tool.color),
            border: selected ? Border.all(color: context.colors.onSurface, width: 3) : null,
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -22,
                  child: Icon(tool.icon, size: 96, color: Colors.white.withValues(alpha: 0.16)),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(tool.icon, color: Colors.white, size: 22),
                      ),
                      const Spacer(),
                      Text(
                        tool.title.of(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tool.subtitle.of(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ElementOfDay extends StatelessWidget {
  const _ElementOfDay({required this.element});

  final ChemElement element;

  @override
  Widget build(BuildContext context) {
    final e = element;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showElementDetail(context, e),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(width: 72, height: 72, child: ElementTile(element: e, size: 72)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t(S.elementOfDay),
                        style: TextStyle(
                            color: context.colors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(e.name(context.lang),
                        style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    Text(
                      '${context.t(S.categoryName(e.category))} · ${formatAtomicMass(context, e)} g/mol',
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: accentGradient(Palette.amber),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t(S.didYouKnow),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: Color(0xFF3E2700), fontSize: 15)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        color: Color(0xFF3E2700), fontWeight: FontWeight.w600, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
