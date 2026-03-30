import SwiftUI
import WebKit

#if os(iOS)
struct CHMReaderView: UIViewRepresentable {
    let book:         Book
    @Binding var currentPage:  Int
    @Binding var totalPages:   Int
    var onTap:        (() -> Void)?
    var onSwipeDown:  (() -> Void)?
    var onPageChange: (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "reader")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor    = .clear
        webView.isOpaque           = false

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        tap.cancelsTouchesInView = false
        webView.addGestureRecognizer(tap)

        let swipeDown = UISwipeGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSwipeDown)
        )
        swipeDown.direction = .down
        webView.addGestureRecognizer(swipeDown)

        loadCHM(into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    private func loadCHM(into webView: WKWebView) {
        guard let url = book.fileURL else {
            loadError(into: webView, message: L10n.CHM.fileNotFound)
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            loadError(into: webView, message: L10n.CHM.notDownloaded)
            return
        }

        webView.loadHTMLString(chmNotSupportedHTML(url: url), baseURL: nil)
    }

    private func chmNotSupportedHTML(url: URL) -> String {
        let settings = iCloudSettingsStore.shared
        let bgColor: String
        let textColor: String
        switch settings.readerTheme {
        case "dark":  bgColor = "#1e1e1e"; textColor = "#e0e0e0"
        case "sepia": bgColor = "#f8f0d8"; textColor = "#3a2e1e"
        default:      bgColor = "#ffffff"; textColor = "#1a1a1a"
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {
                background: \(bgColor); color: \(textColor);
                font-family: -apple-system, sans-serif;
                display: flex; flex-direction: column;
                align-items: center; justify-content: center;
                min-height: 80vh; padding: 32px; margin: 0;
                text-align: center;
            }
            .icon { font-size: 64px; margin-bottom: 16px; }
            h2 { font-size: 20px; margin: 0 0 12px; }
            p  { font-size: 15px; color: gray; line-height: 1.5; margin: 0 0 8px; }
            .path { font-size: 12px; color: #888; font-family: monospace;
                    word-break: break-all; margin-top: 16px; }
        </style>
        </head>
        <body>
            <div class="icon">📖</div>
            <h2>CHM — дань олдам</h2>
            <p>Формат CHM (Microsoft HTML Help) использует проприетарный<br>
            алгоритм сжатия LZX, недоступный без лицензии в App Store.</p>
            <p>Для чтения CHM на iOS рекомендуем:</p>
            <p>• <strong>iCHM</strong> — специализированный CHM-ридер<br>
               • Конвертация в EPUB через <strong>Calibre</strong> (бесплатно)</p>
            <div class="path">\(url.lastPathComponent)</div>
        </body>
        </html>
        """
    }

    private func loadError(into webView: WKWebView, message: String) {
        webView.loadHTMLString("<body style='font-family:sans-serif;padding:40px'><p>\(message)</p></body>", baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: CHMReaderView
        init(_ parent: CHMReaderView) { self.parent = parent }

        func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {}

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.totalPages  = 1
                self.parent.currentPage = 1
            }
        }

        @objc func handleTap(_ r: UITapGestureRecognizer) {
            DispatchQueue.main.async { self.parent.onTap?() }
        }

        @objc func handleSwipeDown(_ r: UISwipeGestureRecognizer) {
            DispatchQueue.main.async { self.parent.onSwipeDown?() }
        }
    }
}
#else
struct CHMReaderView: View {
    let book: Book
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var onTap: (() -> Void)?
    var onSwipeDown: (() -> Void)?
    var onPageChange: (() -> Void)?
    var body: some View { EmptyView() }
}
#endif
