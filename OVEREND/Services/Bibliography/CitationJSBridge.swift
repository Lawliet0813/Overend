//
//  CitationJSBridge.swift
//  OVEREND
//
//  Citation.js 整合橋接器 - 使用 JavaScriptCore 嵌入 Citation.js
//  支援 BibTeX、RIS、CSL-JSON 等格式的解析與轉換
//

import Foundation
import JavaScriptCore

// MARK: - CSL Extension Entry (避免與 CSLItem 衝突)

/// Citation.js 專用的 CSL-JSON 書目條目
struct CitationJSEntry: Codable, Identifiable {
    let id: String
    var type: String
    var title: String?
    var author: [CitationJSName]?
    var issued: CitationJSDate?
    var containerTitle: String?
    var publisher: String?
    var publisherPlace: String?
    var volume: String?
    var issue: String?
    var page: String?
    var doi: String?
    var url: String?
    var abstract: String?
    var language: String?
    var isbn: String?
    var issn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, author, issued, publisher, volume, issue, page
        case doi = "DOI"
        case url = "URL"
        case abstract, language
        case isbn = "ISBN"
        case issn = "ISSN"
        case containerTitle = "container-title"
        case publisherPlace = "publisher-place"
    }
    
    /// 轉換為 BibTeX 類型
    var bibTeXType: String {
        switch type {
        case "article-journal", "article": return "article"
        case "book": return "book"
        case "chapter": return "incollection"
        case "paper-conference": return "inproceedings"
        case "thesis": return "phdthesis"
        case "report": return "techreport"
        case "webpage": return "online"
        default: return "misc"
        }
    }
    
    /// 生成引用鍵
    var suggestedCitationKey: String {
        let authorPart = author?.first?.family?.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .prefix(10) ?? "unknown"
        let yearPart = issued?.dateParts?.first?.first.map { String($0) } ?? "nd"
        let titleWord = title?.split(separator: " ").first?.lowercased()
            .filter { $0.isLetter }
            .prefix(5) ?? ""
        return "\(authorPart)\(yearPart)\(titleWord)"
    }
    
    /// 轉換為 CSLItem（與現有模型相容）
    func toCSLItem() -> CSLItem {
        CSLItem(
            id: id,
            type: type,
            title: title,
            author: author?.map { CSLName(family: $0.family, given: $0.given, literal: $0.literal, isInstitution: nil) },
            editor: nil,
            issued: issued.flatMap { CSLDate(dateParts: $0.dateParts, literal: $0.literal) },
            containerTitle: containerTitle,
            volume: volume,
            issue: issue,
            page: page,
            doi: doi,
            url: url,
            abstract: abstract,
            language: language
        )
    }
}

/// Citation.js 專用姓名結構
struct CitationJSName: Codable {
    var family: String?
    var given: String?
    var literal: String?
    
    /// 格式化為 BibTeX 格式
    var bibTeXFormat: String {
        if let literal = literal {
            return literal
        }
        if let family = family, let given = given {
            return "\(family), \(given)"
        }
        return family ?? given ?? ""
    }
}

/// Citation.js 專用日期結構
struct CitationJSDate: Codable {
    var dateParts: [[Int]]?
    var raw: String?
    var literal: String?
    
    enum CodingKeys: String, CodingKey {
        case dateParts = "date-parts"
        case raw, literal
    }
    
    /// 取得年份字串
    var yearString: String? {
        if let parts = dateParts?.first, !parts.isEmpty {
            return String(parts[0])
        }
        if let raw = raw, raw.count >= 4 {
            return String(raw.prefix(4))
        }
        return literal
    }
}

// MARK: - CSLName Extension

extension CSLName {
    /// 格式化為 BibTeX 格式
    var bibTeXFormat: String {
        if let literal = literal {
            return literal
        }
        if let family = family, let given = given {
            return "\(family), \(given)"
        }
        return family ?? given ?? ""
    }
}

// MARK: - CSLDate Extension

