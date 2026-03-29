# Specification: audio-handler

## Context
Аудиокниги в форматах MP3, M4A, M4B, AAC обрабатываются через AVFoundation. M4B поддерживает главы. Требуется интеграция с Control Center и Now Playing Info.

## User Scenarios
1. **Пользователь открывает M4B аудиокнигу:** Главы отображаются в оглавлении, воспроизведение начинается с последней позиции.
2. **Пользователь сворачивает приложение:** Воспроизведение продолжается, управление через Control Center.
3. **MP3 без глав:** Воспроизводится как единый трек с прогрессом.

## Functional Requirements
- FR-01: `AudioHandler` — final class, реализует `FileFormatHandler`.
- FR-02: Поддерживаемые форматы: `.mp3`, `.m4a`, `.m4b`, `.aac`.
- FR-03: `openPage(_ index: Int)` — возвращает `.audio(AVPlayerItem, duration:)` для главы по индексу.
- FR-04: `pageCount()` — количество глав (из `AVAsset.chapterMetadataGroups`) или 1 для файлов без глав.
- FR-05: `extractMetadata()` — из `AVAsset.metadata`: title, artist (author), album, artwork.
- FR-06: `extractCover()` — из `AVMetadataItem` с ключом `.commonKeyArtwork`.
- FR-07: Настройка `AVAudioSession.category = .playback` при открытии.
- FR-08: Now Playing Info: `MPNowPlayingInfoCenter.default().nowPlayingInfo` с обложкой, названием, прогрессом.
- FR-09: Remote Control Events: play/pause, next/prev chapter, seek.
- FR-10: Сохранение позиции воспроизведения через `ReadingStateManager`.

## Non-Functional Requirements
- NFR-01: Воспроизведение начинается < 500ms после открытия.
- NFR-02: Фоновое воспроизведение работает без прерываний.

## Boundaries (что НЕ входит)
- Не реализовывать TTS — это TTSService.
- Не реализовывать AudioPlayerView UI.

## Acceptance Criteria
- [ ] M4B с главами воспроизводится, главы доступны в оглавлении.
- [ ] MP3 воспроизводится как единый трек.
- [ ] Фоновое воспроизведение работает.
- [ ] Control Center управляет воспроизведением.
- [ ] Now Playing Info отображается корректно.

## Open Questions
- Как обрабатывать M4B с DRM (Audible AAX)?
- Нужна ли поддержка плейлистов из нескольких MP3 файлов как одной аудиокниги?