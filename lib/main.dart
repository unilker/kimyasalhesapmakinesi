import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final notice = await rootBundle.loadString('NOTICE');
    final license = await rootBundle.loadString('LICENSE');
    yield LicenseEntryWithLineBreaks(['Kimya Hesap'], '$notice\n\n$license');
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], ofl);
    final noto = await rootBundle.loadString('assets/fonts/OFL-Noto.txt');
    yield LicenseEntryWithLineBreaks(['Noto Sans', 'Noto Sans Math'], noto);
  });
  final state = await AppState.create();
  runApp(AppScope(state: state, child: const KimyaApp()));
}
