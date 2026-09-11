# Tamamlanma Tanımı (Definition of Done)

Bir iş aşağıdakilerin tümü sağlandığında tamamlanır:

- [ ] Kabul kriterleri karşılandı ve web paritesi değerlendirildi.
- [ ] Yeni/değişen davranış için test eklendi (domain/formulasız test yok).
- [ ] `make verify-iteration` yeşil; UI değiştiyse ilgili seçili XCUITest yeşil.
- [ ] Erişilebilirlik: Dynamic Type, VoiceOver etiketi/ipucu, 44×44 pt hedef.
- [ ] Hata ve çevrimdışı davranışı tanımlı; içerik varsa korunuyor.
- [ ] Açık mod marka görünümü (zorunlu tek görünüm) kontrol edildi.
- [ ] İlgili doküman/ADR aynı PR'da güncellendi.
- [ ] Güvenlik/gizlilik etkisi değerlendirildi; yeni izin/SDK/veri toplama yok veya ADR'li.
- [ ] Hassas veri, token veya cihaz kimliği eklenmedi.
