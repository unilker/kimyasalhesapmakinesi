import '../core/bi.dart';
import '../core/chem/element.dart';
import '../core/units.dart';

/// User interface texts in English and Turkish.
class S {
  S._();

  static const appName = Bi('Chem Calc', 'Kimya Hesap');

  // Navigation
  static const navTools = Bi('Tools', 'Araçlar');
  static const navCalculator = Bi('Calculator', 'Hesap Makinesi');
  static const navCalculatorShort = Bi('Calculator', 'Hesap');
  static const navPeriodic = Bi('Periodic Table', 'Periyodik Tablo');
  static const navPeriodicShort = Bi('Elements', 'Tablo');
  static const navHistory = Bi('History', 'Geçmiş');
  static const settings = Bi('Settings', 'Ayarlar');

  // Common actions
  static const calculate = Bi('Calculate', 'Hesapla');
  static const copy = Bi('Copy', 'Kopyala');
  static const copied = Bi('Copied to clipboard', 'Panoya kopyalandı');
  static const result = Bi('Result', 'Sonuç');
  static const clear = Bi('Clear', 'Temizle');
  static const examples = Bi('Examples', 'Örnekler');
  static const formula = Bi('Formula', 'Formül');
  static const molarMass = Bi('Molar mass', 'Mol kütlesi');
  static const saveToHistory = Bi('Save to history', 'Geçmişe kaydet');
  static const savedToHistory = Bi('Saved to history', 'Geçmişe kaydedildi');
  static const cancel = Bi('Cancel', 'Vazgeç');
  static const delete = Bi('Delete', 'Sil');
  static const undo = Bi('Undo', 'Geri al');
  static const close = Bi('Close', 'Kapat');
  static const also = Bi('Also', 'Ayrıca');
  static const value = Bi('Value', 'Değer');
  static const unit = Bi('Unit', 'Birim');

  // Home
  static const goodMorning = Bi('Good morning', 'Günaydın');
  static const goodAfternoon = Bi('Good afternoon', 'İyi günler');
  static const goodEvening = Bi('Good evening', 'İyi akşamlar');
  static const homeSubtitle =
      Bi('What shall we calculate today?', 'Bugün ne hesaplıyoruz?');
  static const searchTools = Bi('Search tools…', 'Araç ara…');
  static const noToolsFound = Bi('No matching tool', 'Eşleşen araç yok');
  static const elementOfDay = Bi('Element of the day', 'Günün elementi');
  static const didYouKnow = Bi('Did you know?', 'Biliyor muydunuz?');
  static const recent = Bi('Recent calculations', 'Son hesaplamalar');
  static const seeAll = Bi('See all', 'Tümü');
  static const pickTool = Bi('Pick a tool to get started', 'Başlamak için bir araç seçin');
  static const pickToolHint = Bi(
    'Everything works offline, right on your device.',
    'Her şey çevrimdışı, doğrudan cihazınızda çalışır.',
  );

  // Calculator
  static const constants = Bi('Constants', 'Sabitler');
  static const calcError = Bi('Error', 'Hata');
  static const errSyntax = Bi('Check the expression', 'İfadeyi kontrol edin');
  static const errDivZero = Bi('Division by zero', 'Sıfıra bölme');
  static const errDomain = Bi('Outside the domain', 'Tanım kümesi dışında');
  static const errOverflow = Bi('Number too large', 'Sayı çok büyük');
  static const errUnknownName = Bi('Unknown name', 'Bilinmeyen ad');
  static const sessionHistory = Bi('This session', 'Bu oturum');
  static const tapToReuse = Bi('Tap a line to reuse it', 'Tekrar kullanmak için satıra dokunun');

