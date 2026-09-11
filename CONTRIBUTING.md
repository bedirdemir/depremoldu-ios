# Katkı Rehberi

## Kurulum

```sh
make verify-iteration
```

Hızlı kapı geçmeden commit atılmaz. UI değişikliklerinde ilgili seçili XCUITest de çalıştırılır:

```sh
make ui-test-selected UI_TEST_SELECTOR='DepremOlduAppUITests/DepremOlduAppUITests/testEarthquakeListShowsContentAndLegend'
```

## Dal ve commit

- `dev` tabanlı `feature/*`, `fix/*`, `docs/*`, `chore/*`.
- Conventional Commits: `feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`, `build:`, `ci:`.
- `main`, `test`, `dev` üzerine doğrudan commit atılmaz.

## Kod kuralları

- Swift 6 strict concurrency; uyarılar app target'ta hatadır.
- UI, domain, ağ ve kalıcılık katmanları ayrıdır; view içinde URL kurma, JSON decode veya kalıcı veri yazımı yapılmaz.
- Tüketici metinleri Türkçedir ve web kopyasıyla aynıdır.
- Yeni dosya ekledikten sonra `make project` çalıştırılır ve üretilen proje commit'lenir.

## PR

- Açıklama: ne değişti, neden, nasıl doğrulandı (komut + sonuç), riskler, ekran görüntüleri.
- Aynı PR içinde ilgili dokümantasyon güncellenir.
- Uygulama ve testler yeşil olmadan review istenmez.
