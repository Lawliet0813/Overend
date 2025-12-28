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
    
    @FocusedValue(\.showNewLibrary) var showNewLibrary
    @FocusedValue(\.showNewEntry) var showNewEntry
    @FocusedValue(\.selectedLibrary) var selectedLibrary
    @FocusedValue(\.importBibTeXAction) var importBibTeXAction
    @FocusedValue(\.importPDFAction) var importPDFAction

    var body: some Scene {
        WindowGroup {
            NewContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .frame(minWidth: 1200, minHeight: 800)
        }
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
        }

        // 設置視窗
        Settings {
            SettingsView()
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

