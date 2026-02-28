// ReaderView.swift — ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ
import SwiftUI
import SwiftData

// MARK: - Главный экран ридера

struct ReaderView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext
    
    @State private var showBars = true
    @State private var showContents = false
    @State private var showSettings = false
    @State private var hideTimer: Timer?
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 200

    var body: some View {
        ZStack {
            // Фон
            Color.white
                .ignoresSafeArea()

            // Заглушка контента (потом WKWebView)
            ScrollView {
                Text(sampleText)
                    .font(.system(size: 18))
                    .lineSpacing(8)
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 80)
            }

            // Мёртвые зоны + зоны управления
            ReaderGestureLayer(
                showBars: $showBars,
                showContents: $showContents,
                showSettings: $showSettings,
                onCenterTap: { toggleBars() }
            )

            // UI оверлей
            VStack(spacing: 0) {
                ReaderTopBar(
                    book: book,
                    isVisible: showBars,
                    onContents: { withAnimation(.easeInOut(duration: 0.25)) { showContents.toggle() }},
                    onSearch: {}
                )
                Spacer()
                ReaderBottomBar(
                    book: book,
                    isVisible: showBars
                )
            }
            .ignoresSafeArea(edges: .bottom)

            // Левая панель — Содержание
            if showContents {
                ReaderContentsPanel(isVisible: $showContents)
                    .transition(.move(edge: .leading))
            }

            // Правая панель — Настройки
            if showSettings {
                ReaderSettingsPanel(isVisible: $showSettings)
                    .transition(.move(edge: .trailing))
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        .statusBarHidden(!showBars)
        #endif
        .animation(.easeInOut(duration: 0.25), value: showBars)
        .animation(.easeInOut(duration: 0.25), value: showContents)
        .animation(.easeInOut(duration: 0.25), value: showSettings)
        .onAppear {
            scheduleHide()
            ReadingSession.shared.saveLastBook(book, context: modelContext)
        }
        .onDisappear {
            // Сохраняем прогресс при выходе
            book.progress = Double(currentPage) / Double(totalPages)
            book.lastPage = currentPage
        }
    }

    // MARK: - Логика скрытия

    private func toggleBars() {
        showBars.toggle()
        if showBars { scheduleHide() } else { hideTimer?.invalidate() }
    }

    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                showBars = false
            }
        }
    }
}

// MARK: - Слой жестов с мёртвыми зонами

struct ReaderGestureLayer: View {
    @Binding var showBars: Bool
    @Binding var showContents: Bool
    @Binding var showSettings: Bool
    let onCenterTap: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let deadZone: CGFloat = 20      // мёртвая зона от краёв
            let edgeZone: CGFloat = 44      // зона вызова панелей

            ZStack(alignment: .topLeading) {
                // Центральная зона — toggle баров
                Color.clear
                    .frame(width: w - edgeZone * 2, height: h - deadZone * 2)
                    .contentShape(Rectangle())
                    .onTapGesture { onCenterTap() }
                    .offset(x: edgeZone, y: deadZone)

                // Левый edge — открыть содержание
                Color.clear
                    .frame(width: edgeZone, height: h - deadZone * 2)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { val in
                                if val.translation.width > 40 {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showContents = true
                                    }
                                }
                            }
                    )
                    .offset(x: 0, y: deadZone)

                // Правый edge — открыть настройки
                Color.clear
                    .frame(width: edgeZone, height: h - deadZone * 2)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { val in
                                if val.translation.width < -40 {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showSettings = true
                                    }
                                }
                            }
                    )
                    .offset(x: w - edgeZone, y: deadZone)
            }
        }
    }
}

// MARK: - Top Bar

struct ReaderTopBar: View {
    let book: Book
    let isVisible: Bool
    let onContents: () -> Void
    let onSearch: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(book.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            Spacer()

            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17))
                    .frame(width: 44, height: 44)
            }

            Button(action: onContents) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 17))
                    .frame(width: 44, height: 44)
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
    let book: Book
    let isVisible: Bool

    var body: some View {
        VStack(spacing: 6) {
            Slider(value: .constant(Double(book.progress)), in: 0...1)
                .tint(Color.accentColor)
                .padding(.horizontal, 16)

            HStack {
                Text("Гл. 3 · Начало")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(book.progressPercent)%")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("стр. \(book.lastPage + 1) / 200")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
        .offset(y: isVisible ? 0 : 100)
        .opacity(isVisible ? 1 : 0)
    }
}

// MARK: - Левая панель: Содержание

struct ReaderContentsPanel: View {
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Содержание")
                        .font(.headline)
                    Spacer()
                    Button { withAnimation { isVisible = false } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 22))
                    }
                }
                .padding(16)

                Divider()

                List {
                    ForEach(1...10, id: \.self) { i in
                        HStack {
                            Text("Глава \(i)")
                                .font(.body)
                            Spacer()
                            Text("\(i * 18)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .frame(width: 280)
            .background(.regularMaterial)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 4, y: 0)

            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { isVisible = false } }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Правая панель: Настройки

struct ReaderSettingsPanel: View {
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 0) {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { isVisible = false } }

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Оформление")
                        .font(.headline)
                    Spacer()
                    Button { withAnimation { isVisible = false } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 22))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Тема").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        ThemeButton(label: "Светлая", color: .white, textColor: .black)
                        ThemeButton(label: "Сепия", color: Color(red: 0.97, green: 0.93, blue: 0.82), textColor: .black)
                        ThemeButton(label: "Тёмная", color: Color(white: 0.2), textColor: .white)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Размер текста").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Text("А").font(.caption)
                        Slider(value: .constant(0.5)).tint(Color.accentColor)
                        Text("А").font(.title3)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Интервал").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        SpacingButton(label: "Узкий", value: 1.2)
                        SpacingButton(label: "Средний", value: 1.6)
                        SpacingButton(label: "Широкий", value: 2.0)
                    }
                }

                Spacer()
            }
            .padding(20)
            .frame(width: 280)
            .background(.regularMaterial)
            .shadow(color: .black.opacity(0.15), radius: 12, x: -4, y: 0)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Вспомогательные компоненты

struct ThemeButton: View {
    let label: String
    let color: Color
    let textColor: Color

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

struct SpacingButton: View {
    let label: String
    let value: Double

    var body: some View {
        Text(label)
            .font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Sample text

private let sampleText = """
В начале июля, в чрезвычайно жаркое время, под вечер, один молодой человек вышел из своей каморки, которую нанимал от жильцов в С-м переулке, на улицу и медленно, как бы в нерешимости, отправился к К-ну мосту.

Он благополучно избегнул встречи с своею хозяйкой на лестнице. Каморка его приходилась под самою кровлей высокого пятиэтажного дома и походила более на шкаф, чем на квартиру.
"""

#Preview {
    ReaderView(book: Book.sampleBooks[0])
}
