//
//  OVERENDApp.swift
//  OVEREND
//
//  Created by Claude on 2025-12-27.
//  讓研究者專注於研究本身，而不是文獻管理。
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - FocusedValues for Menu Commands

struct LibraryFocusedValueKey: FocusedValueKey {
    typealias Value = Library
}

struct ShowNewLibraryKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ShowNewEntryKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ImportBibTeXActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct ImportPDFActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var selectedLibrary: Library? {
        get { self[LibraryFocusedValueKey.self] }
        set { self[LibraryFocusedValueKey.self] = newValue }
    }
    
    var showNewLibrary: Binding<Bool>? {
        get { self[ShowNewLibraryKey.self] }
        set { self[ShowNewLibraryKey.self] = newValue }
    }
    
    var showNewEntry: Binding<Bool>? {
        get { self[ShowNewEntryKey.self] }
        set { self[ShowNewEntryKey.self] = newValue }
    }
    
    var importBibTeXAction: (() -> Void)? {
        get { self[ImportBibTeXActionKey.self] }
        set { self[ImportBibTeXActionKey.self] = newValue }
    }
    
    var importPDFAction: (() -> Void)? {
        get { self[ImportPDFActionKey.self] }
        set { self[ImportPDFActionKey.self] = newValue }
    }
}

// MARK: - App Entry

@main
struct OVERENDApp: App {
    // Core Data 持久化控制器
    let persistenceController = PersistenceController.shared

    // 初始化時測試 Rust 核心
    init() {
        testOverendCore()
    }

    // 測試 OverendCore 是否正常運作
    private func testOverendCore() {
        if #available(macOS 13.0, *) {
            let bridge = OverendCoreBridge.shared
            let message = bridge.helloWorld()
            print("🦀 Rust Core: \(message)")
        } else {
            print("⚠️ OverendCore requires macOS 13.0+")
        }
    }
    
    @FocusedValue(\.showNewLibrary) var showNewLibrary
    @FocusedValue(\.showNewEntry) var showNewEntry
    @FocusedValue(\.selectedLibrary) var selectedLibrary
    @FocusedValue(\.importBibTeXAction) var importBibTeXAction
    @FocusedValue(\.importPDFAction) var importPDFAction
    
    // Splash Screen 狀態
    @State private var showSplash = true
    
    // 主題狀態
    @StateObject private var appTheme = AppTheme()

    var body: some Scene {
        WindowGroup {
            ZStack {
                NewContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(appTheme) // 注入主題
                    .opacity(showSplash ? 0 : 1)
                
                // Splash Screen
                if showSplash {
                    SplashScreenView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)  // 移除標題列
        .commands {
            // 自定義菜單命令
            CommandGroup(replacing: .newItem) {
                Button("新增文獻庫...") {
                    showNewLibrary?.wrappedValue = true
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("新增書目...") {
                    showNewEntry?.wrappedValue = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(selectedLibrary == nil)
            }

            CommandGroup(after: .importExport) {
                Button("匯入 BibTeX...") {
                    importBibTeXAction?()
                }
                .keyboardShortcut("i", modifiers: [.command])
                .disabled(selectedLibrary == nil)

                Button("匯入 PDF...") {
                    importPDFAction?()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(selectedLibrary == nil)

                Divider()

                Button("匯出 BibTeX...") {
                    exportBibTeX()
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(selectedLibrary == nil)
            }
            
            // 快速操作命令
            CommandGroup(after: .toolbar) {
                Button("快速搜尋") {
                    NotificationCenter.default.post(name: .quickSearch, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
                
                Button("AI 助手") {
                    NotificationCenter.default.post(name: .showAIAssistant, object: nil)
                }
                .keyboardShortcut("/", modifiers: [.command])
                
                Button("切換文獻庫") {
                    NotificationCenter.default.post(name: .switchToLibrary, object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Divider()
                
                Button("測試 OCR") {
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsSheet(
                        NSHostingController(rootView: OCRTestView())
                    )
                }
                .keyboardShortcut("o", modifiers: [.command, .option])
                
                Button("匯出訓練資料") {
                    let exportView = TrainingDataExportView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsSheet(
                        NSHostingController(rootView: exportView)
                    )
                }
                .keyboardShortcut("t", modifiers: [.command, .option])
                
                Button("手動標註資料") {
                    let labelingView = DataLabelingView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsSheet(
                        NSHostingController(rootView: labelingView)
                    )
                }
                .keyboardShortcut("l", modifiers: [.command, .option])
                
                /*
                Button("測試 ML 模型") {
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsSheet(
                        NSHostingController(rootView: MLModelTestView())
                    )
                }
                .keyboardShortcut("m", modifiers: [.command, .option])
                */
            }
        }

        // 設置視窗 - 使用 Emerald 設計
        Settings {
            EmeraldSettingsView()
                .environmentObject(appTheme) // 注入主題
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func exportBibTeX() {
        guard let library = selectedLibrary else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.text]
        panel.nameFieldStringValue = "\(library.name).bib"
        panel.prompt = "導出"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try BibTeXGenerator.exportLibrary(
                        library,
                        to: url,
                        in: persistenceController.container.viewContext
                    )
                } catch {
                    print("導出失敗: \(error)")
                }
            }
        }
    }
}