  // Periodic table
  static const table = Bi('Table', 'Tablo');
  static const list = Bi('List', 'Liste');
  static const searchElement =
      Bi('Name, symbol or number', 'Ad, sembol veya numara');
  static const atomicNumber = Bi('Atomic number', 'Atom numarası');
  static const atomicMass = Bi('Atomic mass', 'Atom kütlesi');
  static const category = Bi('Category', 'Sınıf');
  static const electronConfig = Bi('Electron configuration', 'Elektron dizilimi');
  static const electronegativity =
      Bi('Electronegativity (Pauling)', 'Elektronegatiflik (Pauling)');
  static const group = Bi('Group', 'Grup');
  static const period = Bi('Period', 'Periyot');
  static const block = Bi('Block', 'Blok');
  static const state = Bi('State (25 °C)', 'Fiziksel hal (25 °C)');
  static const valence = Bi('Valence electrons', 'Değerlik elektronu');
  static const radioactiveNote = Bi(
    'No stable isotopes – mass number of the longest-lived isotope.',
    'Kararlı izotopu yok – en uzun ömürlü izotopun kütle numarası.',
  );
  static const useInMolarMass = Bi('Use in molar mass', 'Mol kütlesinde kullan');
  static const allCategories = Bi('All', 'Tümü');

  // History
  static const historyEmpty = Bi('No calculations yet', 'Henüz hesaplama yok');
  static const historyEmptyHint = Bi(
    'Your results will appear here. History is stored only on this device.',
    'Sonuçlarınız burada görünecek. Geçmiş yalnızca bu cihazda saklanır.',
  );
  static const clearHistory = Bi('Clear history', 'Geçmişi temizle');
  static const clearHistoryConfirm = Bi(
    'All saved calculations will be deleted. This cannot be undone.',
    'Kaydedilen tüm hesaplamalar silinecek. Bu işlem geri alınamaz.',
  );
  static const entryDeleted = Bi('Entry deleted', 'Kayıt silindi');
  static const today = Bi('Today', 'Bugün');
  static const yesterday = Bi('Yesterday', 'Dün');
  static Bi historyCount(int n, int limit) =>
      Bi('$n of $limit saved', '$n / $limit kayıt');

  // Settings
  static const language = Bi('Language', 'Dil');
  static const systemDefault = Bi('System default', 'Sistem varsayılanı');
  static const theme = Bi('Theme', 'Tema');
  static const themeLight = Bi('Light', 'Açık');
  static const themeDark = Bi('Dark', 'Koyu');
  static const sigDigits = Bi('Significant digits', 'Anlamlı basamak');
  static const sigDigitsHint =
      Bi('Used when displaying results', 'Sonuçlar gösterilirken kullanılır');
  static const historyLimit = Bi('History size', 'Geçmiş kapasitesi');
  static const historyLimitHint = Bi(
    'Oldest entries are removed automatically',
    'En eski kayıtlar otomatik olarak silinir',
  );
  static const about = Bi('About', 'Hakkında');
  static const privacy = Bi('Privacy', 'Gizlilik');
  static const privacyText = Bi(
    'Chem Calc works completely offline. There are no accounts, no ads and no tracking, and no data is collected. Your history is stored only on this device and is deleted when you clear it or uninstall the app.',
    'Kimya Hesap tamamen çevrimdışı çalışır. Üyelik, reklam veya takip yoktur ve hiçbir veri toplanmaz. Geçmişiniz yalnızca bu cihazda saklanır; temizlediğinizde veya uygulamayı kaldırdığınızda silinir.',
  );
  static const licenses = Bi('Open-source licenses', 'Açık kaynak lisansları');
  static const dataSources = Bi('Data sources', 'Veri kaynakları');
  static const dataSourcesText = Bi(
    'Atomic masses: IUPAC standard atomic weights. Constants: CODATA 2018 / SI 2019.',
    'Atom kütleleri: IUPAC standart atom ağırlıkları. Sabitler: CODATA 2018 / SI 2019.',
  );
  static const version = Bi('Version', 'Sürüm');

