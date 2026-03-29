import SwiftUI
import WebKit

struct EPUBWebView: UIViewRepresentable {
    let chapter:     EPUBChapter
    let fontSize:    Double
    let lineSpacing: Double
    let theme:       String
    var scrollMode:  String = "page_horizontal"
    var onTap:        (() -> Void)?
    var onSwipeDown:  (() -> Void)?
    var onSwipeLeft:  (() -> Void)?
    var onSwipeRight: (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor    = .clear
        webView.isOpaque           = false
        webView.scrollView.showsVerticalScrollIndicator   = false
        webView.scrollView.showsHorizontalScrollIndicator = false

        applyScrollMode(to: webView)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        webView.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan))
        pan.cancelsTouchesInView = false
        pan.delegate = context.coordinator
        webView.addGestureRecognizer(pan)

        loadChapter(in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let key = "\(chapter.id)-\(fontSize)-\(lineSpacing)-\(theme)-\(scrollMode)"
        if context.coordinator.loadedKey == key { return }
        context.coordinator.loadedKey = key
        applyScrollMode(to: webView)
        loadChapter(in: webView)
    }

    private func applyScrollMode(to webView: WKWebView) {
        switch scrollMode {
        case "scroll_vertical":
            webView.scrollView.isPagingEnabled        = false
            webView.scrollView.alwaysBounceVertical   = true
            webView.scrollView.alwaysBounceHorizontal = false
        case "scroll_horizontal":
            webView.scrollView.isPagingEnabled        = false
            webView.scrollView.alwaysBounceVertical   = false
            webView.scrollView.alwaysBounceHorizontal = true
        default:
            webView.scrollView.isPagingEnabled        = false
            webView.scrollView.alwaysBounceVertical   = true
            webView.scrollView.alwaysBounceHorizontal = false
        }
    }

    private func loadChapter(in webView: WKWebView) {
        guard var html = try? String(contentsOf: chapter.url, encoding: .utf8) else { return }
        let style = "<style>\(buildCSS())</style>"
        if let range = html.range(of: "</head>") {
            html.insert(contentsOf: style, at: range.lowerBound)
        } else {
            html = "<html><head>\(style)</head><body>\(html)</body></html>"
        }
        webView.loadHTMLString(html, baseURL: chapter.url.deletingLastPathComponent())
    }

    private func buildCSS() -> String {
        let bg, fg, linkColor: String
        switch theme {
        case "dark":  bg = "#1e1e1e"; fg = "#e0e0e0"; linkColor = "#7aafff"
        case "sepia": bg = "#f7f0e2"; fg = "#3b2f1e"; linkColor = "#8b4513"
        default:      bg = "#ffffff"; fg = "#1a1a1a"; linkColor = "#0066cc"
        }
        return """
        * { box-sizing: border-box; }
        html, body {
            background-color: \(bg) !important;
            color: \(fg) !important;
            font-family: -apple-system, 'Georgia', serif;
            font-size: \(Int(fontSize))px !important;
            line-height: \(lineSpacing) !important;
            margin: 0;
            padding: 16px 20px 60px 20px;
            max-width: 100%;
            word-break: break-word;
        }
        p { margin: 0 0 0.8em 0; }
        h1, h2, h3, h4 { color: \(fg) !important; line-height: 1.3; }
        a { color: \(linkColor) !important; }
        img { max-width: 100%; height: auto; display: block; margin: 8px auto; }
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate, UIGestureRecognizerDelegate {
        var parent: EPUBWebView
        var loadedKey: String = ""

        init(_ parent: EPUBWebView) { self.parent = parent }

        @objc func handleTap(_ r: UITapGestureRecognizer) {
            DispatchQueue.main.async { self.parent.onTap?() }
        }

        @objc func handlePan(_ r: UIPanGestureRecognizer) {
            guard r.state == .ended else { return }
            let vel   = r.velocity(in: r.view)
            let trans = r.translation(in: r.view)

            let isSwipeDown  = vel.y >  500 && trans.y >  60 && abs(trans.x) < 120
            let isSwipeLeft  = vel.x < -500 && trans.x < -60 && abs(trans.y) < 120
            let isSwipeRight = vel.x >  500 && trans.x >  60 && abs(trans.y) < 120

            if isSwipeDown {
                DispatchQueue.main.async { self.parent.onSwipeDown?() }
            } else if isSwipeLeft {
                DispatchQueue.main.async { self.parent.onSwipeLeft?() }
            } else if isSwipeRight {
                DispatchQueue.main.async { self.parent.onSwipeRight?() }
            }
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return true
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRequireFailureOf other: UIGestureRecognizer) -> Bool {
            return false
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(action.navigationType == .linkActivated ? .cancel : .allow)
        }
    }
}

struct EPUBReaderView: View {
    let book:     Book
    @Binding var currentPage: Int
    @Binding var totalPages:  Int
    @StateObject private var settings = iCloudSettingsStore.shared

    var onTap:        (() -> Void)?
    var onSwipeDown:  (() -> Void)?
    var onPageChange: (() -> Void)?

    @State private var epubBook:     EPUBBook?
    @State private var errorMessage: String?
    @State private var isLoading     = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Открываю книгу…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.orange)
                    Text("Ошибка открытия EPUB")
                        .font(.title2.bold())
                    Text(error)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let epub = epubBook {
                let idx = min(max(currentPage - 1, 0), epub.chapters.count - 1)
                EPUBWebView(
                    chapter:     epub.chapters[idx],
                    fontSize:    settings.fontSize,
                    lineSpacing: settings.lineSpacing,
                    theme:       settings.readerTheme,
                    scrollMode:  settings.scrollMode,
                    onTap:       onTap,
                    onSwipeDown: onSwipeDown,
                    onSwipeLeft:  { goNext(epub: epub) },
                    onSwipeRight: { goPrev(epub: epub) }
                )
                .id(currentPage)
            }
        }
        .onAppear { loadEPUB() }
    }

    private func loadEPUB() {
        guard let url = book.fileURL else {
            errorMessage = "Файл не найден"
            isLoading    = false
            return
        }
        Task {
            do {
                let epub: EPUBBook = try await withCheckedThrowingContinuation { cont in
                    DispatchQueue.global(qos: .userInitiated).async {
                        do { cont.resume(returning: try EPUBParser.shared.parse(url: url)) }
                        catch { cont.resume(throwing: error) }
                    }
                }
                epubBook   = epub
                totalPages = epub.chapters.count
                isLoading  = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading    = false
            }
        }
    }

    private func goNext(epub: EPUBBook) {
        guard currentPage < epub.chapters.count else { return }
        currentPage += 1
        onPageChange?()
    }

    private func goPrev(epub: EPUBBook) {
        guard currentPage > 1 else { return }
        currentPage -= 1
        onPageChange?()
    }
}
