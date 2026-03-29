import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import ZIPFoundation

#if os(iOS)
struct ComicReaderView: View {
    let book:         Book
    @Binding var currentPage:  Int
    @Binding var totalPages:   Int
    var onTap:        (() -> Void)?
    var onSwipeDown:  (() -> Void)?
    var onPageChange: (() -> Void)?

    @State private var pages:    [UIImage] = []
    @State private var isLoading = true
    @State private var error:     String?
    @State private var webtoonMode   = false
    @State private var mangaMode     = false

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView(L10n.Comic.opening)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = error {
                ComicErrorView(message: err)
            } else if pages.isEmpty {
                ComicErrorView(message: L10n.Comic.noImages)
            } else if webtoonMode {
                WebtoonScrollView(
                    pages:       pages,
                    currentPage: $currentPage,
                    onTap:       onTap,
                    onSwipeDown: onSwipeDown,
                    onPageChange: onPageChange
                )
            } else {
                PagedComicView(
                    pages:       pages,
                    currentPage: $currentPage,
                    mangaMode:   mangaMode,
                    onTap:       onTap,
                    onSwipeDown: onSwipeDown,
                    onPageChange: onPageChange
                )
            }

            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Button {
                            withAnimation { mangaMode.toggle() }
                        } label: {
                            Image(systemName: mangaMode ? "arrow.right.to.line" : "arrow.left.to.line")
                                .font(.system(size: 13, weight: .medium))
                                .padding(8)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button {
                            withAnimation { webtoonMode.toggle() }
                        } label: {
                            Image(systemName: webtoonMode ? "rectangle.split.3x1" : "scroll")
                                .font(.system(size: 13, weight: .medium))
                                .padding(8)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
        .task {
            await loadPages()
        }
    }

    private func loadPages() async {
        guard let url = book.fileURL else {
            error = L10n.Comic.fileNotFound
            isLoading = false
            return
        }

        let format = book.format.lowercased()

        if format == "cbr" || format == "cb7" {
            error = "\(format.uppercased()) \(L10n.Comic.cbrNoLib)"
            isLoading = false
            return
        }

        if format == "cbt" {
            await loadTarPages(url: url)
            return
        }

        await loadZipPages(url: url)
    }

    private func loadZipPages(url: URL) async {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            var imageEntries: [String] = []

            for entry in archive where entry.type == .file {
                let path = entry.path.lowercased()
                if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") ||
                   path.hasSuffix(".png") || path.hasSuffix(".webp") ||
                   path.hasSuffix(".gif") || path.hasSuffix(".bmp") {
                    imageEntries.append(entry.path)
                }
            }

            imageEntries.sort { naturalSort($0, $1) }

            var loaded: [UIImage] = []
            for path in imageEntries {
                guard let entry = archive[path] else { continue }
                var data = Data()
                _ = try archive.extract(entry) { chunk in data.append(chunk) }
                if let img = UIImage(data: data) {
                    loaded.append(img)
                }
            }

            await MainActor.run {
                pages      = loaded
                totalPages = loaded.count
                currentPage = 1
                isLoading  = false
            }
        } catch {
            await MainActor.run {
                self.error = "\(L10n.Comic.archiveError)\(error.localizedDescription)"
                isLoading  = false
            }
        }
    }

    private func loadTarPages(url: URL) async {
        await MainActor.run {
            error = L10n.Comic.cbtPending
            isLoading = false
        }
    }

    private func naturalSort(_ a: String, _ b: String) -> Bool {
        a.compare(b, options: [.numeric, .caseInsensitive]) == .orderedAscending
    }
}

struct PagedComicView: View {
    let pages:     [UIImage]
    @Binding var currentPage: Int
    let mangaMode:   Bool
    var onTap:       (() -> Void)?
    var onSwipeDown: (() -> Void)?
    var onPageChange: (() -> Void)?

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(
                mangaMode ? Array(pages.enumerated().reversed()) : Array(pages.enumerated()),
                id: \.offset
            ) { idx, image in
                ZoomableImageView(image: image, onTap: onTap)
                    .tag(idx + 1)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: currentPage) { onPageChange?() }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { val in
                    if val.translation.height > 60 { onSwipeDown?() }
                }
        )
    }
}

struct WebtoonScrollView: View {
    let pages:      [UIImage]
    @Binding var currentPage: Int
    var onTap:       (() -> Void)?
    var onSwipeDown: (() -> Void)?
    var onPageChange: (() -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .id(idx)
                        .onAppear {
                            currentPage = idx + 1
                            onPageChange?()
                        }
                }
            }
        }
        .onTapGesture { onTap?() }
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let image:  UIImage
    var onTap:  (() -> Void)?

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator   = false
        scrollView.delegate = context.coordinator

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 100
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
        ])

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        tap.require(toFail: doubleTap)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let imageView = scrollView.viewWithTag(100) as? UIImageView {
            imageView.image = image
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableImageView
        init(_ parent: ZoomableImageView) { self.parent = parent }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(100)
        }

        @objc func handleTap(_ r: UITapGestureRecognizer) {
            DispatchQueue.main.async { self.parent.onTap?() }
        }

        @objc func handleDoubleTap(_ r: UITapGestureRecognizer) {
            guard let scrollView = r.view as? UIScrollView else { return }
            if scrollView.zoomScale > 1.0 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let point = r.location(in: scrollView)
                let rect  = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}

struct ComicErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
