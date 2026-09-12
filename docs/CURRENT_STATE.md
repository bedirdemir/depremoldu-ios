# Güncel Durum

Son güncelleme: 2026-09-12

## Faz

- Faz 1 (temel + sürüm 1.0.0 kapsamı): **Uygulandı** — liste, harita, fay katmanı, Afet Bilinci, Hakkında, yerel cache/retry, testler ve dokümantasyon.
- Faz 2 (fiziksel cihaz kabulü): **Bekliyor** — ürün sahibi cihaz turu.
- Depo ve release kaydı: `github.com/bedirdemir/depremoldu-ios` (private); `main`/`test`/`dev` dalları ve PR akışı kuruldu; PR #1 (`dev -> test`) ve PR #2 (`test -> main`) merge edildi; `main` üzerinde annotated `v1.0.0` tag'i var. Tüm dallarda branch protection (PR zorunlu, force push/deletion kapalı) etkin.

## Doğrulananlar

- `make verify-iteration`: version-check, project-check, paket testleri (56), Development build, app unit testleri (14).
- `make verify`: ek olarak Release build ve UI suite (8 test).
- Simulator görsel doğrulaması: liste, konum sheet'i, harita, fay katmanı, Afet Bilinci, Hakkında.
- Gömülü `Faults.json`: 5693 fay çizgisi, 46328 nokta (GINRAS/AFEAD 2018) — web `public/FaultData` KMZ dosyalarından script ile üretildi.

## Kabul revizyonu (2026-09-12)

Fiziksel kabul öncesi ürün geri bildirimleri uygulandı: yalnız açık mod, sabit/sol hizalı başlık, ürün ikonu ve marka çizgisi, native sürekli liste (sayfalama kaldırıldı), tam genişlik divider ve sıkı satırlar, nokta üstü map popup'ı, Yenile düğmesinin kaldırılıp açılış yükleme göstergesinin eklenmesi, Hakkında metin/bağlantı güncellemeleri, içeriğe göre boyutlanan konum sheet'i ve son ince ayarlar. Ayrıntı: CHANGELOG `[Unreleased]`, ADR-0009 ve ADR-0010. Fiziksel cihaz turu bu revizyonla tekrarlanacaktır.

## Bekleyen insan kabulü

- Fiziksel iPhone'da canlı API akışı, çevrimdışı davranış, Dynamic Type ve VoiceOver turu.
- App Store Connect'te bundle ID kaydı, TestFlight upload ve ekran görüntüleri.
- `test` -> `main` promotion ve `v1.0.0` tag.

## Not Run / açık riskler

- Gerçek cihazda düşük bağlantı ve uzun süreli arka plan davranışı test edilmedi.
- Sağlayıcı API'si (`api.orhanaydogdu.com.tr`) üçüncü taraf; oran sınırı ve kesinti riski uygulama dışıdır. Retry/cache bu riski azaltır.
- Fay verisi statiktir; güncelleme yeni uygulama sürümü gerektirir.
- Android portu başlamadı; bu depo sözleşmelerin kaynağı olacaktır.

## Sıradaki adımlar

1. Fiziksel cihaz kabul turu ve düzeltmeleri.
2. TestFlight iç test upload'ı.
3. App Store metadata, gizlilik formu ve ekran görüntüleri.
4. `depremoldu-android` deposunun bu depodaki domain/presentation sözleşmelerinden başlatılması.
