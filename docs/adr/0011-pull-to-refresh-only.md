# ADR-0011: Yenileme tamamen pull-to-refresh, açılışta üst yükleme göstergesi

- Durum: Kabul
- Tarih: 2026-09-12
- İlgili: ADR-0009 (üst başlıktaki Yenile düğmesi kaldırıldı)

## Bağlam

Üst başlıktaki Yenile düğmesi, pull-to-refresh zaten aynı işi yaptığı için gereksiz görüldü. Ayrıca uygulama açılışında verinin yüklendiği, tam ekran ortadaki spinner yerine pull-to-refresh ile aynı konumdaki (listenin üstü) bir göstergeyle daha anlaşılır anlatılmalıydı.

## Karar

1. Üst başlıktaki Yenile düğmesi kaldırıldı; başlıkta yalnız marka ve Hakkında kalır.
2. Yenileme yalnız pull-to-refresh iledir. Harita sekmesinde manuel yenileme yoktur; sekme açılışında veri otomatik tazelenir (15 sn cache kuralı).
3. Açılışta (içerik yokken) ve stale cache arka planda yeniden doğrulanırken listenin en üstünde bir `ProgressView` satırı gösterilir. Kullanıcının kendi pull-to-refresh hareketi sırasında sistem göstergesi yeterlidir; ek gösterge çizilmez.

## Sonuçlar

- Tek bir yenileme yolu vardır; davranış web'den bilinçli olarak sadeleşir.
- Harita sekmesinde manuel tetikleme olmadığı için ileride gerekirse haritaya özel bir yenileme yüzeyi ayrı kararla eklenir.
- Yükleme durumu, veri alanının (listenin) üstünde gösterilir; tam ekran blokaj yoktur.
