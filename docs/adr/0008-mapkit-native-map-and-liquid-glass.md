# ADR-0008: MapKit taban haritası ve Liquid Glass kapsamı

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

Web, CARTO `light_all` karo katmanını Leaflet ile kullanır. iOS'ta üçüncü taraf harita SDK'sı veya MapKit seçenekleri vardır; iOS 26 Liquid Glass yeni bir sistem yüzeyidir.

## Karar

- Taban harita MapKit `mutedStandard`, POI filtresi kapalı; OSM/CARTO karo katmanı kullanılmaz.
- Marker ve fay çizgileri web görsel kurallarıyla çizilir (renk, yarıçap, kalınlık, opaklık).
- Liquid Glass yalnız işlevsel chrome'da (fay chip'i gibi) ve iOS 26+ için `glassEffect` ile kullanılır; veri yüzeyleri (legend, kartlar) opak kalır. Eski sürümlerde material fallback uygulanır.
- Harita atıfları Apple kurallarına tabidir; web atıf metni (OSM/CARTO) gösterilmez.

## Sonuçlar

- Üçüncü taraf harita bağımlılığı ve tile lisansı yükü yoktur.
- Görsel birebir eşitlik yoktur; bilgi hiyerarşisi ve veri görselleştirmesi korunur.
- Android portunda Google Maps/MapLibre ile aynı marker/fay stil politikası uygulanır.
