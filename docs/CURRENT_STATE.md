# Güncel Durum

Son güncelleme: 2026-09-21

## Faz

- Faz 1 (temel + sürüm 1.0.0 kapsamı): **Uygulandı** — liste, harita, fay katmanı, Afet Bilinci, Hakkında, yerel cache/retry, testler ve dokümantasyon.
- Faz 2 (fiziksel cihaz kabulü): **Büyük ölçüde tamam** — 1.0.0 App Store'da yayında; 1.0.1 yükleme animasyonu için ürün sahibi cihaz turu bekleniyor.
- Depo ve release kaydı: `github.com/bedirdemir/depremoldu-ios` (private); `main`/`test`/`dev` dalları ve PR akışı kuruldu; PR #1 (`dev -> test`) ve PR #2 (`test -> main`) merge edildi; `main` üzerinde annotated `v1.0.0` tag'i var. Tüm dallarda branch protection (PR zorunlu, force push/deletion kapalı) etkin.

## Doğrulananlar

- `make verify-iteration`: version-check, project-check, paket testleri (57), Development build, app unit testleri (17).
- `make verify`: ek olarak Release build ve UI suite (11 test + 1 mağaza ekran görüntüsü skip).
- Simulator görsel doğrulaması: liste, konum sheet'i, harita, fay katmanı, Afet Bilinci, Hakkında.
- Gömülü `Faults.json`: 5693 fay çizgisi, 46328 nokta (GINRAS/AFEAD 2018) — web `public/FaultData` KMZ dosyalarından script ile üretildi.

## Kabul revizyonu (2026-09-12)

Fiziksel kabul öncesi ürün geri bildirimleri uygulandı: yalnız açık mod, sabit/sol hizalı başlık, ürün ikonu ve marka çizgisi, native sürekli liste (sayfalama kaldırıldı), tam genişlik divider ve sıkı satırlar, nokta üstü map popup'ı, Yenile düğmesinin kaldırılıp açılış yükleme göstergesinin eklenmesi, Hakkında metin/bağlantı güncellemeleri, içeriğe göre boyutlanan konum sheet'i ve son ince ayarlar. Ayrıntı: CHANGELOG `[Unreleased]`, ADR-0009 ve ADR-0010. Fiziksel cihaz turu bu revizyonla tekrarlanacaktır.

## App Store güncelleme kaydı

- 2026-09-21: `1.0.1` (3) güncelleme build'i App Store Connect'e yüklendi (`Upload succeeded`); TestFlight turu atlandı. Kaynak: yerel `fix/system-loading-indicator` çalışma ağacı; değişiklik, açılış/yenileme yükleme göstergesinin sistem varsayılan renkli ve yumuşak animasyonlu hale getirilmesi. Ayrıntı: [docs/releases/1.0.1-app-store.md](releases/1.0.1-app-store.md). Ürün sahibi adımı: App Store Connect'te 1.0.1 sürümü + build 3 + "What's New" ile incelemeye gönderme.

## TestFlight (internal) kaydı

- 2026-09-12: `1.0.0` (build 1), `test` @ `7a486a9` kaynağından App Store Connect'e yüklendi; paket processing. Ayrıntı: [docs/releases/1.0.0-testflight.md](releases/1.0.0-testflight.md).
- 2026-09-12: Build `1.0.0 (2)` (açık kaynak repo bağlantısı revizyonu) TestFlight'ta ürün sahibi tarafından kabul edildi (sorun yok). `test -> main` promotion tamamlandı ve final `v1.0.0` tag'i oluşturuldu.
- App Store gönderimi için her şey hazır: metadata + 6.5" ekran görüntüleri (`docs/appstore/`, 1284×2778; harita karesi tam yüklenmiş olarak yeniden çekildi), gizlilik URL'si `https://depremoldu.org/gizlilik`, upload edilmiş build `1.0.0 (2)`. **App Store Connect formu ve Submit adımı kullanıcıya aittir.**

## Bekleyen insan kabulü

- Fiziksel cihazda 1.0.1 yükleme göstergesi animasyonu.
- App Store Connect'te 1.0.1 sürümünü oluşturup build 3'ü ekleme ve incelemeye gönderme.

## Not Run / açık riskler

- Gerçek cihazda düşük bağlantı ve uzun süreli arka plan davranışı test edilmedi.
- Sağlayıcı API'si (`api.orhanaydogdu.com.tr`) üçüncü taraf; oran sınırı ve kesinti riski uygulama dışıdır. Retry/cache bu riski azaltır.
- Fay verisi statiktir; güncelleme yeni uygulama sürümü gerektirir.
- Android portu başlamadı; bu depo sözleşmelerin kaynağı olacaktır.

## Sıradaki adımlar

1. App Store Connect'te 1.0.1 sürümü + build 3 + "What's New" ile incelemeye gönderme.
2. Fiziksel cihazda 1.0.1 animasyon kabulü.
3. `depremoldu-android` deposunun bu depodaki domain/presentation sözleşmelerinden başlatılması.
