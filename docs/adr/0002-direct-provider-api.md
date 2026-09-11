# ADR-0002: Doğrudan sağlayıcı API'si, backend yok

- Durum: Kabul
- Tarih: 2026-09-12

## Bağlam

Web uygulaması deprem verisini `api.orhanaydogdu.com.tr/deprem/data/search` üzerinden alır. iOS için ayrı bir proxy backend kurulabilirdi.

## Karar

- Uygulamanın kendi backend'i yoktur; her kullanıcı cihazı doğrudan sağlayıcıya POST isteği atar.
- İstek gövdesi web ile aynıdır: `provider=kandilli`, `sort=date_-1`, 100'lük `skip/limit` sayfaları.
- Sağlayıcı şema değişiklikleri DTO/mapper fixture'larıyla erken yakalanır; lossy decode web davranışını korur.

## Sonuçlar

- Sunucu maliyeti, sır ve operasyon yükü yoktur.
- Sağlayıcı oran sınırı/kesintisi doğrudan kullanıcıyı etkiler; yerel cache + bounded retry bunu azaltır.
- Gelecekte bildirim için backend gerekirse ayrı ADR ve servis gerekir (ADR-0003).
