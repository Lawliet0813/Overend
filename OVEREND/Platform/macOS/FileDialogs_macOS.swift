//
//  FileDialogs_macOS.swift
//  OVEREND
//
//  macOS 專用的檔案對話框實現
//

#if os(macOS)
import AppKit
import UniformTypeIdentifiers

struct MacOSFileDialogProvider: FileDialogProvider {
    
    func showSavePanel(
        defaultName: String,
        allowedTypes: [UTType],
        completion: @escaping (URL?) -> Void
    ) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = allowedTypes
        panel.nameFieldStringValue = defaultName
        panel.prompt = "儲存"
        panel.message = "選擇儲存位置"
        
        panel.begin { response in
            if response == .OK {
                completion(panel.url)
            } else {
                completion(nil)
            }
        }
    }
    
    func showOpenPanel(
        allowedTypes: [UTType],
        allowsMultipleSelection: Bool,
        completion: @escaping ([URL]) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.prompt = "選擇"
        
        panel.begin { response in
            if response == .OK {
                completion(panel.urls)
            } else {
                completion([])
            }
        }
    }
}

// MARK: - macOS Specific Helpers

struct MacOSHelpers {
    /// 在 Finder 中顯示檔案
    static func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    /// 使用預設應用程式開啟檔案
    static func openWithDefaultApp(url: URL) {
        NSWorkspace.shared.open(url)
    }
    
    /// 獲取應用程式支援目錄
    static var applicationSupportDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }
}

#endif