  // Molar mass
  static const formulaHint =
      Bi('e.g. CuSO4·5H2O, Ca(OH)2', 'ör. CuSO4·5H2O, Ca(OH)2');
  static const composition = Bi('Composition', 'Bileşim');
  static const element = Bi('Element', 'Element');
  static const atoms = Bi('Atoms', 'Atom');
  static const massShare = Bi('Mass %', 'Kütle %');
  static const totalAtoms = Bi('Total atoms', 'Toplam atom');
  static const massMoles = Bi('Mass ⇄ moles', 'Kütle ⇄ mol');
  static const mass = Bi('Mass', 'Kütle');
  static const moles = Bi('Moles', 'Mol');
  static const particles = Bi('Particles', 'Tanecik');
  static const caseTip = Bi(
    'Symbols are case sensitive: Co = cobalt, CO = carbon monoxide. Write charges with ^ (Fe^3+).',
    'Semboller büyük/küçük harfe duyarlıdır: Co = kobalt, CO = karbon monoksit. Yükleri ^ ile yazın (Fe^3+).',
  );
  static const charge = Bi('Charge', 'Yük');
  static const errEmptyFormula = Bi('Enter a formula', 'Bir formül girin');
  static Bi errUnknownElement(String s) =>
      Bi('Unknown element: $s', 'Bilinmeyen element: $s');
  static Bi errUnexpectedChar(String s) =>
      Bi('Unexpected character: $s', 'Beklenmeyen karakter: $s');
  static const errBrackets =
      Bi('Brackets are not balanced', 'Parantezler dengeli değil');
  static Bi errInvalidNumber(String s) =>
      Bi('Invalid number: $s', 'Geçersiz sayı: $s');

  // Balancer / stoichiometry
  static const equationHint =
      Bi('e.g. Fe + O2 -> Fe2O3', 'ör. Fe + O2 -> Fe2O3');
  static const balanced = Bi('Balanced equation', 'Denkleştirilmiş denklem');
  static const errNoArrow = Bi(
    'Put an arrow (->) between reactants and products',
    'Girenler ile ürünler arasına ok (->) koyun',
  );
  static const errEmptySide = Bi(
    'Both sides need at least one substance',
    'Her iki tarafta da en az bir madde olmalı',
  );
  static Bi errInvalidSpecies(String s) =>
      Bi('Invalid formula: $s', 'Geçersiz formül: $s');
  static const errCannotBalance = Bi(
    'This equation cannot be balanced. Check the formulas.',
    'Bu denklem denkleştirilemiyor. Formülleri kontrol edin.',
  );
  static const errMultipleSolutions = Bi(
    'This equation has more than one independent solution (it may combine several reactions).',
    'Bu denklemin birden fazla bağımsız çözümü var (birkaç tepkimenin toplamı olabilir).',
  );
  static const stoichiometry = Bi('Stoichiometry', 'Stokiyometri');
  static const stoichHint = Bi(
    'Enter the amounts you know (one or more reactants, or a product). The limiting reactant and theoretical amounts are calculated.',
    'Bildiğiniz miktarları girin (bir veya daha fazla giren ya da bir ürün). Sınırlayıcı bileşen ve teorik miktarlar hesaplanır.',
  );
  static const limiting = Bi('Limiting', 'Sınırlayıcı');
  static const leftOver = Bi('Left over', 'Artan');
  static const reactants = Bi('Reactants', 'Girenler');
  static const products = Bi('Products', 'Ürünler');
  static const consumed = Bi('Consumed', 'Harcanan');
  static const produced = Bi('Produced', 'Oluşan');
  static const enterAmount = Bi('Enter at least one amount', 'En az bir miktar girin');

  // Empirical formula
  static const addElement = Bi('Add element', 'Element ekle');
  static const massOrPercent = Bi('Mass or %', 'Kütle veya %');
  static const symbol = Bi('Symbol', 'Sembol');
  static const optionalMolarMass =
      Bi('Molar mass (optional)', 'Mol kütlesi (isteğe bağlı)');
  static const empiricalFormula = Bi('Empirical formula', 'Basit (ampirik) formül');
  static const molecularFormula = Bi('Molecular formula', 'Molekül formülü');
  static const moleRatio = Bi('Mole ratio', 'Mol oranı');
  static const empiricalHint = Bi(
    'Enter mass percentages or masses of each element – only the ratios matter.',
    'Her elementin kütlece yüzdesini veya kütlesini girin – yalnızca oranlar önemlidir.',
  );
  static const errElements = Bi(
    'Enter a valid symbol and a positive amount for every row',
    'Her satıra geçerli bir sembol ve pozitif bir miktar girin',
  );

