#!/usr/bin/env python3
"""
Полная проверка проекта VReader перед публикацией файлов.
Запуск: python3 check_refs.py
"""
import re, os, sys

PROJECT = os.path.join(os.path.dirname(__file__), '../App/Vreader/Vreader')
OUTPUTS = PROJECT

def load_final():
    final = {}
    for f in os.listdir(PROJECT):
        if f.endswith('.swift'):
            final[f] = ('project', open(f'{PROJECT}/{f}').read())
    for f in os.listdir(OUTPUTS):
        if f.endswith('.swift') and f != 'check_refs.py':
            final[f] = ('output', open(f'{OUTPUTS}/{f}').read())
    return final

def strip_noise(code):
    code = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '""', code)
    code = re.sub(r'//[^\n]*', '', code)
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    return code

SYSTEM = {
    'String','Int','Double','Bool','Date','UUID','URL','Data','Float','Int64','Int32',
    'UInt64','UInt8','UInt16','UInt32',
    'Optional','Array','Set','Dictionary','Result','IndexSet','Error','Void','Any',
    'CGFloat','CGPoint','CGSize','CGRect','LocalizedError','Never','AnyHashable','AnyObject',
    'UnsafeMutableRawPointer','NSKeyValueChangeKey','URLSessionTask',
    'Locale','NSMetadataQueryUbiquitousDocumentsScope',
    'SecItemAdd','SecItemCopyMatching','SecItemDelete',
    'TimeInterval','CharacterSet','Scanner','Decoder','Encoder',
    'NSLocalizedString','NSAttributedString','NSRange','NSMutableAttributedString',
    'UTType',
    'View','App','Scene','ObservableObject','Observable','Identifiable','Codable',
    'Hashable','Equatable','Comparable','CaseIterable','RawRepresentable','Sendable',
    'Published','State','Binding','StateObject','ObservedObject','EnvironmentObject',
    'EnvironmentKey','AppStorage','Environment','Query','FetchDescriptor','SortDescriptor',
    'ModelContext','ModelContainer','ModelConfiguration','Schema',
    'URLSession','URLRequest','URLResponse','HTTPURLResponse','URLComponents',
    'URLQueryItem','URLCredential','URLResourceKey','FileManager',
    'JSONEncoder','JSONDecoder','XMLParser','XMLParserDelegate','NSObject',
    'NSPredicate','NSMetadataQuery','NSUbiquitousKeyValueStore','NSError',
    'UIImage','NSImage','UIViewRepresentable','UIGestureRecognizer',
    'UITapGestureRecognizer','UISwipeGestureRecognizer','UIPanGestureRecognizer',
    'UIView','UIScrollView','UIImageView','UIViewController',
    'WKWebView','WKWebViewConfiguration','WKNavigationDelegate',
    'WKNavigationAction','WKNavigationActionPolicy','WKScriptMessage',
    'WKUserContentController','WKScriptMessageHandler','WKNavigation',
    'PDFView','PDFDocument','PDFPage','Archive',
    'AVPlayer','AVPlayerItem','AVURLAsset','AVMetadataItem','CMTime',
    'Task','DispatchQueue','MainActor','Timer','NotificationCenter',
    'Notification','UserDefaults','Bundle','OSStatus','Progress',
    'AnyCancellable','AnyPublisher',
    'Color','Font','Image','Text','Button','Spacer','Divider','List','ForEach',
    'VStack','HStack','ZStack','LazyVStack','LazyHStack',
    'ScrollView','NavigationStack','NavigationLink','NavigationPath',
    'TabView','Form','Section','Label','Slider','Picker','TextField','SecureField',
    'Toggle','EmptyView','StrokeStyle','LabeledContent',
    'Group','GeometryReader','GeometryProxy','ContentUnavailableView','ProgressView',
    'RoundedRectangle','Rectangle','Capsule','Circle','LinearGradient','Animation',
    'ViewBuilder','ToolbarItem','ByteCountFormatter','DateFormatter',
    'GridItem','LazyVGrid','DragGesture','TapGesture','UnitPoint','Self',
    'ProgressView','ScrollView','NavigationStack','Sheet','Toolbar',
    'ToolbarItem','ToolbarItemPlacement',
    'SwiftUI','Foundation','AVFoundation','UIKit','WebKit',
    'Context','Coordinator','Keys',
}

