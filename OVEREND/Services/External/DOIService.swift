//
//  DOIService.swift
//  OVEREND
//
//  DOI 提取與元數據查詢服務
//

import Foundation
import PDFKit

/// DOI 服務 - 從 PDF 提取 DOI 並查詢文獻元數據
class DOIService {
    
    // MARK: - DOI 正則表達式
    
    /// DOI 格式: 10.xxxx/xxxxx（增強版，支援更多變體，包括括號）
    private static let doiPatterns = [
        #"doi:\s*10\.\d{4,}/[^\s\]\"'>]+"#,           // doi: 10.xxxx/xxx (允許括號)
        #"DOI:\s*10\.\d{4,}/[^\s\]\"'>]+"#,           // DOI: 10.xxxx/xxx (允許括號)
        #"https?://doi\.org/(10\.\d{4,}/[^\s\]\"'>]+)"#,      // https://doi.org/10.xxxx/xxx
        #"https?://dx\.doi\.org/(10\.\d{4,}/[^\s\]\"'>]+)"#,  // http://dx.doi.org/10.xxxx/xxx
        #"\b(10\.\d{4,}/[^\s\]\"'>]+)\b"#             // 純 DOI 格式（優先級最低，允許括號）
    ]
    
    // MARK: - DOI 提取
    
    /// 從 PDF 文件提取 DOI
    /// - Parameter url: PDF 文件路徑
    /// - Returns: 找到的 DOI，如果沒找到則返回 nil
    static func extractDOI(from url: URL) -> String? {
        guard let pdfDocument = PDFDocument(url: url) else {
            return nil
        }
        
        // 擴大掃描範圍：掃描前 5 頁
        let pagesToScan = min(5, pdfDocument.pageCount)
        
        for i in 0..<pagesToScan {
            if let page = pdfDocument.page(at: i),
               let text = page.string,
               let doi = findDOI(in: text) {
                return doi
            }
        }
        
        return nil
    }
    
