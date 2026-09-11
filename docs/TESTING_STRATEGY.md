# Test Stratejisi

## Katmanlar

| Katman | Araç | Kapsam |
|---|---|---|
| Paket domain | Swift Testing | Magnitüd eşikleri, biçimlendirme, TR göreli zaman merdiveni, tarih normalizasyonu, koordinat doğrulaması, fay fallback/stil formülleri |
| Paket networking | Swift Testing + URLProtocol/stub | Endpoint gövdesi, lossy DTO decode, mapper, HTTP 200/200-dışı, `Retry-After`, transport hataları |
| Paket repository | Swift Testing | Fresh/stale cache, bozuk/expired cache, retry allowlist + backoff, coalescing, cache yazımı |
| App unit | Swift Testing (hosted) | Feed model durumları, liste/harita limitleri, sayım metni, refresh hatası korunumu, fay modeli, içerik sözleşmesi, UI fixture |
| App UI | XCUITest (`TESTING` fake repo) | Liste + legend, satırdan konum sheet'i, harita + legend + fay chip'i, Afet Bilinci kartları, Hakkında, hata/boş durum, yenile |
| Fiziksel cihaz | Manuel checklist | Gerçek API, çevrimdışı, düşük internet, Dynamic Type, VoiceOver, koyu mod |

## Determinizm kuralları

- Ağ erişimi yalnız fiziksel cihaz kabulündedir; testlerde gerçek internet kullanılmaz.
- Saat, saat dilimi ve jitter enjekte edilir (`DateProviding`, `EarthquakeRetrySleeping`, `EarthquakeRetryJitterProviding`).
- UI testleri Test yapılandırmasında sabit fixture'larla çalışır; `-depremoldu-ui-failure` ve `-depremoldu-ui-empty` launch argümanları hata/boş durumu tetikler. Bu yollar `#if TESTING` içindedir; Release build'de yoktur.
- Fixture'lar gerçek sağlayıcı yanıtından türetilir ve şema değişikliğinde birlikte güncellenir.

## Komutlar

```sh
make verify-iteration   # version + project-check + paket testleri + build + app unit testleri
make verify             # ek olarak Release build + tüm UI suite
make ui-test-selected UI_TEST_SELECTOR='DepremOlduAppUITests/DepremOlduAppUITests/testMapTabShowsLegendAndFaultToggle'
```

Proje tazeliği: `make project-check`, `scripts/generate_xcodeproj.py` çıktısını commit'le karşılaştırır; kaynak dosya eklenip proje güncellenmezse kapı kırmızı olur.

## Kritik test matrisi

- Magnitüd sınırları: 3.99/4.0/4.99/5.0/6.49/6.5.
- Sayfalama: 50'lik dilimler, sayfa sayısı, sınır kırpma, refresh sonrası küçülen içerikte sayfa düzeltmesi, `1-50 / 200 deprem` sayımı.
- Koordinat biçimi: kayan nokta artıkları temizlenir (`39.160000000000004` -> `39.16`).
- Göreli zaman sınırları: 44/45/89/90 sn, 44/45/89/90 dk, 21/22/35/36/25/26/45/46 gün, 319/320/547/548 gün, gelecek zaman.
- Eksik/bozuk alanlar: `mag` yok, `depth` yok, koordinat dizisi bozuk, `result` nesne, JSON bozuk, `mag` string.
- Saat dilimi: `Europe/Istanbul` ile epoch dönüşümü; geçersiz saat dilimi fallback'i.
- Cache: fresh (<15 sn), stale (1 saat), süresi geçmiş (>24 saat), gelecek tarihli, bozuk kayıt.
- Retry: 503/429/500 allowlist, 404 non-retry, Retry-After 12 sn, backoff 0.5/1.0 sn, max 3 deneme.
- Fay: geçersiz CONF/RATE fallback C/3, tek noktalı çizgi düşürme, sürüm uyumsuzluğu, zoom clamp ve iki ondalık yuvarlama.

## Not Run politikası

Simulator'da doğrulanamayan gerçek ağ, düşük bağlantı, pil ve fiziksel dokunma davranışları `docs/checklists/PHYSICAL_DEVICE_ACCEPTANCE.md` ile cihaz turuna bırakılır ve açıkça `Not Run` yazılır.
