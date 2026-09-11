# Deprem Oldu iOS

`depremoldu-ios`, [`CODE/depremoldu-workspace/depremolduorg-nuxtjs`](../depremolduorg-nuxtjs) web ürününün native SwiftUI karşılığıdır. Türkiye'deki son depremleri listeler, depremleri haritada gösterir ve GINRAS/AFEAD diri fay hattı katmanını sunar.

- Native teknoloji: Swift 6, SwiftUI, MapKit. Desteklenen sistemlerde Liquid Glass.
- Backend yoktur: uygulama Kandilli verisini doğrudan `api.orhanaydogdu.com.tr` üzerinden, her kullanıcının kendi cihazından çeker.
- Fay hattı verisi uygulama paketinde gömülüdür (GINRAS/AFEAD, 2018) ve çevrimdışı çalışır.
- İlk sürüm Türkçe'dir; hesap, izin duvarı ve bildirim yoktur.
- Android (`depremoldu-android`) sonraki aşamada bu depodaki domain/sözleşmelerden kopyalanarak yazılacaktır.

## Başlangıç noktaları

- [Mimari](docs/ARCHITECTURE.md)
- [Ürün kapsamı ve web paritesi](docs/PRODUCT_SCOPE.md)
- [Branching ve sürümleme](docs/BRANCHING_RELEASES.md)
- [Test stratejisi](docs/TESTING_STRATEGY.md)
- [Güncel durum](docs/CURRENT_STATE.md)
- [Varlık kaynakları](docs/ASSET_PROVENANCE.md)
- [Apple yayın rehberi](docs/APPLE_RELEASE_GUIDE.md)

## Geliştirme kurulumu

Gereksinimler:

- Xcode 26.6 ve `xcode-select` ile seçilmiş Swift 6 toolchain;
- iOS 26.5 simulator runtime'ı (veya kurulu en güncel runtime).

Hızlı kapı:

```sh
make verify-iteration
```

Bu kapı versioning kontrolü, proje tazelik kontrolü, paket testleri, Development simulator build'i ve app unit testlerini çalıştırır. UI değişikliğinde ilgili seçili XCUITest ayrıca `make ui-test-selected UI_TEST_SELECTOR='…'` ile çalıştırılır.

Tam kapı:

```sh
make verify
```

Bu kapı ek olarak Release simulator build'ini ve tüm UI suite'ini çalıştırır. Varsayılan hedef `iPhone 17 Pro Max` simulator'dır; başka bir cihaz `make verify SIMULATOR_NAME='iPhone 17 Pro'` ile seçilebilir.

Xcode projesi kaynak ağacından üretilir; dosya ekledikten/çıkardıktan sonra:

```sh
make project
```

Fiziksel iPhone signing'i için ignored yerel override hazırlanır:

```sh
cp Configuration/Local.example.xcconfig Configuration/Local.xcconfig
```

Yalnız `Configuration/Local.xcconfig` içindeki Team ID değiştirilir; dosya CI/temiz checkout'ta yokken build bozulmaz.

## Project graph

- `DepremOldu`: iOS 18+ SwiftUI app target.
- `DepremOlduAppTests`: feed model composition, sunum limitleri, fay modeli, içerik sözleşmesi ve UI fixture XCTest/Swift Testing testleri.
- `DepremOlduAppUITests`: liste, konum sheet'i, harita, fay katmanı, Afet Bilinci, Hakkında, hata/boş durumları XCUITest'leri (Test yapılandırmasında deterministic fake repository ile).
- `Packages/DepremOlduCore`: `DepremOlduDomain`, `DepremOlduNetworking`, `DepremOlduPersistence`, `DepremOlduRepository`, `DepremOlduFaults` ve test-only `DepremOlduTestSupport`.
- `Configuration`: ortak Base ile Debug, Test ve Release build ayarları.
- Shared scheme'ler: `DepremOldu-Development`, `DepremOldu-Test`, `DepremOldu-Release`.

Bundle ID: `org.depremoldu.app`.

## Git akışı

- `main`: App Store üretim gerçekliği ve sürüm etiketleri.
- `test`: TestFlight release candidate.
- `dev`: bütünleşmiş geliştirme.
- `feature/*`, `fix/*`, `docs/*`, `chore/*`: kısa ömürlü çalışma dalları; `dev` tabanlı.

AI çalışma dalı, kod, test, doküman ve commit hazırlayabilir. PR açma, review, onay ve merge insana aittir. Ayrıntı: [Branching ve sürümleme](docs/BRANCHING_RELEASES.md).

## Veri kaynakları ve sorumluluk

Deprem verileri Boğaziçi Üniversitesi Kandilli Rasathanesi ve Deprem Araştırma Enstitüsü (KOERI) kaynaklıdır ve `api.orhanaydogdu.com.tr` aracılığıyla sunulur. Fay hattı verisi GINRAS/AFEAD 2018 veri setinden türetilmiştir. Uygulama resmî bir deprem uyarı sistemi değildir; veriler bilgilendirme amaçlıdır.
