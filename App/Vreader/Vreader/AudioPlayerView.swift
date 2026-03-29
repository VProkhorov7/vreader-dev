import SwiftUI
import AVFoundation
import MediaPlayer
import Combine

// MARK: - ViewModel

@MainActor
final class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying      = false
    @Published var currentTime:   TimeInterval = 0
    @Published var duration:      TimeInterval = 0
    @Published var currentChapter = 0
    @Published var chapters:      [AudioChapter] = []
    @Published var speed:         Float = 1.0
    @Published var title          = ""
    @Published var artist         = ""
    @Published var artworkImage:  UIImage?

    private var player:       AVPlayer?
    private var timeObserver: Any?
    private var book:         Book?

    struct AudioChapter: Identifiable {
        let id:    Int
        let title: String
        let start: TimeInterval
        let end:   TimeInterval
    }

    // MARK: - Load

    func load(book: Book) {
        guard let url = book.fileURL else { return }
        self.book = book

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        let asset = AVURLAsset(url: url)
        let item  = AVPlayerItem(asset: asset)
        player    = AVPlayer(playerItem: item)

        Task {
            do {
                let dur = try await asset.load(.duration)
                self.duration = dur.seconds

                let meta = try await asset.load(.commonMetadata)
                await extractMetadata(from: meta, fallbackTitle: book.title)

                self.chapters = try await loadChapters(from: asset)
            } catch {}
        }

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentTime = time.seconds
                self.updateCurrentChapter()
            }
        }

        setupRemoteControls()
    }

    // MARK: - Playback

    func play()  { player?.play();  isPlaying = true  }
    func pause() { player?.pause(); isPlaying = false }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
        currentTime = time
        updateCurrentChapter()
    }

    func skip(seconds: TimeInterval) {
        seek(to: max(0, min(currentTime + seconds, duration)))
    }

    func setSpeed(_ speed: Float) {
        self.speed   = speed
        player?.rate = isPlaying ? speed : 0
    }

    func goToChapter(_ chapter: AudioChapter) {
        seek(to: chapter.start)
    }

    var currentChapterTitle: String {
        guard !chapters.isEmpty, currentChapter < chapters.count else {
            return book?.title ?? ""
        }
        return chapters[currentChapter].title
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    // MARK: - Private

    private func updateCurrentChapter() {
        guard !chapters.isEmpty else { return }
        let idx = chapters.lastIndex { $0.start <= currentTime } ?? 0
        if idx != currentChapter { currentChapter = idx }
    }

    private func extractMetadata(from meta: [AVMetadataItem], fallbackTitle: String) async {
        title  = fallbackTitle
        artist = ""
        for item in meta {
            guard let key = item.commonKey else { continue }
            switch key {
            case .commonKeyTitle:
                if let v = try? await item.load(.stringValue), !v.isEmpty { title = v }
            case .commonKeyArtist:
                if let v = try? await item.load(.stringValue) { artist = v }
            case .commonKeyArtwork:
                if let data = try? await item.load(.dataValue) {
                    artworkImage = UIImage(data: data)
                }
            default: break
            }
        }
    }

    private func loadChapters(from asset: AVURLAsset) async throws -> [AudioChapter] {
        let locales = try await asset.load(.availableChapterLocales)
        guard !locales.isEmpty else { return [] }
        let locale = locales.first ?? Locale.current
        let groups = try await asset.loadChapterMetadataGroups(
            withTitleLocale: locale,
            containingItemsWithCommonKeys: [.commonKeyTitle]
        )
        
        var chapters: [AudioChapter] = []
        for (idx, group) in groups.enumerated() {
            let start = group.timeRange.start.seconds
            let end   = start + group.timeRange.duration.seconds
            
            var title = "\(L10n.Reader.chapter) \(idx + 1)"
            if let titleItem = group.items.first(where: { $0.commonKey == .commonKeyTitle }) {
                if let loadedTitle = try? await titleItem.load(.stringValue) {
                    title = loadedTitle
                }
            }
            
            chapters.append(AudioChapter(id: idx, title: title, start: start, end: end))
        }
        return chapters
    }

    private func setupRemoteControls() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget             { [weak self] _ in self?.play();             return .success }
        center.pauseCommand.addTarget            { [weak self] _ in self?.pause();            return .success }
        center.togglePlayPauseCommand.addTarget  { [weak self] _ in self?.togglePlayPause();  return .success }
        center.skipForwardCommand.preferredIntervals  = [30]
        center.skipForwardCommand.addTarget  { [weak self] _ in self?.skip(seconds:  30); return .success }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in self?.skip(seconds: -15); return .success }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: e.positionTime)
            return .success
        }
    }

    deinit {
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
        do { try AVAudioSession.sharedInstance().setActive(false) } catch {}
    }
}