    /// 在文本中尋找 DOI（使用多個模式）
    private static func findDOI(in text: String) -> String? {
        // 依序嘗試各個模式（從最精確到最寬鬆）
        for pattern in doiPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            
            let range = NSRange(text.startIndex..., in: text)
            
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                // 如果有 capture group，使用它（會排除 doi: 前綴）
                let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
                
                if let swiftRange = Range(captureRange, in: text) {
                    var doi = String(text[swiftRange])
                    
                    // 清理可能的前綴
                    doi = doi.replacingOccurrences(of: "doi:", with: "", options: .caseInsensitive)
                    doi = doi.replacingOccurrences(of: "DOI:", with: "")
                    
                    // 清理尾部的標點符號（但保留括號，因為 DOI 可能包含括號）
                    doi = doi.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:\">"))
                    doi = doi.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 驗證 DOI 格式
                    if doi.hasPrefix("10.") && doi.contains("/") {
                        return doi
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - 基本元數據提取（無 DOI 時使用）
    
    /// 從 PDF 提取基本元數據（標題、作者、年份）
    /// - Parameters:
    ///   - url: PDF 文件路徑
    ///   - fileName: 文件名作為後備標題
    /// - Returns: 基本元數據
    static func extractBasicMetadata(from url: URL, fileName: String) -> (title: String, author: String, year: String) {
        guard let pdfDocument = PDFDocument(url: url) else {
            return (fileName, "Unknown", "")
        }
        
        // 嘗試從 PDF 內建元數據提取
        var author = "Unknown"
        var year = ""
        
        // 檢查 PDF Document Attributes
        if let attributes = pdfDocument.documentAttributes {
            if let pdfAuthor = attributes[PDFDocumentAttribute.authorAttribute] as? String,
               !pdfAuthor.isEmpty {
                author = pdfAuthor
            }
            
            // 有些 PDF 在 creationDate 有日期
            if let creationDate = attributes[PDFDocumentAttribute.creationDateAttribute] as? Date {
                let calendar = Calendar.current
                year = String(calendar.component(.year, from: creationDate))
            }
        }
        
        // 從第一頁文字提取
        if let firstPage = pdfDocument.page(at: 0),
           let text = firstPage.string {
            
            // 如果還沒有年份，嘗試從文字提取
            if year.isEmpty {
                year = extractYear(from: text)
            }
            
            // 如果作者仍是 Unknown，嘗試從文字提取
            if author == "Unknown" {
                author = extractAuthor(from: text)
            }
        }
        
        return (fileName, author, year)
    }
    
    /// 從文本提取年份（支援民國年轉換）
    private static func extractYear(from text: String) -> String {
        // 先檢查民國年份
        if let rocYear = extractROCYear(from: text) {
            return rocYear
        }
        
        // 尋找常見的西元年份格式
        let yearPatterns = [
            #"\((\d{4})\)"#,           // (2023)
            #"©\s*(\d{4})"#,           // ©2023
            #"\b(19\d{2}|20\d{2})\b"#  // 獨立的年份
        ]
        
        for pattern in yearPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
                    if let swiftRange = Range(captureRange, in: text) {
                        let yearStr = String(text[swiftRange])
                        if let yearInt = Int(yearStr), yearInt >= 1900 && yearInt <= 2099 {
                            return yearStr
                        }
                    }
                }
            }
        }
        
        return ""
    }
    
    /// 從文本提取民國年份並轉換為西元
    private static func extractROCYear(from text: String) -> String? {
        // 民國年份格式：「民國XX年」、「中華民國XX年」
        let rocPatterns = [
            #"民國\s*(\d{1,3})\s*年"#,
            #"中華民國\s*(\d{1,3})\s*年"#
        ]
        
        for pattern in rocPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   match.numberOfRanges > 1 {
                    let rocRange = match.range(at: 1)
                    if let swiftRange = Range(rocRange, in: text) {
                        let rocYearStr = String(text[swiftRange])
                        if let rocYear = Int(rocYearStr) {
                            // 民國轉西元：西元年 = 民國年 + 1911
                            let westernYear = rocYear + 1911
                            // 驗證合理性 (1912-2099)
                            if westernYear >= 1912 && westernYear <= 2099 {
                                return String(westernYear)
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    /// 從文本提取作者（啟發式方法，支援繁體中文姓名）
    private static func extractAuthor(from text: String) -> String {
        let sample = String(text.prefix(800)) // 增加掃描範圍
        let lines = sample.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // 跳過標題
            
            // 過濾明顯不是作者的行
            if line.count > 100 { continue } // 作者行通常不會太長
            if line.count < 3 { continue }   // 太短也不太可能
            
            // 遇到這些關鍵字就停止搜尋
            let stopKeywords = ["abstract", "keywords", "introduction", "摘要", "關鍵字", "本研究", "研究", "問卷", "調查"]
            if stopKeywords.contains(where: { line.lowercased().contains($0.lowercased()) }) {
                break
            }
            
            // 檢查是否包含作者分隔符
            let hasAuthorSeparator = line.contains(",") || 
                                    line.contains("、") || 
                                    line.lowercased().contains(" and ")
            
            if hasAuthorSeparator {
                var cleanLine = line
                cleanLine = cleanLine.replacingOccurrences(of: "*", with: "")
                cleanLine = cleanLine.replacingOccurrences(of: "†", with: "")
                cleanLine = cleanLine.replacingOccurrences(of: "‡", with: "")
                cleanLine = cleanLine.trimmingCharacters(in: .whitespaces)
                
                // 額外驗證：不應該包含數字（作者名通常不含數字）
                let digitCount = cleanLine.filter { $0.isNumber }.count
                if digitCount > 3 { continue } // 如果有超過3個數字，可能不是作者
                
                // 檢查是否包含太多標點符號（可能是句子）
                let punctuationCount = cleanLine.filter { "。！？：；".contains($0) }.count
                if punctuationCount > 0 { continue }
                
                if cleanLine.count > 5 && cleanLine.count < 80 {
                    return formatChineseNames(cleanLine)
                }
            }
        }
        
        return "Unknown"
    }
    
    /// 格式化中文姓名（姓與名之間加空格）
    private static func formatChineseNames(_ authorString: String) -> String {
        let authors = authorString.components(separatedBy: CharacterSet(charactersIn: ",、"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let formatted = authors.map { author -> String in
            // 檢查是否為中文姓名（2-4個中文字符）
            let chineseCharacters = author.filter { char in
                ("\u{4E00}"..."\u{9FFF}").contains(char)
            }
            
            // 如果是純中文且長度為2-4個字
            if chineseCharacters.count == author.count && author.count >= 2 && author.count <= 4 {
                // 中文姓名：第一個字是姓，其餘是名
                let firstChar = String(author.prefix(1))
                let restChars = String(author.dropFirst())
                return "\(firstChar) \(restChars)"
            }
            
            return author
        }
        
        return formatted.joined(separator: "、")
    }
    
    // MARK: - CrossRef API 查詢
    
    /// CrossRef API 返回的文獻元數據
    struct Metadata {
        let title: String
        let authors: [String]
        let year: String
        let journal: String?
        let volume: String?
        let issue: String?
        let pages: String?
        let publisher: String?
        let doi: String
        let entryType: String
        
        /// 轉換為 BibTeX 字段
        var fields: [String: String] {
            var result: [String: String] = [
                "title": title,
                "author": authors.joined(separator: " and "),
                "year": year,
                "doi": doi
            ]
            
            if let journal = journal { result["journal"] = journal }
            if let volume = volume { result["volume"] = volume }
            if let issue = issue { result["number"] = issue }
            if let pages = pages { result["pages"] = pages }
            if let publisher = publisher { result["publisher"] = publisher }
            
            return result
        }
        
        /// 生成 Citation Key
        var citationKey: String {
            let firstAuthor = authors.first?
                .components(separatedBy: " ").last?
                .lowercased() ?? "unknown"
            return "\(firstAuthor)\(year)"
        }
    }
    
    /// 透過 DOI 查詢文獻元數據
    /// - Parameter doi: DOI 字符串
    /// - Returns: 文獻元數據
    static func fetchMetadata(for doi: String) async throws -> Metadata {
        let cleanDOI = doi.trimmingCharacters(in: .whitespaces)
        let urlString = "https://api.crossref.org/works/\(cleanDOI)"
        
        guard let url = URL(string: urlString) else {
            throw DOIError.invalidDOI
        }
        
        var request = URLRequest(url: url)
        request.setValue("OVEREND/1.0 (mailto:contact@overend.app)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DOIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw DOIError.notFound
            }
            throw DOIError.networkError
        }
        
        return try parseResponse(data: data, doi: cleanDOI)
    }
    
    /// 解析 CrossRef API 回應
    private static func parseResponse(data: Data, doi: String) throws -> Metadata {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any] else {
            throw DOIError.parseError
        }
        
        // 標題
        let titleArray = message["title"] as? [String] ?? []
        let title = titleArray.first ?? "Untitled"
        
        // 作者
        var authors: [String] = []
        if let authorArray = message["author"] as? [[String: Any]] {
            for author in authorArray {
                let given = author["given"] as? String ?? ""
                let family = author["family"] as? String ?? ""
                if !family.isEmpty {
                    authors.append("\(given) \(family)".trimmingCharacters(in: .whitespaces))
                }
            }
        }
        if authors.isEmpty {
            authors = ["Unknown"]
        }
        
        // 年份
        var year = ""
        if let published = message["published-print"] as? [String: Any],
           let dateParts = published["date-parts"] as? [[Int]],
           let firstPart = dateParts.first,
           let yearInt = firstPart.first {
            year = String(yearInt)
        } else if let published = message["published-online"] as? [String: Any],
                  let dateParts = published["date-parts"] as? [[Int]],
                  let firstPart = dateParts.first,
                  let yearInt = firstPart.first {
            year = String(yearInt)
        } else if let created = message["created"] as? [String: Any],
                  let dateParts = created["date-parts"] as? [[Int]],
                  let firstPart = dateParts.first,
                  let yearInt = firstPart.first {
            year = String(yearInt)
        }
        
        // 期刊資訊
        let containerTitle = (message["container-title"] as? [String])?.first
        let volume = message["volume"] as? String
        let issue = message["issue"] as? String
        let pages = message["page"] as? String
        let publisher = message["publisher"] as? String
        
        // 判斷類型
        let type = message["type"] as? String ?? "article"
        let entryType: String
        switch type {
        case "journal-article":
            entryType = "article"
        case "book", "monograph":
            entryType = "book"
        case "proceedings-article":
            entryType = "inproceedings"
        case "dissertation":
            entryType = "phdthesis"
        case "report":
            entryType = "techreport"
        default:
            entryType = "misc"
        }
        
        return Metadata(
            title: title,
            authors: authors,
            year: year,
            journal: containerTitle,
            volume: volume,
            issue: issue,
            pages: pages,
            publisher: publisher,
            doi: doi,
            entryType: entryType
        )
    }
    
    // MARK: - 錯誤定義
    
    enum DOIError: Error, LocalizedError {
        case invalidDOI
        case notFound
        case networkError
        case parseError
        
        var errorDescription: String? {
            switch self {
            case .invalidDOI:
                return "無效的 DOI 格式"
            case .notFound:
                return "找不到該 DOI 的文獻資料"
            case .networkError:
                return "網路連線錯誤"
            case .parseError:
                return "解析元數據失敗"
            }
        }
    }
}
