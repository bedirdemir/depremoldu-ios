# Changelog

Bu dosya formatı [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) temellidir ve proje [Semantic Versioning](https://semver.org/) kullanır.

## [Unreleased]

### Changed

- Uygulama, ürün ikonu (`depremolduappicon.png`) ve çizgi markası (brand-mark SVG'den üretilen raster template) ile güncellendi; marka üst başlıkta ve "Son Depremler" sekmesinde kullanılıyor. Aynı ikon Android portunda da kullanılacak.
- Uygulama yalnızca açık modda çalışır; sistem koyu modda da açık palet korunur (`UIUserInterfaceStyle = Light`).
- Üst şerit, sekme geçişlerinde animasyonsuz sabit bir başlığa dönüştürüldü; `depremoldu.org` solda, Yenile yalnız veri sekmelerinde. Yenile sırasında düğmede spinner görünür ve istek uçuşta çoklanmaz.
- Liste native sürekli akışa çevrildi: 200 kayıt tek listede, sayfalama araçları yerine pull-to-refresh; alt sayaç "200 deprem".
- Satır divider'ları soldan sağa tam genişlikte; satır arası dikey boşluk yarıya indirildi, sol boşluk azaltıldı, bölge adları ve büyüklük değerleri kalınlaştırıldı, legend ile liste arası boşluk kaldırıldı. Arka plan renkleri web'deki soldan sağa gradient ile birebir aynıdır (accent %8.5 -> beyaz, 20%/90% durak).
- Haritada deprem seçimi noktanın üstünde popup olarak gösterilir; "Detay" bağlantısı yok. Koordinatlar kayan nokta artıklarından arındırıldı.
- Liste altındaki atıf/bağlantı bloğu kaldırıldı; veri/API atıfları Hakkında'nın ilk bölümüne, API ve Geliştirici Web Sitesi (`bedirdemir.com`) bağlantıları Bağlantılar bölümüne taşındı. Afet Bilinci kapanış metni genişletildi ve Hakkında'ya eklendi.

## [1.0.0] - 2026-09-12

### Added

- Türkiye'deki son 200 depremi gösteren native SwiftUI listesi; büyüklük rozeti, Türkçe göreli zaman, tarih-saat ve derinlik bilgileri.
- Son 500 depremi büyüklük sınıfına göre renkli/boyutlu marker'larla gösteren MapKit haritası.
- GINRAS/AFEAD 2018 diri fay hattı katmanı: güven ve oran bazlı renk/kalınlık, zoom'a duyarlı stil, legend ve kaynak atıfı.
- Deprem konumu sheet'i ve haritadan detay kartı.
- Web ile aynı 14 içerikli Afet Bilinci ekranı; harici bağlantılar uygulama içi Safari ile açılır.
- Hakkında ekranı: sürüm, veri kaynakları, bağlantılar ve sorumluluk notu.
- Doğrudan sağlayıcı API'si (`api.orhanaydogdu.com.tr`) ile cihazdan veri çekme; 15 sn fresh / 24 saat stale yerel cache, bounded retry ve request coalescing.
- Open Sans (OFL) fontları, marka App Icon'u ve koyu mod paleti.
- Swift Testing paket/domain testleri, hosted app unit testleri ve XCUITest UI testleri.
- `make verify-iteration` / `make verify` kapıları, Xcode projesi üretici script ve CI workflow'u.
- Dokümantasyon: mimari, ürün kapsamı, branching/release, test stratejisi, ADR'ler ve kontrol listeleri.
