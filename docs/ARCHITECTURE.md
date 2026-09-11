# Hedef Mimari

Bu belge Deprem Oldu iOS uygulamasının katmanlarını, bağımlılık yönünü ve veri akışını tanımlar. Durum: ilk sürüm (1.0.0) uygulanmıştır.

## Teknoloji tabanı

- Swift 6 language mode, strict concurrency; app target'ta uyarılar hatadır.
- SwiftUI app lifecycle; karmaşık harita yüzeyi için `MKMapView` köprüsü.
- MapKit taban haritası, `MKMultiPolyline` fay katmanı, `SFSafariViewController` harici içerik.
- iPhone deployment target iOS 18+. Liquid Glass yalnız iOS 26+ için availability-guarded `glassEffect` ile işlevsel katmanda kullanılır; eski sürümlerde material fallback uygulanır.
- Swift Testing paket/domain testleri, XCTest hosted app testleri ve XCUITest UI testleri için kullanılır.
- Üçüncü taraf runtime bağımlılığı yoktur. Fontlar (Open Sans, OFL) paketlenir.

## Depo yapısı

```text
depremoldu-ios/
├── AGENTS.md
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── Makefile
├── DepremOldu.xcodeproj          # scripts/generate_xcodeproj.py tarafından üretilir
├── Apps/
│   └── DepremOldu/
│       ├── Application/          # app entry, dependency composition, shell, tema
│       ├── Features/
│       │   ├── Earthquakes/      # liste + konum sheet'i
│       │   ├── Map/              # MapKit köprüsü, fay katmanı, legend
│       │   ├── Awareness/        # statik afet bilinci içeriği
│       │   └── About/            # atıf ve sürüm bilgisi
│       └── Resources/
│           ├── Assets.xcassets/
│           ├── Fonts/            # Open Sans statik kesitler + OFL
│           └── Faults.json       # GINRAS/AFEAD gömülü veri seti
├── Packages/
│   └── DepremOlduCore/
│       ├── Sources/
│       │   ├── DepremOlduDomain/       # modeller, sınıflandırma, TR göreli zaman
│       │   ├── DepremOlduNetworking/   # HTTP primitive + Kandilli contract
│       │   ├── DepremOlduPersistence/  # atomik dosya store'u
│       │   ├── DepremOlduRepository/   # cache/retry/coalescing event akışı
│       │   ├── DepremOlduFaults/       # fay veri modeli, decoder, stil politikası
│       │   └── DepremOlduTestSupport/  # fixture + stub repository
│       └── Tests/
│           ├── DepremOlduDomainTests/
│           ├── DepremOlduNetworkingTests/
│           ├── DepremOlduPersistenceTests/
│           ├── DepremOlduRepositoryTests/
│           └── DepremOlduFaultsTests/
├── Tests/
│   ├── DepremOlduAppTests/
│   └── DepremOlduAppUITests/
├── Configuration/                # Base/Debug/Test/Release xcconfig
├── scripts/                      # proje üretimi, fay verisi, ikon, versioning
├── .github/workflows/ios.yml
└── docs/
```

Bağımlılık yönü:

```text
DepremOldu (app) -> Domain + Faults + Networking + Persistence + Repository
DepremOlduRepository -> Domain + Networking + Persistence
DepremOlduNetworking -> Domain
DepremOlduFaults -> Domain
DepremOlduTestSupport -> Domain + Networking + Repository
```

## Veri akışı

```text
API:  iPhone -> api.orhanaydogdu.com.tr/deprem/data/search (POST, sayfa 100 x 5 = 500 kayıt)
Repo: EarthquakeRepository (fresh 15 sn, stale 24 saat, max 3 deneme, tek-uçuş coalescing)
App:  EarthquakeFeedFeatureModel (@Observable, MainActor) -> liste (200) / harita (500)
Fay:  Faults.json (paket) -> FaultDatasetJSONDecoder -> 12 MKMultiPolyline (4 güven × 3 oran)
```

### Domain

