import SwiftUI
import SafariServices

struct SafariItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(
            url: url,
            configuration: SFSafariViewController.Configuration()
        )
        controller.preferredControlTintColor = UIColor(AppColor.primary)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
