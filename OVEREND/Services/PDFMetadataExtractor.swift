//
//  PDFMetadataExtractor.swift
//  OVEREND
//
//  AI 驅動的 PDF 元數據提取服務
//

import Foundation
import PDFKit

/// PDF元數據提取結果
struct PDFMetadata {
    var title: String
    var authors: [String]
    var year: String?
    var doi: String?
    var abstract: String?
    var journal: String?
    var volume: String?
    var pages: String?
    var entryType: String // article, inproceedings, book, etc.
    var confidence: MetadataConfidence

    enum MetadataConfidence {
        case high    // 找到DOI或完整的PDF元數據
        case medium  // 從文本中提取到大部分信息
        case low     // 僅從文件名提取

        var color: String {
            switch self {
            case .high: return "#00D97E"    // 綠色
            case .medium: return "#FF9800"   // 橙色
            case .low: return "#F44336"      // 紅色
            }
        }

        var label: String {
            switch self {
            case .high: return "高可信度"
            case .medium: return "中等可信度"
            case .low: return "低可信度"
            }
        }
    }
}

/// PDF元數據提取器
class PDFMetadataExtractor {

    /// 從PDF提取元數據
    static func extractMetadata(from url: URL) async -> PDFMetadata {
        // 嘗試從PDF文檔元數據提取
        if let pdfMetadata = extractFromPDFMetadata(url: url) {
            return pdfMetadata
        }

        // 嘗試從PDF文本內容提取
        if let textMetadata = await extractFromPDFText(url: url) {
            return textMetadata
        }

        // 降級：從文件名提取
        return extractFromFilename(url: url)
    }

    // MARK: - 提取方法

    /// 從PDF內建元數據提取
    private static func extractFromPDFMetadata(url: URL) -> PDFMetadata? {
        guard let document = PDFDocument(url: url) else { return nil }

        let attributes = document.documentAttributes

        // 檢查是否有足夠的元數據
        guard let title = attributes?[PDFDocumentAttribute.titleAttribute] as? String,
              !title.isEmpty else {
            return nil
        }

        let author = attributes?[PDFDocumentAttribute.authorAttribute] as? String ?? ""
        let authors = author.isEmpty ? [] : [author]

        // 嘗試從標題或內容中提取DOI
        let doi = extractDOI(from: document)

        return PDFMetadata(
            title: title,
            authors: authors,
            year: extractYear(from: document),
            doi: doi,
            abstract: nil,
            journal: nil,
            volume: nil,
            pages: nil,
            entryType: "article",
            confidence: doi != nil ? .high : .medium
        )
    }

    /// 從PDF文本內容提取（使用AI模式匹配）
    private static func extractFromPDFText(url: URL) async -> PDFMetadata? {
        guard let document = PDFDocument(url: url),
              let firstPage = document.page(at: 0) else {
            return nil
        }

        // 提取前兩頁的文本（通常包含標題、作者、摘要）
        var fullText = firstPage.string ?? ""
        if document.pageCount > 1, let secondPage = document.page(at: 1) {
            fullText += "\n" + (secondPage.string ?? "")
        }

        // 提取DOI
        let doi = extractDOIFromText(fullText)

        // 提取標題（通常是第一行大字或全大寫）
        let title = extractTitle(from: fullText, fallbackURL: url)

        // 提取作者
        let authors = extractAuthors(from: fullText)

        // 提取年份
        let year = extractYearFromText(fullText)

        // 提取摘要
        let abstract = extractAbstract(from: fullText)

        let confidence: PDFMetadata.MetadataConfidence = {
            if doi != nil { return .high }
            if !authors.isEmpty && year != nil { return .medium }
            return .low
        }()

        return PDFMetadata(
            title: title,
            authors: authors,
            year: year,
            doi: doi,
            abstract: abstract,
            journal: nil,
            volume: nil,
            pages: nil,
            entryType: "article",
            confidence: confidence
        )
    }

    /// 從文件名提取（降級方案）
    private static func extractFromFilename(url: URL) -> PDFMetadata {
        let filename = url.deletingPathExtension().lastPathComponent
        let title = filename
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        return PDFMetadata(
            title: title,
            authors: [],
            year: nil,
            doi: nil,
            abstract: nil,
            journal: nil,
            volume: nil,
            pages: nil,
            entryType: "misc",
            confidence: .low
        )
    }

    // MARK: - 輔助方法

