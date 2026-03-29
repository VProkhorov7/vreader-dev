### Data Flow Invariants

1. **Единственный источник истины для isPremium**
   `Transaction.currentEntitlements` (StoreKit 2) — единственный
   источник истины. `iCloudSettingsStore` — только кэш TTL 24ч.
   `PremiumGate.check()` всегда проходит через `PremiumStateValidator`.
   Синхронизация isPremium через CloudKit запрещена.

2. **Все мутации Book/Annotation идут через modelContext**
   Прямая запись в SwiftData минуя `@ModelContext` запрещена.
   Все изменения аннотаций инкрементируют `lamportClock`.

3. **Credentials не покидают Keychain**
   Никаких паролей, токенов, API ключей в: логах, UI state,
   UserDefaults, iCloudSettingsStore, CloudKit, аналитике.

4. **Все строки пользовательского интерфейса через L10n.***
   Хардкод строк в UI запрещён. Проверяется через check_refs.py.

5. **Файловые ссылки через bookmarkData**
   `Book.bookmarkData` — основной идентификатор файла.
   `Book.filePath` — только кэш. При broken path используется
   `FileReferenceResolver.repair()`.

6. **coverData запрещён в SwiftData**
   Обложки хранятся только в Documents/Covers/{bookID}.jpg.
   В SwiftData только `coverPath: String`.

### Performance Contracts

7. **Загрузка списка библиотеки**
   P95 < 300ms для 1000 книг. Достигается через:
   - `coverPath` вместо `coverData` в SwiftData
   - Lazy loading обложек через AsyncImage
   - Пагинация при > 500 книг

8. **Открытие книги**
   P95 < 1s для первой страницы любого формата.
   Достигается через: async FileFormatHandler, предзагрузка
   следующей страницы в фоне.

9. **Memory budget для ридера**
   Максимум 50MB на страницу в памяти.
   Максимум 3 страницы одновременно (текущая + соседние).
   При превышении — автоматическая выгрузка дальних страниц.

10. **AI запросы**
    Интерактивные (перевод по запросу): timeout 10s.
    Фоновые (Summary, X-Ray): timeout 30s.
    При timeout — graceful degradation с понятным сообщением.

### Security Invariants

11. **OAuth только через ASWebAuthenticationSession**
    WKWebView для OAuth запрещён. Проверяется code review.

12. **UTType через optional binding**
    Force-unwrap UTType запрещён. Проверяется check_refs.py.

13. **Gemini API ключ только в Keychain**
    Не в коде, не в Info.plist, не в UserDefaults.

14. **Никаких PII в логах**
    DiagnosticsService не логирует: email, имена файлов
    с личными данными, токены, ключи, содержимое книг.

### Consistency Rules

15. **Идемпотентность CloudKit операций**
    Все CKRecord операции идемпотентны.
    Retry с exponential backoff: 1s → 2s → 4s → 8s → 16s.
    Максимум 5 попыток. После — запись в PendingChangesQueue.

16. **Conflict resolution для аннотаций**
    Оба изменили → merge с `lamportClock`.
    Один удалил, другой изменил → `.userPrompt`.
    Позиция чтения → `.lastWriteWins` по `lamportClock`.

17. **Schema migration обязательна**
    Каждое изменение SwiftData модели = новая VersionedSchema.
    SchemaMigrationPlan тестируется на реальных данных.

18. **Зависимые файлы публикуются вместе**
    Файлы, ссылающиеся друг на друга, всегда в одном PR/коммите.
    Проверяется check_refs.py.

### Observability Invariants

19. **Все ошибки типизированы**
    Использование `Error` без `ErrorCode` запрещено в публичных API.
    Каждая ошибка содержит: код, описание, recovery hint.

20. **Circuit breaker для внешних сервисов**
    AI сервисы (Gemini), облачные провайдеры:
    3 последовательные ошибки → `.degraded` статус.
    Автоматическое восстановление через 60 секунд.
    Пользователь уведомляется о деградации.

---