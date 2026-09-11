# Branching, PR ve Release Akışı

## Kalıcı dallar

```text
feature/fix/docs/chore -> dev -> test -> main
                         PR      PR      PR
```

- `dev`: tamamlanmış ve bütünleşmiş geliştirme.
- `test`: TestFlight release candidate kaynağı.
- `main`: App Store üretim kaynağı, repository default branch'i; semver tag.

`test` test kodlarının dalı değildir; tüm test kodu normal feature ile birlikte gelir.

## Çalışma dalları

- `feature/<kisa-ad>`, `fix/<kisa-ad>`, `docs/<kisa-ad>`, `chore/<kisa-ad>`, `hotfix/<kisa-ad>`.
- Normal dallar güncel `dev` üzerinden açılır; hotfix `main` üzerinden başlar ve sonra `test`/`dev`e geri taşınır.
- `dev`, `test`, `main` üzerine doğrudan push yapılmaz.

## PR sahipliği ve promotion kapıları

- AI çalışma dalını, kodu, testi, dokümanı ve commit'leri hazırlayabilir; PR açma/review/merge insana aittir.
- **Feature/fix/chore -> dev:** hedefli testler + `make verify-iteration`; UI değiştiyse ilgili seçili XCUITest.
- **dev -> test:** sürüm kapsamı dondurulur; version/build güncellenir; changelog ve TestFlight "What to Test" hazırlanır; dondurulmuş exact ağaçta tam `make verify` bir kez çalıştırılır.
- **test -> main:** TestFlight kabulü ve App Store checklist'i tamamlanır; `test` kaynağı son full-gate'ten sonra değişmediyse `make verify` tekrarlanmaz. Merge sonrası annotated `vMAJOR.MINOR.PATCH` tag oluşturulur.
- Fiziksel cihaz kabulü her davranış değişikliğinde ürün sahibi tarafından kaydedilir; çalıştırılamıyorsa `Not Run` + gerekçe yazılır.

## Release numarası

- Kaynak: `Configuration/Base.xcconfig` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`). Doğrulayıcı: `scripts/validate-versioning.sh`.
- Marketing version `MAJOR.MINOR.PATCH`; Apple version'ında suffix, `v` ön eki veya build metadata kullanılmaz.
- Build number monoton artan pozitif tam sayıdır; App Store Connect'te tüketilen build tekrar kullanılmaz.
- İlk sürüm: `1.0.0` build `1`.
- `CHANGELOG.md` her release'de tarihli bölüm ve boş `[Unreleased]` bölümü taşır; `version-check` changelog bölümünü doğrular.

## Branch protection

GitHub'da `main`, `test`, `dev` için direct push kapalı, PR zorunlu ve force push/deletion kapalıdır. Actions required check değildir; yerel `make verify` kanıtı ve insan review merge kapısıdır.

## Commit standardı

- `feat(scope): ...`, `fix(scope): ...`, `test(scope): ...`, `docs: ...`, `chore: ...`, `ci: ...`.
- Üretilen `DepremOldu.xcodeproj/project.pbxproj` değişikliği mümkünse kaynak değişikliğinden ayrı commit'lenir.
