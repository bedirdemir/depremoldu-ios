# Deprem Oldu iOS — Kalıcı AI Çalışma Sözleşmesi

Bu dosya bu depoda çalışan tüm yapay zekâ ajanları için bağlayıcı proje talimatıdır. Daha yakın bir alt klasörde ayrıca `AGENTS.md` varsa yalnızca o alt ağaçta ek/öncelikli kurallar koyabilir.

## 1. Kimlik ve kaynak ürün

- Bu depo, `/Users/bedir/Desktop/CODE/depremoldu-workspace/depremolduorg-nuxtjs` içindeki depremoldu.org web uygulamasının native iOS karşılığıdır.
- Web repo ürün davranışı, terminoloji, görsel dil ve veri sözleşmeleri için okunabilir referanstır; iOS repo ayrı Git geçmişine ve bağımsız mimariye sahiptir.
- “Karşılık/kopya” semantik ve davranışsal parite demektir: magnitüd sınıfları, renkler, sıralama, metinler ve kullanıcı niyeti korunur. Piksel, DOM yerleşimi veya web etkileşimi birebir kopyalanmaz.
- Web kodunu kopyalayıp WebView içine koyma. JavaScript/Vue satırlarını mekanik olarak Swift'e çevirme. Davranışı testlerle tanımla ve Apple platformlarına uygun native arayüz üret.
- SwiftUI'nin standart navigasyon, tab, toolbar, sheet ve kontrol bileşenlerini öncele. Liquid Glass'ı desteklenen sistemlerde işlevsel katmanda ölçülü kullan; yoğun veri içeriğini dekoratif cam efektine dönüştürme.
- Web ile çatışan yeni ürün kararı gerekiyorsa sessizce varsayma: ADR aç veya `docs/DECISIONS.md` içine açık karar sorusu ekle.

## 2. Öncelikler

1. Doğruluk ve veri sözleşmesi uyumu.
2. Kullanıcı güvenliği, gizlilik ve şeffaflık.
3. Test edilebilirlik ve erişilebilirlik.
4. Native, sade ve bakım yapılabilir tasarım.
5. Hız. Hız hiçbir zaman ilk dört maddenin önüne geçmez.

## 3. Değişiklikten önce

- Kısa operasyonel bağlam için `docs/CURRENT_STATE.md`; normatif davranış için ilgili belge ile ADR'leri birlikte oku.
- Gerekli web davranışını `depremolduorg-nuxtjs` içinde doğrula; varsayıma dayalı port yapma.
- Yeni bağımlılık, izin, veri toplama, ağ rotası, deployment target veya kalıcı veri şeması ekleniyorsa önce ADR yaz/güncelle.
- Sağlayıcı API'si ve fay verisi dış servis bağımlılığıdır; sözleşme değişikliğinde fixture ve test güncellemesi zorunludur.

## 4. Mimari sınırlar

- SwiftUI birinci sınıf UI yaklaşımıdır; UIKit yalnızca doğrulanmış platform boşlukları için köprü olabilir (ör. `MKMapView` ve `SFSafariViewController`).
- UI, domain, ağ ve kalıcılık birbirine gömülmez.
- Uygulamada backend yoktur; ağ istekleri kullanıcı cihazından doğrudan sağlayıcıya gider. Sunucu sırrı, API anahtarı veya imzalama materyali hiçbir istemci binary'sine ya da repoya girmez.
- Yeni hesap sistemi, izin duvarı veya bildirim altyapısı açık ürün kararı olmadan eklenmez. İlk sürüm izinsiz ve local-first'tür.
- Fay verisi derleme zamanında `Faults.json` olarak paketlenir; güncelleme yeni uygulama sürümü gerektirir (ADR-0006).
- Domain katmanı Foundation dışında UI/ağ/kalıcılık bağımlılığı taşımaz.

## 5. Test sözleşmesi

