# ADR-0010: Native sürekli liste ve marka kimliği

- Durum: Kabul
- Tarih: 2026-09-12
- İlgili: ADR-0009 (bu ADR, 0009'un sayfalama kararını geçersiz kılar)

## Bağlam

ADR-0009 ile listeye web'deki 50'lik sayfalama taşınmıştı. Ürün sahibi bunun fazla “web davranışı” olduğunu değerlendirdi ve native iOS akışını sorguladı. Ayrıca ürün ikonu güncellendi ve sismograf hattının SVG'si hem üst başlıkta hem de "Son Depremler" sekmesinde istenir oldu.

## Karar

1. **Sürekli liste:** Liste 200 kaydı tek akışta gösterir; sayfalama kontrolleri kaldırılmıştır. Veri zaten tek yüklemede geldiği için native sürekli kaydırma doğru davranıştır. Akış ileride büyürse satır sonu görünümünde artımlı yükleme (progressive loading) kullanılacaktır.
2. **Sayaç:** Alt satırda sade `200 deprem` metni kalır.
3. **Ürün ikonu:** `depremolduappicon.png` (2048×2048) App Store ikonunun kaynağıdır; aynı ikon Android portunda kullanılacaktır.
4. **Marka işareti:** Ürün ikonundaki sismograf hattı, sağlanan SVG'den üretilen **raster template** (`BrandMark.imageset`, 1x/2x/3x) olarak üst başlıkta ve Son Depremler sekmesinde kullanılır. iOS 26 cam sekme çubuğu SVG template görseli hatalı çizdiği (dev siyah/kırmızı paralelkenar artefaktları) için SVG sekme ikonundan çıkarıldı; SVG `docs/assets/brand-mark.svg` altında kaynak olarak korunur.
5. **Yenile durumu:** Üst başlıktaki Yenile düğmesi istek sürerken spinner gösterir; aynı anda ikinci istek başlatılmaz.
6. **Görsel sıkılaştırma:** Satır divider'ları tam genişlikte, satır dikey boşluğu yarıya indirildi, sol boşluk azaltıldı, bölge/büyüklük kalınlaştırıldı, legend ile liste arası boşluk kaldırıldı. Satır zemin gradyanı web ile birebir aynı formüldedir.

## Sonuçlar

- Liste native iOS davranışına döndü; web sayfalama paritesi bilinçli olarak terk edildi.
- Marka kimliği tek kaynaktan (ürün ikonu) türetilir ve Android ile paylaşılır.
- Tab bar artefaktı raster template ile giderildi; ileride SVG desteklenirse geri dönüş için SVG kaynak korunur.
