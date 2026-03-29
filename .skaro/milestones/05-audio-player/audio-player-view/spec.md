# Specification: audio-player-view

## Context
AudioPlayerView — полноэкранный плеер для аудиокниг. Интегрируется с Control Center и экраном блокировки через MPNowPlayingInfoCenter и MPRemoteCommandCenter. Фоновое воспроизведение через AVAudioSession.category = .playback.

## User Scenarios
1. **Пользователь слушает аудиокнигу:** Видит обложку, название, прогресс, кнопки управления.
2. **Сворачивает приложение:** Воспроизведение продолжается, Control Center показывает плеер.
3. **Нажимает паузу в наушниках:** MPRemoteCommandCenter обрабатывает команду.

## Functional Requirements
- FR-01: Полноэкранный UI: большая обложка, название, автор, прогресс slider, кнопки play/pause/prev/next
- FR-02: Скорость воспроизведения: 0.75x, 1x, 1.25x, 1.5x, 2x
- FR-03: Список глав с текущей выделенной
- FR-04: Sleep timer: 15, 30, 45, 60 минут
- FR-05: AVAudioSession.category = .playback для фонового воспроизведения
- FR-06: MPNowPlayingInfoCenter: обложка, название, автор, позиция, длительность
- FR-07: MPRemoteCommandCenter: play, pause, nextTrack, previousTrack, changePlaybackPosition
- FR-08: PlayerState обновляется при всех изменениях
- FR-09: Мини-плеер (AudioMiniPlayerView) для отображения поверх tab bar
- FR-10: Все строки через L10n

## Non-Functional Requirements
- NFR-01: Фоновое воспроизведение не прерывается при сворачивании
- NFR-02: Control Center обновляется < 500ms

## Boundaries (что НЕ входит)
- Не реализовывать Gemini TTS (milestone 06)
- Не реализовывать синхронизацию позиции через CloudKit

## Acceptance Criteria
- [ ] Полноэкранный UI плеера работает
- [ ] Фоновое воспроизведение работает
- [ ] Control Center показывает Now Playing
- [ ] Remote commands (наушники) работают
- [ ] Скорость воспроизведения меняется
- [ ] Sleep timer работает
- [ ] PlayerState обновляется корректно

## Open Questions
- Нужна ли поддержка AirPlay на этом этапе?
- Как обрабатывать прерывания (звонок, другое аудио приложение)?