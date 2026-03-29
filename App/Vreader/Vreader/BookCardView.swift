import SwiftUI

struct BookCardView: View {
    let book: Book
    var downloadProgress: Double? = nil
    var onDownload: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverView(
                book: book,
                downloadProgress: downloadProgress,
                onDownload: onDownload
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                Text(book.author)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if book.progress >= 1 {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                        Text("Прочитано")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 3)
                } else if book.progress > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        ProgressView(value: min(1, max(0, book.progress)))
                            .tint(Color.accentColor)
                            .scaleEffect(x: 1, y: 0.65)
                        Text("\(book.progressPercent)%")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 3)
                } else {
                    Color.clear.frame(height: 16).padding(.top, 3)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title), \(book.author), \(book.sourceLabel), \(book.formatLabel), прочитано \(book.progressPercent)%")
    }
}

// MARK: - CoverView

private struct CoverView: View {
    let book: Book
    var downloadProgress: Double? = nil
    var onDownload: (() -> Void)? = nil

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                // Основная обложка
                coverContent
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Полоса источника и формата внизу
                MetaStrip(book: book)

                // Кнопка скачивания (левый верхний угол)
                if !book.isDownloaded {
                    DownloadBadge(progress: downloadProgress) {
                        onDownload?()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(7)
                }
            }
            // clip всего ZStack целиком — MetaStrip не обрезается
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .aspectRatio(2/3, contentMode: .fit)
    }

    @ViewBuilder
    private var coverContent: some View {
        if let data = book.coverData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [book.color, book.color.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: book.formatIcon)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }
}

// MARK: - Download Badge с кольцевым прогрессом

private struct DownloadBadge: View {
    var progress: Double?
    var onTap: () -> Void

    private var isDownloading: Bool { progress != nil }
    private var clampedProgress: Double { min(1, max(0, progress ?? 0)) }

    var body: some View {
        Button {
            if !isDownloading { onTap() }
        } label: {
            ZStack {
                // Фоновый круг
                Circle()
                    .fill(.black.opacity(0.45))
                    .frame(width: 30, height: 30)

                if isDownloading {
                    // Серый трек
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2.5)
                        .frame(width: 22, height: 22)

                    // Заполненное кольцо
                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 22, height: 22)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: clampedProgress)

                    // Иконка паузы пока грузит
                    Image(systemName: "pause.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    // Стрела скачать
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(true)
        .contentShape(Circle().size(CGSize(width: 44, height: 44)))
        .frame(width: 30, height: 30)
    }
}

// MARK: - MetaStrip внизу обложки

private struct MetaStrip: View {
    let book: Book

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            FormatTag(label: book.formatLabel, color: book.formatColor)
            SourceTag(icon: book.sourceIcon, label: book.sourceLabel)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            // Градиент начинается ~20pt выше низа
            .padding(.top, -20)
        )
    }
}

private struct FormatTag: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

private struct SourceTag: View {
    let icon:  String
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .medium))
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

struct BadgeView: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.85))
            .clipShape(Capsule())
    }
}
