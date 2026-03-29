# Specification: annotation-service

## Context
Инвариант #2 требует что все мутации Annotation инкрементируют lamportClock. AnnotationService — единственный способ создавать и изменять аннотации. Аннотации хранятся в SwiftData и будут синхронизироваться через CloudKit в milestone 05.

## User Scenarios
1. **Пользователь выделяет текст:** Long press → Highlight → AnnotationService.createHighlight() → lamportClock = 1.
2. **Пользователь добавляет заметку:** AnnotationService.createNote() с текстом комментария.
3. **Пользователь удаляет аннотацию:** AnnotationService.delete() → запись в PendingChangesQueue.

## Functional Requirements
- FR-01: AnnotationService — actor
- FR-02: func createBookmark(bookID: UUID, page: Int, chapter: Int, context: ModelContext) async throws -> Annotation
- FR-03: func createHighlight(bookID: UUID, text: String, page: Int, chapter: Int, color: String, context: ModelContext) async throws -> Annotation
- FR-04: func createNote(bookID: UUID, text: String, comment: String, page: Int, chapter: Int, context: ModelContext) async throws -> Annotation
- FR-05: func update(_ annotation: Annotation, comment: String, context: ModelContext) async throws — инкрементирует lamportClock
- FR-06: func delete(_ annotation: Annotation, context: ModelContext) async throws — добавляет запись в PendingChangesQueue
- FR-07: Каждая мутация: lamportClock += 1, deviceID = UIDevice.current.identifierForVendor
- FR-08: func annotations(for bookID: UUID, context: ModelContext) async -> [Annotation]
- FR-09: Все операции через ModelContext (инвариант #2)

## Non-Functional Requirements
- NFR-01: Создание аннотации < 100ms
- NFR-02: lamportClock никогда не уменьшается

## Boundaries (что НЕ входит)
- Не реализовывать CloudKit синхронизацию (milestone 05)
- Не реализовывать UI для аннотаций (только сервис)
- Не реализовывать conflict resolution (milestone 05)

## Acceptance Criteria
- [ ] AnnotationService actor определён
- [ ] Все 3 типа аннотаций создаются
- [ ] lamportClock инкрементируется при каждой мутации
- [ ] deviceID устанавливается корректно
- [ ] Удаление добавляет запись в PendingChangesQueue
- [ ] Все операции через ModelContext

## Open Questions
- Как хранить позицию хайлайта в тексте (character offset vs xpath для EPUB)?
- Нужна ли поддержка цветных хайлайтов (несколько цветов) с первого релиза?