extension CSLDate {
    /// 取得年份字串
    var yearString: String? {
        if let year = year {
            return String(year)
        }
        return literal
    }
}

// MARK: - Citation.js Bridge

/// Citation.js 橋接器 - 透過 JavaScriptCore 執行 Citation.js
class CitationJSBridge {
    
    // MARK: - Singleton
    
    static let shared = CitationJSBridge()
    
    // MARK: - Properties
    
    private var context: JSContext?
    private var isInitialized = false
    private let initLock = NSLock()
    
    // MARK: - Errors
    
    enum BridgeError: LocalizedError {
        case initializationFailed
        case jsLibraryNotFound
        case parsingFailed(String)
        case conversionFailed(String)
        case invalidInput
        
        var errorDescription: String? {
            switch self {
            case .initializationFailed:
                return "無法初始化 JavaScript 環境"
            case .jsLibraryNotFound:
                return "找不到 Citation.js 函式庫"
            case .parsingFailed(let message):
                return "解析失敗: \(message)"
            case .conversionFailed(let message):
                return "轉換失敗: \(message)"
            case .invalidInput:
                return "無效的輸入格式"
            }
        }
    }
    
    // MARK: - Input Formats
    
    enum InputFormat: String {
        case bibtex = "bibtex"
        case ris = "ris"
        case cslJson = "csl-json"
        case endnoteXml = "endnote-xml"
        case auto = "auto"
    }
    
    enum OutputFormat: String {
        case bibtex = "bibtex"
        case ris = "ris"
        case cslJson = "csl-json"
        case apa = "apa"
        case mla = "mla"
        case chicago = "chicago"
    }
    
    // MARK: - Initialization
    
    private init() {
        setupContext()
    }
    
    private func setupContext() {
        initLock.lock()
        defer { initLock.unlock() }
        
        guard !isInitialized else { return }
        
        context = JSContext()
        
        guard let ctx = context else {
            print("CitationJSBridge: Failed to create JSContext")
            return
        }
        
        // 設定錯誤處理
        ctx.exceptionHandler = { _, exception in
            if let error = exception?.toString() {
                print("CitationJSBridge JS Error: \(error)")
            }
        }
        
        // 嘗試載入 Citation.js
        if let citationJSPath = Bundle.main.path(forResource: "citation", ofType: "js") {
            do {
                let jsCode = try String(contentsOfFile: citationJSPath, encoding: .utf8)
                ctx.evaluateScript(jsCode)
                isInitialized = true
                print("CitationJSBridge: Loaded citation.js from bundle")
            } catch {
                print("CitationJSBridge: Failed to load citation.js: \(error)")
            }
        } else {
            // 如果沒有 Citation.js，使用內建的簡化解析器
            setupFallbackParser(ctx)
            isInitialized = true
            print("CitationJSBridge: Using fallback parser (citation.js not found)")
        }
    }
    
    /// 設定後備解析器（當 Citation.js 不可用時）
    private func setupFallbackParser(_ context: JSContext) {
        // 提供基本的 JSON 解析功能
        let fallbackCode = """
        var CitationBridge = {
            parseCSLJSON: function(input) {
                try {
                    return JSON.parse(input);
                } catch (e) {
                    return { error: e.message };
                }
            },
            
            detectFormat: function(input) {
                input = input.trim();
                if (input.startsWith('{') || input.startsWith('[')) {
                    return 'csl-json';
                } else if (input.includes('@article') || input.includes('@book') || input.includes('@')) {
                    return 'bibtex';
                } else if (input.includes('TY  -') || input.includes('ER  -')) {
                    return 'ris';
                }
                return 'unknown';
            }
        };
        """
        context.evaluateScript(fallbackCode)
    }
    
    // MARK: - Public Methods
    
    /// 解析書目資料為 CSL-JSON 格式
    /// - Parameters:
    ///   - input: 輸入的書目資料字串
    ///   - format: 輸入格式（預設自動偵測）
    /// - Returns: CSL-JSON 條目陣列
    func parse(_ input: String, format: InputFormat = .auto) throws -> [CitationJSEntry] {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BridgeError.invalidInput
        }
        
