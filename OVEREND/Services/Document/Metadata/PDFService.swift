//
//  PDFService.swift
//  OVEREND
//
//  PDF 附件管理服務
//

import Foundation
import CoreData
import PDFKit
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

class PDFService {
    static let shared = PDFService()

    enum PDFError: Error, LocalizedError {
        case invalidPDF
        case copyError
        case metadataError
        
        var errorDescription: String? {
            switch self {
            case .invalidPDF:
                return "無效的 PDF 檔案"
            case .copyError:
                return "複製 PDF 檔案失敗"
            case .metadataError:
                return "提取 PDF 元數據失敗"
            }
        }
    }

    // MARK: - 檔案管理

    /// 獲取應用程式的附件存儲目錄
    func getAttachmentsDirectory() throws -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("OVEREND", isDirectory: true)
        let attachmentsDirectory = appDirectory.appendingPathComponent("Attachments", isDirectory: true)

        // 確保目錄存在
        if !FileManager.default.fileExists(atPath: attachmentsDirectory.path) {
            try FileManager.default.createDirectory(at: attachmentsDirectory, withIntermediateDirectories: true)
        }

        return attachmentsDirectory
    }

    /// 複製 PDF 到應用程式存儲目錄
    /// - Parameters:
    ///   - sourceURL: 源 PDF 檔案路徑
    ///   - entryID: 關聯的 Entry ID（用於組織檔案）
    /// - Returns: 新的檔案路徑
    func copyPDFToStorage(from sourceURL: URL, for entryID: UUID) throws -> URL {
        // 檢查檔案大小
        let attributes = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Note: Removed file size limit for flexibility
        
        // 驗證是 PDF
        guard sourceURL.pathExtension.lowercased() == "pdf" else {
            throw PDFError.invalidPDF
        }

        // 創建目標路徑
        let attachmentsDir = try getAttachmentsDirectory()
        let entryDir = attachmentsDir.appendingPathComponent(entryID.uuidString, isDirectory: true)

        if !FileManager.default.fileExists(atPath: entryDir.path) {
            try FileManager.default.createDirectory(at: entryDir, withIntermediateDirectories: true)
        }

        // 使用原始檔名，如果衝突則添加時間戳
        var destinationURL = entryDir.appendingPathComponent(sourceURL.lastPathComponent)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            let timestamp = Int(Date().timeIntervalSince1970)
            let nameWithoutExt = sourceURL.deletingPathExtension().lastPathComponent
            destinationURL = entryDir.appendingPathComponent("\(nameWithoutExt)_\(timestamp).pdf")
        }

        // 複製檔案
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        return destinationURL
    }

    // MARK: - PDF 元數據提取

    /// 從 PDF 提取元數據
    /// - Parameter url: PDF 檔案路徑
    /// - Returns: (頁數, 提取的文字)
    func extractPDFMetadata(from url: URL) throws -> (pageCount: Int, extractedText: String?) {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFError.invalidPDF
        }

        let pageCount = pdfDocument.pageCount

        // 提取前幾頁的文字（最多 3 頁）
        var extractedText = ""
        let pagesToExtract = min(3, pageCount)

        for i in 0..<pagesToExtract {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                extractedText += pageText + "\n\n"
            }
        }

        let trimmedText = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)

        return (pageCount: pageCount, extractedText: trimmedText.isEmpty ? nil : trimmedText)
    }

    // MARK: - 附件創建

    /// 為 Entry 添加 PDF 附件
    /// - Parameters:
    ///   - sourceURL: PDF 檔案路徑
    ///   - entry: 關聯的 Entry
    ///   - context: Core Data 上下文
    /// - Returns: 創建的 Attachment
    @discardableResult
    func addPDFAttachment(
        from sourceURL: URL,
        to entry: Entry,
        context: NSManagedObjectContext
    ) throws -> Attachment {
        // 開始存取安全範圍資源（App Sandbox 需要）
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // 複製檔案到存儲目錄
        let destinationURL = try copyPDFToStorage(from: sourceURL, for: entry.id)

        // 提取元數據
        let (pageCount, extractedText) = try extractPDFMetadata(from: destinationURL)

        // 創建 Attachment 實體
        let attachment = Attachment(
            context: context,
            fileName: sourceURL.lastPathComponent,
            filePath: destinationURL.path,
            entry: entry
        )

        attachment.pageCount = Int16(pageCount)
        attachment.extractedText = extractedText

        // 保存
        try context.save()

        return attachment
    }

    /// 刪除附件（同時刪除檔案）
    /// - Parameters:
    ///   - attachment: 要刪除的附件
    ///   - context: Core Data 上下文
    func deleteAttachment(_ attachment: Attachment, context: NSManagedObjectContext) throws {
        let fileURL = URL(fileURLWithPath: attachment.filePath)

        // 刪除檔案
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        // 刪除 Core Data 實體
        context.delete(attachment)
        try context.save()
    }

    // MARK: - 檔案選擇器

    /// 顯示 PDF 檔案選擇器
    /// - Parameter completion: 選擇完成的回調（返回選中的 PDF URL）
    func selectPDFFile(completion: @escaping (URL?) -> Void) {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.title = "選擇 PDF 檔案"
        panel.message = "請選擇要匯入的 PDF 檔案"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]

        panel.begin { response in
            if response == .OK {
                completion(panel.url)
            } else {
                completion(nil)
            }
        }
        #endif
    }
}
