# Changelog

Bu dosya formatı [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) temellidir ve proje [Semantic Versioning](https://semver.org/) kullanır.

## [Unreleased]

### Changed

- Uygulama yalnızca açık modda çalışır; sistem koyu modda da açık palet korunur (`UIUserInterfaceStyle = Light`).
- Üst şerit, sekme geçişlerinde animasyonsuz sabit bir başlığa dönüştürüldü; `depremoldu.org` sola hizalandı, Yenile yalnız veri sekmelerinde görünür.
- Son Depremler listesi sıkıştırıldı (boşluk ve punto web düzeyine indirildi) ve web paritesiyle 50'lik sayfalama eklendi: Önceki/Sonraki, sayfa numaraları ve `1-50 / 200 deprem` sayımı.
- Haritada deprem seçimi alt kart yerine noktanın üstünde popup olarak gösterilir; popup'taki "Detay" bağlantısı kaldırıldı.
- Koordinat gösterimi kayan nokta artıklarından arındırıldı (`39.16, 38.45`).
- Liste altındaki atıf/bağlantı bloğu kaldırıldı; veri atıfı ve API kullanım bilgisi Hakkında ekranının ilk bölümüne, API bağlantısı Bağlantılar bölümüne taşındı.
- Afet Bilinci kapanış metni genişletildi ve aynı metin Hakkında ekranına eklendi.

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
