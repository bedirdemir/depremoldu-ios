# App Store Metadata — 1.0.0

Bu belge App Store Connect formuna kopyala-yapıştır içindir. Ekran görüntüleri: `docs/appstore/screenshots/` (1320×2868, 6.9" iPhone).

## Kimlik

- App Store adı: Kayıtta seçtiğin ad (ör. "Deprem Oldu: Son Depremler"); cihazdaki görünen ad "Deprem Oldu".
- Bundle ID: `org.depremoldu.app`
- Sürüm: `1.0.0`; seçilecek build: **1.0.0 (1)**
- Birincil dil: Türkçe
- Kategori: **Haberler (News)**; ikincil: **Referans (Reference)**. (Hava Durumu uygun değil.)
- Fiyat: Ücretsiz
- Yaş derecelendirmesi: **4+**
- Telif: `© 2026 depremoldu.org`

## URL'ler

- Destek URL'si: `https://www.depremoldu.org`
- Pazarlama URL'si: `https://www.depremoldu.org`
- Gizlilik Politikası URL'si: `https://depremoldu.org/gizlilik` (yayında).

## Metinler

**Alt başlık (30 karakter):** `Son depremler ve fay haritası`

**Promosyon metni (170 karakter):**
`Kandilli verileriyle Türkiye'deki son depremleri listeleyin; 500 depremi haritada görün, GINRAS diri fay hatlarını katman olarak açın ve deprem bilincine yönelik içeriklere göz atın.`

**Açıklama:**
```
Deprem Oldu, Türkiye'deki son depremleri Kandilli Rasathanesi (KOERI) verileriyle hızlı ve sade bir arayüzde sunar.

• SON DEPREMLER: Büyüklük sınıfına göre renklendirilmiş liste; büyüklük, derinlik, tarih ve göreli zaman bilgileri. Aşağı çekerek yenileyin.
• DEPREM HARİTASI: Son 500 depremi büyüklüklerine göre boyutlandırılmış işaretlerle görün. Dilerseniz GINRAS/AFEAD diri fay hattı katmanını açın; faylar güven ve aktivite oranına göre renklendirilir.
• DEPREM KONUMU: Her deprem için harita üzerinde konum ve detay kartı.
• AFET BİLİNCİ: Deprem anında/öncesinde yapılması gerekenler, çök-kapan-tutun, deprem çantası, tsunami ve deprem çantası gibi konularda seçilmiş içerikler.

Notlar:
- Uygulama backend kullanmaz; veriler cihazınızdan doğrudan sağlayıcıya istek yapılarak alınır ve cihazınızda önbelleğe alınır.
- Hiçbir kişisel veri toplanmaz; hesap, izleme veya reklam yoktur.
- Bu uygulama resmî bir deprem uyarı/erken uyarı sistemi değildir; veriler bilgilendirme amaçlıdır.

Veriler Boğaziçi Üniversitesi Kandilli Rasathanesi ve Deprem Araştırma Enstitüsü Bölgesel Deprem-Tsunami İzleme ve Değerlendirme Merkezi'nden gelmektedir. Fay hattı verisi GINRAS/AFEAD (2018) kaynaklıdır.
```

**Anahtar kelimeler (100 karakter):**
`deprem,son depremler,deprem haritası,kandilli,fay hattı,afet,tsunami,sismik,deprem oldu`

## App Privacy

- Veri toplama: **Data Not Collected** (hesap yok, analytics yok, konum istenmez, reklam kimliği yok).
- İzleme (tracking): **Hayır**.

## Yaş derecelendirmesi anketi

- Tüm kategoriler: Yok / Hiçbiri. Sonuç 4+.

## Ekran görüntüleri (6.9")

1. `01-son-depremler.png` — liste ve büyüklük skalası
2. `02-harita-fay-hatlari.png` — harita + fay katmanı + legend
3. `03-deprem-konumu.png` — konum sheet'i
4. `04-afet-bilinci.png` — içerik kartları
5. `05-hakkinda.png` — veri kaynakları ve bağlantılar

## İnceleme notları (App Review Notes)

```
Uygulama hesap/oturum gerektirmez. Açılışta son depremler listesi otomatik yüklenir; harita sekmesinde fay hattı katmanı test edilebilir. Veriler Kandilli Rasathanesi'nden açık API aracılığıyla alınır (http://www.koeri.boun.edu.tr ve https://api.orhanaydogdu.com.tr). Uygulama resmî uyarı sistemi değildir.
```

## Gizlilik Politikası (yayınlanan sayfanın kaynağı)

```
Deprem Oldu uygulaması hiçbir kişisel veri toplamaz, saklamaz veya paylaşmaz. Hesap oluşturma, izleme (tracking), reklam ve analitik SDK'sı yoktur. Konum izni istenmez.

Deprem verileri, uygulamanın cihazınızdan doğrudan Bağaziçi Üniversitesi Kandilli Rasathanesi verisini sunan açık API'ye (api.orhanaydogdu.com.tr) yaptığı isteklerle alınır ve yalnız cihazınızda önbelleğe alınır. Fay hattı verisi uygulama içinde gömülüdür (GINRAS/AFEAD, 2018).

Harici bağlantılar (AFAD, Evrim Ağacı, YouTube, MTA) yalnız siz dokunduğunuzda açılır; bu sitelerin gizlilik uygulamaları kendilerine aittir.

Sorular için: bedir@proton.me
```

## Açık kaynak

- iOS deposu herkese açıktır: `https://github.com/bedirdemir/depremoldu-ios` (MIT; veri/font atıfları `docs/ASSET_PROVENANCE.md`).
- Uygulamadaki "GitHub" bağlantısı bu depoya gider.

## Gönderim akışı (App Store Connect)

1. Uygulama → **Distribution** sekmesi → `1.0.0` sürümünü hazırla.
2. Build olarak **1.0.0 (2)** seç (TestFlight'ta processing tamamlanmış olmalı).
3. Yukarıdaki metadata, URL'ler ve ekran görüntülerini gir.
4. App Privacy → Data Not Collected; yaş derecelendirmesi anketini doldur.
5. Ihracat uyumluluğu: uygulama özel şifreleme içermediği için (`ITSAppUsesNonExemptEncryption = NO`) soru gelmez.
6. **Add for Review** → **Submit**.
