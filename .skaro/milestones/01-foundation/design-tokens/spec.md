# Specification: design-tokens

## Context
Все UI компоненты должны использовать единый источник дизайн-значений. Хардкод цветов, шрифтов и отступов в компонентах запрещён архитектурными инвариантами. DesignTokens.swift — единственный файл, который содержит все константы.

`DesignTokens` является строительным блоком для `AppTheme`: он предоставляет сырую палитру и нейтральные дефолты, которые `AppTheme` собирает в семантические роли. Все остальные файлы (включая `FileFormatHandler`, логику вытеснения страниц) обязаны ссылаться на `DesignTokens.Reader` как на единственный источник истины для бюджетов памяти.

## User Scenarios
1. **Разработчик добавляет новый компонент:** Берёт все значения из DesignTokens, не придумывает новые числа.
2. **Дизайнер меняет радиус скругления:** Изменение в одном месте (DesignTokens) применяется везде.
3. **Разработчик реализует логику вытеснения страниц ридера:** Читает `DesignTokens.Reader.memoryBudgetPerPage` и `DesignTokens.Reader.maxPagesInMemory` — не дублирует числа из архитектурных инвариантов.
4. **Разработчик применяет анимацию:** Использует `DesignTokens.Animation.springStandard` напрямую в `.animation()` модификаторе, не собирает параметры вручную.

## Functional Requirements
- FR-01: Определить `enum DesignTokens` как caseless enum с вложенными caseless namespace-enum: `Colors`, `Typography`, `Spacing`, `Radius`, `Animation`, `Reader`
- FR-02: `Colors` содержит сырые палитровые константы (hex-based static `Color` значения) — строительные блоки для `AppTheme`, не семантические роли. Обязательные константы: `surfaceBase`, `surfaceLow`, `surfaceMid`, `surfaceHigh`, `accent`, `inkPrimary`, `inkMuted`
- FR-03: `Typography` содержит конкретные `Font` значения на основе системных шрифтов (`Font.system`, `Font.serif`) как нейтральные дефолты. `AppTheme` переопределяет их по теме. Обязательные константы: `fontDisplay`, `fontBody`, минимальный размер (`.caption2`), поддержка Dynamic Type через `.scaledMetric` или стандартные SwiftUI text styles
- FR-04: `Spacing` содержит: `xs`(4), `sm`(8), `md`(16), `lg`(24), `xl`(32), `xxl`(48) — как `CGFloat` статические константы
- FR-05: `Radius` содержит: `small`(4), `medium`(8), `large`(16), `card`(12) — как `CGFloat` статические константы
- FR-06: `Animation` содержит:
  - Сырые константы длительности: `fast`(0.15s), `normal`(0.25s), `slow`(0.4s) — как `Double`
  - Spring параметры: `springDamping`, `springResponse` — как `Double`
  - Готовые `Animation` значения: `easeInOutFast`, `easeInOutNormal`, `easeInOutSlow`, `springStandard` — для прямого использования в `.animation()` модификаторах
- FR-07: `Reader` содержит: `memoryBudgetPerPage`(50 × 1024 × 1024 байт), `maxPagesInMemory`(3), `defaultFontSize`(17), `minFontSize`(12), `maxFontSize`(32) — как `Int` или `CGFloat` по смыслу. Является единственным источником истины для всего проекта
- FR-08: Frosted glass параметры в `Colors` или отдельном namespace: `surfaceOpacity`(0.85 как `Double`), `blurRadius`(20 как `CGFloat`)
- FR-09: Приватный `Color(hex:)` extension определён внутри `DesignTokens.swift` — самодостаточный, не требует отдельного файла. Используется только внутри `Colors` для инициализации констант

## Non-Functional Requirements
- NFR-01: Файл не должен импортировать `UIKit` напрямую — только `SwiftUI`
- NFR-02: Все значения — статические константы, не вычисляемые свойства с side effects
- NFR-03: `enum DesignTokens` и все вложенные namespace — caseless enums (предотвращает инстанцирование, идиоматичный Swift паттерн для namespace)
- NFR-04: `Color(hex:)` extension помечен `private` — не загрязняет глобальный namespace `Color`
- NFR-05: Файл полностью самодостаточен — не импортирует другие модули проекта

## Boundaries (что НЕ входит)
- Не включать логику тем (это `AppTheme`) — семантические роли цветов определяются там
- Не включать строки локализации
- Не включать бизнес-логику
- Не включать `UIColor`, `NSColor` или любые platform-specific типы

## Acceptance Criteria
- [ ] `DesignTokens.swift` существует и компилируется без предупреждений
- [ ] `enum DesignTokens` — caseless; все вложенные namespace (`Colors`, `Typography`, `Spacing`, `Radius`, `Animation`, `Reader`) — caseless enums
- [ ] `Colors` содержит все 7 обязательных констант: `surfaceBase`, `surfaceLow`, `surfaceMid`, `surfaceHigh`, `accent`, `inkPrimary`, `inkMuted` — все типа `Color`
- [ ] `Colors` содержит `surfaceOpacity: Double = 0.85` и `blurRadius: CGFloat = 20`
- [ ] `Typography` содержит `fontDisplay`, `fontBody` — типа `Font`; использует только системные шрифты
- [ ] `Spacing` содержит все 6 констант (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`) типа `CGFloat` с правильными значениями
- [ ] `Radius` содержит все 4 константы (`small`, `medium`, `large`, `card`) типа `CGFloat` с правильными значениями
- [ ] `Animation` содержит `fast: Double = 0.15`, `normal: Double = 0.25`, `slow: Double = 0.4`
- [ ] `Animation` содержит готовые `Animation` значения: `easeInOutFast`, `easeInOutNormal`, `easeInOutSlow`, `springStandard` — типа `Animation`
- [ ] `Reader.memoryBudgetPerPage = 50 * 1024 * 1024`
- [ ] `Reader.maxPagesInMemory = 3`
- [ ] `Reader.defaultFontSize = 17`, `Reader.minFontSize = 12`, `Reader.maxFontSize = 32`
- [ ] `Color(hex:)` extension присутствует в файле, помечен `private`, не экспортируется
- [ ] Файл импортирует только `SwiftUI` — никакого `UIKit`, `AppKit`, других модулей проекта
- [ ] Нет хардкод числовых литералов в других файлах проекта для значений, определённых в `DesignTokens` (проверяется review и `check_refs.py`)
- [ ] `FileFormatHandler` и логика вытеснения страниц ссылаются на `DesignTokens.Reader`, а не содержат собственные числа

## Open Questions
*(все вопросы разрешены, открытых вопросов нет)*