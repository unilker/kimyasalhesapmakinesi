import 'package:flutter/material.dart';

import 'calculator/calculator_screen.dart';
import 'common.dart';
import 'history/history_screen.dart';
import 'home/home_screen.dart';
import 'layout/adaptive.dart';
import 'periodic/periodic_table_screen.dart';
import 'settings/settings_screen.dart';
import 'strings.dart';
import 'theme.dart';
import 'tools/registry.dart';

/// Top-level navigation: a bottom bar on phones, a navigation rail on
/// tablets, unfolded foldables and landscape screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ws = windowSizeForWidth(size.width);
    // Landscape phones are wide but short: a rail saves vertical space.
    final useRail = ws != WindowSize.compact || (size.width > size.height && size.width >= 560);

    final destinations = [
      (Icons.grid_view_rounded, Icons.grid_view_outlined, S.navTools),
      (Icons.calculate_rounded, Icons.calculate_outlined, S.navCalculatorShort),
      (Icons.apps_rounded, Icons.apps_outlined, S.navPeriodicShort),
      (Icons.history_rounded, Icons.history_outlined, S.navHistory),
    ];

    final pages = [
      _HomeTab(onShowHistory: () => setState(() => _index = 3)),
      const CalculatorScreen(),
      const PeriodicTableScreen(),
      const HistoryScreen(),
    ];

    final body = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < pages.length; i++)
          TickerMode(
            enabled: i == _index,
            child: ExcludeFocus(excluding: i != _index, child: pages[i]),
          ),
      ],
    );

    if (!useRail) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.$2), selectedIcon: Icon(d.$1), label: context.t(d.$3)),
          ],
        ),
      );
    }

    final extended = size.width >= 1200;
    // On short (landscape) screens the rail drops labels and the logo so
    // all destinations fit.
    final short = size.height < 480;
    return Scaffold(
      // Each page's own Scaffold avoids the keyboard; resizing here would
      // squeeze the rail when the keyboard opens in landscape.
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: NavigationRail(
              extended: extended,
              minExtendedWidth: 220,
              selectedIndex: _index,
              labelType: extended || short
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              onDestinationSelected: (i) => setState(() => _index = i),
              leading: short ? null : Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.asset('assets/logo.png', width: 48, height: 48, filterQuality: FilterQuality.medium),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: short ? 4 : 16),
                    child: IconButton(
                      tooltip: context.t(S.settings),
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.$2),
                    selectedIcon: Icon(d.$1),
                    label: Text(context.t(d.$3)),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Tools tab. Uses a list–detail layout on large screens and across the
/// hinge of dual-screen / book-posture foldables; otherwise tools open as
/// pages in a nested navigator so the navigation bar stays visible.
class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.onShowHistory});

  final VoidCallback onShowHistory;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  ToolInfo? _selected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final hinge = hingeOf(context);
      final listDetail = c.maxWidth >= 900 || (hinge != null && hinge.axis == Axis.vertical);
      if (listDetail) {
        final tool = _selected;
        return TwoPane(
          minSplitWidth: 900,
          firstFraction: 0.42,
          first: HomeScreen(
            selectedToolId: tool?.id,
            onOpenTool: (t) => setState(() => _selected = t),
            onShowHistory: widget.onShowHistory,
          ),
          second: tool == null
              ? const _PickToolPlaceholder()
              : KeyedSubtree(key: ValueKey(tool.id), child: tool.builder(tool)),
          compact: _stack(),
        );
      }
      return _stack();
    });
  }

  Widget _stack() {
    final tool = _selected;
    return NavigatorPopHandler(
      onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: _navigatorKey,
        pages: [
          MaterialPage<void>(
            key: const ValueKey('home'),
            child: HomeScreen(
              onOpenTool: (t) => setState(() => _selected = t),
              onShowHistory: widget.onShowHistory,
            ),
          ),
          if (tool != null)
            MaterialPage<void>(key: ValueKey(tool.id), child: tool.builder(tool)),
        ],
        onDidRemovePage: (page) {
          if (page.key != const ValueKey('home')) setState(() => _selected = null);
        },
      ),
    );
  }
}

class _PickToolPlaceholder extends StatelessWidget {
  const _PickToolPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(gradient: accentGradient(Palette.teal), shape: BoxShape.circle),
                child: const Icon(Icons.science_rounded, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(context.t(S.pickTool),
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(context.t(S.pickToolHint),
                  textAlign: TextAlign.center, style: TextStyle(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