ok = True
final = load_final()

# --- 1. Дубликаты типов ---
definitions = {}
for fname, (src, content) in final.items():
    seen_in_file = set()
    for m in re.finditer(r'\b(?:struct|final class|class|enum|protocol|actor|typealias)\s+([A-Z]\w+)', content):
        name = m.group(1)
        if name in seen_in_file:
            continue
        seen_in_file.add(name)
        definitions.setdefault(name, []).append((fname, src))

dups = {k: v for k, v in definitions.items()
        if len({fname for fname, _ in v}) > 1 and k not in ('Coordinator',)}  # Coordinator — nested, не конфликт
if dups:
    ok = False
    print("❌ ДУБЛИКАТЫ ТИПОВ:")
    for name, locs in sorted(dups.items()):
        for fname, src in locs:
            print(f"   {name} в [{src}] {fname}")

# --- 2. Неразрешённые типы ---
all_types = set(definitions.keys())
type_issues = []
for fname, (src, content) in sorted(final.items()):
    if src != 'output': continue  # проверяем только наши outputs
    clean = strip_noise(content)
    local = {m.group(1) for m in re.finditer(r'\b(?:struct|class|enum|protocol|actor)\s+([A-Z]\w+)', content)}
    refs = set()
    for pat in [r':\s*([A-Z]\w+)', r'->\s*([A-Z]\w+)', r'\b([A-Z]\w+)\s*\(', r'[<\[]\s*([A-Z]\w+)']:
        for m in re.finditer(pat, clean):
            refs.add(m.group(1))
    missing = sorted(r for r in refs if r not in all_types and r not in SYSTEM and r not in local)
    if missing:
        type_issues.append((fname, missing))

if type_issues:
    ok = False
    print("❌ НЕРАЗРЕШЁННЫЕ ТИПЫ:")
    for fname, missing in type_issues:
        print(f"   {fname}: {missing}")

# --- 3. Book свойства ---
book_props = set()
for fname, (src, content) in final.items():
    for ext_m in re.finditer(r'extension\s+Book\s*\{(.*?)\n\}', content, re.DOTALL):
        for m in re.finditer(r'\bvar\s+(\w+)\b', ext_m.group(1)):
            book_props.add(m.group(1))
book_model = final.get('Book.swift', ('', ''))[1]
for m in re.finditer(r'\bvar\s+(\w+)\s*[=:]', book_model):
    book_props.add(m.group(1))

book_issues = []
VIEW_FILES = {'LibraryView.swift','BookCardView.swift','ReadingView.swift',
              'ReadingSessionView.swift','ReaderView.swift','BookDetailView.swift',
              'ReadingView.swift','ReadingSessionView.swift'}
for fname, (src, content) in sorted(final.items()):
    if src != 'output': continue
    if fname not in VIEW_FILES: continue  # только View файлы используют book: Book
    clean = strip_noise(content)
    used = re.findall(r'\bbook\.([a-z]\w+)', clean)
    missing = sorted(set(p for p in used if p not in book_props))
    if missing:
        book_issues.append((fname, missing))

if book_issues:
    ok = False
    print("❌ НЕИЗВЕСТНЫЕ СВОЙСТВА Book:")
    for fname, missing in book_issues:
        print(f"   {fname}: book.{{{', '.join(missing)}}}")

# --- 4. AppState свойства и методы ---
appstate_members = set()
appstate_src = final.get('AppState.swift', ('',''))[1]
for m in re.finditer(r'\bvar\s+(\w+)\b', appstate_src):
    appstate_members.add(m.group(1))
