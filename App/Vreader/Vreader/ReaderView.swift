// ReaderView.swift
import SwiftUI
import SwiftData
import PDFKit

// MARK: - Жестовая схема
//
// ЦЕНТР (жесты прямо на PDFView через UIKit — не блокируют нативные):
//   Тап              → показать/скрыть бары
//   Свайп вниз       → закрыть ридер
//   Двойной тап      → zoom (PDFKit нативно)
//   Долгое нажатие   → выделение текста (PDFKit нативно)
//   Пинч             → масштаб (PDFKit нативно)
//   Свайп влево/вправо → листание страниц (PDFKit нативно)
//
// КРАЯ (тонкие SwiftUI-оверлеи, не перекрывают PDF):
//   Верхняя зона (80pt) → тап → показать бары
//   Левый край (44pt)   → свайп вправо → содержание
//   Правый край (44pt)  → свайп влево → настройки

// MARK: - PDFKit враппер

struct PDFKitView: UIViewRepresentable {
    let url:         URL
    @Binding var currentPage: Int
    @Binding var totalPages:  Int

    // Колбэки для жестов — вызываются из UIKit, не блокируют нативные
    var scrollMode:   String = "page_horizontal"
    var onTap:        (() -> Void)?
    var onSwipeDown:  (() -> Void)?
    var onPageChange: (() -> Void)?

    private func applyScrollMode(to pdfView: PDFView) {
        switch scrollMode {
        case "scroll_vertical":
            pdfView.displayMode      = .singlePageContinuous
            pdfView.displayDirection = .vertical
            pdfView.usePageViewController(false)
        case "scroll_horizontal":
            pdfView.displayMode      = .singlePageContinuous
            pdfView.displayDirection = .horizontal
            pdfView.usePageViewController(false)
        default: // page_horizontal
            pdfView.displayMode      = .singlePage
            pdfView.displayDirection = .horizontal
            pdfView.usePageViewController(true, withViewOptions: nil)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales      = true
        pdfView.backgroundColor = .clear
        applyScrollMode(to: pdfView)

        if let document = PDFDocument(url: url) {
            pdfView.document = document
            DispatchQueue.main.async {
                totalPages = document.pageCount
                if currentPage > 1, let page = document.page(at: currentPage - 1) {
                    pdfView.go(to: page)
                }
            }
        }

        // Слушаем смену страниц
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        // ── Тап: cancelsTouchesInView = false → PDFKit получает касание тоже
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        tap.numberOfTapsRequired    = 1
        tap.cancelsTouchesInView    = false
        tap.requiresExclusiveTouchType = false
        pdfView.addGestureRecognizer(tap)

        // ── Свайп вниз для закрытия ридера
        let swipeDown = UISwipeGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSwipeDown)
        )
        swipeDown.direction             = .down
        swipeDown.cancelsTouchesInView  = false
        pdfView.addGestureRecognizer(swipeDown)

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}

    // MARK: Coordinator

    class Coordinator: NSObject {
        var parent: PDFKitView
        init(_ parent: PDFKitView) { self.parent = parent }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let page    = pdfView.currentPage,
                  let doc     = pdfView.document else { return }
            let idx = doc.index(for: page)
            DispatchQueue.main.async {
                self.parent.currentPage = idx + 1
                self.parent.totalPages  = doc.pageCount
                self.parent.onPageChange?()
            }
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            // Срабатывает только при одиночном тапе — двойной тап PDFKit обрабатывает сам
            DispatchQueue.main.async { self.parent.onTap?() }
        }

        @objc func handleSwipeDown(_ recognizer: UISwipeGestureRecognizer) {
            DispatchQueue.main.async { self.parent.onSwipeDown?() }
        }
    }
}

// MARK: - Главный экран ридера

struct ReaderView: View {
    let book: Book
    @Environment(\.modelContext)  private var modelContext
    @Environment(\.dismiss)       private var dismiss
    @StateObject private var settings = iCloudSettingsStore.shared

