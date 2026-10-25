import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'ui/rotate_button.dart';
import 'ui/shell.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

class KimyaApp extends StatefulWidget {
  const KimyaApp({super.key});

  static const supportedLocales = [Locale('tr'), Locale('en')];

  @override
  State<KimyaApp> createState() => _KimyaAppState();
}

class _KimyaAppState extends State<KimyaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) =>
          S.appName.of(Localizations.localeOf(context).languageCode),
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: app.themeMode,
      locale: app.locale,
      supportedLocales: KimyaApp.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      localeResolutionCallback: (device, supported) =>
          device?.languageCode == 'tr' ? const Locale('tr') : const Locale('en'),
      builder: (context, child) {
        // Respect the user's font size, within limits the layouts handle.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.35),
          ),
          child: Stack(
            children: [
              child!,
              RotateButton(navigatorKey: _navigatorKey),
            ],
          ),
        );
      },
      home: const AppShell(),
    );
  }
}
