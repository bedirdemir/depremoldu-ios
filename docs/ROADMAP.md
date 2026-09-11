# Yol Haritası

## Faz 1 — Native sürüm 1.0.0 (tamamlandı)

- [x] Domain, networking, persistence, repository, faults paketleri ve testleri
- [x] Son Depremler listesi + konum sheet'i
- [x] Deprem Haritası + 500 marker + GINRAS fay katmanı + legend
- [x] Afet Bilinci (14 kart) + Hakkında/atıf
- [x] Yerel cache, bounded retry, request coalescing
- [x] App icon, Open Sans, koyu mod, erişilebilirlik etiketleri
- [x] Dokümantasyon ve CI workflow'u

## Faz 2 — Saha kabulü (devam ediyor)

- [ ] Fiziksel iPhone kabul turu (canlı API, çevrimdışı, düşük bağlantı)
- [ ] Dynamic Type ve VoiceOver manuel doğrulaması
- [ ] TestFlight internal upload + smoke test
- [ ] App Store metadata ve ekran görüntüleri

## Faz 3 — Yayın

- [ ] `test -> main` promotion, `v1.0.0` tag
- [ ] App Store review ve yayın
- [ ] Yayın sonrası hata/geri bildirim döngüsü

## Faz 4 — Android portu

- [ ] `depremoldu-android` reposunun bu depodaki domain sözleşmeleri, görsel token'lar ve ağ fixture'larıyla başlatılması
- [ ] Kotlin + Compose; aynı eşikler, renkler, formüller ve test matrisi
- [ ] Google Maps/MapLibre fay katmanı ve marker paritesi

## Açık ürün soruları

- Deprem bildirimi (push) istenirse backend ve izin gerektirir; sahibi: ürün sahibi, tetikleyici: yayın sonrası geri bildirim, koşul: ayrı ADR (ADR-0003).
- Kullanıcı konumu / "yakınımdaki depremler": sahibi: ürün sahibi; karar yok.
- Favori bölge filtresi: sahibi: ürün sahibi; web'de olmadığı için varsayılan kapsam dışı.
