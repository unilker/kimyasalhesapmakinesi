# Yayın kılavuzu / Release guide

Kimya Hesap'ı Google Play ve App Store'da yayımlamak için adımlar. Mağaza
metinleri [`STORE_LISTING.md`](STORE_LISTING.md), görseller [`store/`](store/)
klasöründedir.

## 0. Yayından önce bir kez karar verin

- **Uygulama kimlikleri** yayından sonra değiştirilemez:
  Android `com.unilker.kimya_hesap`, iOS `com.unilker.kimyaHesap`
  (iOS kimliğinde alt çizgi kullanılamaz).
- **Sürüm:** `pubspec.yaml` içindeki `version: 1.0.0+1`. Her yüklemede `+`
  sonrasındaki yapı numarası artırılmalıdır (ör. `1.0.1+2`).

## 1. Gizlilik politikası adresi

Mağazalar herkese açık bir adres ister. İki seçenek:

1. **GitHub Pages (önerilen):** GitHub'da depo → *Settings → Pages →
   Build and deployment → Deploy from a branch → `main`, `/docs`* → Save.
   Birkaç dakika sonra adres:
   `https://unilker.github.io/kimyasalhesapmakinesi/privacy.html`
2. **Hemen çalışan adres:**
   `https://github.com/unilker/kimyasalhesapmakinesi/blob/main/docs/PRIVACY.md`

İsterseniz aynı sayfayı kimyager.net'te de yayımlayabilirsiniz.

## 2. Android imzalama anahtarı (bir kez)

Google Play App Signing kullanılır: Google uygulamayı kendi anahtarıyla
imzalar, siz yalnızca **yükleme anahtarıyla** imzalarsınız. Yükleme anahtarı
kaybolursa Play Console'dan sıfırlanabilir, ama yine de güvenli bir yerde
(parola yöneticisi + yedek) saklayın. **Anahtarı ve parolaları asla depoya
eklemeyin.**

```bash
keytool -genkey -v -keystore ~/kimya-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

### a) Kendi bilgisayarınızda derlemek için

`android/key.properties` dosyasını oluşturun (`.gitignore` içindedir):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/home/kullanici/kimya-upload.jks
```

Sonra `flutter build appbundle --release` →
`build/app/outputs/bundle/release/app-release.aab`.

> `key.properties` yoksa release derlemesi debug anahtarıyla imzalanır ve
> Play bunu reddeder. Yüklemeden önce `keytool -printcert -jarfile app-release.aab`
> çıktısında `CN=Android Debug` **olmadığını** kontrol edin.

### b) GitHub Actions ile derlemek için (bilgisayarda Flutter gerekmez)

Depo → *Settings → Secrets and variables → Actions → New repository secret*
ile şu dört sırrı ekleyin:

| Ad | Değer |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/kimya-upload.jks` çıktısı (macOS: `base64 -i ~/kimya-upload.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | anahtar deposu parolası |
| `ANDROID_KEY_PASSWORD` | anahtar parolası |
| `ANDROID_KEY_ALIAS` | `upload` |

Sonra *Actions → Release build → Run workflow* (ya da `v1.0.0` gibi bir etiket
gönderin). İş bitince imzalı `app-release.aab` dosyası *play-bundle* adıyla
indirilebilir. İş akışı, sır eksikse veya paket debug anahtarıyla
imzalanmışsa hata verip durur.

## 3. Google Play Console

1. Geliştirici hesabı (bir kerelik 25 USD) ve kimlik doğrulaması.
2. **Uygulama oluştur:** ad *Kimya Hesap Makinesi*, varsayılan dil Türkçe,
   *Uygulama*, *Ücretsiz*.
3. **Mağaza girişi** (Türkçe ve *English (United States)* çevirisi):
   başlık, kısa ve tam açıklama → `STORE_LISTING.md`;
   simge `store/play_icon_512.png`; öne çıkan grafik
   `store/feature_graphic_{tr,en}.png`; ekran görüntüleri
   `store/screenshots/play_phone`, `play_tablet_7`, `play_tablet_10`.
