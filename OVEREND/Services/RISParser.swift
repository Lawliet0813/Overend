//
//  RISParser.swift
//  OVEREND
//
//  RIS 格式解析器 - 將 .ris 文件解析為書目
//
//  RIS (Research Information Systems) 是一種標準的書目交換格式
//  常見於 EndNote、Mendeley、Zotero 以及各學術資料庫匯出功能
//
//  支援功能：
//  - 標準 RIS 標籤解析
//  - Big5/UTF-8 自動編碼偵測
//  - CSL-JSON 相容欄位映射
//

import Foundation
import CoreData

// MARK: - RIS 條目結構

/// RIS 書目條目
struct RISEntry: Identifiable {
    let id: UUID
    var type: RISType               // TY 標籤定義的類型
    var fields: [String: String]    // 所有欄位
    var authors: [String]           // AU/A1 作者列表
    var keywords: [String]          // KW 關鍵字列表
    
    init(type: RISType = .misc, fields: [String: String] = [:]) {
        self.id = UUID()
        self.type = type
        self.fields = fields
        self.authors = []
        self.keywords = []
    }
    
    /// 標題
    var title: String? {
        fields["TI"] ?? fields["T1"] ?? fields["CT"]
    }
    
    /// 年份
    var year: String? {
        if let py = fields["PY"] {
            // PY 格式可能是 "2024" 或 "2024/01/15/"
            return String(py.prefix(4))
        }
        if let da = fields["DA"] {
            return String(da.prefix(4))
        }
        return nil
    }
    
    /// 期刊名稱
    var journal: String? {
        fields["JO"] ?? fields["JF"] ?? fields["T2"] ?? fields["JA"]
    }
    
    /// 卷數
    var volume: String? {
        fields["VL"]
    }
    
    /// 期數
    var issue: String? {
        fields["IS"]
    }
    
    /// 頁碼
    var pages: String? {
        if let sp = fields["SP"], let ep = fields["EP"] {
            return "\(sp)-\(ep)"
        }
        return fields["SP"]
    }
    
    /// DOI
    var doi: String? {
        fields["DO"] ?? fields["DOI"]
    }
    
    /// URL
    var url: String? {
        fields["UR"] ?? fields["L1"] ?? fields["L2"]
    }
    
    /// 摘要
    var abstract: String? {
        fields["AB"] ?? fields["N2"]
    }
    
    /// 出版社
    var publisher: String? {
        fields["PB"]
    }
    
    /// 轉換為 BibTeX 類型字串
    var bibTeXType: String {
        type.bibTeXType
    }
    
    /// 生成作者字串（BibTeX 格式）
    var authorString: String {
        authors.joined(separator: " and ")
    }
}

// MARK: - RIS 類型定義

/// RIS 文獻類型
enum RISType: String, CaseIterable {
    case journal = "JOUR"           // 期刊文章
    case book = "BOOK"              // 書籍
    case bookSection = "CHAP"       // 書籍章節
    case conference = "CONF"        // 研討會論文
    case thesis = "THES"            // 學位論文
    case report = "RPRT"            // 報告
    case webpage = "ELEC"           // 網頁
    case newspaper = "NEWS"         // 新聞
    case magazine = "MGZN"          // 雜誌
    case patent = "PAT"             // 專利
    case unpublished = "UNPB"       // 未出版
    case generic = "GEN"            // 通用
    case misc = "MISC"              // 其他
    
    /// 對應的 BibTeX 類型
    var bibTeXType: String {
        switch self {
        case .journal: return "article"
        case .book: return "book"
        case .bookSection: return "incollection"
        case .conference: return "inproceedings"
        case .thesis: return "phdthesis"
        case .report: return "techreport"
        case .webpage: return "misc"
        case .newspaper: return "article"
        case .magazine: return "article"
        case .patent: return "misc"
        case .unpublished: return "unpublished"
        case .generic, .misc: return "misc"
        }
    }
    
    /// 顯示名稱
    var displayName: String {
        switch self {
        case .journal: return "期刊文章"
        case .book: return "書籍"
        case .bookSection: return "書籍章節"
        case .conference: return "研討會論文"
        case .thesis: return "學位論文"
        case .report: return "研究報告"
        case .webpage: return "網頁"
        case .newspaper: return "新聞"
        case .magazine: return "雜誌"
        case .patent: return "專利"
        case .unpublished: return "未出版"
        case .generic, .misc: return "其他"
        }
    }
    
    /// 從 RIS TY 標籤解析類型
    static func from(tyTag: String) -> RISType {
        let normalized = tyTag.trimmingCharacters(in: .whitespaces).uppercased()
        return RISType(rawValue: normalized) ?? .misc
    }
}

// MARK: - RIS 解析器