for m in re.finditer(r'\bfunc\s+(\w+)\b', appstate_src):
    appstate_members.add(m.group(1))

appstate_issues = []
for fname, (src, content) in sorted(final.items()):
    if src != 'output': continue
    clean = strip_noise(content)
    used = re.findall(r'appState\.(\w+)', clean)
    missing = sorted(set(p for p in used if p not in appstate_members))
    if missing:
        appstate_issues.append((fname, missing))

if appstate_issues:
    ok = False
    print("❌ НЕИЗВЕСТНЫЕ ЧЛЕНЫ AppState:")
    for fname, missing in appstate_issues:
        print(f"   {fname}: appState.{{{', '.join(missing)}}}")

# --- 5. Скобки ---
brace_issues = []
for fname, (src, content) in sorted(final.items()):
    if src != 'output': continue
    opens = content.count('{'); closes = content.count('}')
    if opens != closes:
        brace_issues.append((fname, opens, closes))

if brace_issues:
    ok = False
    print("❌ НЕСБАЛАНСИРОВАННЫЕ СКОБКИ:")
    for fname, o, c in brace_issues:
        print(f"   {fname}: {{ {o} vs }} {c}")


# --- 6. iOS API совместимость ---
# Deployment target проекта — iOS 17 (используется ContentUnavailableView)
IOS_TARGET = 17

API_VERSIONS = {
    # iOS 13
    'ignoresSafeArea':             13,
    'LazyVGrid':                   13,
    'LazyHGrid':                   13,
    'StateObject':                 14,
    'AppStorage':                  14,
    'SceneStorage':                14,
    # iOS 14
    'fullScreenCover':             14,
    'ProgressView':                14,
    'VideoPlayer':                 14,
    # iOS 15
    'swipeActions':                15,
    'searchable':                  15,
    'refreshable':                 15,
    'symbolRenderingMode':         15,
    'symbolVariant':               15,
    'FocusState':                  15,
    'AsyncImage':                  15,
    'safeAreaInset':               15,
    # iOS 16
    'toolbarBackground':           16,
    'toolbarColorScheme':          16,
    'NavigationStack':             16,
    'NavigationSplitView':         16,
    'GridRow':                     16,
    'Layout':                      16,
    'ViewThatFits':                16,
    'AnyLayout':                   16,
    'ShareLink':                   16,
    'LabeledContent':              16,
    'MultiDatePicker':             16,
    # iOS 17
    'ContentUnavailableView':      17,
    'TipKit':                      17,
    'scrollPosition':              17,
    'scrollTargetBehavior':        17,
    'ScrollTargetBehavior':        17,
    'Observable':                  17,
    'Observation':                 17,
    'onChange':                    17,
    'MapKit':                      17,
    'SwiftData':                   17,
    'ModelContainer':              17,
    'ModelContext':                17,
    'Query':                       17,
    'Model':                       17,
}

api_issues = []
for fname, (src, content_) in sorted(final.items()):
    if src != 'output': continue
    file_issues = []
    for api, min_ios in API_VERSIONS.items():
        if min_ios > IOS_TARGET and re.search(r'\b' + api + r'\b', content_):
            file_issues.append(f"{api} (iOS {min_ios}+)")
    if file_issues:
        api_issues.append((fname, file_issues))

if api_issues:
    ok = False
    print(f"❌ API ВЫШЕ iOS {IOS_TARGET} DEPLOYMENT TARGET:")
    for fname, issues in api_issues:
        print(f"   {fname}: {issues}")
else:
    print(f"✅ Все API совместимы с iOS {IOS_TARGET}+")

if ok:
    print("✅ Проект чист — можно публиковать")
else:
    print("\n⛔ Исправь ошибки перед публикацией")
sys.exit(0 if ok else 1)
