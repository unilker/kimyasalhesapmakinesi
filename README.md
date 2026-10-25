# Kimya Hesap (Chem Calc)

Geliştirici: **Dr. İlker Ün** · [kimyager.net](https://kimyager.net)

Kimya öğrencileri ve akademisyenler için **ücretsiz, reklamsız, tamamen çevrimdışı** bilimsel hesap makinesi.
Android ve iOS'ta telefon, tablet ve katlanabilir cihazlarda çalışır. Arayüz Türkçe ve İngilizcedir.

## Özellikler

| Bölüm | İçerik |
|---|---|
| **Hesap makinesi** | Bilimsel fonksiyonlar, DEG/RAD, `2nd` tuşu, `Ans`, EE (×10ⁿ), fiziksel sabitler, canlı önizleme, donanım klavyesi desteği |
| **Mol kütlesi** | `CuSO4·5H2O`, `K4[Fe(CN)6]`, `Ca(OH)2`, `SO4^2-`, `D2O`; yüzde bileşim, kütle ⇄ mol ⇄ tanecik |
| **Mol ve verim** | Kütle, tanecik sayısı, NŞA'da gaz hacmi, hidrat suyu, % verim |
| **Basit formül** | Yüzde bileşimden basit ve (mol kütlesiyle) molekül formülü |
| **Çözeltiler** | Çözelti hazırlama (m = C·V·M), molalite, %(k/k) → molarite, kütlece yüzde, ppm, Henry yasası |
| **Seyreltme** | C₁V₁ = C₂V₂, seri seyreltme, iki çözeltiyi karıştırma |
| **Asit–baz** | pH/pOH, kuvvetli asit/baz (suyun iyonlaşması dahil), zayıf asit/baz (tam çözüm), tampon ve tampon hazırlama, Ka/pKa, renkli pH skalası |
| **Titrasyon eğrisi** | Kuvvetli/zayıf, mono/poliprotik asit ve bazlar, Na₂CO₃ gibi tuzlar; tam yük denkliğiyle pH eğrisi, eşdeğerlik ve yarı eşdeğerlik noktaları, uygun indikatörler; CRC'den 50 asit/bazlık pKa tablosu |
| **Denklem & stokiyometri** | Tam sayılı (kesin aritmetikle) denkleştirme, iyonik/redoks denklemler, sınırlayıcı bileşen, artan miktar, teorik verim |
| **Denge** | Kp ⇄ Kc, Ksp ve çözünürlük; **ICE tablosu**: herhangi bir tepkime ve K için denge derişimleri (ortak iyon, saf katı/sıvı, uç K değerlerinde tam hassasiyet); CRC'den 120 tuzluk Ksp tablosu, molar ve g/L çözünürlük |
| **Gaz yasaları** | İdeal, birleşik, gaz yoğunluğu, Dalton, Graham; van der Waals gerçek gaz, molekül hızları |
| **Termokimya** | q = mcΔT, karışım sıcaklığı, ΔG = ΔH − TΔS, ΔG° = −RT ln K, Clausius–Clapeyron, van 't Hoff |
| **Tepkime termodinamiği** | 353 maddelik veri tablosundan (CODATA anahtar değerleri + doğrulanmış CRC/NBS/JANAF) ΔH°, ΔS°, ΔG°, K; sıcaklığa bağlılık ve dönüşüm sıcaklığı |
| **Kinetik** | 0., 1., 2. derece, yarılanma süresi, Arrhenius (tek ve iki sıcaklık); **veriden hız kanunu**: [A]–t verisinden derece, k ± s ve t½, başlangıç hızları yönteminden dereceler ve k |
| **Elektrokimya** | Nernst, Faraday elektroliz, ΔG = −nFE, E° ⇄ K; **piller**: 74 yarı tepkimelik aranabilir E° tablosu (Vanýsek, CRC), E°pil, denkleştirilmiş toplam tepkime, ΔG°, K |
| **Spektroskopi** | Beer–Lambert, absorbans ⇄ %T, foton enerjisi / dalga boyu / frekans |
| **Koligatif** | Kaynama noktası yükselmesi, donma noktası alçalması, ozmotik basınç, Raoult |
| **Nükleer, atom ve kristal** | Radyoaktif bozunma ve aktivite; **radyonüklit tablosu** (NUBASE2020: 86 nüklit, yarılanma ± belirsizlik, bozunma türleri, özgül aktivite); Rydberg, Bohr, de Broglie, birim hücre |
| **Analitik kimya** | İstatistik (ortalama ± t-güven aralığı, %RSD, Dixon Q, Grubbs), kalibrasyon doğrusu (LOD/LOQ, bilinmeyen ± güven aralığı); **kütle spektrometrisi** (tam kütle, izotop deseni, [M+H]⁺ vb. iyonlar) |
| **Başvuru** | 118 elementli etkileşimli periyodik tablo, birim çevirici, CODATA 2022 sabitleri |
| **Geçmiş** | Tüm hesaplar cihazda saklanır (25–500 kayıt, ayarlanabilir), kaydırarak silme, tek dokunuşla kopyalama |

Formül tabanlı her araçta **istediğiniz değişkeni bilinmeyen** seçebilir, her girdi için **birim** seçebilirsiniz.
Sayı alanları hem `,` hem `.` ondalık ayırıcısını ve `25+273,15` ya da `1,5e-3` gibi küçük ifadeleri kabul eder.

### Ekran uyumu

- **Telefon:** alt gezinme çubuğu; telefon yatay tutulduğunda yan ray ve iki sütun.
- **Tablet / büyük ekran:** yan gezinme rayı; araçlar listesi ile seçili araç yan yana (liste–detay).
- **Katlanabilir cihazlar:** Menteşe ve katlama yeri algılanır (`MediaQuery.displayFeatures`).
  - Kitap duruşunda paneller menteşenin iki yanına yerleşir.
  - Masa üstü duruşunda hesap makinesinin ekranı üstte, tuşları altta kalır.
  - Kapak ekranı ile iç ekran arasında geçişte uygulama yeniden başlamaz.
- **Dikey ve yatay:** Tüm ekranlar iki yönde de çalışır. Telefonlarda ekran kenarında, istenen yere sürüklenebilen bir **döndürme düğmesi** vardır:
  - dokununca dikey ⇄ yatay geçer ve o yönde kilitler;
  - basılı tutunca *Otomatik döndürme / Dikey / Yatay / Düğmeyi gizle* seçenekleri çıkar;
  - aynı ayarlar *Ayarlar → Ekran yönü* bölümünde de bulunur.

  Tabletlerde ve açık katlanabilirlerde yönü sistem yönetir (Android 16+ ve iPad çoklu görev kilitleri yok sayar), bu yüzden düğme yalnızca telefonlarda görünür.
- **Ekran klavyesi:** Klavye açıldığında yazılan alan otomatik olarak görünür alana kaydırılır. Klavye açıkken döndürme düğmesi gizlenir. Bu davranış her araç için dikey ve yatay 6 ekran boyutunda otomatik testlerle doğrulanır.
- Sistem yazı boyutu (1,35× sınırına kadar), koyu tema ve ekran okuyucu etiketleri desteklenir.

### Gizlilik

İnternet izni yoktur (release APK'da doğrulandı). Üyelik, reklam, analiz ve takip yoktur.
Geçmiş ve ayarlar yalnızca cihazda `SharedPreferences` ile tutulur. Ayrıntılar: [docs/PRIVACY.md](docs/PRIVACY.md).

## Teknoloji ve yapı

[Flutter](https://flutter.dev) (Dart): tek kod tabanından Android ve iOS. Harici bağımlılıklar yalnızca
`shared_preferences`, `intl` ve `flutter_localizations` paketleridir.

```
lib/
  core/                 Arayüzden bağımsız, testli hesap motoru
    chem/               element verisi, formül çözümleyici, denklem denkleştirme, basit formül
    math/               ifade çözümleyici, kesirli sayılar (BigInt)
    solver.dart         "istediğin değişkeni çöz" altyapısı
    solver_catalog.dart tüm denklemler (gaz, çözelti, asit-baz, termo, kinetik …)
    units.dart, constants.dart, format.dart
  state/app_state.dart  ayarlar + geçmiş (yerel)
  ui/                   ekranlar, uyarlanabilir yerleşim (layout/adaptive.dart), tema, metinler
test/                   birim testleri + 10 ekran boyutu (dikey/yatay) × 2 dilde arayüz ve klavye testleri
tool/                   element verisi, simge ve ekran görüntüsü üreticileri
```

## Geliştirme

```bash
flutter pub get
flutter run                 # bağlı cihaz veya emülatörde
flutter analyze
flutter test                # 190+ test
```

Mağaza için ekran görüntüleri üretmek (gerçek yazı tipleriyle PNG):

```bash
flutter test tool/screenshots/screenshots_test.dart --update-goldens
# çıktı: tool/screenshots/out/
```

Simgeleri yeniden üretmek: `python3 tool/gen_icons.py` (Pillow gerekir).
Element tablosunu yeniden üretmek: `python3 tool/gen_elements.py lib/core/chem/elements_data.dart`.

## Yayınlama

Uygulama kimlikleri:

- Android: `com.unilker.kimya_hesap`
- iOS: `com.unilker.kimyaHesap`

İsterseniz ilk yayından **önce** değiştirin, çünkü yayından sonra değiştirilemez.
Sürüm numarası `pubspec.yaml` içindeki `version: 1.0.0+1` satırıdır.

### Google Play

1. Yükleme anahtarı oluşturun (bir kez):
   ```bash
   keytool -genkey -v -keystore ~/kimya-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. `android/key.properties` dosyasını oluşturun. Bu dosya **asla commit edilmez** (`.gitignore` içinde):
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/home/kullanici/kimya-upload.jks
   ```
3. `flutter build appbundle --release`, ardından `build/app/outputs/bundle/release/app-release.aab` dosyasını Play Console'a yükleyin.
4. *Veri güvenliği* formunda "Veri toplanmıyor / paylaşılmıyor" seçeneğini işaretleyin. Gizlilik politikası olarak `docs/PRIVACY.md` içeriğini yayınlayın (ör. GitHub Pages).

### App Store

iOS derlemesi için macOS ve Xcode gerekir. Mac yoksa Codemagic veya GitHub Actions `macos` çalıştırıcısı kullanılabilir.

1. `open ios/Runner.xcworkspace`, ardından *Signing & Capabilities* bölümünde Team'inizi seçin.
2. `flutter build ipa --release` komutunu çalıştırın, sonra Transporter veya Xcode Organizer ile yükleyin.
3. App Privacy bölümünde **Data Not Collected** seçin. `ITSAppUsesNonExemptEncryption=false` zaten ayarlıdır.

Mağaza başlığı **Kimya Hesap Makinesi**'dir; ana ekranda ve uygulama içinde kısa ad **Kimya Hesap** kullanılır.
Mağaza metinleri taslağı: [docs/STORE_LISTING.md](docs/STORE_LISTING.md).

## Lisans ve atıf

Copyright © 2026 Dr. İlker Ün ([kimyager.net](https://kimyager.net)).

Bu proje **[Apache Lisansı 2.0](LICENSE)** ile lisanslanmıştır. Kodu kullanmak, değiştirmek ve dağıtmak (ticari kullanım dahil) serbesttir, ancak şu koşullar zorunludur:

- [`LICENSE`](LICENSE) ve [`NOTICE`](NOTICE) dosyaları ile telif bildirimleri korunmalıdır.
- Türetilen ürünlerde, kullanıcıların görebileceği bir yerde (ör. Hakkında/Lisanslar ekranı veya belgeler) şu atıf yer almalıdır:
  > "Kimya Hesap" (Dr. İlker Ün – https://kimyager.net) temel alınmıştır. Apache Lisansı, Sürüm 2.0 ile lisanslanmıştır.
- Değiştirilen dosyalarda değişiklik yapıldığı belirtilmelidir.
- "Kimya Hesap" adı ve simgesi, türetilen ürünün bu projeyle aynı ya da onaylı olduğunu ima edecek şekilde kullanılamaz (lisansın 6. maddesi).

## Veri kaynakları ve üçüncü taraf lisanslar

- Atom kütleleri: IUPAC/CIAAW 2024 standart atom ağırlıkları (köşeli parantez: en uzun ömürlü izotopun kütle numarası).
- Elektronegatiflik: Pauling ölçeği. Sabitler: CODATA 2022 / SI 2019.
- İzotop kütleleri ve bollukları: NIST Atomic Weights and Isotopic Compositions.
- Yarılanma süreleri ve bozunma türleri: NUBASE2020 (Kondev ve ark., Chin. Phys. C 45, 030001, 2021); nüklit kütleleri AME2020.
- pKa/pKb ve Ksp değerleri: CRC Handbook of Chemistry and Physics, 84. baskı.
- Standart elektrot potansiyelleri: P. Vanýsek, "Electrochemical Series", CRC Handbook of Chemistry and Physics.
- Termodinamik veriler: CODATA Key Values for Thermodynamics (Cox, Wagman, Medvedev, 1989); tamamlayıcı olarak CRC Handbook, NBS (OpenStax Chemistry 2e Ek G) ve NIST-JANAF. Her satırın geçtiği denetimler `tool/data` içindeki dosya başlıklarında yazılıdır.
- İstatistik: Miller & Miller, *Statistics and Chemometrics for Analytical Chemistry*; Dixon Q kritik değerleri Rorabacher (1991); LOD/LOQ ICH Q2.
- Tüm hesaplar bağımsız referans uygulamalarla çapraz kontrol edilir; ayrıntılar: [tool/crosscheck/README.md](tool/crosscheck/README.md).
- Yazı tipleri: Nunito ve Noto Sans alt kümeleri. Her ikisi de SIL Open Font License 1.1 ile lisanslıdır (`assets/fonts/OFL*.txt`).
