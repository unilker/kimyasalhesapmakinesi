/// A bilingual (English / Turkish) text used by data-driven content such as
/// calculator definitions, where generated localizations would be unwieldy.
class Bi {
  const Bi(this.en, this.tr);

  final String en;
  final String tr;

  String of(String languageCode) => languageCode == 'tr' ? tr : en;
}
