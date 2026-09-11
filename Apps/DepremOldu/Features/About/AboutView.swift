import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var safariItem: SafariItem?

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "Sürüm \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        BrandTitle()
                        Text("Türkiye'deki son depremler ve deprem haritası")
                            .font(AppFont.regular(14, relativeTo: .subheadline))
                            .foregroundStyle(.secondary)
                        Text(versionText)
                            .font(AppFont.regular(12, relativeTo: .caption))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                }

                Section("Veri Kaynakları") {
                    linkRow(
                        title: "Kandilli Rasathanesi (KOERI)",
                        detail: "Deprem verileri",
                        url: URL(string: "http://www.koeri.boun.edu.tr/sismo/2/tr/")!
                    )
                    linkRow(
                        title: "GINRAS / AFEAD",
                        detail: "Fay hattı verileri (2018)",
                        url: URL(string: "https://www.depremoldu.org")!
                    )
                }

                Section("Bağlantılar") {
                    linkRow(
                        title: "depremoldu.org",
                        detail: "Web sitesi",
                        url: URL(string: "https://www.depremoldu.org")!
                    )
                    linkRow(
                        title: "GitHub",
                        detail: "Açık kaynak depo",
                        url: URL(string: "https://github.com/bedirdemir/depremolduorg-nuxtjs")!
                    )
                }

                Section("Önemli Not") {
                    Text(
                        "Bu uygulama resmî bir deprem uyarı veya erken uyarı sistemi değildir. "
                            + "Gösterilen veriler yalnızca bilgilendirme amaçlıdır. Acil durumlarda "
                            + "yetkili kurumların resmî duyurularını takip edin."
                    )
                    .font(AppFont.regular(13, relativeTo: .footnote))
                    .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("about.sheet")
            .navigationTitle("Hakkında")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .font(AppFont.semiBold(15, relativeTo: .body))
                }
            }
        }
        .tint(AppColor.primary)
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
        }
    }

    private func linkRow(title: String, detail: String, url: URL) -> some View {
        Button {
            safariItem = SafariItem(url: url)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.medium(15, relativeTo: .body))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(AppFont.regular(12, relativeTo: .caption))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
