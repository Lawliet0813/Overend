//
//  DocumentExportService.swift
//  OVEREND
//
//  文檔匯出服務 - 支援 PDF、DOCX 等格式
//

import Foundation
import AppKit
import UniformTypeIdentifiers

/// 匯出格式類型
enum ExportFormat {
    case pdf
    case docx

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .docx: return "docx"
        }
    }

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .docx: return "Word 文件"
        }
    }

    var contentType: UTType {
        switch self {
        case .pdf: return .pdf
        case .docx: return UTType(filenameExtension: "docx") ?? .data
        }
    }
}

/// 文檔匯出服務
class DocumentExportService {

    // MARK: - Public Methods

    /// 顯示匯出對話框並執行匯出
    static func export(
        document: Document,
        format: ExportFormat,
        template: FormatTemplate
    ) async throws {
        let url = try await showSavePanel(for: document, format: format)

        switch format {
        case .pdf:
            try await exportToPDF(document: document, url: url, template: template)
        case .docx:
            try await exportToDOCX(document: document, url: url)
        }

        await MainActor.run {
            ToastManager.shared.showSuccess("已成功匯出 \(format.displayName)")
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    // MARK: - Save Panel

    /// 顯示保存對話框
    private static func showSavePanel(
        for document: Document,
        format: ExportFormat
    ) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSSavePanel()
                panel.title = "匯出\(format.displayName)"
                panel.nameFieldStringValue = "\(document.title).\(format.fileExtension)"
                panel.canCreateDirectories = true
                panel.allowedContentTypes = [format.contentType]

                panel.begin { response in
                    if response == .OK, let url = panel.url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: ExportError.cancelled)
                    }
                }
            }
        }
    }

    // MARK: - PDF Export

    /// 匯出為 PDF
    private static func exportToPDF(
        document: Document,
        url: URL,
        template: FormatTemplate
    ) async throws {
        let attributedString = document.attributedString

        // 使用 NSPrintOperation 產生 PDF
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                // 建立 NSTextView 來渲染內容
                let textView = createTextView(with: attributedString)

                // 設定列印選項
                let printInfo = createPrintInfo(saveURL: url)

                let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
                printOperation.showsPrintPanel = false
                printOperation.showsProgressPanel = false

                if printOperation.run() {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: ExportError.pdfGenerationFailed)
                }
            }
        }
    }

    /// 創建用於 PDF 生成的 TextView
    private static func createTextView(with attributedString: NSAttributedString) -> NSTextView {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(
            size: NSSize(width: 595, height: CGFloat.greatestFiniteMagnitude)
        )

        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textStorage.setAttributedString(attributedString)

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))
        textView.textStorage?.setAttributedString(attributedString)

        return textView
    }

    /// 創建 PDF 列印資訊
    private static func createPrintInfo(saveURL: URL) -> NSPrintInfo {
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.paperSize = NSSize(width: 595, height: 842) // A4
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = saveURL

        return printInfo
    }

    // MARK: - DOCX Export

    /// 匯出為 DOCX（使用 RTFD 或 Office Open XML）
    private static func exportToDOCX(
        document: Document,
        url: URL
    ) async throws {
        let attributedString = document.attributedString
        
        // 如果內容為空，使用純文字
        if attributedString.length == 0 {
            let emptyContent = "（空白文件）"
            try emptyContent.write(to: url.deletingPathExtension().appendingPathExtension("rtf"), 
                                   atomically: true, 
                                   encoding: .utf8)
            return
        }

        // 嘗試使用 Office Open XML (DOCX) 格式
        if let docxData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [
                .documentType: NSAttributedString.DocumentType.officeOpenXML
            ]
        ) {
            try docxData.write(to: url)
            return
        }
        
        // 回退方案：使用 RTF 格式（Word 可開啟）
        guard let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            throw ExportError.rtfGenerationFailed
        }

        // 儲存為 RTF（修改副檔名）
        let rtfURL = url.deletingPathExtension().appendingPathExtension("rtf")
        try rtfData.write(to: rtfURL)

        // 提示使用者格式變更
        await MainActor.run {
            ToastManager.shared.showInfo("已匯出為 RTF 格式（Word 可開啟）")
        }
        
        // 開啟實際儲存的檔案
        NSWorkspace.shared.activateFileViewerSelecting([rtfURL])
        
        // 拋出取消錯誤以避免外層再顯示成功訊息
        throw ExportError.cancelled
    }
}

// MARK: - Export Errors

enum ExportError: Error, LocalizedError {
    case cancelled
    case pdfGenerationFailed
    case rtfGenerationFailed

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "匯出已取消"
        case .pdfGenerationFailed:
            return "PDF 匯出失敗"
        case .rtfGenerationFailed:
            return "無法生成 RTF 資料"
        }
    }
}
