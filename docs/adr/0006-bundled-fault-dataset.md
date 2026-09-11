# ADR-0006: Gömülü fay veri seti ve sadeleştirilmiş içerik

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

Web, `public/FaultData/AFEAD_*.kmz` dosyalarını Leaflet KMZ eklentisiyle çalışma zamanında yükler. Dosyalar toplam ~4.2 MB KML içerir ve uzun bilimsel referans blokları taşır.

## Karar

- Fay verisi derleme zamanında `Faults.json` olarak dönüştürülür ve pakete gömülür (5693 çizgi, 46328 nokta, ~1.1 MiB).
- Koordinatlar 5 ondalığa yuvarlanır; çizgi adı (varsa), CONF ve RATE korunur; uzun referans/açıklama blokları çıkarılır.
- Çizgi popup'ı yerine yalnız legend, kaynak notu ve katman görünürlüğü sunulur. Fay çizgisine dokunarak ayrıntı gösterme kapsam dışıdır.
- CONF/RATE fallback'i web ile aynıdır: geçersiz güven -> C, geçersiz oran -> 3; 2'den az nokta -> çizgi düşer.

## Sonuçlar

- Harita çevrimdışı ve hızlıdır; çalışma zamanı KMZ/KML parse yükü yoktur.
- Veri güncellemesi yeni uygulama sürümü gerektirir; script (`scripts/build_fault_data.py`) yeniden çalıştırılır.
- Bilimsel açıklama metinleri uygulamada yoktur; kaynak atıfı korunur.
