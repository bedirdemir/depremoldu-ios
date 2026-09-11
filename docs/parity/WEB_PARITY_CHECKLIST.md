# Web Parite Kontrol Listesi

Bu değerler web deposundan (`depremolduorg-nuxtjs`) alınmıştır ve testlerle kilitlidir. Android portu da bu tabloyu kullanacaktır.

## Magnitüd sınıfları

| Sınıf | Eşik | Rozet rengi | Metin | Marker yarıçapı | Liste gradyanı |
|---|---|---|---|---|---|
| Küçük | `< 4.0` | `#FDE047` | siyah | 5 pt | `#FDE047` %8.5 -> beyaz %90 |
| Orta | `4.0 – 4.99` | `#EF4444` | beyaz | 7 pt | `#EF4444` %8.5 -> beyaz %90 |
| Büyük | `5.0 – 6.49` | `#7F1D1D` | beyaz | 9 pt | `#7F1D1D` %8.5 -> beyaz %90 |
| Çok Büyük | `>= 6.5` | `#27272A` | beyaz | 11 pt | `#27272A` %8.5 -> beyaz %90 |

## Marka renkleri

- primary: `#EB455F`; secondary: `#2B3467`; krem: `#FCFFE7`; kart zemini: krem %12.5.

## Fay hatları

- Güven renkleri: A `#B91C1C`, B `#EF4444`, C `#F87171`, D `#FCA5A5`.
- Taban ağırlıklar: RATE 1 -> 4, 2 -> 3, 3 -> 2.
- Zoom faktörü: `clamp(0.58 + (zoom - 5) * 0.09, 0.58, 1.25)`.
- Çizgi genişliği: `round(taban * faktör * 100) / 100`; opaklık 0.9.
- Fallback: geçersiz CONF -> C, geçersiz RATE -> 3; 2'den az nokta -> çizgi düşer.

## Göreli zaman (dayjs `tr`)

`saniye < 45` -> "birkaç saniye önce"; `< 90` -> "bir dakika önce"; `dakika < 45` -> "N dakika önce"; `< 90` -> "bir saat önce"; `saat < 22` -> "N saat önce"; `< 36` -> "bir gün önce"; `gün < 26` -> "N gün önce"; `< 46` -> "bir ay önce"; `< 320` -> "round(gün/30) ay önce"; `< 548` -> "bir yıl önce"; aksi halde "round(gün/365) yıl önce". Gelecek anlar "... içinde" alır.

## Görüntü biçimleri

- Magnitüd: tam sayı ise tek ondalık (`2` -> `2.0`), değilse ham (`4.5`), ayırıcı nokta.
- Derinlik: tam sayı ise ondalıksız (`5`), değilse ham (`5.3`); yoksa `-`.
- Tarih: `YYYY.MM.DD`; saat `HH:mm:ss`; satırda `tarih - saat`.
- Sayım: `1-200 / 200 deprem`.

## API sözleşmesi

- `POST https://api.orhanaydogdu.com.tr/deprem/data/search`
- Gövde: `{ provider: "kandilli", sort: "date_-1", skip, limit }`
- Sayfa boyu 100; liste için 200, harita için 500 kayıt; `result` dizisi değilse boş liste.
- Koordinatlar GeoJSON `[lon, lat]` sırasındadır.
