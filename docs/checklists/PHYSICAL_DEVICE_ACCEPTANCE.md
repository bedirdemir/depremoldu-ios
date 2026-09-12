# Fiziksel Cihaz Kabul Listesi

Durum: **Not Run** (bekliyor). Ürün sahibi tarafından doldurulur.

## Ortam

- [ ] Development scheme, gerçek iPhone, canlı API.
- [ ] Wi-Fi ve hücresel veri.
- [ ] Uçak modu (çevrimdışı açılış ve cache).
- [ ] Yavaş/düşük bağlantı (Network Link Conditioner).

## Akışlar

- [ ] İlk açılış: liste yükleniyor, 200 kayıt ve doğru sayım görünüyor.
- [ ] Uygulama ikonu ana ekranda ürün ikonu (`depremolduappicon`) olarak görünüyor.
- [ ] Açılışta listenin üstünde yükleme göstergesi görünüyor, veri gelince kayboluyor.
- [ ] Pull-to-refresh: veri güncelleniyor; üst başlıkta Yenile düğmesi yok.
- [ ] Satıra dokun: konum sheet'i içeriğe sığan kısmi yükseklikte, doğru merkez ve pin ile açılıyor.
- [ ] Harita: 500 marker, sınıf renkleri ve boyutları doğru.
- [ ] Fay Hatları chip'i: veri yükleniyor, çizgiler doğru renk/kalınlıkta; zoom ile kalınlık değişiyor.
- [ ] Marker seçimi: popup noktanın üstünde doğru bilgiyle açılıyor; detay bağlantısı yok.
- [ ] Afet Bilinci: kartlar ve Oku/İzle/Görüntüle uygulama içi Safari'de açılıyor.
- [ ] Hakkında: sürüm, kaynaklar ve bağlantılar doğru.
- [ ] Çevrimdışı: son veri gösteriliyor, hata bandı "Yenile" sunuyor; cache yoksa hata durumu ve "Tekrar Dene".

## Erişilebilirlik

- [ ] Dynamic Type XXXL ve Accessibility 5: metrikler kesilmiyor, rozet okunuyor.
- [ ] VoiceOver: satırlar tek öğe; harita legend ve chip anlamlı.
- [ ] Azaltılmış hareket ve artırılmış kontrast açıkken görünüm bozulmuyor.
- [ ] Cihaz koyu moddayken uygulama açık modda kalıyor (marka görünümü).

## Notlar

- Bulunan sorunlar `fix/*` dalı + regresyon testiyle kapatılır.
- Sonuç: tarih, cihaz modeli, iOS sürümü ve `Not Run` kalan maddeler buraya yazılır.
