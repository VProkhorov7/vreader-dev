# Specification: design-tokens

## Context
Все UI компоненты должны использовать единый источник дизайн-значений. Хардкод цветов, шрифтов и отступов в компонентах запрещён архитектурными инвариантами. DesignTokens.swift — единственный файл, который содержит все константы.

## User Scenarios
1. **Разработчик добавляет новый компонент:** Берёт все значения из DesignTokens, не придумывает новые числа.
2. **Дизайнер меняет радиус скругления:** Изменение в одном месте (DesignTokens) применяется везде.

## Functional Requirements
- FR-01: Определить enum DesignTokens с вложенными namespace: Colors, Typography, Spacing, Radius, Animation, Reader
- FR-02: Colors содержит: surfaceBase, surfaceLow, surfaceMid, surfaceHigh, accent, inkPrimary, inkMuted — как статические Color значения для каждой темы
- FR-03: Typography содержит: fontDisplay, fontBody, минимальный размер (.caption2), поддержку Dynamic Type
- FR-04: Spacing содержит: xs(4), sm(8), md(16), lg(24), xl(32), xxl(48)
- FR-05: Radius содержит: small(4), medium(8), large(16), card(12)
- FR-06: Animation содержит: fast(0.15s), normal(0.25s), slow(0.4s), spring параметры
- FR-07: Reader содержит: memoryBudgetPerPage(50MB), maxPagesInMemory(3), defaultFontSize(17), minFontSize(12), maxFontSize(32)
- FR-08: Frosted glass параметры: surfaceOpacity(0.85), blurRadius(20)

## Non-Functional Requirements
- NFR-01: Файл не должен импортировать UIKit напрямую — только SwiftUI
- NFR-02: Все значения — статические константы, не вычисляемые свойства с side effects

## Boundaries (что НЕ входит)
- Не включать логику тем (это AppTheme)
- Не включать строки локализации
- Не включать бизнес-логику

## Acceptance Criteria
- [ ] DesignTokens.swift существует и компилируется
- [ ] Все namespace присутствуют: Colors, Typography, Spacing, Radius, Animation, Reader
- [ ] memoryBudgetPerPage = 50 * 1024 * 1024 (50MB в байтах)
- [ ] maxPagesInMemory = 3
- [ ] Frosted glass константы определены
- [ ] Нет хардкод числовых литералов в других файлах (проверяется review)

## Open Questions
- Нужно ли разделять светлые/тёмные варианты цветов в DesignTokens или это полностью делегируется AppTheme?
- Использовать ли SwiftUI Color(red:green:blue:) или Color(hex:) extension?