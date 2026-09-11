# ADR-0007: Türkçe metinler ve Open Sans

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

Web ürünü yalnız Türkçedir ve tüm arayüz Open Sans (300/400/500/700/800) kullanır.

## Karar

- Arayüz metinleri Türkçedir ve web kopyasıyla aynıdır; ek localization katmanı sürüm 1.0.0'da yoktur.
- Open Sans Regular/Medium/SemiBold/Bold statik kesitleri OFL lisansıyla paketlenir; `Font.custom(_:size:relativeTo:)` ile Dynamic Type'a bağlanır.
- Sistem kontrolleri (tab bar, navigation) Apple fontunu kullanır; metin içeriği Open Sans'tır.

## Sonuçlar

- Marka tipografisi korunur; Dynamic Type çalışır.
- İngilizce/çoklu dil ihtiyacı doğarsa String Catalog ve çeviri süreci ayrı iş olarak eklenir.