- `Earthquake`: sağlayıcıdan bağımsız, normalize model; `MagnitudeClass` sınıflandırması web eşikleriyle (`>= 6.5 / >= 5.0 / >= 4.0`) aynıdır.
- `formattedMagnitude` ve `formattedDepth` web görüntü biçimini birebir korur (tam sayı magnitüd tek ondalıkla, ayırıcı nokta).
- `TurkishRelativeTimeFormatter` dayjs `tr` merdivenini uygular (`birkaç saniye önce` … `N yıl önce`); enjekte edilen referans an ile deterministiktir.
- `EarthquakeDisplayDateNormalizer` sağlayıcı `date_time` değerini `location_tz` saat diliminde ayrıştırır; geçersiz giriş `nil` olur ve arayüz `-` gösterir.
- `GeoCoordinate` yalnız finite ve aralık içi değerleri kabul eder; geçersiz koordinat satırı listede kalır ama haritada gösterilmez (web'in finite filtresiyle aynı niyet).

### Networking

- `HTTPClient` protokolü ve `URLSessionHTTPClient`: ephemeral configuration, kapalı cache/cookie/credential, 30 sn timeout, gövde boyutu sınırı, `CancellationError` koruması ve typed transport hataları.
- `KandilliEarthquakeEndpoint`: JSON POST gövdesi (`provider`, `sort`, `skip`, `limit`) ve URL üretimi.
- `KandilliEarthquakeDTO` ailesi: eksik/bozuk alanlarda web `Number()`/`Array.isArray` davranışını taklit eden lossy decode; `result` dizisi değilse boş liste.
- `KandilliEarthquakeMapper`: DTO -> Domain; `mag` eksikse `0`, `depth` eksikse `-`, tarih `YYYY.MM.DD` biçimine normalize edilir.
- HTTP 200 dışı yanıtlar `Retry-After` (saniye) ile typed hata olur; retry kararı repository katmanındadır.

### Persistence

- `FilePersistenceStore`: actor-isolated, atomik yazma, SHA-256 dosya adı, `nil` ile silme.
- Cache dizini `Application Support/DepremOldu/EarthquakeCache/v1`; backup dışı ve `.completeUntilFirstUserAuthentication` korumalıdır.

### Repository

- `EarthquakeRepository` 5 sayfayı paralel çeker; aynı anda gelen tüm isteklere tek operasyon hizmet eder (`EarthquakeFeedCoalescer`).
- Cache sözleşmesi: `fetchedAt` + sağlayıcı ham öğeleri (`EarthquakeCacheRecordV1`, schema ve provider raw). 15 saniyeye kadar fresh, 24 saate kadar stale kabul edilir; gelecek/bozuk/şema uyumsuz kayıt silinir.
- Bozuk veya süresi geçmiş cache yalnız bu kaydı diskarte eder; ağ sonucu yine yayınlanır.
- Retry allowlist: 408/429/500/502/503/504, timeout ve connection-lost; en fazla 3 deneme. `429/503 Retry-After <= 60 sn` doğrudan kullanılır, diğerleri `0.5/1.0 sn × 0.8…1.2` jitter'lı backoff'tur.
- Yayın akışı: fresh cache erken döner; stale cache önce gösterilir, ardından `refreshing` ve ağ sonucu; ağ hatasında stale korunur (`refreshFailed`), kullanılabilir cache yoksa `terminalFailure` olur.
- Web paritesinden kasıtlı sapmalar ADR-0005'te kayıtlıdır: stale-while-revalidate, bounded retry ve force-refresh fresh cache'i atlar.

### Faults

- `Faults.json` sürümlü özel biçim: `{version, source, lines:[{name, c, r, p:[[lon,lat],…]}]}`.
- `FaultDatasetJSONDecoder` geçersiz confidence/rate değerlerini web fallback'iyle (`C`/`3`) düzeltir; 2'den az noktalı çizgileri düşürür.
- `FaultMapStylePolicy` web formüllerini taşır: renkler `A->#b91c1c B->#ef4444 C->#f87171 D->#fca5a5`, taban ağırlık `1->4 2->3 3->2`, zoom faktörü `clamp(0.58 + (zoom-5)*0.09, 0.58, 1.25)`, iki ondalık yuvarlama; `EarthquakeMapBridge` zoom'u `log2(360 / longitudeDelta)` ile türetir.

### App composition ve Presentation

- `AppDependencies` production zincirini (URLSession -> Kandilli service -> repository -> FilePersistenceStore) ve gömülü fay provider'ını kurar; hazırlık hatası crash yerine typed terminal durum olur.
- `AppShellModel` üç sekmeyi (Son Depremler, Harita, Afet Bilinci), liste/konum sheet sunumunu ve Hakkında sheet'ini sahiplenir.
- `EarthquakeFeedFeatureModel` MainActor izole, monoton generation ile geç event'leri izole eder; liste 200, harita 500 kaydı gösterir; refresh hatası içeriği düşürmez.
- Sunum durumları ayrıdır: `loading` (içerik yok), `content` (fresh/stale + refresh state), `failure` (içerik yok). Sayım metni web'deki gibi `1-200 / 200 deprem` biçimindedir.
- `EarthquakeMapFeatureModel` fay veri setini ilk görünümde bir kez yükler; katman varsayılan kapalıdır (web'deki başlangıç davranışı) ve chip ile açılır.
- Göreli zamanlar 30 saniyelik tick ile canlı tutulur.

### MapKit köprüsü

- `EarthquakeMapBridge` `UIViewRepresentable`; annotation'lar yalnız veri kimliği değiştiğinde yeniden kurulur.
- Marker: web `circleMarker` görünümü; sınıf başına yarıçap 5/7/9/11 pt, ~2.5 pt siyah kenar, seçilide 1.35× ölçek.
- Fay katmanı güven × oran başına en fazla 12 `MKMultiPolyline` olarak eklenir; zoom değişiminde renderer genişlikleri web formülüyle güncellenir.
- Seçim iki yönlüdür: harita dokunuşu alt kartı açar, kart kapatıldığında annotation seçimi kalkar.

## Concurrency

- UI state MainActor'da; ağ/parse/cache structured concurrency ile.
- Fay veri çözümü `Task.detached` içinde main dışında çalışır.
- View kaybolduğunda feed/fay görevleri iptal edilir; koordinat/sekme değişiminde eski cevap yeni durumu ezemez.
- `Sendable` ihlalleri sessiz `@unchecked` ile kapatılmaz.

## Yapılandırma

- Debug/`DepremOldu-Development`: geliştirme ve local simulator akışı (canlı API).
- Test/`DepremOldu-Test`: deterministic fake repository (`TESTING`); ağ yoktur.
- Release/`DepremOldu-Release`: production optimizasyonu; backdoor yoktur.
- Ortam seçimi derleme zamanı `.xcconfig` iledir; secret değildir.
- `Base.xcconfig` ignored `Configuration/Local.xcconfig` dosyasını optional ve en son include eder.

## Tasarım ve erişilebilirlik

- Renk token'ları web ile aynıdır: primary `#EB455F`, secondary `#2B3467`, krem `#FCFFE7`, magnitüd renkleri `#FDE047 / #EF4444 / #7F1D1D / #27272A`.
- Magnitüd sınıflandırması renk + etiketle birlikte verilir; renk tek başına anlam taşımaz.
- Liste satırları VoiceOver'da tek öğe olarak okunur (magnitüd, bölge, zaman, derinlik) ve "Konumunu haritada açar" ipucu taşır.
- Open Sans fontları Dynamic Type ile ölçeklenir (`Font.custom(_:size:relativeTo:)`).
- Koyu mod ayrı paletle desteklenir; açık mod web görünümünün birebiridir.
- En az 44×44 pt dokunma hedefleri korunur.

## Web paritesi doğrulaması

- Domain paritesi: gerçek sağlayıcı fixture'ları + eşik/biçim unit testleri.
- Sunum paritesi: liste bilgi hiyerarşisi, legend sınıfları, fay renk/ağırlık formülleri, Afet Bilinci kart metinleri.
- Native kalite: HIG, erişilebilirlik ve fiziksel cihaz kabul testi.
- Piksel eşitliği kabul kapısı değildir.
