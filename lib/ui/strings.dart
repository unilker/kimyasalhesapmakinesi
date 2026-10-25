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
  static const licenseText = Bi(
    'Free and open source under the Apache License 2.0. Anyone who uses, modifies or redistributes it must keep the copyright notice and credit the author (see NOTICE).',
    'Apache Lisansı 2.0 ile ücretsiz ve açık kaynaktır. Kullanan, değiştiren veya yeniden dağıtan herkes telif bildirimini korumalı ve geliştiriciye atıf yapmalıdır (bkz. NOTICE).',
  );
  static const dataSources = Bi('Data sources', 'Veri kaynakları');
  static const dataSourcesText = Bi(
    'Atomic masses: IUPAC (CIAAW) standard atomic weights, 2024 revision. Constants: CODATA 2022 / SI 2019.',
    'Atom kütleleri: IUPAC (CIAAW) standart atom ağırlıkları, 2024 revizyonu. Sabitler: CODATA 2022 / SI 2019.',
  );
  static const version = Bi('Version', 'Sürüm');
  static const developer = Bi('Developer', 'Geliştirici');

  // Orientation
  static const orientation = Bi('Screen orientation', 'Ekran yönü');
  static const rotateScreen = Bi('Rotate screen', 'Ekranı döndür');
  static const autoRotate = Bi('Auto-rotate', 'Otomatik döndürme');
  static const portrait = Bi('Portrait', 'Dikey');
  static const landscape = Bi('Landscape', 'Yatay');
  static const showRotateButton = Bi('Show rotate button', 'Döndürme düğmesini göster');
  static const rotateButtonHint = Bi(
    'Tap the button on the screen edge to switch between portrait and landscape; long-press it for more options. You can drag it anywhere.',
    'Ekran kenarındaki düğmeye dokunarak dikey ve yatay arasında geçin; diğer seçenekler için basılı tutun. Düğmeyi istediğiniz yere sürükleyebilirsiniz.',
  );
  static const lockedPortrait = Bi(
    'Locked to portrait · long-press the button for auto-rotate',
    'Dikey konuma kilitlendi · otomatik döndürme için düğmeyi basılı tutun',
  );
  static const lockedLandscape = Bi(
    'Locked to landscape · long-press the button for auto-rotate',
    'Yatay konuma kilitlendi · otomatik döndürme için düğmeyi basılı tutun',
  );
  static const autoRotateOn = Bi('Auto-rotate is on', 'Otomatik döndürme açık');
  static const hideButton = Bi('Hide button', 'Düğmeyi gizle');
  static const hiddenHint = Bi(
    'You can show it again in Settings → Screen orientation.',
    'Ayarlar → Ekran yönü bölümünden yeniden gösterebilirsiniz.',
  );
  static const largeScreenOrientation = Bi(
    'On tablets and unfolded foldables the system manages the orientation; the app adapts to both.',
    'Tabletlerde ve açık katlanabilir cihazlarda ekran yönünü sistem yönetir; uygulama her iki yöne de uyum sağlar.',
  );

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
  static const presets = Bi('Ready values', 'Hazır değerler');
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

  // Statistics & calibration
  static const dataSet = Bi('Data set', 'Veri seti');
  static const calibrationLine = Bi('Calibration line', 'Kalibrasyon doğrusu');
  static const data = Bi('Values', 'Değerler');
  static const dataHint = Bi(
    'Separate values with spaces, new lines or ";". Decimal comma or point.',
    'Değerleri boşluk, yeni satır veya “;” ile ayırın. Ondalık için virgül veya nokta kullanılabilir.',
  );
  static const confidence = Bi('Confidence level', 'Güven düzeyi');
  static const count = Bi('Number of values n', 'Değer sayısı n');
  static const mean = Bi('Mean', 'Ortalama');
  static const median = Bi('Median', 'Medyan');
  static const sd = Bi('Standard deviation s', 'Standart sapma s');
  static const variance = Bi('Variance s²', 'Varyans s²');
  static const rsd = Bi('Relative standard deviation', 'Bağıl standart sapma');
  static const sem = Bi('Standard error of the mean', 'Ortalamanın standart hatası');
  static const range = Bi('Range (min – max)', 'Aralık (en küçük – en büyük)');
  static const ci = Bi('Confidence interval of the mean', 'Ortalamanın güven aralığı');
  static const qTest = Bi('Dixon Q test', 'Dixon Q testi');
  static const grubbsTest = Bi('Grubbs test', 'Grubbs testi');
  static const suspect = Bi('Suspect value', 'Şüpheli değer');
  static const statistic = Bi('Test value / critical value', 'Test değeri / kritik değer');
  static const outlierYes = Bi('Outlier – may be rejected', 'Aykırı değer – atılabilir');
  static const outlierNo = Bi('Not an outlier – keep it', 'Aykırı değil – korunmalı');
  static const qRange = Bi('The Q test is defined for 3–10 values.', 'Q testi 3–10 değer için tanımlıdır.');
  static const needTwo = Bi('Enter at least 2 numbers', 'En az 2 sayı girin');
  static const invalidList = Bi('Some entries are not numbers', 'Bazı girdiler sayı değil');
  static const pairs = Bi('Standards: one “x y” pair per line', 'Standartlar: her satıra bir “x y” çifti');
  static const pairsHint = Bi('e.g. 2 5.0', 'ör. 2 5,0');
  static const unknownSignal = Bi('Signal of the unknown y₀ (optional)', 'Bilinmeyenin sinyali y₀ (isteğe bağlı)');
  static const replicates = Bi('Number of y₀ replicates', 'y₀ tekrar sayısı');
  static const slope = Bi('Slope m ± s', 'Eğim m ± s');
  static const intercept = Bi('Intercept b ± s', 'Kesim noktası b ± s');
  static const correlation = Bi('Correlation r / R²', 'Korelasyon r / R²');
  static const syx = Bi('Residual SD s_y/x', 'Artık standart sapma s_y/x');
  static const lodLabel = Bi('Limit of detection 3.3·s_y/x/m', 'Gözlenebilme sınırı 3,3·s_y/x/m');
  static const loqLabel = Bi('Limit of quantification 10·s_y/x/m', 'Tayin sınırı 10·s_y/x/m');
  static const unknownX = Bi('Unknown x₀ (± confidence interval)', 'Bilinmeyen x₀ (± güven aralığı)');
  static const needPairs = Bi(
    'Enter at least 3 “x y” pairs with different x values',
    'Farklı x değerlerine sahip en az 3 “x y” çifti girin',
  );
  static const exampleData = Bi('Example data', 'Örnek veri');
  static const statsSource = Bi(
    'Methods: Miller & Miller, Statistics and Chemometrics for Analytical Chemistry; Q values: Rorabacher (1991); LOD/LOQ: ICH Q2.',
    'Yöntemler: Miller & Miller, Statistics and Chemometrics for Analytical Chemistry; Q değerleri: Rorabacher (1991); LOD/LOQ: ICH Q2.',
  );

  // Titration curve
  static const analyte = Bi('Analyte (in the flask)', 'Analit (erlende)');
  static const analyteAcid = Bi('Acid titrated with strong base', 'Kuvvetli bazla titre edilen asit');
  static const analyteBase = Bi('Base titrated with strong acid', 'Kuvvetli asitle titre edilen baz');
  static const pKaList = Bi('pKa values (empty = strong)', 'pKa değerleri (boş = kuvvetli)');
  static const pKaListHint = Bi(
    'e.g. 4.76, or 2.16 7.21 12.32 for H₃PO₄. For bases, the pKa of the conjugate acid.',
    'ör. 4,76 veya H₃PO₄ için 2,16 7,21 12,32. Bazlar için eşlenik asidin pKa’sı.',
  );
  static const analyteConc = Bi('Analyte concentration', 'Analit derişimi');
  static const analyteVol = Bi('Analyte volume', 'Analit hacmi');
  static const titrantConc = Bi('Titrant concentration', 'Titrant derişimi');
  static const volumeQuery = Bi('pH after adding (optional)', 'Şu kadar eklenince pH (isteğe bağlı)');
  static const equivalencePoint = Bi('Equivalence point', 'Eşdeğerlik noktası');
  static const halfEquivalence = Bi('Half-equivalence (pH ≈ pKa)', 'Yarı eşdeğerlik (pH ≈ pKa)');
  static const initialPH = Bi('Initial pH', 'Başlangıç pH’ı');
  static const indicatorsLabel = Bi('Suitable indicators', 'Uygun göstergeler');
  static const noIndicator = Bi('No common indicator changes colour exactly here', 'Bu pH’ta renk değiştiren yaygın bir gösterge yok');
  static const titrantAdded = Bi('Titrant added (mL)', 'Eklenen titrant (mL)');
  static const titrationNote = Bi(
    'Exact charge balance at 25 °C (Kw = 10⁻¹⁴), activities taken as concentrations.',
    'Tam yük denkliği, 25 °C (Kw = 10⁻¹⁴); aktiflikler derişime eşit alınır.',
  );
  static const invalidPKa = Bi('Check the pKa values', 'pKa değerlerini kontrol edin');
  static const acidTableTitle = Bi('Weak acids and bases (25 °C)', 'Zayıf asit ve bazlar (25 °C)');
  static const pickFromTable = Bi('Choose from the pKa table', 'pKa tablosundan seç');
  static const searchAcid = Bi('Search: acetic, NH3, phosphoric …', 'Ara: asetik, NH3, fosforik …');
  static const acidTableSource = Bi(
    'Source: CRC Handbook of Chemistry and Physics, 84th ed. Bases are listed with pKb; the titration uses pKa(BH⁺) = 14.00 − pKb.',
    'Kaynak: CRC Handbook of Chemistry and Physics, 84. baskı. Bazlar pKb ile verilir; titrasyonda pKa(BH⁺) = 14,00 − pKb kullanılır.',
  );

  // Galvanic cell
  static const cathodeLabel = Bi('Cathode (reduction)', 'Katot (indirgenme)');
  static const anodeLabel = Bi('Anode (oxidation)', 'Anot (yükseltgenme)');
  static const swapElectrodes = Bi('Swap electrodes', 'Elektrotları değiştir');
  static const chooseHalfReaction = Bi('Choose a half-reaction', 'Yarı tepkime seçin');
  static const searchHalfReaction = Bi('Search: Cu, MnO4, Cl2 …', 'Ara: Cu, MnO4, Cl2 …');
  static const potentialTable = Bi('Standard reduction potentials', 'Standart indirgenme potansiyelleri');
  static const showTable = Bi('Show the E° table', 'E° tablosunu göster');
  static const cellPotential = Bi('Standard cell potential E°', 'Standart pil potansiyeli E°');
  static const overallReaction = Bi('Overall reaction', 'Toplam tepkime');
  static const electronsTransferred = Bi('Electrons transferred n', 'Aktarılan elektron n');
  static const spontaneousYes = Bi('E° > 0: spontaneous as written (galvanic cell)',
      'E° > 0: yazıldığı yönde istemli (galvanik pil)');
  static const spontaneousNo = Bi('E° < 0: not spontaneous – swap the electrodes or apply this voltage (electrolysis)',
      'E° < 0: istemsiz – elektrotları değiştirin ya da bu gerilimi uygulayın (elektroliz)');
  static const sameHalfReaction = Bi('Choose two different half-reactions', 'İki farklı yarı tepkime seçin');
  static const reactionQuotient = Bi('Reaction quotient Q (optional, for E)', 'Tepkime oranı Q (isteğe bağlı, E için)');
  static const cellPotentialAtQ = Bi('Cell potential E at this Q', 'Bu Q değerinde pil potansiyeli E');
  static const cellNote = Bi('25 °C, 1 atm; E° values: P. Vanýsek, CRC Handbook of Chemistry and Physics.',
      '25 °C, 1 atm; E° değerleri: P. Vanýsek, CRC Handbook of Chemistry and Physics.');

  // Reaction thermodynamics (Hess)
  static const hessNote = Bi(
    'ΔH° and ΔS° from standard formation data at 298.15 K, 1 bar (CODATA key values; CRC/NBS/JANAF for the rest). At other temperatures ΔH° and ΔS° are taken as constant.',
    'ΔH° ve ΔS° 298,15 K ve 1 bar standart oluşum verilerinden (CODATA anahtar değerleri; diğerleri CRC/NBS/JANAF). Başka sıcaklıklarda ΔH° ve ΔS° sabit kabul edilir.',
  );
  static const speciesData = Bi('Species and table values', 'Türler ve tablo değerleri');
  static const temperatureK = Bi('Temperature', 'Sıcaklık');
  static const errNotInTable = Bi('Not in the data table: ', 'Veri tablosunda yok: ');
  static const errUnbalancedThermo = Bi('The written coefficients do not balance the equation',
      'Yazılan katsayılar denklemi denkleştirmiyor');
  static const alwaysSpontaneous = Bi('ΔH° < 0 and ΔS° > 0: spontaneous at every temperature',
      'ΔH° < 0 ve ΔS° > 0: her sıcaklıkta istemli');
  static const neverSpontaneous = Bi('ΔH° > 0 and ΔS° < 0: not spontaneous at any temperature',
      'ΔH° > 0 ve ΔS° < 0: hiçbir sıcaklıkta istemli değil');
  static Bi spontaneousBelow(String t) =>
      Bi('Spontaneous below $t (enthalpy-driven)', '$t altında istemli (entalpi kontrollü)');
  static Bi spontaneousAbove(String t) =>
      Bi('Spontaneous above $t (entropy-driven)', '$t üstünde istemli (entropi kontrollü)');
  static const atTemperature = Bi('At the chosen temperature', 'Seçilen sıcaklıkta');
  static const sourceLabel = Bi('Source', 'Kaynak');

  // Mass spectrometry
  static const msNote = Bi(
    'Unit-resolution isotope pattern from NIST isotopic compositions; m/z includes the electron mass.',
    'NIST izotop bileşimlerinden birim çözünürlüklü izotop deseni; m/z elektron kütlesini içerir.',
  );
  static const formulaOrIon = Bi('Molecular formula', 'Molekül formülü');
  static const ionType = Bi('Ion', 'İyon');
  static const neutralMolecule = Bi('Neutral M', 'Nötr M');
  static const monoisotopic = Bi('Monoisotopic (exact) mass', 'Monoizotopik (tam) kütle');
  static const monoisotopicMz = Bi('Monoisotopic m/z', 'Monoizotopik m/z');
  static const averageMass = Bi('Average mass', 'Ortalama kütle');
  static const dbeLabel = Bi('Rings + double bonds (DBE)', 'Halka + çift bağ (DBE)');
  static const nominalMass = Bi('Nominal mass', 'Nominal kütle');
  static const isotopePeaks = Bi('Isotope peaks', 'İzotop tepeleri');
  static const relativeIntensity = Bi('Relative intensity (%)', 'Bağıl şiddet (%)');
  static Bi errNoIsotopes(String el) =>
      Bi('$el has no natural isotopic composition', '$el elementinin doğal izotop bileşimi yok');
  static const errCannotRemove = Bi('The formula has no atom to remove for this ion',
      'Bu iyon için formülden çıkarılacak atom yok');

  // Kinetic data analysis
  static const rateDataNote = Bi(
    'Least-squares lines of [A], ln[A] and 1/[A] against t; the order with the largest R² is suggested. Check the residuals and the chemistry before trusting it.',
    '[A], ln[A] ve 1/[A] değerlerinin t’ye karşı en küçük kareler doğruları; en büyük R²’ye sahip derece önerilir. Güvenmeden önce artıkları ve kimyayı kontrol edin.',
  );
  static const timeConcPairs = Bi('Data: one “t [A]” pair per line', 'Veri: her satıra bir “t [A]” çifti');
  static const timeUnit = Bi('Time unit', 'Zaman birimi');
  static const suggestedOrder = Bi('Suggested order', 'Önerilen derece');
  static Bi orderName(int n) => Bi(
      switch (n) { 0 => 'Zero order', 1 => 'First order', _ => 'Second order' },
      '$n. derece');
  static const rateConstant = Bi('Rate constant k', 'Hız sabiti k');
  static const initialConc = Bi('[A]₀ from the fit', 'Uydurmadan [A]₀');
  static const halfLifeLabel = Bi('Half-life t½ (from [A]₀)', 'Yarılanma süresi t½ ([A]₀’dan)');
  static const allOrders = Bi('All three linear plots', 'Üç doğrusal grafik');
  static const integratedLaw = Bi('Concentration vs time', 'Derişim – zaman');
  static const initialRatesMode = Bi('Initial rates', 'Başlangıç hızları');
  static const initialRatesData = Bi('One experiment per line: [A] [B] … rate',
      'Her satıra bir deney: [A] [B] … hız');
  static const initialRatesNote = Bi(
    'ln rate = ln k + m·ln[A] + n·ln[B] … fitted by least squares; k is then averaged over the experiments with the rounded orders.',
    'ln hız = ln k + m·ln[A] + n·ln[B] … en küçük karelerle uydurulur; k, yuvarlanmış derecelerle deneylerin ortalamasıdır.',
  );
  static const fittedOrders = Bi('Fitted order', 'Uydurulan derece');
  static const rateWord = Bi('rate', 'hız');
  static const rateLaw = Bi('Rate law', 'Hız kanunu');
  static const overallOrderLabel = Bi('Overall order', 'Toplam derece');
  static const errInitialRates = Bi(
    'Each line needs the same number of positive values, with more experiments than reactants and independently varied concentrations',
    'Her satırda aynı sayıda pozitif değer olmalı; deney sayısı tepken sayısından fazla olmalı ve derişimler bağımsız değişmeli',
  );
  static const needPositive = Bi('Concentrations must be positive and at least 3 pairs are needed',
      'Derişimler pozitif olmalı ve en az 3 çift gerekir');

  // Radionuclides
  static const nuclideNote = Bi(
    'Half-lives, decay modes and masses: NUBASE2020 / AME2020 (1 y = 365.2422 d).',
    'Yarılanma süreleri, bozunma türleri ve kütleler: NUBASE2020 / AME2020 (1 yıl = 365,2422 gün).',
  );
  static const chooseNuclide = Bi('Choose a radionuclide', 'Radyonüklit seçin');
  static const searchNuclide = Bi('Search: 14C, iodine, 131 …', 'Ara: 14C, iyot, 131 …');
  static const halfLife = Bi('Half-life t½', 'Yarılanma süresi t½');
  static const decayModes = Bi('Decay modes', 'Bozunma türleri');
  static const decayConstant = Bi('Decay constant λ', 'Bozunma sabiti λ');
  static const meanLife = Bi('Mean life τ = 1/λ', 'Ortalama ömür τ = 1/λ');
  static const specificActivity = Bi('Specific activity', 'Özgül aktivite');
  static const atomicMassLabel = Bi('Atomic mass', 'Atom kütlesi');
  static const naturalAbundance = Bi('Natural abundance', 'Doğal bolluk');
  static const elapsedTime = Bi('Elapsed time', 'Geçen süre');
  static const initialAmountOptional = Bi('Initial amount (optional)', 'Başlangıç miktarı (isteğe bağlı)');
  static const remainingFraction = Bi('Remaining', 'Kalan');
  static const decayedFraction = Bi('Decayed', 'Bozunan');
  static const remainingAmount = Bi('Remaining amount', 'Kalan miktar');
  static Bi halfLivesElapsed(String n) => Bi('$n half-lives', '$n yarılanma süresi');

  // Speciation
  static const speciationNote = Bi(
    'αⱼ = (Ka₁⋯Kaⱼ/[H⁺]ʲ) / Σ; independent of the total concentration (ideal solution).',
    'αⱼ = (Ka₁⋯Kaⱼ/[H⁺]ʲ) / Σ; toplam derişimden bağımsızdır (ideal çözelti).',
  );
  static const atPH = Bi('pH (optional)', 'pH (isteğe bağlı)');
  static const fractionsAt = Bi('Species fractions', 'Tür kesirleri');
  static const dominantSpecies = Bi('Dominant species', 'Baskın tür');
  static const meanProtonsRemoved = Bi('Protons removed per molecule', 'Molekül başına ayrılan proton');

  // Uncertainty propagation
  static const uncNote = Bi(
    'GUM law of propagation for independent inputs (first order, derivatives by Richardson-extrapolated differences); optional Monte Carlo check with normal inputs (GUM Supplement 1).',
    'Bağımsız girdiler için GUM yayılım yasası (birinci derece, türevler Richardson ekstrapolasyonlu farklarla); isteğe bağlı Monte Carlo kontrolü, normal dağılımlı girdilerle (GUM Ek 1).',
  );
  static const uncExpression = Bi('Expression, e.g. m/(M*V)', 'İfade, ör. m/(M*V)');
  static const uncVariables = Bi('Variables: value ± standard uncertainty', 'Değişkenler: değer ± standart belirsizlik');
  static const uncName = Bi('Name', 'Ad');
  static const uncValue = Bi('Value', 'Değer');
  static const uncU = Bi('± u', '± u');
  static const addVariable = Bi('Add variable', 'Değişken ekle');
  static const combinedU = Bi('Combined standard uncertainty u', 'Birleşik standart belirsizlik u');
  static const relativeU = Bi('Relative uncertainty', 'Bağıl belirsizlik');
  static const expandedU = Bi('Expanded uncertainty U (k = 2, ≈95 %)', 'Genişletilmiş belirsizlik U (k = 2, ≈%95)');
  static const budgetTitle = Bi('Uncertainty budget', 'Belirsizlik bütçesi');
  static const monteCarloLabel = Bi('Monte Carlo check (20 000 draws)', 'Monte Carlo kontrolü (20 000 çekiliş)');
  static const mcInterval = Bi('95 % coverage interval', '%95 kapsama aralığı');
  static const mcMeanSd = Bi('Mean ± standard deviation', 'Ortalama ± standart sapma');
  static const errVariableName = Bi(
    'Variable names may contain letters only (no digits), and not sin, ln, e, pi …',
    'Değişken adları yalnızca harflerden oluşabilir (rakam olmaz) ve sin, ln, e, pi … olamaz',
  );
  static const errVariableValue = Bi('Enter a value and an uncertainty ≥ 0 for every variable',
      'Her değişken için bir değer ve ≥ 0 belirsizlik girin');
  static const angleRad = Bi('Angles in radians', 'Açılar radyan');
  static const angleDeg = Bi('Angles in degrees', 'Açılar derece');

  // NMR
  static const nmrNote = Bi(
    'Frequencies from the IUPAC 2001 Ξ scale (reference compounds relative to TMS ¹H); receptivities from γ, I and natural abundance.',
    'Frekanslar IUPAC 2001 Ξ ölçeğinden (TMS ¹H’ye göre referans bileşikleri); alıcılıklar γ, I ve doğal bolluktan hesaplanır.',
  );
  static const spectrometer = Bi('Spectrometer ¹H frequency', 'Spektrometre ¹H frekansı');
  static const nucleusLabel = Bi('Nucleus', 'Çekirdek');
  static const moreNuclei = Bi('All nuclei', 'Tüm çekirdekler');
  static const shiftPpm = Bi('Chemical shift difference (ppm, optional)', 'Kimyasal kayma farkı (ppm, isteğe bağlı)');
  static const referenceFrequency = Bi('Reference frequency', 'Referans frekansı');
  static const fieldLabel = Bi('Magnetic field B₀', 'Manyetik alan B₀');
  static const spinLabel = Bi('Spin I', 'Spin I');
  static const quadrupolar = Bi('quadrupolar', 'kuadrupolar');
  static const receptivityH = Bi('Receptivity vs ¹H', '¹H’ye göre alıcılık');
  static const receptivityC = Bi('Receptivity vs ¹³C', '¹³C’ye göre alıcılık');
  static const referenceCompound = Bi('Reference compound', 'Referans bileşiği');
  static const allAtField = Bi('All nuclei at this field', 'Bu alanda tüm çekirdekler');
  static const errSpectrometer = Bi('Enter the ¹H frequency in MHz', '¹H frekansını MHz olarak girin');

  // ICE table
  static const iceNote = Bi(
    'Enter K for the equation as written. Concentrations in mol/L for Kc, partial pressures for Kp; pure solids and liquids, marked (s) or (l), are left out.',
    'K’yi denklemin yazıldığı hâline göre girin. Kc için mol/L, Kp için kısmi basınç kullanın; (s) veya (l) ile işaretli saf katı ve sıvılar ifadeye girmez.',
  );
  static const reactionLabel = Bi('Reaction', 'Tepkime');
  static const iceReactionHint = Bi('e.g. H2 + I2 = 2HI', 'ör. H2 + I2 = 2HI');
  static const equilibriumConstant = Bi('Equilibrium constant K', 'Denge sabiti K');
  static const initialAmounts = Bi('Initial concentrations', 'Başlangıç derişimleri');
  static const initialOf = Bi('Initial', 'Başlangıç');
  static const changeOf = Bi('Change', 'Değişim');
  static const pickSalt = Bi('Choose a salt from the Ksp table', 'Ksp tablosundan tuz seç');
  static const kspTableTitle = Bi('Solubility products (25 °C)', 'Çözünürlük çarpımları (25 °C)');
  static const searchSalt = Bi('Search: AgCl, fluoride, calcium …', 'Ara: AgCl, florür, kalsiyum …');
  static const kspSource = Bi(
    'Source: CRC Handbook of Chemistry and Physics, 84th ed. Ideal solutions: activity coefficients, ion pairing and hydrolysis are ignored.',
    'Kaynak: CRC Handbook of Chemistry and Physics, 84. baskı. İdeal çözelti: aktiflik katsayıları, iyon çiftleşmesi ve hidroliz ihmal edilir.',
  );
  static const molarSolubilityLabel = Bi('Molar solubility s', 'Molar çözünürlük s');
  static const massSolubilityLabel = Bi('Solubility', 'Çözünürlük');
  static const equilibriumOf = Bi('Equilibrium', 'Denge');
  static const equilibriumComposition = Bi('Equilibrium composition', 'Denge bileşimi');
  static const extentLabel = Bi('Extent of reaction x', 'Tepkime ilerleme miktarı x');
  static const shiftsRight = Bi('Q < K: the reaction proceeds to the right', 'Q < K: tepkime sağa (ürünlere) ilerler');
  static const shiftsLeft = Bi('Q > K: the reaction proceeds to the left', 'Q > K: tepkime sola (girenlere) ilerler');
  static const atEquilibrium = Bi('Q = K: already at equilibrium', 'Q = K: sistem zaten dengede');
  static const initialQ = Bi('Initial Q', 'Başlangıç Q');
  static const pureSolidLiquid = Bi('pure solid/liquid – not in K', 'saf katı/sıvı – K’ye girmez');
  static const autoBalancedNote = Bi('Balanced automatically – K must refer to this equation',
      'Otomatik denkleştirildi – K bu denkleme ait olmalı');
  static const errUnbalancedWritten = Bi('The written coefficients do not balance the equation',
      'Yazılan katsayılar denklemi denkleştirmiyor');
  static const errNoIceSpecies = Bi('At least one dissolved or gaseous species is needed',
      'En az bir çözünmüş veya gaz hâlinde tür gerekli');
  static const errNoReaction = Bi(
      'The reaction cannot proceed in either direction: add some reactant or product',
      'Tepkime iki yönde de ilerleyemiyor: biraz giren ya da ürün ekleyin');
  static const errPositiveK = Bi('K must be a positive number; concentrations cannot be negative',
      'K pozitif bir sayı olmalı; derişimler negatif olamaz');

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
        Quantity.speed => const Bi('Speed', 'Hız'),
        Quantity.activity => const Bi('Activity', 'Aktivite'),
        Quantity.henry => const Bi("Henry's constant", 'Henry sabiti'),
        Quantity.vdwA => const Bi('van der Waals a', 'van der Waals a'),
        Quantity.vdwB => const Bi('van der Waals b', 'van der Waals b'),
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