// MARK: - View

struct AudioPlayerView: View {
    let book: Book
    @Binding var currentPage:  Int
    @Binding var totalPages:   Int
    var onTap:        (() -> Void)?
    var onSwipeDown:  (() -> Void)?
    var onPageChange: (() -> Void)?

    @StateObject private var vm = AudioPlayerViewModel()
    @State private var showChapters = false

    private let speeds: [Float] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 0) {
                Spacer()
                coverSection
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                chapterTitle
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                progressSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                controlsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                speedSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                if !vm.chapters.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { showChapters.toggle() }
                    } label: {
                        Label("\(L10n.Audio.chapters) (\(vm.chapters.count))", systemImage: "list.bullet")
                            .font(.subheadline)
                    }
                    .padding(.bottom, 16)
                }
            }

            if showChapters {
                AudioChaptersPanel(
                    chapters:       vm.chapters,
                    currentChapter: vm.currentChapter,
                    isVisible:      $showChapters,
                    onSelect:       { vm.goToChapter($0) }
                )
                .transition(.move(edge: .bottom))
                .zIndex(10)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { val in
                    if val.translation.height > 60 { onSwipeDown?() }
                }
        )
        .onAppear {
            vm.load(book: book)
            totalPages = 100
        }
        .onChange(of: vm.progress) { _, progress in
            let page = max(1, Int(progress * 100))
            currentPage = page
            onPageChange?()
        }
    }

    // MARK: - Sections

    private var coverSection: some View {
        Group {
            if let img = vm.artworkImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(book.color.gradient)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "headphones")
                            .font(.system(size: 64, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.8))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
            }
        }
        .frame(maxHeight: 260)
    }

    private var chapterTitle: some View {
        VStack(spacing: 6) {
            Text(vm.title)
                .font(.headline)
                .lineLimit(1)
            if !vm.artist.isEmpty {
                Text(vm.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if !vm.chapters.isEmpty {
                Text(vm.currentChapterTitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .multilineTextAlignment(.center)
    }

    private var progressSection: some View {
        VStack(spacing: 4) {
            Slider(value: Binding(
                get: { vm.progress },
                set: { vm.seek(to: $0 * vm.duration) }
            ))
            .tint(Color.accentColor)

            HStack {
                Text(formatTime(vm.currentTime))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("-\(formatTime(max(0, vm.duration - vm.currentTime)))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 0) {
            Spacer()
            Button { vm.skip(seconds: -15) } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 28, weight: .light))
                    .frame(width: 56, height: 56)
            }
            Spacer()
            Button { vm.togglePlayPause() } label: {
                Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 72, height: 72)
            }
            Spacer()
            Button { vm.skip(seconds: 30) } label: {
                Image(systemName: "goforward.30")
                    .font(.system(size: 28, weight: .light))
                    .frame(width: 56, height: 56)
            }
            Spacer()
        }
        .foregroundStyle(.primary)
    }

    private var speedSection: some View {
        HStack(spacing: 8) {
            ForEach(speeds, id: \.self) { s in
                Button { vm.setSpeed(s) } label: {
                    Text(speedLabel(s))
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(s == vm.speed
                            ? Color.accentColor.opacity(0.15)
                            : Color.secondary.opacity(0.1))
                        .foregroundStyle(s == vm.speed ? Color.accentColor : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(s == vm.speed ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func speedLabel(_ s: Float) -> String {
        s == 1.0 ? "1×" : String(format: "%.2g×", s)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

// MARK: - Chapters Panel

struct AudioChaptersPanel: View {
    let chapters:       [AudioPlayerViewModel.AudioChapter]
    let currentChapter: Int
    @Binding var isVisible: Bool
    let onSelect: (AudioPlayerViewModel.AudioChapter) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                HStack {
                    Text(L10n.Audio.chapters).font(.headline)
                    Spacer()
                    Button { withAnimation { isVisible = false } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 22))
                    }
                }
                .padding(16)
                Divider()
                List(chapters) { ch in
                    Button {
                        onSelect(ch)
                        withAnimation { isVisible = false }
                    } label: {
                        HStack {
                            if ch.id == currentChapter {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 20)
                            } else {
                                Text("\(ch.id + 1)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20)
                            }
                            Text(ch.title)
                                .font(.body)
                                .foregroundStyle(ch.id == currentChapter ? Color.accentColor : Color.primary)
                            Spacer()
                            Text(formatTime(ch.start))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
            .frame(maxHeight: 400)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .ignoresSafeArea()
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { isVisible = false } }
        )
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}
