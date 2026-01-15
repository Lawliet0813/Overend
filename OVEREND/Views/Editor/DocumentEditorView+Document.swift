//
//  DocumentEditorView+Document.swift
//  OVEREND
//
//  編輯器文件操作方法 - 從 DocumentEditorView 拆分
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - 文件操作方法擴展

extension DocumentEditorView {
    
    // MARK: - 儲存
    
    func saveDocument() {
        document.attributedString = attributedText
        document.updatedAt = Date()
        try? viewContext.save()
        updateUndoRedoState()
    }
    
    // MARK: - 封面
    
    func handleInsertCover(_ info: NCCUCoverInfo) {
        guard let textView = textViewRef, let textStorage = textView.textStorage else { return }
        
        let cover = NCCUFormatService.shared.generateCover(info: info)
        
        textStorage.beginEditing()
        textStorage.insert(cover, at: 0)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
        ToastManager.shared.showSuccess("已插入封面")
    }
    
    // MARK: - 引用
    
    func insertCitation(_ entry: Entry) {
        guard let textView = textViewRef else { return }
        
        let insertionPoint = textView.selectedRange().location
        guard let textStorage = textView.textStorage else { return }
        
        let citationAttributed = NSAttributedString(
            string: "(\(entry.author), \(entry.year.isEmpty ? "n.d." : entry.year))",
            attributes: [
                .foregroundColor: NSColor.black,
                .font: NSFont.systemFont(ofSize: 12)
            ]
        )
        
        textStorage.insert(citationAttributed, at: insertionPoint)
        
        attributedText = textView.attributedString()
        saveDocument()
        
        ToastManager.shared.showSuccess("已插入引用")
    }
    
    // MARK: - 匯入
    
    func handleImport(_ url: URL) {
        Task {
            do {
                let canAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if canAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                let data = try Data(contentsOf: url)
                
                let imported: NSAttributedString
                do {
                    imported = try NSAttributedString(
                        data: data,
                        options: [.documentType: NSAttributedString.DocumentType.officeOpenXML],
                        documentAttributes: nil
                    )
                } catch {
                    imported = try NSAttributedString(
                        data: data,
                        options: [.documentType: NSAttributedString.DocumentType.rtf],
                        documentAttributes: nil
                    )
                }
                
                let mutableImported = NSMutableAttributedString(attributedString: imported)
                mutableImported.addAttribute(
                    .foregroundColor,
                    value: NSColor.black,
                    range: NSRange(location: 0, length: mutableImported.length)
                )
                
                await MainActor.run {
                    attributedText = mutableImported
                    saveDocument()
                    ToastManager.shared.showSuccess("已成功匯入文件（\(imported.length) 字元）")
                }
            } catch {
                await MainActor.run {
                    print("Import error: \(error)")
                    ToastManager.shared.showError("匯入失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 匯出
    
    func exportDocument(format: PandocService.OutputFormat) {
        Task {
            await MainActor.run { isExporting = true }
            
            do {
                let panel = NSSavePanel()
                panel.title = "匯出\(format == .docx ? " DOCX" : " PDF")"
                panel.nameFieldStringValue = "\(document.title).\(format.ext)"
                panel.allowedContentTypes = [format == .docx ? 
                    (UTType(filenameExtension: "docx") ?? .data) : .pdf]
                
                let response = await panel.beginSheetModal(for: NSApp.keyWindow!)
                
                if response == .OK, let url = panel.url {
                    try await exportWithNativeAPI(to: url, format: format)
                    
                    await MainActor.run {
                        ToastManager.shared.showSuccess("已成功匯出")
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            } catch {
                await MainActor.run {
                    print("Export error: \(error)")
                    ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                }
            }
            
            await MainActor.run { isExporting = false }
        }
    }
    
    func exportWithNativeAPI(to url: URL, format: PandocService.OutputFormat) async throws {
        switch format {
        case .docx:
            if let data = try? attributedText.data(
                from: NSRange(location: 0, length: attributedText.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.officeOpenXML]
            ) {
                try data.write(to: url)
            } else {
                let rtfData = try attributedText.data(
                    from: NSRange(location: 0, length: attributedText.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
                let rtfURL = url.deletingPathExtension().appendingPathExtension("rtf")
                try rtfData.write(to: rtfURL)
            }
        case .pdf:
            try await exportPDFNative(to: url)
        default:
            break
        }
    }
    
    func exportPDFNative(to url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))
                textView.textStorage?.setAttributedString(attributedText)
                
                let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
                printInfo.paperSize = NSSize(width: 595, height: 842)
                printInfo.topMargin = 72
                printInfo.bottomMargin = 72
                printInfo.leftMargin = 72
                printInfo.rightMargin = 72
                printInfo.jobDisposition = .save
                printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url
                
                let printOp = NSPrintOperation(view: textView, printInfo: printInfo)
                printOp.showsPrintPanel = false
                printOp.showsProgressPanel = false
                
                if printOp.run() {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "PDF", code: -1))
                }
            }
        }
    }
}
