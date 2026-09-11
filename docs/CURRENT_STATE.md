# Güncel Durum

Son güncelleme: 2026-09-12

## Faz

- Faz 1 (temel + sürüm 1.0.0 kapsamı): **Uygulandı** — liste, harita, fay katmanı, Afet Bilinci, Hakkında, yerel cache/retry, testler ve dokümantasyon.
- Faz 2 (fiziksel cihaz kabulü): **Bekliyor** — ürün sahibi cihaz turu.

## Doğrulananlar

- `make verify-iteration`: version-check, project-check, paket testleri (56), Development build, app unit testleri (14).
- `make verify`: ek olarak Release build ve UI suite (8 test).
- Simulator görsel doğrulaması: liste, konum sheet'i, harita, fay katmanı, Afet Bilinci, Hakkında.
- Gömülü `Faults.json`: 5693 fay çizgisi, 46328 nokta (GINRAS/AFEAD 2018) — web `public/FaultData` KMZ dosyalarından script ile üretildi.

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
