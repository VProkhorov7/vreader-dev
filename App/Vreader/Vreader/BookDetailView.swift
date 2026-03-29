import SwiftUI
import SwiftData

struct BookDetailView: View {
    let book: Book
    @Environment(\.modelContext)  private var modelContext
    @Environment(\.dismiss)       private var dismiss

    @State private var isDownloading  = false
    @State private var downloadProgress: Double = 0
    @State private var downloadError:  String?
    @State private var openReader      = false

    var body: some View {
        NavigationStack {
            // ZStack: фон + контент (scroll) + нижняя закреплённая кнопка
            ZStack(alignment: .bottom) {
                backgroundLayer

                // Скроллируемая часть: обложка + мета-информация
                ScrollView {
                    VStack(spacing: 0) {
                        coverSection
                        metaSection
                        // Отступ снизу — чтобы контент не заезжал под кнопку
                        Spacer().frame(height: 110)
                    }
                }
                .ignoresSafeArea(edges: .top)

                // Нижняя плашка с кнопкой — всегда видна
                bottomActionBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Назад")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $openReader) {
            ReaderView(book: book)
        }
    }

    // MARK: - Фон

    private var backgroundLayer: some View {
        ZStack {
            if let path = book.coverPath, let img = UIImage(contentsOfFile: path) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .blur(radius: 40).scaleEffect(1.2).opacity(0.35)
            } else {
                LinearGradient(
                    colors: [book.color.opacity(0.25), Color(uiColor: .systemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
            }
            Color(uiColor: .systemBackground).opacity(0.5)
        }
        .ignoresSafeArea()
    }

    // MARK: - Обложка

    private var coverSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 72)

            Group {
                if let path = book.coverPath, let img = UIImage(contentsOfFile: path) {
                    Image(uiImage: img).resizable().scaledToFit()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient(
                                colors: [book.color, book.color.opacity(0.65)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                        Image(systemName: book.formatIcon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .aspectRatio(2/3, contentMode: .fit)
                }
            }
            .frame(maxWidth: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 12)

            // Пилюли источника и формата
            HStack(spacing: 8) {
                MetaChip(icon: book.sourceIcon, label: book.sourceLabel, color: book.sourceColor)
                MetaChip(icon: book.formatIcon, label: book.formatLabel, color: book.formatColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
    }

    // MARK: - Мета-информация (заголовок, автор, размер)

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(book.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)

            Text(book.author)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            if book.fileSize > 0 {
                Label(book.formattedSize, systemImage: "doc")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            if book.progress > 0 && book.isDownloaded {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: book.progress).tint(Color.accentColor)
                    Text("Прочитано \(book.progressPercent)%")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Нижняя плашка с кнопкой

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            // Тонкая полоска-разделитель
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            VStack(spacing: 10) {
                actionContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var actionContent: some View {
        if book.isDownloaded {
            Button {
                openReader = true
            } label: {
                Label("Читать", systemImage: "book.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        } else if isDownloading {
            VStack(spacing: 8) {
                // Кольцевой прогресс + процент
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 3)
                            .frame(width: 36, height: 36)
                        Circle()
                            .trim(from: 0, to: downloadProgress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: downloadProgress)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(downloadProgress < 0.01
                             ? "Подготовка..."
                             : "Скачивание \(Int(downloadProgress * 100))%")
                            .font(.system(size: 15, weight: .medium))
                        ProgressView(value: downloadProgress)
                            .tint(Color.accentColor)
                            .animation(.easeInOut, value: downloadProgress)
                    }
                }
                Button {
                    isDownloading = false
                } label: {
                    Text("Отмена")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        } else {
            // Кнопка скачать
            Button {
                startDownload()
            } label: {
                Label("Скачать", systemImage: "arrow.down.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)

            // Подсказка про офлайн
            Text("Для чтения офлайн необходимо скачать книгу")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if let err = downloadError {
                Label(err, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Скачивание

    private func startDownload() {
        isDownloading = true
        downloadError = nil
        downloadProgress = 0

        guard let sourceURL = book.remoteURL else {
            downloadError = "Адрес файла недоступен"
            isDownloading = false
            return
        }

        let destURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Books", isDirectory: true)
            .appendingPathComponent("\(book.id.uuidString).\(book.format)")

        try? FileManager.default.createDirectory(
            at: destURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let task = URLSession.shared.downloadTask(with: sourceURL) { tmpURL, _, error in
            DispatchQueue.main.async {
                isDownloading = false
                if let error { downloadError = error.localizedDescription; return }
                guard let tmpURL else { return }
                do {
                    try? FileManager.default.removeItem(at: destURL)
                    try FileManager.default.moveItem(at: tmpURL, to: destURL)
                    book.filePath = destURL.path
                    try? modelContext.save()
                    openReader = true
                } catch {
                    downloadError = error.localizedDescription
                }
            }
        }

        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async { downloadProgress = progress.fractionCompleted }
        }
        _ = observation
        task.resume()
    }
}

// MARK: - MetaChip

private struct MetaChip: View {
    let icon:  String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .medium))
            Text(label).font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}
