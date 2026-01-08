//
//  FileDialogs_iPad.swift
//  OVEREND
//
//  iPad 專用的檔案對話框實現 - 使用 UIDocumentPicker
//

#if os(iOS)
import UIKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - iPad File Dialog Provider

struct iPadFileDialogProvider: FileDialogProvider {
    
    func showSavePanel(
        defaultName: String,
        allowedTypes: [UTType],
        completion: @escaping (URL?) -> Void
    ) {
        // iPad 使用 UIDocumentPicker 進行儲存
        // 需要透過 SwiftUI 的 fileExporter 或自訂實現
        // 這裡提供基礎框架，實際使用時透過 SwiftUI modifier
        completion(nil)
    }
    
    func showOpenPanel(
        allowedTypes: [UTType],
        allowsMultipleSelection: Bool,
        completion: @escaping ([URL]) -> Void
    ) {
        // iPad 使用 UIDocumentPicker 進行開啟
        // 實際使用時透過 SwiftUI 的 fileImporter modifier
        completion([])
    }
}

// MARK: - Document Picker Representable

struct DocumentPickerView: UIViewControllerRepresentable {
    let allowedTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onCompletion: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onCompletion: ([URL]) -> Void
        
        init(onCompletion: @escaping ([URL]) -> Void) {
            self.onCompletion = onCompletion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onCompletion(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCompletion([])
        }
    }
}

// MARK: - iPad Specific Helpers

struct iPadHelpers {
    /// 分享檔案
    static func shareFile(url: URL, from sourceView: UIView) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = sourceView
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    /// 獲取文件目錄
    static var documentsDirectory: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}

#endif
