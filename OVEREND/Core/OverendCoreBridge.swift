//
//  OverendCoreBridge.swift
//  OVEREND
//
//  Swift 與 Rust 核心之間的橋接層
//  提供友好的 Swift API 包裝 UniFFI 生成的 Rust 函數
//

import Foundation

/// Rust 核心引擎的 Swift 橋接
/// 提供 Typst 編譯、Hayagriva 書目管理等功能
@available(macOS 13.0, iOS 16.0, *)
public final class OverendCoreBridge {

    // MARK: - Singleton

    public static let shared = OverendCoreBridge()

    private let engine: OverendEngine

    private init() {
        // 初始化 Rust 引擎
        self.engine = OverendEngine()
        print("✅ OverendCore initialized successfully")
    }

    // MARK: - Test Function

    /// 測試 Rust 核心是否正常工作
    /// - Returns: 來自 Rust 的問候訊息
    public func helloWorld() -> String {
        do {
            return try engine.helloWorld()
        } catch {
            return "❌ Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Typst Compilation

    /// 編譯 Typst 原始碼為 PDF
    /// - Parameters:
    ///   - source: Typst 標記語言原始碼
    ///   - fontData: 可選的自訂字體資料
    /// - Returns: 編譯後的 PDF 資料
    /// - Throws: TypstError 如果編譯失敗
    public func compileTypst(source: String, fontData: Data? = nil) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let pdfData = try engine.compileTypst(source: source, fontData: fontData)
                continuation.resume(returning: pdfData)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// 將 Typst 文件渲染為 PDF（別名方法）
    /// - Parameters:
    ///   - typstSource: Typst 標記語言原始碼
    ///   - outputPath: 可選的輸出檔案路徑
    /// - Returns: PDF 資料
    public func renderPDF(typstSource: String, outputPath: String? = nil) async throws -> Data {
        let pdfData = try await compileTypst(source: typstSource)

        // 如果指定了輸出路徑，寫入檔案
        if let path = outputPath {
            let url = URL(fileURLWithPath: path)
            try pdfData.write(to: url)
        }

        return pdfData
    }

    // MARK: - BibTeX Parsing

    /// 解析 BibTeX 內容
    /// - Parameter content: BibTeX 格式的書目資料
    /// - Returns: 解析後的書目條目陣列
    /// - Throws: BibliographyError 如果解析失敗
    public func parseBibTeX(_ content: String) throws -> [BibEntry] {
        return try engine.parseBibtex(content: content)
    }

    // MARK: - Hayagriva Bibliography

    /// 將 Swift CitationStyle 轉換為 Rust CitationStyle
    private func convertCitationStyle(_ style: String) -> RustCitationStyle {
        switch style.lowercased() {
        case "apa6", "apa7", "apa":
            return .apa
        case "chicago":
            return .chicagoAuthorDate
        case "ieee":
            return .ieee
        case "mla":
            return .mla
        default:
            return .apa  // 預設使用 APA
        }
    }

    /// 格式化引用（使用 Hayagriva）
    /// - Parameters:
    ///   - bibtexContent: BibTeX 格式的書目資料
    ///   - citeKeys: 要引用的條目鍵值
    ///   - style: 引用格式名稱（如 "apa", "mla", "chicago" 等）
    /// - Returns: 格式化後的引用字串
    /// - Throws: BibliographyError 如果格式化失敗
    public func formatCitation(
        bibtexContent: String,
        citeKeys: [String],
        style: String = "apa"
    ) throws -> String {
        let rustStyle = convertCitationStyle(style)
        return try engine.formatCitation(
            bibtexContent: bibtexContent,
            citeKeys: citeKeys,
            style: rustStyle
        )
    }

    /// 生成參考文獻列表（使用 Hayagriva）
    /// - Parameters:
    ///   - bibtexContent: BibTeX 格式的書目資料
    ///   - style: 引用格式名稱（如 "apa", "mla", "chicago" 等）
    /// - Returns: 格式化後的參考文獻列表（每個條目一個字串）
    /// - Throws: BibliographyError 如果生成失敗
    public func generateBibliography(
        bibtexContent: String,
        style: String = "apa"
    ) throws -> [String] {
        let rustStyle = convertCitationStyle(style)
        return try engine.generateBibliography(
            bibtexContent: bibtexContent,
            style: rustStyle
        )
    }
}
