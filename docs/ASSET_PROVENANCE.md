# Varlık Kaynakları ve Lisanslar

Bu belge uygulama paketindeki üçüncü taraf varlıkları ve doğrulama tarihini tutar.

## Open Sans fontları

- Dosyalar: `Apps/DepremOldu/Resources/Fonts/OpenSans-{Regular,Medium,SemiBold,Bold}.ttf`
- Kaynak: [googlefonts/opensans](https://github.com/googlefonts/opensans) (Regular, SemiBold, Bold) ve Google Fonts değişken fontundan `fontTools varLib.instancer` ile üretilen Medium (wght 500) kesiti.
- Lisans: SIL Open Font License 1.1 (`Fonts/OFL.txt` pakete dahildir).
- Doğrulama: 2026-09-12.

## App simgesi

- Kaynak: web deposu `public/android-chrome-512x512.png` (depremoldu.org marka işareti).
- Üretim: `scripts/build_app_icon.py` piksel sınıflandırması ile 1024×1024 keskin ikon üretir; marka renkleri `#FCFFE7` zemin ve `#EB455F` çizgidir.
- Sahiplik: depremoldu.org projesi.

## Fay hattı verisi

- Kaynak: web deposu `public/FaultData/AFEAD_*.kmz` (GINRAS/AFEAD 2018 diri fay verisi).
- Üretim: `scripts/build_fault_data.py` KMZ -> `Apps/DepremOldu/Resources/Faults.json` (5693 çizgi, 46328 nokta, ~1.1 MiB). Uzun bilimsel referans blokları bilinçli olarak çıkarılmıştır (ADR-0006).
- Atıf: harita legend'ında ve Hakkında ekranında "GINRAS/AFEAD" olarak görünür.

## Deprem verisi

- Kaynak: Boğaziçi Üniversitesi Kandilli Rasathanesi ve Deprem Araştırma Enstitüsü (KOERI) verisi; `api.orhanaydogdu.com.tr` aracılığıyla.
- Lisans/atıf: uygulama içinde liste footer'ı ve Hakkında ekranında belirtilir.
- Veri pakete gömülmez; her istek kullanıcı cihazından yapılır.

## Harita

- Apple MapKit standart haritası; Apple'ın harita atıf kuralları geçerlidir. Web'deki OSM/CARTO karo katmanı kullanılmaz (ADR-0008).

## Kural

Yeni varlık eklenmeden önce kaynak, lisans, sahiplik ve doğrulama tarihi bu belgeye işlenir. Lisansı doğrulanmamış görsel/içerik App Store release'ine giremez.
