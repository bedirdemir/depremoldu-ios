# ADR-0005: Feed cache, bounded retry ve coalescing

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

Web uygulaması 15 saniyelik bellek/localStorage cache ve tek-uçuş promise paylaşımı kullanır; hata durumunda boş liste gösterir ve retry yapmaz. Native uygulamada çevrimdışı ve düşük bağlantı deneyimi daha önemlidir.

## Karar

- Fresh pencere 15 saniyedir; bu sürede cache'ten dönülür ve ağa çıkılmaz.
- 24 saate kadar stale kayıt kullanılabilir: önce gösterilir, arka planda yenilenir; ağ hatasında kullanıcıya eski veri + hata bandı sunulur.
- Retry yalnız 408/429/500/502/503/504, timeout ve connection-lost için; toplam en fazla 3 deneme; `429/503 Retry-After <= 60 sn` doğrudan, diğerleri `0.5/1.0 sn × 0.8…1.2` jitter.
- Aynı anda gelen tüm yüklemeler tek ağ operasyonunu paylaşır (web `sharedFetchPromise` eşdeğeri).
- Kullanıcı "Yenile" derse fresh cache atlanır (web'de 15 sn içinde atlanmazdı).
- Cache, sağlayıcı ham öğeleri + `fetchedAt` taşıyan sürümlü kayıttır; bozuk/şema uyumsuz kayıt yalnız kendini diskarte eder.

## Sonuçlar

- Web mutlu yol davranışı korunur; offline dayanıklılık artar.
- Sapmalar bu ADR ile kayıtlıdır ve testlerle kilitlidir.