    @State private var showBars     = false  // полноэкранный режим по умолчанию
    @State private var showContents = false
    @State private var showSettings = false
    @State private var hideTimer:   Timer?
    @State private var currentPage:   Int = 1
    @State private var totalPages:    Int = 1
    @State private var showPageHint:  Bool = false
    @State private var pageHintTimer: Timer?
    @State private var pageDidChange: Bool = false  // защита от сброса прогресса

    private var readerBackground: Color {
        switch settings.readerTheme {
        case "dark":  return Color(white: 0.12)
        case "sepia": return Color(red: 0.97, green: 0.93, blue: 0.82)
        default:      return Color.white
        }
    }

    var body: some View {
        ZStack {
            readerBackground.ignoresSafeArea()

            // ── Контент книги — жесты внутри через UIKit ──
            contentView
                .padding(.top, 50)
                .padding(.bottom, 60)

            // ── Краевые зоны — только края, центр свободен ──
            EdgeGestureOverlay(
                showBars:     $showBars,
                showContents: $showContents,
                showSettings: $showSettings
            )

            // ── Бары ──
            VStack(spacing: 0) {
                ReaderTopBar(
                    book:       book,
                    isVisible:  showBars,
                    onContents: { withAnimation(.easeInOut(duration: 0.25)) { showContents.toggle() }},
                    onSearch:   {},
                    onHome:     { AppState.shared.selectedTab = .library }
                )
                Spacer()
                ReaderBottomBar(
                    book:        book,
                    currentPage: currentPage,
                    totalPages:  totalPages,
                    isVisible:   showBars
                )
            }
            .ignoresSafeArea(edges: .bottom)

            // Нижний hint при листании (когда бары скрыты)
            if showPageHint && !showBars {
                VStack {
                    Spacer()
                    PageHintBar(currentPage: currentPage, totalPages: totalPages)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.opacity)
                .zIndex(5)
            }

            if showContents {
                ReaderContentsPanel(isVisible: $showContents)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
            }
            if showSettings {
                ReaderSettingsPanel(isVisible: $showSettings)
                    .transition(.move(edge: .trailing))
                    .zIndex(10)
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        .statusBarHidden(!showBars)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .animation(.easeInOut(duration: 0.25), value: showBars)
        .animation(.easeInOut(duration: 0.25), value: showContents)
        .animation(.easeInOut(duration: 0.25), value: showSettings)
        .onAppear {
            if book.lastPage > 0 { currentPage = book.lastPage }
            pageDidChange = false
            scheduleHide()
            ReadingSession.shared.saveLastBook(book, context: modelContext)
        }
        .onDisappear { saveProgress() }
    }

    // MARK: - Контент

    @ViewBuilder
    private var contentView: some View {
        if let url = book.fileURL {
            switch book.format.lowercased() {
            case "pdf", "djvu":
                PDFKitView(
                    url:          url,
                    currentPage:  $currentPage,
                    totalPages:   $totalPages,
                    scrollMode:   settings.scrollMode,
                    onTap:        { toggleBars() },
                    onSwipeDown:  { dismiss() },
                    onPageChange: { flashPageHint() }
                )
                .ignoresSafeArea(edges: .bottom)

            case "epub":
                EPUBReaderView(
                    book:         book,
                    currentPage:  $currentPage,
                    totalPages:   $totalPages,
                    onTap:        { toggleBars() },
                    onSwipeDown:  { dismiss() },
                    onPageChange: { flashPageHint() }
                )

            case "txt", "rtf", "fb2", "mobi", "azw3":
                TextReaderView(
                    book:         book,
                    currentPage:  $currentPage,
                    totalPages:   $totalPages,
                    onTap:        { toggleBars() },
                    onSwipeDown:  { dismiss() },
                    onPageChange: { flashPageHint() }
                )

            case "cbz", "cbr", "cb7", "cbt":
                ComicReaderView(
                    book:         book,
                    currentPage:  $currentPage,
                    totalPages:   $totalPages,
                    onTap:        { toggleBars() },
                    onSwipeDown:  { dismiss() },
                    onPageChange: { flashPageHint() }
                )

            case "mp3", "m4a", "m4b":
                AudioPlayerView(
                    book:         book,
                    currentPage:  $currentPage,
                    totalPages:   $totalPages,
                    onTap:        { toggleBars() },
                    onSwipeDown:  { dismiss() },
                    onPageChange: { flashPageHint() }
                )

            case "chm":
                CHMReaderView(
                    book:         book,
                    currentPage:  $currentPage,
                    totalPages:   $totalPages,
                    onTap:        { toggleBars() },
                    onSwipeDown:  { dismiss() },
                    onPageChange: { flashPageHint() }
                )

            default:
                UnsupportedFormatView(format: book.format)
            }
        } else {
            NotDownloadedView(book: book)
        }
    }

    // MARK: - Прогресс

    private func saveProgress() {
        guard totalPages > 0, pageDidChange else { return }
        book.progress     = Double(currentPage) / Double(totalPages)
        book.lastPage     = currentPage
        book.lastOpenedAt = Date()
        try? modelContext.save()
    }

    private func toggleBars() {
        showBars.toggle()
        if showBars { scheduleHide() } else { hideTimer?.invalidate() }
    }

    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.25)) { showBars = false }
        }
    }

    private func flashPageHint() {
        pageDidChange = true
        guard !showBars else { return }  // если бары уже открыты — не мешаем
        pageHintTimer?.invalidate()
        withAnimation(.easeInOut(duration: 0.2)) { showPageHint = true }
        pageHintTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) { showPageHint = false }
        }
    }

    // MARK: - Краевые зоны (не закрывают центр)

    struct EdgeGestureOverlay: View {
        @Binding var showBars:     Bool
        @Binding var showContents: Bool
        @Binding var showSettings: Bool

        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let edgeW: CGFloat = 44
                let topH:  CGFloat = 80

                ZStack(alignment: .topLeading) {

                    // Верхняя зона → показать бары
                    Color.clear
                        .frame(width: w, height: topH)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) { showBars = true }
                        }

                    // Левый край → содержание
                    Color.clear
                        .frame(width: edgeW, height: h - topH)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 20).onEnded { val in
                            if val.translation.width > 40 {
                                withAnimation(.easeInOut(duration: 0.25)) { showContents = true }
                            }
                        })
                        .offset(x: 0, y: topH)

                    // Правый край → настройки
                    Color.clear
                        .frame(width: edgeW, height: h - topH)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 20).onEnded { val in
                            if val.translation.width < -40 {
                                withAnimation(.easeInOut(duration: 0.25)) { showSettings = true }
                            }
                        })
                        .offset(x: w - edgeW, y: topH)
                }
                // Центр не перекрываем — PDFKit работает напрямую
                .allowsHitTesting(true)
            }
        }
    }

    // MARK: - Top Bar

    struct ReaderTopBar: View {
        let book: Book; let isVisible: Bool
        let onContents: () -> Void; let onSearch: () -> Void; let onHome: () -> Void
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            HStack(spacing: 16) {
                Button { DispatchQueue.main.async { dismiss() } } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold)).frame(width: 44, height: 44)
                }
                Button { DispatchQueue.main.async { onHome() } } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 17)).frame(width: 44, height: 44)
                }
                Spacer()
                Text(book.title).font(.subheadline.weight(.medium)).lineLimit(1)
                Spacer()
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17)).frame(width: 44, height: 44)
                }
                Button(action: onContents) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 17)).frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            .background(.regularMaterial)
            .offset(y: isVisible ? 0 : -100)
            .opacity(isVisible ? 1 : 0)
        }
    }

    // MARK: - Bottom Bar

    struct ReaderBottomBar: View {
        let book: Book; let currentPage: Int; let totalPages: Int; let isVisible: Bool

        private var progress: Double {
            guard totalPages > 0 else { return 0 }
            return min(1.0, max(0.0, Double(currentPage) / Double(totalPages)))
        }

        var body: some View {
            VStack(spacing: 6) {
                ProgressView(value: progress).tint(Color.accentColor).padding(.horizontal, 16)
                HStack {
                    Text(String(format: NSLocalizedString("reader.page_num", value: "стр. %d", comment: ""), currentPage)).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%").font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: NSLocalizedString("reader.page_of", value: "из %d", comment: ""), totalPages)).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20).padding(.bottom, 8)
            }
            .background(.regularMaterial)
            .offset(y: isVisible ? 0 : 100)
            .opacity(isVisible ? 1 : 0)
        }
    }

    // MARK: - Левая панель

    struct ReaderContentsPanel: View {
        @Binding var isVisible: Bool
        var body: some View {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(L10n.Reader.contents).font(.headline)
                        Spacer()
                        Button { withAnimation { isVisible = false } } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).font(.system(size: 22))
                        }
                    }
                    .padding(16)
                    Divider()
                    List {
                        ForEach(1...10, id: \.self) { i in
                            HStack {
                                Text("\(L10n.Reader.chapter) \(i)").font(.body)
                                Spacer()
                                Text("\(i * 18)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .frame(width: 280).background(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 4, y: 0)

                Color.black.opacity(0.3).ignoresSafeArea()
                    .onTapGesture { withAnimation { isVisible = false } }
            }
            .ignoresSafeArea()
            // Свайп влево → закрыть содержание
            .gesture(DragGesture(minimumDistance: 30).onEnded { val in
                if val.translation.width < -30 {
                    withAnimation(.easeInOut(duration: 0.25)) { isVisible = false }
                }
            })
        }
    }

    // MARK: - Правая панель

    struct ReaderSettingsPanel: View {
        @Binding var isVisible: Bool
        @StateObject private var settings = iCloudSettingsStore.shared

        var body: some View {
            HStack(spacing: 0) {
                Color.black.opacity(0.3).ignoresSafeArea()
                    .onTapGesture { withAnimation { isVisible = false } }

                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(L10n.Reader.appearance).font(.headline)
                        Spacer()
                        Button { withAnimation { isVisible = false } } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).font(.system(size: 22))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Reader.theme).font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            ThemeButton(label: L10n.Reader.Theme.light, color: Color.white, textColor: Color.black,
                                        isSelected: settings.readerTheme == "light") { settings.readerTheme = "light" }
                            ThemeButton(label: L10n.Reader.Theme.sepia, color: Color(red: 0.97, green: 0.93, blue: 0.82), textColor: Color.black,
                                        isSelected: settings.readerTheme == "sepia") { settings.readerTheme = "sepia" }
                            ThemeButton(label: L10n.Reader.Theme.dark, color: Color(white: 0.2), textColor: Color.white,
                                        isSelected: settings.readerTheme == "dark") { settings.readerTheme = "dark" }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.Reader.fontSize).font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(settings.fontSize))pt").font(.caption.bold()).foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("А").font(.caption)
                            Slider(value: $settings.fontSize, in: 12...28, step: 1).tint(Color.accentColor)
                            Text("А").font(.title3)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Reader.lineSpacing).font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            SpacingButton(label: L10n.Reader.Spacing.narrow, value: 1.2, current: settings.lineSpacing) { settings.lineSpacing = 1.2 }
                            SpacingButton(label: L10n.Reader.Spacing.medium, value: 1.6, current: settings.lineSpacing) { settings.lineSpacing = 1.6 }
                            SpacingButton(label: L10n.Reader.Spacing.wide,   value: 2.0, current: settings.lineSpacing) { settings.lineSpacing = 2.0 }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Reader.scrollMode).font(.caption).foregroundStyle(.secondary)
                        VStack(spacing: 6) {
                            ScrollModeButton(label: L10n.Reader.Scroll.pageHorizontal,   icon: "rectangle.portrait.on.rectangle.portrait",
                                             value: "page_horizontal",  current: settings.scrollMode) { settings.scrollMode = "page_horizontal" }
                            ScrollModeButton(label: L10n.Reader.Scroll.scrollVertical,   icon: "scroll",
                                             value: "scroll_vertical",  current: settings.scrollMode) { settings.scrollMode = "scroll_vertical" }
                            ScrollModeButton(label: L10n.Reader.Scroll.scrollHorizontal, icon: "arrow.left.and.right",
                                             value: "scroll_horizontal", current: settings.scrollMode) { settings.scrollMode = "scroll_horizontal" }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.Reader.languageScript).font(.caption).foregroundStyle(.secondary)

                        Toggle(isOn: $settings.verticalTextMode) {
                            HStack(spacing: 8) {
                                Image(systemName: "text.justify.right")
                                    .font(.system(size: 14))
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(L10n.Reader.verticalText)
                                        .font(.caption)
                                    Text(L10n.Reader.verticalTextHint)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .tint(.accentColor)

                        HStack(spacing: 6) {
                            Image(systemName: "character")
                                .font(.system(size: 13))
                                .frame(width: 20)
                                .foregroundStyle(.secondary)
                            Text(L10n.Reader.rtlHint)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()
                }
                .padding(20).frame(width: 280).background(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: -4, y: 0)
            }
            .ignoresSafeArea()
            // Свайп вправо → закрыть настройки
            .gesture(DragGesture(minimumDistance: 30).onEnded { val in
                if val.translation.width > 30 {
                    withAnimation(.easeInOut(duration: 0.25)) { isVisible = false }
                }
            })
        }
    }

    // MARK: - Вспомогательные кнопки

    struct ThemeButton: View {
        let label: String; let color: Color; let textColor: Color
        let isSelected: Bool; let action: () -> Void
        var body: some View {
            Button(action: action) {
                Text(label).font(.caption.bold()).foregroundStyle(textColor)
                    .frame(maxWidth: .infinity).padding(.vertical, 8).background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1))
            }.buttonStyle(.plain)
        }
    }

    struct ScrollModeButton: View {
        let label:   String
        let icon:    String
        let value:   String
        let current: String
        let action:  () -> Void
        var body: some View {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .frame(width: 18)
                    Text(label).font(.caption)
                    Spacer()
                    if value == current {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(value == current ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(value == current ? Color.accentColor : Color.clear, lineWidth: 1.5))
            }.buttonStyle(.plain)
        }
    }

    struct SpacingButton: View {
        let label: String; let value: Double; let current: Double; let action: () -> Void
        var body: some View {
            Button(action: action) {
                Text(label).font(.caption)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(value == current ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(value == current ? Color.accentColor : Color.clear, lineWidth: 1.5))
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Заглушки

    struct UnsupportedFormatView: View {
        let format: String
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "doc.questionmark").font(.system(size: 56)).foregroundStyle(.secondary)
                Text(String(format: NSLocalizedString("reader.format_unsupported", value: "Формат %@ не поддерживается", comment: ""), format.uppercased())).font(.headline).foregroundStyle(.secondary)
                Text(L10n.Reader.unsupportedFormats)
                    .font(.subheadline).foregroundStyle(.tertiary).multilineTextAlignment(.center)
            }
            .padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    struct NotDownloadedView: View {
        let book: Book
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "icloud.and.arrow.down").font(.system(size: 56)).foregroundStyle(.secondary)
                Text(L10n.Reader.notDownloaded).font(.headline).foregroundStyle(.secondary)
                Text(String(format: NSLocalizedString("reader.download_hint", value: "Скачайте «%@» для чтения офлайн", comment: ""), book.title)).font(.subheadline).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                Button { } label: { Label(L10n.Reader.download, systemImage: "arrow.down.circle.fill") }
                    .buttonStyle(.borderedProminent)
            }
            .padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Page Hint Bar (показывается на 3 сек при листании)

extension ReaderView {
    struct PageHintBar: View {
        let currentPage: Int
        let totalPages:  Int

        private var progress: Double {
            guard totalPages > 0 else { return 0 }
            return min(1.0, max(0.0, Double(currentPage) / Double(totalPages)))
        }

        var body: some View {
            VStack(spacing: 5) {
                // Тонкая линия прогресса
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.2))
                            .frame(height: 3)
                        Capsule().fill(Color.white.opacity(0.85))
                            .frame(width: geo.size.width * progress, height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 24)

                // Номер страницы
                Text("\(currentPage)  /  \(totalPages)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .padding(.bottom, 12)
            }
            .padding(.top, 10)
            .background(.ultraThinMaterial.opacity(0))
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ReaderView(book: Book.samples[0])
}
