# Ürün Kapsamı ve Web Paritesi

Kaynak ürün: `depremolduorg-nuxtjs` (Nuxt 4 + Vue 3 + Pinia + Tailwind). Web üç sayfadan oluşur: Son Depremler (`/`), Deprem Haritası (`/map`), Afet Bilinci (`/inform`).

## Sürüm 1.0.0 kapsamı

### Son Depremler

| Web davranışı | iOS karşılığı | Durum |
|---|---|---|
| Son 200 deprem listesi (50/sayfa sayfalama) | Son 200 deprem, native sürekli liste + pull-to-refresh | Uygulandı (sayfalama yerine native liste) |
| Büyüklük sınıfı renkleri ve rozeti (ML) | Aynı eşikler, aynı renkler, 64×96 pt rozet | Uygulandı |
| Göreli zaman (dayjs `tr`) | `TurkishRelativeTimeFormatter`, 30 sn tick | Uygulandı |
| Tarih-saat, derinlik, "Konumu görüntüle" | Aynı bilgi satırları; satır tamamı dokunulabilir | Uygulandı |
| "X-Y / N deprem" sayacı | Footer'da aynı metin | Uygulandı |
| "Yenile" butonu | Toolbar butonu + pull-to-refresh | Uygulandı |
| Konum modalı (Leaflet + pin) | MapKit sheet'i + bilgi kartı | Uygulandı |
| Footer atıf ve GitHub bağlantısı | Liste footer'ı + Hakkında ekranı | Uygulandı |
| 15 sn bellek/localStorage cache | 15 sn fresh + 24 saat stale disk cache | Uygulandı (ADR-0005) |

### Deprem Haritası

| Web davranışı | iOS karşılığı | Durum |
|---|---|---|
| Son 500 deprem, büyüklüğe göre yarıçap/renk | Aynı sınıflar: 5/7/9/11 pt, siyah kenar | Uygulandı |
| Türkiye merkezli başlangıç görünümü | `39.13, 35.211` merkez | Uygulandı |
| "SON 500 DEPREM" legend kutusu | Sağ üst legend kartı | Uygulandı |
| Fay hatları katmanı (GINRAS), varsayılan kapalı | "Fay Hatları" chip'i, varsayılan kapalı | Uygulandı |
| CONF renkleri ve RATE/zoom ağırlıkları | `FaultMapStylePolicy` birebir formül | Uygulandı |
| Popup (bölge, zaman, büyüklük, derinlik, koordinat) | Alt seçim kartı + "Detay" sheet'i | Uygulandı |
| OSM/CARTO açık tema | MapKit `mutedStandard` | Native karşılık (ADR-0008) |
| Fay çizgisi popup açıklamaları (uzun bilimsel metin) | — | Kapsam dışı (ADR-0006) |

### Afet Bilinci

| Web davranışı | iOS karşılığı | Durum |
|---|---|---|
| 14 içerik kartı (AFAD, Evrim Ağacı, YouTube, MTA) | Aynı başlık/özet/kaynak/aksiyon ve URL'ler | Uygulandı |
| Kartlar harici sekmede açılır | `SFSafariViewController` sheet'i | Uygulandı |

### Web'de olmayan native eklemeler

- Boş durum, hata durumu ve "Tekrar Dene" eylemi (web hataları sessizce yutar).
- Hakkında ekranı: sürüm, veri kaynakları, sorumluluk notu.
- Çevrimdışıyken stale veri gösterimi ve yenileme hatası bandı.
- Koyu mod desteği.

## Kapsam dışı (bilinçli)

- Push bildirimleri ve deprem uyarıları: backend gerektirir; ADR-0003.
- Hesap, favori/konum kaydetme: web'de yok; ürün kararı bekler.
- Kullanıcı konumu ve yakınımdaki depremler: web'de yok; izin gerektirir.
- Kullanıcıya özel filtre/arama: web'de yok.
- Android: sonraki aşama (`depremoldu-android`, bu depodan kopyalanacak).
- Web sitesinin WebView içinde gösterimi: yasak (AGENTS.md).

## Parite kuralları

- Metinler Türkçe ve web kopyasıyla aynıdır.
- Magnitüd eşikleri, renkleri ve legend sırası değişmez.
- Fay stili formülleri (`0.58 + (zoom-5)*0.09`, `clamp 0.58…1.25`, iki ondalık) değişmez.
- API istek biçimi (`provider=kandilli`, `sort=date_-1`, 100'lük sayfalar) korunur.
- Görsel farklar (sayfalama, popup, taban harita) ADR'lerde gerekçelendirilir.