        // 偵測格式
        let detectedFormat = format == .auto ? detectFormat(input) : format
        
        switch detectedFormat {
        case .cslJson:
            return try parseCSLJSON(input)
        case .bibtex:
            return try parseBibTeX(input)
        case .ris:
            return try parseRIS(input)
        default:
            // 嘗試使用 Citation.js（如果可用）
            if let result = tryParseWithCitationJS(input) {
                return result
            }
            throw BridgeError.parsingFailed("無法識別的格式")
        }
    }
    
    /// 將 CSL-JSON 轉換為指定格式
    /// - Parameters:
    ///   - entries: CSL-JSON 條目陣列
    ///   - format: 輸出格式
    /// - Returns: 轉換後的字串
    func convert(_ entries: [CitationJSEntry], to format: OutputFormat) throws -> String {
        switch format {
        case .cslJson:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(entries)
            return String(data: data, encoding: .utf8) ?? ""
            
        case .bibtex:
            return convertToBibTeX(entries)
            
        case .ris:
            return convertToRIS(entries)
            
        default:
            throw BridgeError.conversionFailed("不支援的輸出格式: \(format.rawValue)")
        }
    }
    
    /// 偵測輸入格式
    func detectFormat(_ input: String) -> InputFormat {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return .cslJson
        } else if trimmed.contains("@article") || trimmed.contains("@book") ||
                  trimmed.contains("@inproceedings") || trimmed.contains("@misc") ||
                  trimmed.range(of: "@\\w+\\{", options: .regularExpression) != nil {
            return .bibtex
        } else if trimmed.contains("TY  -") || trimmed.contains("ER  -") {
            return .ris
        } else if trimmed.contains("<xml") || trimmed.contains("<records>") {
            return .endnoteXml
        }
        
        return .auto
    }
    
    // MARK: - Private Parsing Methods
    
    private func parseCSLJSON(_ input: String) throws -> [CitationJSEntry] {
        guard let data = input.data(using: .utf8) else {
            throw BridgeError.invalidInput
        }
        
        let decoder = JSONDecoder()
        
        // 嘗試解析為陣列
        if let entries = try? decoder.decode([CitationJSEntry].self, from: data) {
            return entries
        }
        
        // 嘗試解析為單一物件
        if let entry = try? decoder.decode(CitationJSEntry.self, from: data) {
            return [entry]
        }
        
        throw BridgeError.parsingFailed("無效的 CSL-JSON 格式")
    }
    
    private func parseBibTeX(_ input: String) throws -> [CitationJSEntry] {
        // 使用現有的 BibTeXParser 然後轉換為 CSL-JSON
        // 這裡提供一個簡化的實作
        var entries: [CitationJSEntry] = []
        
        let pattern = "@(\\w+)\\s*\\{\\s*([^,]+)\\s*,([^@]*)\\}"
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(input.startIndex..., in: input)
        
        regex.enumerateMatches(in: input, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let typeRange = Range(match.range(at: 1), in: input),
                  let keyRange = Range(match.range(at: 2), in: input),
                  let fieldsRange = Range(match.range(at: 3), in: input) else {
                return
            }
            
            let type = String(input[typeRange]).lowercased()
            let key = String(input[keyRange]).trimmingCharacters(in: .whitespaces)
            let fieldsStr = String(input[fieldsRange])
            
            var entry = CitationJSEntry(id: key, type: mapBibTeXTypeToCSL(type))
            
            // 解析欄位
            let fieldPattern = "(\\w+)\\s*=\\s*[{\"](.*?)[}\"]"
            if let fieldRegex = try? NSRegularExpression(pattern: fieldPattern, options: [.dotMatchesLineSeparators]) {
                let fieldRange = NSRange(fieldsStr.startIndex..., in: fieldsStr)
                fieldRegex.enumerateMatches(in: fieldsStr, options: [], range: fieldRange) { fieldMatch, _, _ in
                    guard let fieldMatch = fieldMatch,
                          let nameRange = Range(fieldMatch.range(at: 1), in: fieldsStr),
                          let valueRange = Range(fieldMatch.range(at: 2), in: fieldsStr) else {
                        return
                    }
                    
                    let name = String(fieldsStr[nameRange]).lowercased()
                    let value = String(fieldsStr[valueRange])
                    
                    switch name {
                    case "title":
                        entry.title = value
                    case "author":
                        entry.author = parseAuthors(value)
                    case "year":
                        entry.issued = CitationJSDate(dateParts: [[Int(value) ?? 0]], raw: value, literal: nil)
                    case "journal", "booktitle":
                        entry.containerTitle = value
                    case "publisher":
                        entry.publisher = value
                    case "volume":
                        entry.volume = value
                    case "number":
                        entry.issue = value
                    case "pages":
                        entry.page = value
                    case "doi":
                        entry.doi = value
                    case "url":
                        entry.url = value
                    case "abstract":
                        entry.abstract = value
                    default:
                        break
                    }
                }
            }
            
            entries.append(entry)
        }
        
        if entries.isEmpty {
            throw BridgeError.parsingFailed("找不到有效的 BibTeX 條目")
        }
        
        return entries
    }
    
    private func parseRIS(_ input: String) throws -> [CitationJSEntry] {
        // 使用 RISParser 然後轉換
        let risEntries = try RISParser.parse(input)
        
        return risEntries.map { risEntry -> CitationJSEntry in
            var entry = CitationJSEntry(
                id: risEntry.id.uuidString,
                type: mapRISTypeToCSL(risEntry.type.rawValue)
            )
            
            entry.title = risEntry.title
            entry.author = risEntry.authors.map { author -> CitationJSName in
                let parts = author.components(separatedBy: ", ")
                if parts.count >= 2 {
                    return CitationJSName(family: parts[0], given: parts[1], literal: nil)
                }
                return CitationJSName(family: nil, given: nil, literal: author)
            }
            
            if let year = risEntry.year {
                entry.issued = CitationJSDate(dateParts: [[Int(year) ?? 0]], raw: year, literal: nil)
            }
            
            entry.containerTitle = risEntry.journal
            entry.volume = risEntry.volume
            entry.page = risEntry.pages
            entry.doi = risEntry.doi
            entry.url = risEntry.url
            entry.abstract = risEntry.abstract
            entry.publisher = risEntry.publisher
            
            return entry
        }
    }
    
    private func tryParseWithCitationJS(_ input: String) -> [CitationJSEntry]? {
        guard let ctx = context, isInitialized else { return nil }
        
        // 嘗試使用 Citation.js 的 Cite 類別
        let escapedInput = input.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
        
        let script = """
        (function() {
            try {
                if (typeof Cite !== 'undefined') {
                    var cite = new Cite("\(escapedInput)");
                    return JSON.stringify(cite.get({ format: 'real', type: 'json', style: 'csl' }));
                }
                return null;
            } catch (e) {
                return JSON.stringify({ error: e.message });
            }
        })()
        """
        
        if let result = ctx.evaluateScript(script)?.toString(),
           result != "null",
           let data = result.data(using: .utf8),
           let entries = try? JSONDecoder().decode([CitationJSEntry].self, from: data) {
            return entries
        }
        
        return nil
    }
    
    // MARK: - Conversion Methods
    
    private func convertToBibTeX(_ entries: [CitationJSEntry]) -> String {
        var output = ""
        
        for entry in entries {
            output += "@\(entry.bibTeXType){\(entry.id),\n"
            
            if let title = entry.title {
                output += "  title = {\(title)},\n"
            }
            
            if let authors = entry.author, !authors.isEmpty {
                let authorStr = authors.map { $0.bibTeXFormat }.joined(separator: " and ")
                output += "  author = {\(authorStr)},\n"
            }
            
            if let year = entry.issued?.yearString {
                output += "  year = {\(year)},\n"
            }
            
            if let journal = entry.containerTitle {
                output += "  journal = {\(journal)},\n"
            }
            
            if let publisher = entry.publisher {
                output += "  publisher = {\(publisher)},\n"
            }
            
            if let volume = entry.volume {
                output += "  volume = {\(volume)},\n"
            }
            
            if let issue = entry.issue {
                output += "  number = {\(issue)},\n"
            }
            
            if let pages = entry.page {
                output += "  pages = {\(pages)},\n"
            }
            
            if let doi = entry.doi {
                output += "  doi = {\(doi)},\n"
            }
            
            if let url = entry.url {
                output += "  url = {\(url)},\n"
            }
            
            if let abstract = entry.abstract {
                output += "  abstract = {\(abstract)},\n"
            }
            
            output += "}\n\n"
        }
        
        return output
    }
    
    private func convertToRIS(_ entries: [CitationJSEntry]) -> String {
        var output = ""
        
        for entry in entries {
            output += "TY  - \(mapCSLTypeToRIS(entry.type))\n"
            
            if let title = entry.title {
                output += "TI  - \(title)\n"
            }
            
            if let authors = entry.author {
                for author in authors {
                    output += "AU  - \(author.bibTeXFormat)\n"
                }
            }
            
            if let year = entry.issued?.yearString {
                output += "PY  - \(year)\n"
            }
            
            if let journal = entry.containerTitle {
                output += "JO  - \(journal)\n"
            }
            
            if let volume = entry.volume {
                output += "VL  - \(volume)\n"
            }
            
            if let issue = entry.issue {
                output += "IS  - \(issue)\n"
            }
            
            if let pages = entry.page {
                let pageParts = pages.components(separatedBy: "-")
                if pageParts.count >= 1 {
                    output += "SP  - \(pageParts[0])\n"
                }
                if pageParts.count >= 2 {
                    output += "EP  - \(pageParts[1])\n"
                }
            }
            
            if let doi = entry.doi {
                output += "DO  - \(doi)\n"
            }
            
            if let url = entry.url {
                output += "UR  - \(url)\n"
            }
            
            if let abstract = entry.abstract {
                output += "AB  - \(abstract)\n"
            }
            
            if let publisher = entry.publisher {
                output += "PB  - \(publisher)\n"
            }
            
            output += "ER  - \n\n"
        }
        
        return output
    }
    
    // MARK: - Helper Methods
    
    private func parseAuthors(_ authorString: String) -> [CitationJSName] {
        let authors = authorString.components(separatedBy: " and ")
        return authors.map { author -> CitationJSName in
            let trimmed = author.trimmingCharacters(in: .whitespaces)
            let parts = trimmed.components(separatedBy: ", ")
            if parts.count >= 2 {
                return CitationJSName(family: parts[0], given: parts[1], literal: nil)
            }
            return CitationJSName(family: nil, given: nil, literal: trimmed)
        }
    }
    
    private func mapBibTeXTypeToCSL(_ type: String) -> String {
        switch type {
        case "article": return "article-journal"
        case "book": return "book"
        case "incollection", "inbook": return "chapter"
        case "inproceedings", "conference": return "paper-conference"
        case "phdthesis", "mastersthesis": return "thesis"
        case "techreport": return "report"
        case "online", "misc": return "webpage"
        default: return "article"
        }
    }
    
    private func mapRISTypeToCSL(_ type: String) -> String {
        switch type {
        case "JOUR": return "article-journal"
        case "BOOK": return "book"
        case "CHAP": return "chapter"
        case "CONF": return "paper-conference"
        case "THES": return "thesis"
        case "RPRT": return "report"
        case "ELEC": return "webpage"
        default: return "article"
        }
    }
    
    private func mapCSLTypeToRIS(_ type: String) -> String {
        switch type {
        case "article-journal", "article": return "JOUR"
        case "book": return "BOOK"
        case "chapter": return "CHAP"
        case "paper-conference": return "CONF"
        case "thesis": return "THES"
        case "report": return "RPRT"
        case "webpage": return "ELEC"
        default: return "GEN"
        }
    }
}
