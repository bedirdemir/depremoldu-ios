# Apple Hesap ve Yayın Rehberi

Bu belge TestFlight ve App Store dağıtımı için operasyonel adımları listeler. Uygulama tarafı hazırdır; hesap ve upload adımları ürün sahibi tarafından yapılır.

## Kimlik

- Bundle ID: `org.depremoldu.app` (`Configuration/Base.xcconfig`).
- Display name: "Deprem Oldu".
- Kategori: Hava Durumu (`public.app-category.weather`).
- Tüm veriler kullanıcı cihazından çekilir; sunucu altyapısı yoktur.

## Ön koşullar

1. Apple Developer Program üyeliği.
2. App Store Connect'te `org.depremoldu.app` bundle ID kaydı ve "Deprem Oldu" uygulama kaydı.
3. Xcode'da Apple ID oturumu; fiziksel cihaz için `Configuration/Local.xcconfig` içine Team ID.

## TestFlight akışı

```sh
make version-check
make verify            # dondurulmuş exact ağaçta bir kez
```

Sonra:

1. `test` dalı checkout edilir.
2. Xcode'da `DepremOldu-Release` scheme'i ile "Any iOS Device (arm64)" hedefinde Archive alınır.
3. Organizer -> Distribute App -> App Store Connect -> Upload.
4. App Store Connect'te build "Complete" olana kadar beklenir; What to Test ve test notları girilir.
5. Internal tester (ürün sahibi) smoke testi yapar.

## App Store metadata kontrolü

- Açıklama, anahtar kelimeler, destek URL'si, pazarlama URL'si (`https://www.depremoldu.org`).
- Ekran görüntüleri: Son Depremler, Harita (fay katmanı açık), Afet Bilinci, Hakkında.
- Yaş derecelendirmesi anketi.
- App Privacy: veri toplanmaz, izleme yok.
- `ITSAppUsesNonExemptEncryption = NO` (yalnız HTTPS/Apple güvenliği ve SHA-256).
- Sorumluluk notu: uygulama resmî uyarı sistemi değildir; açıklamada ve Hakkında ekranında yer alır.

## Build numarası

- Her upload öncesi `Configuration/Base.xcconfig` içindeki `CURRENT_PROJECT_VERSION` artırılır.
- Daha önce başarılı upload olmadığı için başlangıç değeri `1`dir.

## Release sonrası

- `test -> main` PR'ı, sonra annotated `v1.0.0` tag'i.
- `CHANGELOG.md` tarihli bölümü release ile eşleşir.
