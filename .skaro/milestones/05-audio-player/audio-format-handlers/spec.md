# Specification: audio-format-handlers

## Context
Аудиокниги (MP3, M4A, M4B, AAC) воспроизводятся через AVFoundation. M4B поддерживает главы через AVAsset. AudioFormatHandler реализует FileFormatHandler протокол для аудио форматов.

## User Scenarios
1. **Открытие M4B аудиокниги:** AudioHandler загружает файл, извлекает главы, метаданные и обложку.
2. **Воспроизведение MP3:** Простое воспроизведение без глав.
3. **Переход к главе:** AudioHandler.openPage(chapterIndex) перемещает позицию воспроизведения.

## Functional Requirements
- FR-01: AudioFormatHandler реализует FileFormatHandler
- FR-02: Использует AVPlayer для воспроизведения
- FR-03: Извлечение глав из M4B через AVAsset.chapterMetadataGroups
- FR-04: openPage() для аудио = seek to chapter start time
- FR-05: extractMetadata(): title, author, album из ID3/iTunes tags
- FR-06: extractCover(): обложка из ID3 APIC тега или iTunes artwork
- FR-07: pageCount() = количество глав (или 1 для MP3 без глав)
- FR-08: Поддержка форматов: mp3, m4a, m4b, aac
- FR-09: Ошибки через VReaderError

## Non-Functional Requirements
- NFR-01: Открытие аудиофайла < 500ms
- NFR-02: Не загружать весь файл в память

## Boundaries (что НЕ входит)
- Не реализовывать UI плеера
- Не реализовывать TTS
- Не реализовывать скачивание аудиокниг

## Acceptance Criteria
- [ ] AudioFormatHandler реализует FileFormatHandler
- [ ] M4B главы извлекаются корректно
- [ ] Метаданные и обложка извлекаются
- [ ] openPage() выполняет seek
- [ ] Все 4 формата поддерживаются

## Open Questions
- Нужна ли поддержка многофайловых аудиокниг (папка с MP3 файлами)?
- Как обрабатывать аудиокниги с переменным битрейтом для точного seek?