  // Solver
  static const solveFor = Bi('Solve for', 'Bilinmeyen');
  static const equation = Bi('Equation', 'Denklem');
  static Bi errMissing(String v) =>
      Bi('Enter a value for $v', '$v için bir değer girin');
  static Bi errNegative(String v) =>
      Bi('$v cannot be negative', '$v negatif olamaz');
  static const errNoSolution = Bi(
    'No valid solution for these values',
    'Bu değerlerle geçerli bir çözüm yok',
  );
  static const fromFormula = Bi('Formula (optional)', 'Formül (isteğe bağlı)');
  static const invalidNumber = Bi('Invalid number', 'Geçersiz sayı');

  // pH scale
  static const acidic = Bi('Acidic', 'Asidik');
  static const neutral = Bi('Neutral', 'Nötr');
  static const basic = Bi('Basic', 'Bazik');
  static const at25C = Bi('At 25 °C (Kw = 1.0 × 10⁻¹⁴)', '25 °C’de (Kw = 1,0 × 10⁻¹⁴)');

  // Units & constants
  static const tapToCopy = Bi('Tap a row to copy', 'Kopyalamak için satıra dokunun');
  static const exact = Bi('exact', 'tam');

  static Bi categoryName(ElementCategory c) => switch (c) {
        ElementCategory.alkaliMetal => const Bi('Alkali metal', 'Alkali metal'),
        ElementCategory.alkalineEarthMetal =>
          const Bi('Alkaline earth metal', 'Toprak alkali metal'),
        ElementCategory.transitionMetal =>
          const Bi('Transition metal', 'Geçiş metali'),
        ElementCategory.postTransitionMetal =>
          const Bi('Post-transition metal', 'Zayıf metal'),
        ElementCategory.metalloid => const Bi('Metalloid', 'Yarı metal'),
        ElementCategory.nonmetal => const Bi('Nonmetal', 'Ametal'),
        ElementCategory.halogen => const Bi('Halogen', 'Halojen'),
        ElementCategory.nobleGas => const Bi('Noble gas', 'Soy gaz'),
        ElementCategory.lanthanide => const Bi('Lanthanide', 'Lantanit'),
        ElementCategory.actinide => const Bi('Actinide', 'Aktinit'),
        ElementCategory.unknown => const Bi('Unknown properties', 'Özellikleri bilinmiyor'),
      };

  static Bi stateName(MatterState s) => switch (s) {
        MatterState.solid => const Bi('Solid', 'Katı'),
        MatterState.liquid => const Bi('Liquid', 'Sıvı'),
        MatterState.gas => const Bi('Gas', 'Gaz'),
        MatterState.unknown => const Bi('Unknown', 'Bilinmiyor'),
      };

