import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/app_state.dart';
import '../common.dart';
import '../layout/adaptive.dart';
import '../rotate_button.dart';
import '../strings.dart';
import '../theme.dart';

const appVersion = '1.0.0';
const developerName = 'Dr. İlker Ün';
const developerWebsite = 'https://kimyager.net';
const appCopyright = '© 2026 $developerName · kimyager.net';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Scaffold(
      appBar: AppBar(title: Text(context.t(S.settings))),
      body: SafeArea(
        top: false,
        child: MaxWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              _Section(
                icon: Icons.translate_rounded,
                color: Palette.blue,
                title: context.t(S.language),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (v, label) in [
                      (LanguagePref.system, context.t(S.systemDefault)),
                      (LanguagePref.tr, 'Türkçe'),
                      (LanguagePref.en, 'English'),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: app.language == v,
                        onSelected: (_) => app.setLanguage(v),
                      ),
                  ],
                ),
              ),
              _Section(
                icon: Icons.palette_rounded,
                color: Palette.pink,
                title: context.t(S.theme),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (v, icon, label) in [
                      (ThemeMode.system, Icons.brightness_auto_rounded, context.t(S.systemDefault)),
                      (ThemeMode.light, Icons.light_mode_rounded, context.t(S.themeLight)),
                      (ThemeMode.dark, Icons.dark_mode_rounded, context.t(S.themeDark)),
                    ])
                      ChoiceChip(
                        avatar: Icon(icon, size: 18),
                        label: Text(label),
                        selected: app.themeMode == v,
                        onSelected: (_) => app.setThemeMode(v),
                      ),
                  ],
                ),
              ),
              _Section(
                icon: Icons.screen_rotation_rounded,
                color: Palette.indigo,
                title: context.t(S.orientation),
                subtitle: context.t(orientationLockSupported(context)
                    ? S.rotateButtonHint
                    : S.largeScreenOrientation),
                child: !orientationLockSupported(context)
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (v, icon, label) in [
                                (OrientationPref.auto, Icons.screen_rotation_rounded, S.autoRotate),
                                (OrientationPref.portrait, Icons.stay_current_portrait_rounded, S.portrait),
                                (OrientationPref.landscape, Icons.stay_current_landscape_rounded, S.landscape),
                              ])
                                ChoiceChip(
                                  avatar: Icon(icon, size: 18),
                                  label: Text(context.t(label)),
                                  selected: app.orientation == v,
                                  onSelected: (_) => app.setOrientation(v),
                                ),
                            ],
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(context.t(S.showRotateButton),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            value: app.showRotateButton,
                            onChanged: app.setShowRotateButton,
                          ),
                        ],
                      ),
              ),
              _Section(
                icon: Icons.pin_rounded,
                color: Palette.teal,
                title: '${context.t(S.sigDigits)}: ${app.significantDigits}',
                subtitle: '${context.t(S.sigDigitsHint)} · ${context.nf.format(6.02214076e23)} · ${context.nf.format(22.41396954)}',
                child: Slider(
                  value: app.significantDigits.toDouble(),
                  min: 3,
                  max: 12,
                  divisions: 9,
                  label: '${app.significantDigits}',
                  onChanged: (v) => app.setSignificantDigits(v.round()),
                ),
              ),
              _Section(
                icon: Icons.history_rounded,
                color: Palette.orange,
                title: context.t(S.historyLimit),
                subtitle: '${context.t(S.historyLimitHint)} · ${context.t(S.historyCount(app.history.length, app.historyLimit))}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final n in historyLimitOptions)
                          ChoiceChip(
                            label: Text('$n'),
                            selected: app.historyLimit == n,
                            onSelected: (_) => app.setHistoryLimit(n),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: app.history.isEmpty ? null : () => _confirmClear(context),
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: Text(context.t(S.clearHistory)),
                    ),
                  ],
                ),
              ),
              _Section(
                icon: Icons.verified_user_rounded,
                color: Palette.green,
                title: context.t(S.privacy),
                child: Text(context.t(S.privacyText)),
              ),
              _Section(
                icon: Icons.menu_book_rounded,
                color: Palette.brown,
                title: context.t(S.dataSources),
                child: Text(context.t(S.dataSourcesText)),
              ),
              _Section(
                icon: Icons.info_rounded,
                color: Palette.violet,
                title: context.t(S.about),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${context.t(S.appName)} · ${context.t(S.version)} $appVersion',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Material(
                      color: context.colors.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: const Icon(Icons.person_rounded),
                        title: Text(context.t(S.developer),
                            style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(developerName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: context.colors.onSurface)),
                            Text('kimyager.net',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: context.colors.primary)),
                          ],
                        ),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () => launchUrl(
                          Uri.parse(developerWebsite),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(appCopyright),
                    const SizedBox(height: 6),
                    Text(context.t(S.licenseText),
                        style: TextStyle(color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => showLicensePage(
                        context: context,
                        applicationName: context.t(S.appName),
                        applicationVersion: appVersion,
                        applicationLegalese: appCopyright,
                      ),
                      icon: const Icon(Icons.article_rounded),
                      label: Text(context.t(S.licenses)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: accentGradient(color),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: TextStyle(color: context.colors.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
