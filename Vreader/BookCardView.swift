import SwiftUI

struct BookCardView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Обложка
            RoundedRectangle(cornerRadius: 10)
                .fill(book.color.gradient)
                .aspectRatio(2/3, contentMode: .fit)
                .overlay(
                    VStack(spacing: 4) {
                        Spacer()
                        Text(book.title)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        Spacer()
                        Text(book.format)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.3))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .padding(.bottom, 8)
                    }
                )
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)

            // Название — строго 3 строки, не меньше
            Text(book.title)
                .font(.caption.bold())
                .lineLimit(3)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 48, alignment: .topLeading) // 3 строки caption

            // Автор
            Text(book.author)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Прогресс — фиксированная зона 20pt
            ZStack(alignment: .leading) {
                Color.clear.frame(height: 20)
                if book.progress >= 1 {
                    Label("Прочитано", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else if book.progress > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        ProgressView(value: book.progress)
                            .tint(.accentColor)
                        Text("\(Int(book.progress * 100))%")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title), \(book.author), прочитано \(Int(book.progress * 100))%")
    }
}

#Preview {
    HStack(alignment: .top, spacing: 12) {
        BookCardView(book: Book.sampleBooks[0])
        BookCardView(book: Book.sampleBooks[4])
        BookCardView(book: Book.sampleBooks[5])
    }
    .padding()
    .frame(width: 420)
}