  static Bi quantityName(Quantity q) => switch (q) {
        Quantity.mass => const Bi('Mass', 'Kütle'),
        Quantity.volume => const Bi('Volume', 'Hacim'),
        Quantity.amount => const Bi('Amount', 'Madde miktarı'),
        Quantity.pressure => const Bi('Pressure', 'Basınç'),
        Quantity.temperature => const Bi('Temperature', 'Sıcaklık'),
        Quantity.temperatureDifference => const Bi('Temperature change', 'Sıcaklık farkı'),
        Quantity.energy => const Bi('Energy', 'Enerji'),
        Quantity.length => const Bi('Length', 'Uzunluk'),
        Quantity.time => const Bi('Time', 'Zaman'),
        Quantity.concentration => const Bi('Concentration', 'Derişim'),
        Quantity.density => const Bi('Density', 'Yoğunluk'),
        Quantity.molarMass => const Bi('Molar mass', 'Mol kütlesi'),
        Quantity.molarEnergy => const Bi('Molar energy', 'Molar enerji'),
        Quantity.molarEntropy => const Bi('Molar entropy', 'Molar entropi'),
        Quantity.specificHeat => const Bi('Specific heat', 'Öz ısı'),
        Quantity.current => const Bi('Current', 'Akım'),
        Quantity.charge => const Bi('Charge', 'Yük'),
        Quantity.voltage => const Bi('Voltage', 'Gerilim'),
        Quantity.rateConstant => const Bi('Rate constant', 'Hız sabiti'),
        Quantity.zeroOrderRate => const Bi('Rate constant', 'Hız sabiti'),
        Quantity.secondOrderRate => const Bi('Rate constant', 'Hız sabiti'),
        Quantity.frequency => const Bi('Frequency', 'Frekans'),
        Quantity.molality => const Bi('Molality', 'Molalite'),
        Quantity.absorptivity => const Bi('Molar absorptivity', 'Molar absorptivite'),
        Quantity.cryoscopic => const Bi('Constant', 'Sabit'),
        Quantity.percent => const Bi('Percent', 'Yüzde'),
        Quantity.dimensionless => const Bi('Number', 'Sayı'),
      };

  /// Short, accurate chemistry facts for the home screen.
  static const facts = [
    Bi('Helium was discovered in the Sun’s spectrum (1868) before it was found on Earth.',
        'Helyum, Dünya’da bulunmadan önce Güneş’in tayfında keşfedildi (1868).'),
    Bi('Mercury and bromine are the only elements that are liquid at room temperature.',
        'Oda sıcaklığında sıvı olan elementler yalnızca cıva ve bromdur.'),
    Bi('Gallium melts at 29.8 °C – it can melt in your hand.',
        'Galyum 29,8 °C’de erir – avucunuzda bile eriyebilir.'),
    Bi('Since 2019 the Avogadro constant is exactly 6.02214076 × 10²³ mol⁻¹.',
        '2019’dan beri Avogadro sabiti tam olarak 6,02214076 × 10²³ mol⁻¹’dir.'),
    Bi('Fluorine is the most electronegative element (3.98 on the Pauling scale).',
        'Flor en elektronegatif elementtir (Pauling ölçeğinde 3,98).'),
    Bi('Water is densest at about 4 °C, so lakes freeze from the top down.',
        'Su yaklaşık 4 °C’de en yoğundur; bu yüzden göller yüzeyden donar.'),
    Bi('Diamond and graphite are both made of pure carbon.',
        'Elmas ve grafitin ikisi de saf karbondan oluşur.'),
    Bi('Tungsten has the highest melting point of all metals: 3422 °C.',
        'Tungsten, metaller arasında en yüksek erime noktasına sahiptir: 3422 °C.'),
    Bi('Osmium is the densest naturally occurring element (about 22.6 g/cm³).',
        'Osmiyum doğada bulunan en yoğun elementtir (yaklaşık 22,6 g/cm³).'),
    Bi('The name “oxygen” comes from Greek words meaning “acid former”.',
        '“Oksijen” adı, Yunanca “asit oluşturan” anlamına gelen sözcüklerden gelir.'),
    Bi('About 74% of the ordinary matter in the universe (by mass) is hydrogen.',
        'Evrendeki sıradan maddenin kütlece yaklaşık %74’ü hidrojendir.'),
    Bi('Oxygen makes up about 65% of the human body by mass.',
        'İnsan vücudunun kütlece yaklaşık %65’i oksijendir.'),
    Bi('Pure water at 25 °C has pH 7 because [H⁺] = [OH⁻] = 10⁻⁷ M.',
        '25 °C’de saf suyun pH’ı 7’dir, çünkü [H⁺] = [OH⁻] = 10⁻⁷ M’dir.'),
    Bi('Element 118, oganesson, is the heaviest element known so far.',
        'Bilinen en ağır element 118 numaralı oganessondur.'),
  ];
}
