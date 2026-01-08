//
//  PandocService.swift
//  OVEREND
//
//  Pandoc 整合服務 - 高保真度 DOCX/PDF 轉換
//

import Foundation
import AppKit

/// Pandoc 轉換服務
class PandocService {
    
    // MARK: - Types
    
    enum OutputFormat: String {
        case docx
        case pdf
        case markdown = "md"
        case html
        case rtf
        
        var ext: String { rawValue }
        
        var pandocFormat: String {
            switch self {
            case .docx: return "docx"
            case .pdf: return "pdf"
            case .markdown: return "markdown"
            case .html: return "html5"
            case .rtf: return "rtf"
            }
        }
    }
    
    enum PandocError: Error, LocalizedError {
        case pandocNotInstalled
        case conversionFailed(String)
        case inputFileNotFound
        case outputFailed
        
        var errorDescription: String? {
            switch self {
            case .pandocNotInstalled:
                return "未安裝 Pandoc。請執行 'brew install pandoc' 安裝。"
            case .conversionFailed(let msg):
                return "轉換失敗：\(msg)"
            case .inputFileNotFound:
                return "找不到輸入檔案"
            case .outputFailed:
                return "無法產生輸出檔案"
            }
        }
    }
    
    // MARK: - Public Properties
    
    /// 檢查 Pandoc 是否已安裝
    static var isAvailable: Bool {
        pandocPath != nil
    }
    
    /// Pandoc 執行檔路徑
    static var pandocPath: String? {
        let possiblePaths = [
            "/opt/homebrew/bin/pandoc",     // Apple Silicon Homebrew
            "/usr/local/bin/pandoc",        // Intel Homebrew
            "/usr/bin/pandoc"               // System install
        ]
        return possiblePaths.first { FileManager.default.fileExists(atPath: $0) }
    }
    
    // MARK: - Conversion Methods
    
    /// 轉換檔案格式
    static func convert(
        from inputURL: URL,
        to format: OutputFormat,
        outputURL: URL? = nil
    ) async throws -> URL {
        guard let pandoc = pandocPath else {
            throw PandocError.pandocNotInstalled
        }
        
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw PandocError.inputFileNotFound
        }
        
        let output = outputURL ?? FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(format.ext)
        
        var arguments = [
            inputURL.path,
            "-o", output.path,
            "-f", detectInputFormat(inputURL),
            "-t", format.pandocFormat
        ]
        
        // PDF 需要指定 engine
        if format == .pdf {
            // 優先使用 wkhtmltopdf，其次 weasyprint，最後 LaTeX
            if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/wkhtmltopdf") ||
               FileManager.default.fileExists(atPath: "/usr/local/bin/wkhtmltopdf") {
                arguments += ["--pdf-engine=wkhtmltopdf"]
            } else if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/weasyprint") ||
                      FileManager.default.fileExists(atPath: "/usr/local/bin/weasyprint") {
                arguments += ["--pdf-engine=weasyprint"]
            }
            // 若都沒有，使用預設 LaTeX（需安裝）
        }
        
        // 執行 Pandoc
        let (exitCode, stderr) = try await runProcess(executablePath: pandoc, arguments: arguments)
        
        if exitCode != 0 {
            throw PandocError.conversionFailed(stderr)
        }
        
        guard FileManager.default.fileExists(atPath: output.path) else {
            throw PandocError.outputFailed
        }
        
        return output
    }
    
    /// 從 DOCX 讀取為 NSAttributedString（高保真度）
    static func importDOCX(from url: URL) async throws -> NSAttributedString {
        // 先用 Pandoc 轉換成 HTML（保留更多格式）
        let htmlURL = try await convert(from: url, to: .html)
        
        defer {
            try? FileManager.default.removeItem(at: htmlURL)
        }
        
        let htmlData = try Data(contentsOf: htmlURL)
        
        let attributedString = try NSAttributedString(
            data: htmlData,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        
        return attributedString
    }
    
    /// 將 NSAttributedString 匯出為 DOCX
    static func exportToDocx(
        _ attributedString: NSAttributedString,
        outputURL: URL
    ) async throws {
        // 先轉換成 HTML
        let htmlData = try attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
        )
        
        let tempHTML = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("html")
        
        try htmlData.write(to: tempHTML)
        
        defer {
            try? FileManager.default.removeItem(at: tempHTML)
        }
        
        // 用 Pandoc 轉換成 DOCX
        let result = try await convert(from: tempHTML, to: .docx, outputURL: outputURL)
        
        // 如果輸出位置不同，移動檔案
        if result.path != outputURL.path {
            try FileManager.default.moveItem(at: result, to: outputURL)
        }
    }
    
    /// 將 NSAttributedString 匯出為 PDF
    static func exportToPdf(
        _ attributedString: NSAttributedString,
        outputURL: URL
    ) async throws {
        // 先轉換成 HTML
        let htmlData = try attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
        )
        
        let tempHTML = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("html")
        
        try htmlData.write(to: tempHTML)
        
        defer {
            try? FileManager.default.removeItem(at: tempHTML)
        }
        
        // 用 Pandoc 轉換成 PDF
        let result = try await convert(from: tempHTML, to: .pdf, outputURL: outputURL)
        
        if result.path != outputURL.path {
            try FileManager.default.moveItem(at: result, to: outputURL)
        }
    }
    
    // MARK: - Private Methods
    
    /// 偵測輸入格式
    private static func detectInputFormat(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "docx": return "docx"
        case "doc": return "doc"
        case "html", "htm": return "html"
        case "md", "markdown": return "markdown"
        case "rtf": return "rtf"
        case "txt": return "plain"
        default: return "markdown"
        }
    }
    
    /// 執行外部程式
    private static func runProcess(
        executablePath: String,
        arguments: [String]
    ) async throws -> (Int32, String) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = arguments
                
                let stderrPipe = Pipe()
                process.standardError = stderrPipe
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                    
                    continuation.resume(returning: (process.terminationStatus, stderr))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Convenience Extensions

extension PandocService {
    
    /// 快速檢查並顯示安裝提示
    @MainActor
    static func checkAvailabilityOrPrompt() -> Bool {
        if isAvailable {
            return true
        }
        
        // 顯示安裝提示
        let alert = NSAlert()
        alert.messageText = "需要安裝 Pandoc"
        alert.informativeText = "Pandoc 是一個通用的文件轉換工具，可提供更好的 DOCX 格式支援。\n\n請在終端機執行：\nbrew install pandoc"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "複製安裝指令")
        alert.addButton(withTitle: "稍後")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("brew install pandoc", forType: .string)
            ToastManager.shared.showInfo("已複製安裝指令到剪貼簿")
        }
        
        return false
    }
}
