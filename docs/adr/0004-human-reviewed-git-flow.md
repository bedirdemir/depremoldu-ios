# ADR-0004: İnsan onaylı Git akışı

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

Depo ajanlar tarafından da düzenlenmektedir; release ve App Store kararları insana aittir.

## Karar

- Kalıcı dallar `dev -> test -> main`; promotion yalnız PR ile.
- AI çalışma dalı/commit/test/doküman üretebilir; PR açma, review, merge ve tag insana aittir.
- `test` TestFlight kaynağı, `main` App Store kaynağıdır.
- Sürüm kaynağı `Configuration/Base.xcconfig`; `make version-check` ve `CHANGELOG` doğrular.

## Sonuçlar

- Release geçmişi denetlenebilir ve geri alınabilir.
- Ajan hızı insan onay kapılarıyla dengelenir.
