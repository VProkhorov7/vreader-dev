import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = iCloudSettingsStore.shared

    var body: some View {
        NavigationStack {
            List {

                // MARK: Чтение
                Section("Чтение") {
                    HStack {
                        Label("Размер шрифта", systemImage: "textformat.size")
                        Spacer()
                        Text("\(Int(settings.fontSize))pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.fontSize, in: 12...28, step: 1)
                        .tint(Color.accentColor)

                    HStack {
                        Label("Межстрочный интервал", systemImage: "text.alignleft")
                        Spacer()
                        Text(String(format: "%.1f", settings.lineSpacing))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.lineSpacing, in: 1.0...2.5, step: 0.1)
                        .tint(Color.accentColor)

                    NavigationLink {
                        FontPickerView(selectedFont: $settings.fontName)
                    } label: {
                        HStack {
                            Label("Шрифт", systemImage: "f.cursive")
                            Spacer()
                            Text(settings.fontName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: Тема
                Section("Тема оформления") {
                    Picker("Тема", selection: $settings.readerTheme) {
                        Label("Светлая", systemImage: "sun.max").tag("light")
                        Label("Сепия",   systemImage: "leaf").tag("sepia")
                        Label("Тёмная",  systemImage: "moon.fill").tag("dark")
                    }
                    .pickerStyle(.inline)
                }

                // MARK: Синхронизация
                Section("Синхронизация") {
                    Label("iCloud синхронизация", systemImage: "icloud")
                    // TODO: Фаза 3 — синхронизация прогресса и заметок
                    Text("Прогресс и закладки синхронизируются через iCloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: ИИ (Фаза 4)
                Section("Искусственный интеллект") {
                    Label("ИИ-функции (скоро)", systemImage: "sparkles")
                        .foregroundStyle(.secondary)
                    Text("Вопросы по книге, резюме глав, умные заметки — появятся в следующем обновлении")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: Приложение
                Section("Приложение") {
                    HStack {
                        Label("Версия", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        // TODO: ссылка на отзыв в App Store
                    } label: {
                        Label("Оставить отзыв", systemImage: "star")
                    }

                    Button {
                        // TODO: поддержка
                    } label: {
                        Label("Написать в поддержку", systemImage: "envelope")
                    }
                }

                #if DEBUG
                Section("Разработка") {
                    Label("DEBUG-режим активен", systemImage: "hammer.fill")
                        .foregroundStyle(.orange)
                }
                #endif
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Font Picker

struct FontPickerView: View {
    @Binding var selectedFont: String

    private let fonts = [
        "Georgia", "Palatino", "Times New Roman",
        "Helvetica Neue", "SF Pro Text", "Menlo"
    ]

    var body: some View {
        List {
            ForEach(fonts, id: \.self) { font in
                HStack {
                    Text("Пример текста")
                        .font(.custom(font, size: 16))
                    Spacer()
                    Text(font)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if selectedFont == font {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selectedFont = font }
            }
        }
        .navigationTitle("Выбор шрифта")
    }
}

#Preview {
    SettingsView()
}