/// RIS 格式解析器
class RISParser {
    
    // MARK: - 錯誤類型
    
    enum ParserError: LocalizedError {
        case invalidFormat
        case emptyContent
        case encodingError(String)
        case invalidEntry(line: Int, message: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "無效的 RIS 格式"
            case .emptyContent:
                return "檔案內容為空"
            case .encodingError(let message):
                return "編碼錯誤：\(message)"
            case .invalidEntry(let line, let message):
                return "第 \(line) 行解析錯誤：\(message)"
            }
        }
    }
    
    // MARK: - 解析方法
    
    /// 解析 RIS 字串內容
    /// - Parameter content: RIS 格式的字串
    /// - Returns: 解析後的 RIS 條目陣列
    static func parse(_ content: String) throws -> [RISEntry] {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParserError.emptyContent
        }
        
        var entries: [RISEntry] = []
        var currentEntry: RISEntry?
        var lineNumber = 0
        
        // 逐行解析
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            lineNumber += 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 跳過空行
            if trimmedLine.isEmpty {
                continue
            }
            
            // 解析標籤和值
            // RIS 格式: "TAG  - Value"
            guard let tagMatch = parseRISLine(trimmedLine) else {
                // 不是標準 RIS 行，可能是多行值的延續
                if currentEntry != nil && !trimmedLine.isEmpty {
                    // 嘗試附加到前一個欄位（如摘要）
                    continue
                }
                continue
            }
            
            let (tag, value) = tagMatch
            
            switch tag {
            case "TY":
                // 新的條目開始
                if let entry = currentEntry {
                    entries.append(entry)
                }
                currentEntry = RISEntry(type: RISType.from(tyTag: value))
                
            case "ER":
                // 條目結束
                if let entry = currentEntry {
                    entries.append(entry)
                }
                currentEntry = nil
                
            case "AU", "A1", "A2", "A3", "A4":
                // 作者（可多個）
                currentEntry?.authors.append(value)
                currentEntry?.fields[tag] = value
                
            case "KW":
                // 關鍵字（可多個）
                currentEntry?.keywords.append(value)
                currentEntry?.fields[tag] = value
                
            default:
                // 其他欄位
                currentEntry?.fields[tag] = value
            }
        }
        
        // 處理最後一個條目（如果沒有 ER 標籤）
        if let entry = currentEntry {
            entries.append(entry)
        }
        
        // 驗證結果
        guard !entries.isEmpty else {
            throw ParserError.invalidFormat
        }
        
        return entries
    }
    
    /// 從檔案解析 RIS（自動偵測編碼）
    /// - Parameter url: 檔案路徑
    /// - Returns: 解析後的 RIS 條目陣列
    static func parseFile(at url: URL) throws -> [RISEntry] {
        // 使用編碼偵測器自動處理編碼
        let content = try EncodingDetector.readWithAutoEncoding(url: url)
        return try parse(content)
    }
    
    /// 從 Data 解析 RIS（自動偵測編碼）
    /// - Parameter data: 原始資料
    /// - Returns: 解析後的 RIS 條目陣列
    static func parseData(_ data: Data) throws -> [RISEntry] {
        let content = try EncodingDetector.readWithAutoEncoding(data: data)
        return try parse(content)
    }
    
    // MARK: - 私有方法
    
    /// 解析單行 RIS 格式
    /// - Parameter line: 單行內容
    /// - Returns: (標籤, 值) 元組，或 nil 如果不是有效的 RIS 行
    private static func parseRISLine(_ line: String) -> (String, String)? {
        // RIS 格式: "TAG  - Value" 或 "TAG- Value"
        // 標籤通常是 2-4 個大寫字母
        
        // 正則表達式: 2-4 個字母開頭，後接空白和破折號
        let pattern = #"^([A-Z][A-Z0-9]{1,3})\s*-\s*(.*)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
              match.numberOfRanges >= 3 else {
            return nil
        }
        
        guard let tagRange = Range(match.range(at: 1), in: line),
              let valueRange = Range(match.range(at: 2), in: line) else {
            return nil
        }
        
        let tag = String(line[tagRange])
        let value = String(line[valueRange]).trimmingCharacters(in: .whitespaces)
        
        return (tag, value)
    }
    
    // MARK: - 驗證
    
    /// 驗證 RIS 條目是否有效
    /// - Parameter entry: RIS 條目
    /// - Returns: 是否有效
    static func validate(entry: RISEntry) -> Bool {
        // 至少需要標題
        guard entry.title != nil && !entry.title!.isEmpty else {
            return false
        }
        return true
    }
    
    /// 驗證檔案是否為有效的 RIS 格式
    /// - Parameter url: 檔案路徑
    /// - Returns: 是否為有效的 RIS 格式
    static func isValidRISFile(at url: URL) -> Bool {
        do {
            let content = try EncodingDetector.readWithAutoEncoding(url: url)
            // 檢查是否包含 TY 標籤（RIS 條目的開始標記）
            return content.contains("TY  -") || content.contains("TY-")
        } catch {
            return false
        }
    }
}