    /// 提取DOI
    private static func extractDOI(from document: PDFDocument) -> String? {
        guard let firstPage = document.page(at: 0),
              let text = firstPage.string else {
            return nil
        }
        return extractDOIFromText(text)
    }

    /// 從文本中提取DOI
    private static func extractDOIFromText(_ text: String) -> String? {
        // DOI正則表達式
        let doiPattern = #"10\.\d{4,}/[^\s]+"#

        if let regex = try? NSRegularExpression(pattern: doiPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
        }
        return nil
    }

    /// 提取年份
    private static func extractYear(from document: PDFDocument) -> String? {
        guard let firstPage = document.page(at: 0),
              let text = firstPage.string else {
            return nil
        }
        return extractYearFromText(text)
    }

    /// 從文本中提取年份
    private static func extractYearFromText(_ text: String) -> String? {
        // 尋找 2000-2099 之間的年份
        let yearPattern = #"\b(20\d{2})\b"#

        if let regex = try? NSRegularExpression(pattern: yearPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
        }
        return nil
    }

    /// 提取標題
    private static func extractTitle(from text: String, fallbackURL: URL) -> String {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // 通常標題是第一行或前幾行中最長的
        if let firstLine = lines.first, firstLine.count > 10 {
            return firstLine.trimmingCharacters(in: .whitespaces)
        }

        // 降級：使用文件名
        return fallbackURL.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    /// 提取作者
    private static func extractAuthors(from text: String) -> [String] {
        // 簡化版：尋找包含常見作者模式的行
        // 更複雜的實現可以使用NLP或正則表達式
        let lines = text.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            // 跳過標題
            if index == 0 { continue }

            // 尋找包含姓名模式的行（首字母大寫）
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 檢查是否看起來像作者列表
            if trimmed.range(of: #"[A-Z][a-z]+\s+[A-Z][a-z]+"#, options: .regularExpression) != nil {
                // 簡單分割作者
                let authors = trimmed.components(separatedBy: CharacterSet(charactersIn: ",;"))
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { $0.count > 2 && $0.count < 50 }

                if !authors.isEmpty {
                    return Array(authors.prefix(10)) // 最多10個作者
                }
            }

            // 通常作者在前幾行
            if index > 5 { break }
        }

        return []
    }

    /// 提取摘要
    private static func extractAbstract(from text: String) -> String? {
        // 尋找 "Abstract" 關鍵字後的內容
        let patterns = ["Abstract", "ABSTRACT", "摘要", "Summary"]

        for pattern in patterns {
            if let range = text.range(of: pattern, options: .caseInsensitive) {
                let afterAbstract = String(text[range.upperBound...])

                // 提取接下來的段落（直到下一個章節或200字）
                let lines = afterAbstract.components(separatedBy: .newlines)
                var abstractText = ""

                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)

                    // 停止條件：遇到新章節或字數過多
                    if trimmed.isEmpty { continue }
                    if trimmed.range(of: #"^\d+\."#, options: .regularExpression) != nil { break }
                    if trimmed.uppercased() == trimmed && trimmed.count > 5 { break }
                    if abstractText.count > 500 { break }

                    abstractText += trimmed + " "
                }

                if abstractText.count > 50 {
                    return abstractText.trimmingCharacters(in: .whitespaces)
                }
            }
        }

        return nil
    }

    /// 生成BibTeX
    static func generateBibTeX(from metadata: PDFMetadata, citationKey: String) -> String {
        var bibtex = "@\(metadata.entryType){\(citationKey),\n"

        // 標題
        bibtex += "  title = {\(metadata.title)},\n"

        // 作者
        if !metadata.authors.isEmpty {
            let authorsString = metadata.authors.joined(separator: " and ")
            bibtex += "  author = {\(authorsString)},\n"
        }

        // 年份
        if let year = metadata.year {
            bibtex += "  year = {\(year)},\n"
        }

        // DOI
        if let doi = metadata.doi {
            bibtex += "  doi = {\(doi)},\n"
        }

        // 期刊
        if let journal = metadata.journal {
            bibtex += "  journal = {\(journal)},\n"
        }

        // 卷號
        if let volume = metadata.volume {
            bibtex += "  volume = {\(volume)},\n"
        }

        // 頁碼
        if let pages = metadata.pages {
            bibtex += "  pages = {\(pages)},\n"
        }

        bibtex += "}"

        return bibtex
    }
}
