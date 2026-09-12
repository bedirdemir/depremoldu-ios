# Varlık Kaynakları ve Lisanslar

Bu belge uygulama paketindeki üçüncü taraf varlıkları ve doğrulama tarihini tutar.

## Open Sans fontları

- Dosyalar: `Apps/DepremOldu/Resources/Fonts/OpenSans-{Regular,Medium,SemiBold,Bold}.ttf`
- Kaynak: [googlefonts/opensans](https://github.com/googlefonts/opensans) (Regular, SemiBold, Bold) ve Google Fonts değişken fontundan `fontTools varLib.instancer` ile üretilen Medium (wght 500) kesiti.
- Lisans: SIL Open Font License 1.1 (`Fonts/OFL.txt` pakete dahildir).
- Doğrulama: 2026-09-12.

## App simgesi ve marka işareti

- Kaynak: web deposu `public/depremolduappicon.png` (2048×2048, ürün ikonu; `#FCFFE7` zemin + `#EB455F` çizgi).
- Üretim: `scripts/build_app_icon.py` ikonu 1024×1024 App Store varlığına indirir ve alfa kanalını krem zemine düzler. Aynı ikon Android portunda da kullanılacaktır.
- Marka işareti (çizgi): `docs/assets/brand-mark.svg` (ürün ikonundaki sismograf hattı); `scripts/build_brand_mark.py` bu hattı saydam zeminli, 1x/2x/3x template PNG'lere dönüştürür (`BrandMark.imageset`). Üst başlıkta ve "Son Depremler" sekmesinde kullanılır.
- Sahiplik: depremoldu.org projesi.

## Fay hattı verisi

- Kaynak: web deposu `public/FaultData/AFEAD_*.kmz` (GINRAS/AFEAD 2018 diri fay verisi).
- Üretim: `scripts/build_fault_data.py` KMZ -> `Apps/DepremOldu/Resources/Faults.json` (5693 çizgi, 46328 nokta, ~1.1 MiB). Uzun bilimsel referans blokları bilinçli olarak çıkarılmıştır (ADR-0006).
- Atıf: harita legend'ında ve Hakkında ekranında "GINRAS/AFEAD" olarak görünür; bağlantı `http://neotec.ginras.ru/` adresine gider.

## Deprem verisi

- Kaynak: Boğaziçi Üniversitesi Kandilli Rasathanesi ve Deprem Araştırma Enstitüsü (KOERI) verisi; `api.orhanaydogdu.com.tr` aracılığıyla.
- Lisans/atıf: uygulama içinde liste footer'ı ve Hakkında ekranında belirtilir.
- Veri pakete gömülmez; her istek kullanıcı cihazından yapılır.

## Harita

- Apple MapKit standart haritası; Apple'ın harita atıf kuralları geçerlidir. Web'deki OSM/CARTO karo katmanı kullanılmaz (ADR-0008).

## Kural

Yeni varlık eklenmeden önce kaynak, lisans, sahiplik ve doğrulama tarihi bu belgeye işlenir. Lisansı doğrulanmamış görsel/içerik App Store release'ine giremez.
