# Güvenlik Politikası

## Veri akışı

- Uygulamanın backend'i yoktur; istekler kullanıcı cihazından doğrudan `https://api.orhanaydogdu.com.tr` adresine gider.
- Kişisel veri toplanmaz, hesap yoktur, izleme/analytics SDK'sı yoktur, reklam kimliği kullanılmaz.
- Yerel cache yalnız deprem listesini içerir; `Application Support` altında backup dışı ve veri korumalı tutulur.

## Sır yönetimi

- API anahtarı, sunucu sırrı, APNs anahtarı veya imzalama materyali repoya girmez.
- `Configuration/Local.xcconfig` ignored'dur; Team ID yalnız yerel makinede tutulur.
- CI, tracked imzalama materyalini ve private key işaretlerini reddeder.

## Ağ güvenliği

- Yalnız HTTPS kullanılır; ATS istisnası yoktur.
- İstek gövdeleri sağlayıcı sözleşmesiyle sınırlıdır; kullanıcı girdisi taşımaz.
- Harici bağlantılar `SFSafariViewController` ile açılır; site içerikleri uygulama sürecinde çalışmaz.

## Bildirim

Güvenlik sorunları public issue yerine repo sahibine özel kanaldan bildirilir. Yanıt hedefi 72 saattir.
