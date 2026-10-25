import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/math/expression.dart';

/// One saved calculation. Everything is stored only on the device.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.toolId,
    required this.input,
    required this.result,
    required this.time,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        toolId: j['tool'] as String,
        input: j['in'] as String,
        result: j['out'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(j['t'] as int),
      );

  final String id;
  final String toolId;

  /// Human readable summary of the inputs.
  final String input;

  /// Human readable result (already formatted).
  final String result;
  final DateTime time;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tool': toolId,
        'in': input,
        'out': result,
        't': time.millisecondsSinceEpoch,
      };
}

enum LanguagePref { system, tr, en }

/// Screen orientation chosen by the user. Only phones honour a lock; on
/// tablets and unfolded foldables the system manages orientation.
enum OrientationPref { auto, portrait, landscape }

List<DeviceOrientation> orientationsFor(OrientationPref p) => switch (p) {
      OrientationPref.auto => DeviceOrientation.values,
      OrientationPref.portrait => const [DeviceOrientation.portraitUp],
      OrientationPref.landscape => const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
    };

const historyLimitOptions = [25, 50, 100, 250, 500];

/// How the tools are laid out on the home screen.
enum ToolLayout { grid, list }

/// App-wide settings and calculation history, persisted locally with
/// [SharedPreferences]. Nothing ever leaves the device.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  static Future<AppState> create() async =>
      AppState(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kLang = 'lang';
  static const _kTheme = 'theme';
  static const _kDigits = 'digits';
  static const _kLimit = 'historyLimit';
  static const _kAngle = 'angle';
  static const _kHistory = 'history';
  static const _kOrientation = 'orientation';
  static const _kRotateButton = 'rotateButton';
  static const _kRotateY = 'rotateButtonY';
  static const _kRotateLeft = 'rotateButtonLeft';
  static const _kToolLayout = 'toolLayout';

  LanguagePref _language = LanguagePref.system;
  ThemeMode _themeMode = ThemeMode.system;
  int _significantDigits = 6;
  int _historyLimit = 100;
  AngleMode _angleMode = AngleMode.degrees;
  List<HistoryEntry> _history = [];
  OrientationPref _orientation = OrientationPref.auto;
  bool _showRotateButton = true;
  double _rotateButtonY = 0.2;
  bool _rotateButtonLeft = false;
  ToolLayout _toolLayout = ToolLayout.list;

  LanguagePref get language => _language;
  ThemeMode get themeMode => _themeMode;
  int get significantDigits => _significantDigits;
  int get historyLimit => _historyLimit;
  AngleMode get angleMode => _angleMode;
  OrientationPref get orientation => _orientation;
  bool get showRotateButton => _showRotateButton;

  /// Vertical position of the rotate button as a fraction of the screen.
  double get rotateButtonY => _rotateButtonY;
  bool get rotateButtonLeft => _rotateButtonLeft;
  ToolLayout get toolLayout => _toolLayout;

  /// Newest first.
  List<HistoryEntry> get history => List.unmodifiable(_history);

  Locale? get locale => switch (_language) {
        LanguagePref.system => null,
        LanguagePref.tr => const Locale('tr'),
        LanguagePref.en => const Locale('en'),
      };

  void _load() {
    _language = LanguagePref.values.firstWhere(
      (l) => l.name == _prefs.getString(_kLang),
      orElse: () => LanguagePref.system,
    );
    _themeMode = ThemeMode.values.firstWhere(
      (t) => t.name == _prefs.getString(_kTheme),
      orElse: () => ThemeMode.system,
    );
    _significantDigits = (_prefs.getInt(_kDigits) ?? 6).clamp(3, 12);
    _historyLimit = _prefs.getInt(_kLimit) ?? 100;
    if (!historyLimitOptions.contains(_historyLimit)) _historyLimit = 100;
    _angleMode = _prefs.getString(_kAngle) == AngleMode.radians.name
        ? AngleMode.radians
        : AngleMode.degrees;
    _orientation = OrientationPref.values.firstWhere(
      (o) => o.name == _prefs.getString(_kOrientation),
      orElse: () => OrientationPref.auto,
    );
    _showRotateButton = _prefs.getBool(_kRotateButton) ?? true;
    _rotateButtonY = (_prefs.getDouble(_kRotateY) ?? 0.2).clamp(0.0, 1.0);
    _rotateButtonLeft = _prefs.getBool(_kRotateLeft) ?? false;
    _toolLayout = ToolLayout.values.firstWhere(
      (l) => l.name == _prefs.getString(_kToolLayout),
      orElse: () => ToolLayout.list,
    );
    SystemChrome.setPreferredOrientations(orientationsFor(_orientation));
    final raw = _prefs.getString(_kHistory);
    if (raw != null) {
      try {
        _history = [
          for (final e in jsonDecode(raw) as List)
            HistoryEntry.fromJson(e as Map<String, dynamic>),
        ];
      } catch (_) {
        _history = [];
      }
    }
  }

  void setLanguage(LanguagePref v) {
    _language = v;
    _prefs.setString(_kLang, v.name);
    notifyListeners();
  }

  void setThemeMode(ThemeMode v) {
    _themeMode = v;
    _prefs.setString(_kTheme, v.name);
    notifyListeners();
  }

  void setSignificantDigits(int v) {
    _significantDigits = v.clamp(3, 12);
    _prefs.setInt(_kDigits, _significantDigits);
    notifyListeners();
  }

  void setHistoryLimit(int v) {
    _historyLimit = v;
    _prefs.setInt(_kLimit, v);
    _trim();
    _saveHistory();
    notifyListeners();
  }

  void setAngleMode(AngleMode v) {
    _angleMode = v;
    _prefs.setString(_kAngle, v.name);
    notifyListeners();
  }

  void setOrientation(OrientationPref v) {
    _orientation = v;
    _prefs.setString(_kOrientation, v.name);
    SystemChrome.setPreferredOrientations(orientationsFor(v));
    notifyListeners();
  }

  void setShowRotateButton(bool v) {
    _showRotateButton = v;
    _prefs.setBool(_kRotateButton, v);
    notifyListeners();
  }

  void setToolLayout(ToolLayout v) {
    _toolLayout = v;
    _prefs.setString(_kToolLayout, v.name);
    notifyListeners();
  }

  void setRotateButtonPosition({required double y, required bool left}) {
    _rotateButtonY = y.clamp(0.0, 1.0);
    _rotateButtonLeft = left;
    _prefs.setDouble(_kRotateY, _rotateButtonY);
    _prefs.setBool(_kRotateLeft, left);
    notifyListeners();
  }

  void addHistory({
    required String toolId,
    required String input,
    required String result,
  }) {
    // Skip exact repeats of the latest entry (e.g. pressing "=" twice).
    if (_history.isNotEmpty &&
        _history.first.toolId == toolId &&
        _history.first.input == input &&
        _history.first.result == result) {
      return;
    }
    final now = DateTime.now();
    _history.insert(
      0,
      HistoryEntry(
        id: '${now.microsecondsSinceEpoch}',
        toolId: toolId,
        input: input,
        result: result,
        time: now,
      ),
    );
    _trim();
    _saveHistory();
    notifyListeners();
  }

  void removeHistory(String id) {
    _history.removeWhere((e) => e.id == id);
    _saveHistory();
    notifyListeners();
  }

  void restoreHistory(HistoryEntry entry) {
    _history.add(entry);
    _history.sort((a, b) => b.time.compareTo(a.time));
    _trim();
    _saveHistory();
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    _saveHistory();
    notifyListeners();
  }

  void _trim() {
    if (_history.length > _historyLimit) {
      _history = _history.sublist(0, _historyLimit);
    }
  }

  void _saveHistory() {
    _prefs.setString(
      _kHistory,
      jsonEncode([for (final e in _history) e.toJson()]),
    );
  }
}

/// Makes [AppState] available to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Access without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
