# ADR-0003: Backend, hesap, izin ve bildirim yok

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

Sürüm 1.0.0 kapsamı web paritesi ve hızlı yayın hedefiyle belirlendi.

## Karar

- Hesap sistemi, giriş, senkronizasyon yoktur.
- Konum izni istenmez; kullanıcı konumu gerektiren özellik yoktur.
- Push bildirimi ve deprem uyarısı yoktur (backend ve izin gerektirir).
- Analytics/izleme SDK'sı yoktur; yalnız crash'siz, veri toplamayan bir uygulama hedeflenir.

## Sonuçlar

- App Privacy beyanı "veri toplanmıyor" olarak verilebilir; permission wall yoktur.
- Bu özelliklerden biri istenirse yeni ADR, gizlilik güncellemesi ve ürün kabulü gerekir.
