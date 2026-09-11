import SwiftUI

struct AwarenessView: View {
    @State private var safariItem: SafariItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(AwarenessContent.items) { item in
                        AwarenessCardView(item: item) {
                            safariItem = SafariItem(url: item.url)
                        }
                    }

                    Text("İçerikler ilgili kaynaklara aittir; bağlantılar harici sitelerde açılır.")
                        .font(AppFont.regular(11, relativeTo: .caption2))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandTitle()
                }
            }
        }
        .tint(AppColor.primary)
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
        }
    }
}

struct AwarenessCardView: View {
    let item: AwarenessItem
    let onOpen: () -> Void

    private var backgroundColor: Color {
        Color(hex: 0xFCFFE7, opacity: 0.13)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                Text(item.title)
                    .font(AppFont.bold(19, relativeTo: .title3))
                    .foregroundStyle(AppColor.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if let summary = item.summary {
                Text(summary)
                    .font(AppFont.regular(14, relativeTo: .subheadline))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let source = item.source {
                    Text("- \(source)")
                        .font(AppFont.regular(13, relativeTo: .footnote))
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: onOpen) {
                HStack(spacing: 6) {
                    Text(item.actionTitle)
                        .font(AppFont.medium(14, relativeTo: .subheadline))
                    Image(systemName: item.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColor.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.title) içeriğini \(item.actionTitle.lowercased())")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("awareness.card.\(item.id)")
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}