4. **Uygulama içeriği:**
   - Gizlilik politikası: 1. adımdaki adres
   - Reklamlar: *Hayır*
   - Uygulama erişimi: *Tüm işlevler kısıtlama olmadan kullanılabilir*
   - İçerik derecelendirmesi (IARC anketi): kategori *Referans, Haber veya
     Eğitim*; şiddet, cinsellik, kumar vb. sorularının hepsine *Hayır* →
     beklenen sonuç *Herkes / 3+*
   - Hedef kitle: 13 yaş altı gruplar seçilirse Aileler politikası devreye
     girer (uygulama uyumludur: veri toplamaz, reklam yoktur) ama inceleme
     uzar; yalnızca *13+* seçmek daha hızlıdır. Karar sizindir.
   - Veri güvenliği: *Uygulama hiçbir kullanıcı verisi toplamıyor veya
     paylaşmıyor*
   - Kamu sağlığı, finans vb. beyanlar: geçerli değil
5. **Kapalı test (yeni kişisel hesaplar için zorunlu):** 13 Kasım 2023'ten
   sonra açılan kişisel hesaplarda üretime geçmeden önce **en az 12 test
   kullanıcısı, kesintisiz 14 gün** kapalı testte kalmalıdır. Sayının 12'nin
   altına düşmemesi için 15–20 kişi davet edin. Ardından Kontrol paneli →
   *Üretim erişimine başvur*. (Kurumsal hesaplar bu kuraldan muaftır.)
6. **Üretim sürümü:** `app-release.aab` yükleyin, sürüm notu yazın, ülkeleri
   seçin, incelemeye gönderin.

## 4. App Store (iOS)

Gerekenler: Apple Developer Program üyeliği (yıllık 99 USD) ve derleme için
macOS + Xcode (Mac yoksa Codemagic gibi bir bulut derleme hizmeti).

1. **Bundle ID:** developer.apple.com → *Identifiers* → `com.unilker.kimyaHesap`.
2. **App Store Connect → Yeni uygulama:** ad *Kimya Hesap Makinesi*, birincil
   dil Türkçe, SKU ör. `kimya-hesap`.
3. **İmzalama:** `open ios/Runner.xcworkspace` → *Runner → Signing &
   Capabilities* → *Automatically manage signing* + Team'iniz.
4. **Derleme ve yükleme:** `flutter build ipa --release`, ardından
   `build/ios/ipa/*.ipa` dosyasını *Transporter* uygulamasıyla ya da
   Xcode *Organizer* ile yükleyin. İsteğe bağlı olarak önce TestFlight'ta
   deneyin.
5. **Uygulama bilgileri** (Türkçe + İngilizce yerelleştirme): alt başlık,
   tanıtım metni, açıklama, anahtar kelimeler → `STORE_LISTING.md`;
   destek adresi `https://kimyager.net`; gizlilik politikası adresi 1. adımdan.
   Ekran görüntüleri: `store/screenshots/appstore_iphone_6_9` ve
   `appstore_ipad_13`.
6. **App Privacy:** *Data Not Collected*. **Yaş derecelendirmesi:** anketin
   tamamına *Hayır* → 4+. **Kategori:** Eğitim (ikincil: Araçlar).
   **Şifreleme:** `ITSAppUsesNonExemptEncryption = NO` Info.plist'te ayarlı,
   ek belge gerekmez.
7. Derlemeyi seçip incelemeye gönderin.

## 5. Görselleri ve metinleri yeniden üretmek

```bash
python3 tool/gen_icons.py              # uygulama simgeleri
python3 tool/gen_store_graphics.py     # Play simgesi ve öne çıkan grafik
flutter test tool/screenshots/store_test.dart --update-goldens   # ekran görüntüleri
python3 tool/check_store_listing.py    # metin uzunlukları (CI'da da çalışır)
```

Ekran görüntülerini küçültmek için (kayıpsız): `pip install pyoxipng`, sonra
`python3 -c "import oxipng,glob;[oxipng.optimize(f,level=3) for f in glob.glob('docs/store/screenshots/**/*.png',recursive=True)]"`.
