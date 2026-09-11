# ADR-0009: Kabul revizyonu — açık mod, sabit başlık, sayfalama ve map popup

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

İlk cihaz turu öncesi ürün sahibi görsel/deneyim geri bildirimi verdi: koyu mod gerekmiyor, üst başlık sekme geçişlerinde animasyon üretiyor ve logo ortada duruyor, haritada detay alt kart yerine nokta üzerinde popup olmalı, liste daha sıkı olmalı ve gerçek sayfalama içermeli, liste altı atıf metinleri Hakkında'ya taşınmalı.

## Karar

1. **Yalnız açık mod:** `UIUserInterfaceStyle = Light` ve `preferredColorScheme(.light)`; koyu palet kaldırıldı.
2. **Sabit başlık:** Marka, Yenile ve Hakkında öğeleri `TabView` dışında tek bir özel başlıkta toplandı; logo sola hizalandı. Böylece sekme geçişlerinde başlık yeniden kurulmaz/animasyon üretmez. Yenile yalnız Son Depremler ve Harita sekmelerinde görünür (web paritesi).
3. **Sayfalama:** Liste, web'deki 50'lik sayfalamayı kullanır (Önceki/Sonraki + sayfa numaraları, `1-50 / 200 deprem` sayımı, sayfa değişiminde başa kaydırma). Web'in 200 kayıtlık liste sınırı korunur.
4. **Map popup:** Seçim, alt kart yerine `MKMapView` callout'u olarak noktanın üstünde gösterilir; içerik SwiftUI ile çizilir ve Dynamic Type'tan bağımsız sabit boyuttadır. "Detay" bağlantısı kaldırıldı.
5. **Sadeleştirme:** Liste altındaki atıf/bağlantı bloğu kaldırıldı; veri atıfı + API kullanım bilgisi Hakkında'nın ilk bölümüne, API bağlantısı Bağlantılar bölümüne taşındı. Afet Bilinci kapanış metni genişletildi ve Hakkında'ya eklendi.
6. **Yoğunluk:** Satır içi boşluklar ve puntolar web mobil ölçülerine indirildi; koordinatlar kayan nokta artıklarından arındırıldı.

## Sonuçlar

- Deneyim web diline yaklaşır ve cihaz kabulü öncesi geri bildirim kapandı.
- Koyu mod istenirse yeni ADR ile ayrı palet çalışması gerekir.
- Popup içeriği sabit boyutta olduğundan çok büyük Dynamic Type'ta büyümez; erişilebilir eşdeğer bilgi liste ve konum sheet'inde tam Dynamic Type ile sunulur.
