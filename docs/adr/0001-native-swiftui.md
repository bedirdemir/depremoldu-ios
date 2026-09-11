# ADR-0001: Native SwiftUI ve iOS 18 tabanı

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

Web ürünü Nuxt/Vue ile yazılmıştır; iOS uygulaması için WebView sarmalayıcı, cross-platform (React Native/Flutter) veya native SwiftUI seçenekleri vardır.

## Karar

- SwiftUI birinci sınıf UI; UIKit yalnız `MKMapView` ve `SFSafariViewController` köprülerinde.
- Deployment target iOS 18; Liquid Glass yalnız iOS 26+ availability ile işlevsel katmanda (chip, toolbar), veri yüzeyleri opak kalır.
- Koyu mod desteklenir; açık mod web paletinin birebiridir.

## Sonuçlar

- Apple platform davranışı ve erişilebilirlik doğal olarak elde edilir.
- iOS 18 tabanı pazar kapsamını geniş tutar; Liquid Glass eski sürümlerde material fallback'e iner.
- Android'de aynı domain sözleşmeleri kullanılacak; UI bağımsız yazılacaktır.
