import SwiftUI
import Foundation
import WebKit

#if os(iOS)
struct TextReaderView: UIViewRepresentable {
    let book:         Book
    @Binding var currentPage:  Int
    @Binding var totalPages:   Int
    var onTap:        (() -> Void)?
    var onSwipeDown:  (() -> Void)?
    var onPageChange: (() -> Void)?

    private var settings: iCloudSettingsStore { iCloudSettingsStore.shared }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "reader")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor     = .clear
        webView.isOpaque            = false
        webView.scrollView.bounces  = false
        webView.navigationDelegate  = context.coordinator

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

        loadContent(into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        loadContent(into: webView)
    }

    private func loadContent(into webView: WKWebView) {
        guard let url = book.fileURL else { return }

        let html: String
        switch book.format.lowercased() {
        case "rtf":
            html = rtfToHTML(url: url)
        default:
            html = txtToHTML(url: url)
        }
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func txtToHTML(url: URL) -> String {
        let raw = (try? String(contentsOf: url, encoding: .utf8))
            ?? (try? String(contentsOf: url, encoding: .windowsCP1251))
            ?? (try? String(contentsOf: url, encoding: .isoLatin1))
            ?? ""
        let escaped = raw
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        return wrapHTML(body: "<p>\(escaped)</p>", isPreformatted: false, rawText: raw)
    }

    private func rtfToHTML(url: URL) -> String {
        guard let data = try? Data(contentsOf: url),
              let attrStr = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
              ) else {
            return wrapHTML(body: "<p>Не удалось открыть RTF файл.</p>", isPreformatted: false, rawText: "")
        }

        let htmlData = try? attrStr.data(
            from: NSRange(location: 0, length: attrStr.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
        )
        let bodyContent = htmlData.flatMap { String(data: $0, encoding: .utf8) } ?? attrStr.string
        return wrapHTML(body: bodyContent, isPreformatted: true, rawText: attrStr.string)
    }

    private func wrapHTML(body: String, isPreformatted: Bool, rawText: String) -> String {
        let script = detectScript(rawText)
        let direction  = script == .arabic ? "rtl" : "ltr"
        let writingMode = (settings.verticalTextMode && script == .cjk) ? "vertical-rl" : "horizontal-tb"
        let textAlign  = script == .arabic ? "right" : "left"

        let bgColor: String
        let textColor: String
        switch settings.readerTheme {
        case "dark":  bgColor = "#1e1e1e"; textColor = "#e0e0e0"
        case "sepia": bgColor = "#f8f0d8"; textColor = "#3a2e1e"
        default:      bgColor = "#ffffff"; textColor = "#1a1a1a"
        }

        let fontFamily = cjkFontStack(for: script)
        let fontSize   = Int(settings.fontSize)
        let lineHeight = settings.lineSpacing

        let pageScript = """
        <script>
        window.addEventListener('load', function() {
            const totalH = document.body.scrollHeight;
            const viewH  = window.innerHeight;
            const pages  = Math.max(1, Math.ceil(totalH / viewH));
            window.webkit.messageHandlers.reader.postMessage({type:'pages', total: pages});
        });
        window.addEventListener('scroll', function() {
            const scrollTop = window.scrollY || document.documentElement.scrollTop;
            const totalH    = document.body.scrollHeight - window.innerHeight;
            const page      = totalH > 0 ? Math.ceil((scrollTop / totalH) * 100) : 0;
            window.webkit.messageHandlers.reader.postMessage({type:'scroll', page: page});
        });
        </script>
        """

        let contentBlock = isPreformatted ? body : """
        <div class="content" dir="\(direction)" style="text-align:\(textAlign)">
            \(body)
        </div>
        """

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=3">
        <style>
            * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
            html, body {
                margin: 0; padding: 0;
                background: \(bgColor);
                color: \(textColor);
                font-family: \(fontFamily);
                font-size: \(fontSize)px;
                line-height: \(lineHeight);
                writing-mode: \(writingMode);
                direction: \(direction);
                word-break: break-word;
                overflow-wrap: break-word;
            }
            body { padding: 20px 24px 60px 24px; }
            .content { max-width: 100%; }
            p { margin: 0 0 1em 0; }
            h1, h2, h3 { margin: 1.2em 0 0.4em 0; }
            a { color: #4a90d9; }
        </style>
        \(pageScript)
        </head>
        <body>
            \(contentBlock)
        </body>
        </html>
        """
    }

    private func cjkFontStack(for script: DetectedScript) -> String {
        switch script {
        case .cjk:
            return "'Hiragino Sans', 'Hiragino Mincho ProN', 'PingFang SC', 'PingFang TC', 'STSong', sans-serif"
        case .arabic:
            return "'Geeza Pro', 'Al Nile', 'Baghdad', 'Damascus', Georgia, serif"
        default:
            return "Georgia, 'Times New Roman', serif"
        }
    }

    private enum DetectedScript {
        case latin, arabic, cjk, cyrillic, other
    }

    private func detectScript(_ text: String) -> DetectedScript {
        guard !text.isEmpty else { return .latin }
        let sample = String(text.prefix(500))
        var counts: [DetectedScript: Int] = [.arabic: 0, .cjk: 0, .cyrillic: 0, .latin: 0]
        for scalar in sample.unicodeScalars {
            let v = scalar.value
            if (v >= 0x0600 && v <= 0x06FF) || (v >= 0x0750 && v <= 0x077F) ||
               (v >= 0xFB50 && v <= 0xFDFF) || (v >= 0xFE70 && v <= 0xFEFF) {
                counts[.arabic, default: 0] += 1
            } else if (v >= 0x4E00 && v <= 0x9FFF) || (v >= 0x3400 && v <= 0x4DBF) ||
                      (v >= 0x3000 && v <= 0x303F) || (v >= 0xFF00 && v <= 0xFFEF) ||
                      (v >= 0x3040 && v <= 0x30FF) {
                counts[.cjk, default: 0] += 1
            } else if v >= 0x0400 && v <= 0x04FF {
                counts[.cyrillic, default: 0] += 1
            } else if v >= 0x0041 && v <= 0x007A {
                counts[.latin, default: 0] += 1
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? .other
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: TextReaderView

        init(_ parent: TextReaderView) { self.parent = parent }

        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any] else { return }
            DispatchQueue.main.async {
                if let type = dict["type"] as? String {
                    if type == "pages", let total = dict["total"] as? Int {
                        self.parent.totalPages = total
                    } else if type == "scroll", let page = dict["page"] as? Int {
                        self.parent.currentPage = max(1, page)
                        self.parent.onPageChange?()
                    }
                }
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
struct TextReaderView: View {
    let book: Book
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var onTap: (() -> Void)?
    var onSwipeDown: (() -> Void)?
    var onPageChange: (() -> Void)?
    var body: some View { EmptyView() }
}
#endif