- Hata düzeltmesi önce başarısız bir regresyon testiyle kanıtlanır.
- Yeni domain davranışı unit test olmadan tamamlanmış sayılmaz.
- Ağ katmanı gerçek internet yerine protokol/URLProtocol test doubles ve sabit JSON fixture'larıyla test edilir.
- Tarih, saat dilimi, DST, ondalık ayırıcı, bozuk/eksik API dizileri ve offline durumları kritik test matrisidir.
- UI testleri yalnızca değerli ana akışları kapsar; hesaplama doğruluğu UI testine bırakılmaz.
- Testler deterministik olmalı; wall clock, locale ve ağ enjekte edilmelidir. UI testleri `TESTING` yapılandırmasındaki fake repository ile çalışır; Release backdoor'u yoktur.
- Geliştirme iterasyonu hedefli paket/app unit testleri ve UI değiştiyse ilgili seçili XCUITest ile kanıtlanır; tur sonunda `make verify-iteration` çalıştırılır.
- Uzun tam `make verify` yalnız dondurulmuş exact `dev` release-candidate ağacında `dev -> test` / TestFlight öncesi zorunludur.
- Çalıştırılamayan doğrulamayı `Not Run`, gerekçe ve kalan riskle açıkça yaz.

## 6. Dokümantasyon sözleşmesi

- Davranış, mimari, API, izin, gizlilik, yayın veya operasyon akışı değiştiğinde aynı PR içinde ilgili Markdown güncellenir.
- Aktif faz/milestone/blocker/insan kabulü durumunu maddi biçimde değiştiren görevde `docs/CURRENT_STATE.md` aynı değişiklikte güncellenir.
- Belgelerde “sonra bakarız” türü belirsizlik bırakma; sahibi, tetikleyicisi ve koşulu olan açık soru yaz.
- Dış servis koşulları zamanla değişebilir; kaynak linki ve doğrulama tarihi tut.
- Hassas bilgiler, cihaz kimlikleri, token'lar veya gerçek kullanıcı verisi belgelere/fixture'lara girmez.

## 7. Git, commit ve review

- Çalışma dalı `dev` tabanlı `feature/*`, `fix/*`, `docs/*` veya `chore/*` olmalıdır.
- `main`, `test` ve `dev` üzerine doğrudan geliştirme commit'i atma.
- Conventional Commits kullan: `feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`, `build:`, `ci:`.
- Commit'ler küçük, tek amaçlı ve derlenebilir/test edilebilir olsun. Kullanıcının ilgisiz değişikliklerine dokunma.
- Yapay zekâ PR açmaz, review/approve etmez ve merge etmez; kullanıcı açıkça bu politikayı değiştirmedikçe yalnızca PR metni taslağı hazırlar.
- `dev -> test` ve `test -> main` yalnızca kullanıcı testi ve insan incelemesi sonrası PR ile ilerler.

## 8. App Store ve gizlilik korumaları

- Placeholder ekran, çalışmayan bağlantı, eksik izin açıklaması veya zorunlu olmayan permission duvarı yayın build'ine giremez.
- Uygulama konum izni istemez; istenirse önce değer anlatılır ve yalnız `When In Use` kullanılır.
- Kandilli/KOERI, GINRAS/AFEAD ve diğer veri kaynaklarının atıfları UI ve Hakkında ekranında görünür kalır.
- Deprem bilgileri bilgilendirme amaçlıdır; resmî uyarı, garanti veya acil yönlendirme gibi sunulmaz. Bu sorumluluk notu ürün arayüzünde korunur.
- App Privacy beyanı kod ve gerçek veri akışıyla uyuşmalıdır. Uygulama kişisel veri toplamaz, izleme/analytics SDK'sı içermez; yeni SDK eklemeden önce privacy manifest ve veri toplama etkisi incelenir.

## 9. Tamamlanma tanımı

Bir iş ancak kabul kriterleri, testler, erişilebilirlik kontrolü, hata/offline davranışı, dokümantasyon ve güvenlik/gizlilik etkisi birlikte ele alındığında tamamlanır. Ayrıntılı kontrol listesi: `docs/checklists/DEFINITION_OF_DONE.md`.