// MARK: - Core Data 匯入擴展

extension RISParser {
    
    /// 批量匯入 RIS 條目到 Core Data
    /// - Parameters:
    ///   - entries: 解析後的 RIS 條目
    ///   - library: 目標文獻庫
    ///   - context: Core Data 上下文
    /// - Returns: 成功匯入的數量
    @discardableResult
    static func importEntries(
        _ entries: [RISEntry],
        into library: Library,
        context: NSManagedObjectContext
    ) throws -> Int {
        var importedCount = 0
        var importedEntryIDs: [UUID] = []
        
        for risEntry in entries {
            // 跳過無效條目
            guard validate(entry: risEntry) else {
                AppLogger.debug("⚠️ RISParser: 跳過無效條目（缺少標題）")
                continue
            }
            
            // 生成 Citation Key
            let citationKey = generateCitationKey(from: risEntry)
            
            // 檢查是否已存在
            if Entry.find(byCitationKey: citationKey, in: context) != nil {
                AppLogger.debug("⚠️ RISParser: 跳過重複書目: \(citationKey)")
                continue
            }
            
            // 建立欄位字典（轉換為 BibTeX 相容格式）
            var fields: [String: String] = [:]
            
            if let title = risEntry.title {
                fields["title"] = title
            }
            if !risEntry.authors.isEmpty {
                fields["author"] = risEntry.authorString
            }
            if let year = risEntry.year {
                fields["year"] = year
            }
            if let journal = risEntry.journal {
                fields["journal"] = journal
            }
            if let volume = risEntry.volume {
                fields["volume"] = volume
            }
            if let issue = risEntry.issue {
                fields["number"] = issue
            }
            if let pages = risEntry.pages {
                fields["pages"] = pages
            }
            if let doi = risEntry.doi {
                fields["doi"] = doi
            }
            if let url = risEntry.url {
                fields["url"] = url
            }
            if let abstract = risEntry.abstract {
                fields["abstract"] = abstract
            }
            if let publisher = risEntry.publisher {
                fields["publisher"] = publisher
            }
            if !risEntry.keywords.isEmpty {
                fields["keywords"] = risEntry.keywords.joined(separator: ", ")
            }
            
            // 建立 Entry
            let newEntry = Entry(
                context: context,
                citationKey: citationKey,
                entryType: risEntry.bibTeXType,
                fields: fields,
                library: library
            )
            
            importedCount += 1
            importedEntryIDs.append(newEntry.id)
        }
        
        // 儲存
        try context.save()
        
        // 觸發 Agent 自動分析
        if !importedEntryIDs.isEmpty {
            if #available(macOS 26.0, *) {
                AgentAutoTrigger.notifyImport(
                    entryIDs: importedEntryIDs,
                    libraryID: library.id,
                    source: ImportSource.ris
                )
            }
        }
        
        AppLogger.success("✅ RISParser: 成功匯入 \(importedCount) 筆書目")
        return importedCount
    }
    
    /// 從 RIS 條目生成 Citation Key
    /// - Parameter entry: RIS 條目
    /// - Returns: Citation Key
    private static func generateCitationKey(from entry: RISEntry) -> String {
        var key = ""
        
        // 作者姓氏
        if let firstAuthor = entry.authors.first {
            // 嘗試提取姓氏（中文名或西文名）
            let authorParts = firstAuthor.components(separatedBy: CharacterSet(charactersIn: ", "))
            if let lastName = authorParts.first {
                // 移除非字母字元，保留中文
                let cleanName = lastName.filter { $0.isLetter }
                key += cleanName.prefix(10).lowercased()
            }
        }
        
        // 年份
        if let year = entry.year {
            key += year
        }
        
        // 標題首個有意義的詞
        if let title = entry.title {
            let words = title.components(separatedBy: .whitespaces)
            // 跳過 "The", "A", "An" 等冠詞
            let stopWords = Set(["the", "a", "an", "of", "and", "in", "on", "for"])
            for word in words {
                let cleanWord = word.lowercased().filter { $0.isLetter }
                if !stopWords.contains(cleanWord) && !cleanWord.isEmpty {
                    key += cleanWord.prefix(8)
                    break
                }
            }
        }
        
        // 如果 key 太短，加上隨機字串
        if key.count < 5 {
            key += String(UUID().uuidString.prefix(6))
        }
        
        return key
    }
}
