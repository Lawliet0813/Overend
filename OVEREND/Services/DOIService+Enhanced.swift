//
//  DOIService+Enhanced.swift
//  OVEREND
//
//  DOI 與 PDF 元數據提取增強版
//

import Foundation
import PDFKit

// MARK: - Enhanced PDF Metadata Extraction

extension DOIService {
    
    /// 增強版 PDF 元數據提取（多重策略）
    /// - Parameters:
    ///   - url: PDF 文件路徑
    ///   - fileName: 文件名（作為後備）
    /// - Returns: 提取的元數據
    static func extractEnhancedMetadata(from url: URL, fileName: String) -> (title: String, author: String, year: String, type: String) {
        guard let pdfDocument = PDFDocument(url: url) else {
            return (fileName, "Unknown", "", "misc")
        }
        
        var title = fileName
        var author = "Unknown"
        var year = ""
        var type = "misc"
        
        // 策略 1: PDF 內建屬性（但要驗證品質）
        if let attributes = pdfDocument.documentAttributes {
            if let pdfTitle = attributes[PDFDocumentAttribute.titleAttribute] as? String {
                let cleanTitle = pdfTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                // 驗證標題品質：
                // 1. 長度合理（10-200 字元）
                // 2. 不是文件名（不包含副檔名）
                // 3. 不全是大寫（可能是期刊名）
                // 4. 不包含太多特殊符號
                // 5. 不是 Hex 編碼（Microsoft Word 二進位）
                let hasFileExtension = cleanTitle.lowercased().contains(".pdf") || 
                                      cleanTitle.lowercased().contains(".doc") ||
                                      cleanTitle.lowercased().contains(".indd") ||
                                      cleanTitle.lowercased().contains(".ppt")
                
                let isHexEncoded = cleanTitle.hasPrefix("<") && cleanTitle.hasSuffix(">") &&
                                  cleanTitle.filter({ "0123456789ABCDEFabcdef".contains($0) }).count > Int(Double(cleanTitle.count) * 0.8)
                
                if cleanTitle.count >= 10 && cleanTitle.count <= 200 &&
                   !hasFileExtension &&
                   !isHexEncoded &&
                   cleanTitle != cleanTitle.uppercased() {
                    // 檢查是否有太多非文字字符
                    let alphanumericCount = cleanTitle.filter { $0.isLetter || $0.isNumber || $0.isWhitespace || "、，。！？：；（）".contains($0) }.count
                    if Double(alphanumericCount) / Double(cleanTitle.count) > 0.6 {
                        title = cleanTitle
                    }
                }
            }
            
            if let pdfAuthor = attributes[PDFDocumentAttribute.authorAttribute] as? String {
                let cleanAuthor = pdfAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
                // 驗證作者品質：
                // 1. 不是太短（>3 字元 for 代碼，>5 字元 for 單字）
                // 2. 不是明顯的代碼（WIN7-64, c295）
                // 3. 不是單個英文單字（yang, administrator, user）
                let looksLikeCode = cleanAuthor.count <= 3 || 
                                   cleanAuthor.contains("-") ||
                                   cleanAuthor.lowercased() == "administrator" ||
                                   cleanAuthor.lowercased() == "user" ||
                                   cleanAuthor.lowercased() == "owner"
                
                // 如果是單個英文單字（沒有空格），可能是登入名稱而非真實姓名
                // 真實英文姓名應該有空格（First Last）或至少很長
                let isSingleEnglishWord = !cleanAuthor.contains(" ") && 
                                         !cleanAuthor.contains(",") &&
                                         cleanAuthor.count <= 15 &&
                                         cleanAuthor.allSatisfy { $0.isLetter || $0.isWhitespace }
                
                // 額外檢查：如果太短且全是英文字母，很可能是用戶名
                let isProbablyUsername = cleanAuthor.count <= 10 && 
                                        cleanAuthor.allSatisfy { $0.isLetter } &&
                                        !cleanAuthor.contains(" ")
                
                if !cleanAuthor.isEmpty && !looksLikeCode && !isSingleEnglishWord && !isProbablyUsername {
                    author = cleanAuthor
                }
            }
            
            if let creationDate = attributes[PDFDocumentAttribute.creationDateAttribute] as? Date {
                let calendar = Calendar.current
                year = String(calendar.component(.year, from: creationDate))
            }
        }
        
        // 策略 2: 從文字內容提取（前 5 頁）
        let pagesToScan = min(5, pdfDocument.pageCount)
        var fullText = ""
        
        for i in 0..<pagesToScan {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        if !fullText.isEmpty {
            // 如果標題仍是文件名或是亂碼，強制從內容提取
            let titleIsBad = title == fileName || 
                           title.hasPrefix("<") || 
                           title.contains(".indd") ||
                           title.contains(".pdf") ||
                           title.count < 5
            
            if titleIsBad {
                if let extractedTitle = extractTitleFromText(fullText) {
                    title = extractedTitle
                }
            }
            
            // 如果作者仍是 Unknown，嘗試從內容提取
            if author == "Unknown" {
                author = extractAuthorEnhanced(from: fullText)
            }
            
            // 如果年份仍為空，嘗試從內容提取
            if year.isEmpty {
                year = extractYearEnhanced(from: fullText)
            }
            
            // 識別文獻類型
            type = extractTypeEnhanced(from: fullText)
        }
        
        return (title, author, year, type)
    }
    
    // MARK: - 增強版標題提取
    
    /// 從文本提取標題（假設標題在前幾行）
    private static func extractTitleFromText(_ text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard lines.count >= 2 else { return nil }
        
        // 策略 1: 尋找明確的標題標記（論文、研究、分析等關鍵字）
        let titleKeywords = ["研究", "分析", "探討", "論", "系統", "設計", "開發", "實作", 
                           "study", "analysis", "research", "system", "design", "development"]
        
        for (index, line) in lines.prefix(10).enumerated() {
            // 跳過太短的行
            if line.count < 10 { continue }
            
            // 如果包含標題關鍵字且長度合理
            if titleKeywords.contains(where: { line.contains($0) }) && line.count >= 15 && line.count <= 200 {
                // 排除明顯不是標題的
                let lowerLine = line.lowercased()
                if !lowerLine.contains("abstract") && 
                   !lowerLine.contains("keywords") &&
                   !lowerLine.contains("摘要") {
                    return line
                }
            }
        }
        
        // 策略 2: 找最長的行（通常標題是最長的）
        var candidateLines: [(index: Int, line: String, length: Int)] = []
        
        for (index, line) in lines.prefix(15).enumerated() {
            // 跳過太短或太長的
            if line.count < 15 || line.count > 200 { continue }
            
            // 跳過期刊名、會議名
            let lowerLine = line.lowercased()
            let skipKeywords = ["journal", "conference", "proceedings", "ieee", "acm", 
                              "springer", "elsevier", "vol", "no.", "pp.", "doi"]
            if skipKeywords.contains(where: { lowerLine.contains($0) }) { continue }
            
            // ⭐ 新增：跳過機構資訊（期刊論文作者機構）
            let institutionKeywords = ["department", "university", "college", "institute", 
                                      "professor", "assistant professor", "associate professor",
                                      "graduate student", "doctoral student", "phd student"]
            if institutionKeywords.contains(where: { lowerLine.contains($0) }) { continue }
            
            // 跳過摘要、關鍵字區域
            if lowerLine.contains("abstract") || 
               lowerLine.contains("keywords") ||
               lowerLine.contains("摘要") ||
               lowerLine.contains("關鍵字") { break }
            
            // 跳過太多標點符號的（可能是句子）
            let punctuationCount = line.filter { "。！？：；.!?:;".contains($0) }.count
            if punctuationCount > 3 { continue }
            
            // 跳過數字太多的（可能是編號、頁碼）
            let digitCount = line.filter { $0.isNumber }.count
            if Double(digitCount) / Double(line.count) > 0.2 { continue }
            
            candidateLines.append((index, line, line.count))
        }
        
        // 取最長的候選標題，但優先考慮中文標題
        if !candidateLines.isEmpty {
            // 優先選擇包含中文的標題
            let chineseLines = candidateLines.filter { candidate in
                let chineseCount = candidate.line.filter { char in
                    ("\u{4E00}"..."\u{9FFF}").contains(char)
                }.count
                return Double(chineseCount) / Double(candidate.line.count) > 0.3 // 超過30%是中文
            }
            
            // 如果有中文標題，從中選最長的
            if !chineseLines.isEmpty {
                if let longest = chineseLines.sorted(by: { $0.length > $1.length }).first {
                    return longest.line
                }
            }
            
            // 如果沒有中文標題，才選擇最長的（可能是英文）
            if let longest = candidateLines.sorted(by: { $0.length > $1.length }).first {
                return longest.line
            }
        }
        
        return nil
    }
    
    // MARK: - 增強版作者提取
    
    /// 增強版作者提取（支援多種格式）
    private static func extractAuthorEnhanced(from text: String) -> String {
        let sample = String(text.prefix(3000)) // 擴大掃描範圍
        let lines = sample.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 策略 0: 期刊論文作者（在標題後面，通常有中英文對照）⭐ 新增
        // 尋找可能是作者行的模式：中文名字 + 英文名字
        for (index, line) in lines.prefix(20).enumerated() {
            // 跳過前 3 行（通常是期刊名和標題）
            if index < 3 { continue }
            
            // 檢查是否同時包含中文名字和英文名字
            let hasChineseName = line.range(of: "[\u{4E00}-\u{9FFF}]{2,4}", options: .regularExpression) != nil
            let hasEnglishName = line.range(of: "[A-Z][a-z]+-[A-Z][a-z]+\\s+[A-Z][a-z]+", options: .regularExpression) != nil
            
            // 如果包含中文名和英文名，很可能是作者行
            if hasChineseName && (hasEnglishName || line.contains("*") || line.contains("**")) {
                // 移除上標符號和英文部分，只保留中文作者
                var cleanedLine = line
                
                // 移除英文部分（通常在中文後面）
                if let range = cleanedLine.range(of: "[A-Z][a-z]+", options: .regularExpression) {
                    cleanedLine = String(cleanedLine[..<range.lowerBound])
                }
                
                // 移除上標符號
                let superscripts = ["*", "†", "‡", "§", "¶", "‖", "◆", "■", "●"]
                for symbol in superscripts {
                    cleanedLine = cleanedLine.replacingOccurrences(of: symbol, with: "")
                }
                
                cleanedLine = cleanedLine.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 提取中文名字（2-4個字的中文詞）
                let pattern = "[\u{4E00}-\u{9FFF}]{2,4}"
                let regex = try? NSRegularExpression(pattern: pattern)
                let nsString = cleanedLine as NSString
                let matches = regex?.matches(in: cleanedLine, range: NSRange(location: 0, length: nsString.length)) ?? []
                
                if !matches.isEmpty {
                    let authors = matches.compactMap { match -> String? in
                        let range = match.range
                        return nsString.substring(with: range)
                    }.joined(separator: "、")
                    
                    if !authors.isEmpty {
                        return authors
                    }
                }
            }
            
            // 如果遇到摘要，停止搜尋
            if line.contains("摘") && line.contains("要") { break }
            if line.lowercased().contains("abstract") { break }
        }
        
        // 策略 1: 尋找台灣論文的作者標記（研究生、指導教授）
        for (index, line) in lines.enumerated() {
            // 檢查「研究生」「作者」等關鍵字
            if line.contains("研究生") || line.contains("研 究 生") {
                // 作者可能在同一行或下一行
                let authorLine = line.contains("：") || line.contains(":") 
                    ? line.components(separatedBy: CharacterSet(charactersIn: "：:")).dropFirst().joined(separator: "").trimmingCharacters(in: .whitespaces)
                    : (index + 1 < lines.count ? lines[index + 1] : "")
                
                if !authorLine.isEmpty && isLikelyChineseName(authorLine) {
                    return cleanAuthorString(authorLine)
                }
            }
        }
        
        // 策略 2: 尋找明確的作者標記（Author, 作者）
        for (index, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            
            // 檢查作者關鍵字
            if lowerLine.hasPrefix("author") || 
               lowerLine.hasPrefix("作者") ||
               lowerLine.hasPrefix("by ") {
                // 作者可能在同一行或下一行
                let authorLine = lowerLine.hasPrefix("author:") || lowerLine.hasPrefix("作者：") 
                    ? line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    : (index + 1 < lines.count ? lines[index + 1] : "")
                
                if !authorLine.isEmpty {
                    return cleanAuthorString(authorLine)
                }
            }
        }
        
        // 策略 2: 啟發式搜尋（放寬條件）
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // 跳過第一行（可能是標題）
            
            // 停止條件
            let stopKeywords = ["abstract", "keywords", "introduction", "摘要", "關鍵字", "壹、", "一、"]
            if stopKeywords.contains(where: { line.lowercased().contains($0.lowercased()) }) {
                break
            }
            
            // 檢查作者特徵
            if isLikelyAuthorLine(line) {
                return cleanAuthorString(line)
            }
        }
        
        return "Unknown"
    }
    
    /// 判斷是否像作者行
    private static func isLikelyAuthorLine(_ line: String) -> Bool {
        // 長度檢查（放寬）
        guard line.count >= 3 && line.count <= 150 else { return false }
        
        // 檢查分隔符（作者通常用這些分隔）
        let hasSeparator = line.contains(",") || 
                          line.contains("、") ||
                          line.contains(" and ") ||
                          line.contains("·") ||
                          line.contains("；")
        
        if !hasSeparator { return false }
        
        // 不應該包含句子結束符號
        if line.contains("。") || line.contains("！") || line.contains("？") {
            return false
        }
        
        // 檢查是否包含數字（但不要太多）
        let digitCount = line.filter { $0.isNumber }.count
        let digitRatio = Double(digitCount) / Double(line.count)
        if digitRatio > 0.3 { return false } // 超過 30% 是數字，可能不是作者
        
        // 檢查是否包含電子郵件（作者行可能有）
        if line.contains("@") {
            return true // 有 email 通常是作者行
        }
        
        // 檢查是否包含學校/機構名（作者行可能有）
        let institutionKeywords = ["university", "college", "institute", "大學", "學院", "研究所", "中心"]
        if institutionKeywords.contains(where: { line.lowercased().contains($0.lowercased()) }) {
            return true
        }
        
        // 檢查是否符合姓名模式
        let nameParts = line.components(separatedBy: CharacterSet(charactersIn: ",、；"))
        if nameParts.count >= 2 {
            // 檢查每個部分是否像姓名
            let likelyNames = nameParts.filter { part in
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                return isLikelyName(trimmed)
            }
            
            return Double(likelyNames.count) / Double(nameParts.count) > 0.6 // 超過 60% 像姓名
        }
        
        return false
    }
    
    /// 判斷是否像姓名
    private static func isLikelyName(_ text: String) -> Bool {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空字串不是
        guard !trimmed.isEmpty else { return false }
        
        // 移除上標符號（在檢查前先清理）
        let superscripts = ["*", "†", "‡", "§", "¶", "‖", "◆", "■", "●"]
        for symbol in superscripts {
            trimmed = trimmed.replacingOccurrences(of: symbol, with: "")
        }
        trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 太長不太可能是名字
        guard trimmed.count <= 50 else { return false }
        
        // 檢查是否為中文姓名（2-4 個中文字）
        let chineseCount = trimmed.filter { ("\u{4E00}"..."\u{9FFF}").contains($0) }.count
        if chineseCount >= 2 && chineseCount <= 4 && chineseCount == trimmed.count {
            return true
        }
        
        // 檢查是否為英文姓名（包含空格或點，但不超過 3 個詞）
        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count >= 2 && words.count <= 4 {
            // 檢查每個詞是否主要是字母
            let alphabeticWords = words.filter { word in
                let letterCount = word.filter { $0.isLetter }.count
                return Double(letterCount) / Double(word.count) > 0.7
            }
            return alphabeticWords.count == words.count
        }
        
        return false
    }
    
    /// 判斷是否像中文姓名（2-5個中文字）
    private static func isLikelyChineseName(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除可能的上標數字
        var cleaned = trimmed
        while cleaned.last?.isNumber == true {
            cleaned.removeLast()
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 檢查是否為中文姓名（2-5個中文字符）
        let chineseCount = cleaned.filter { ("\u{4E00}"..."\u{9FFF}").contains($0) }.count
        
        // 如果主要是中文且長度合理
        if chineseCount >= 2 && chineseCount <= 5 {
            // 允許少量空格或標點
            let validChars = cleaned.filter { char in
                ("\u{4E00}"..."\u{9FFF}").contains(char) || 
                char.isWhitespace ||
                "、，·".contains(char)
            }.count
            return Double(validChars) / Double(cleaned.count) > 0.8
        }
        
        return false
    }
    
    /// 清理作者字串
    private static func cleanAuthorString(_ rawAuthor: String) -> String {
        var cleaned = rawAuthor
        
        // 移除上標符號（但不移除數字，因為可能是機構代碼）
        let superscriptSymbols = ["*", "†", "‡", "§", "¶", "‖", "◆", "■", "●"]
        for symbol in superscriptSymbols {
            cleaned = cleaned.replacingOccurrences(of: symbol, with: "")
        }
        
        // 移除「撰」「著」等論文尾綴
        cleaned = cleaned.replacingOccurrences(of: "撰", with: "")
        cleaned = cleaned.replacingOccurrences(of: "著", with: "")
        
        // 移除所有空白（包括全形空格 U+3000）
        // 中文姓名不需要空格
        cleaned = cleaned.replacingOccurrences(of: "\u{3000}", with: "") // 全形空格
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")        // 半形空格
        cleaned = cleaned.replacingOccurrences(of: "\t", with: "")       // Tab
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 處理中文作者名單（移除數字上標，但保留姓名）
        // 例如：「鍾琮媛1、王小明2」→「鍾琮媛、王小明」
        if cleaned.contains("、") {
            let authors = cleaned.components(separatedBy: "、")
                .map { author in
                    // 移除尾部的數字（通常是機構代碼）
                    var cleanAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
                    while cleanAuthor.last?.isNumber == true {
                        cleanAuthor.removeLast()
                    }
                    return cleanAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter { !$0.isEmpty }
            cleaned = authors.joined(separator: "、")
        }
        
        return cleaned
    }
    
    // MARK: - 增強版年份提取
    
    /// 增強版年份提取
    private static func extractYearEnhanced(from text: String) -> String {
        let sample = String(text.prefix(3000))
        
        // 策略 1: 明確的年份標記
        let yearPatterns = [
            (#"(?:發表|出版|刊登|published|copyright|©)\s*[:：]?\s*(\d{4})"#, true),  // 明確年份標記
            (#"\((\d{4})\)"#, true),                                                    // (2023)
            (#"©\s*(\d{4})"#, true),                                                    // ©2023
            (#"民國\s*(\d{1,3})\s*年"#, false),                                          // 民國年
            (#"中華民國\s*(\d{1,3})\s*年"#, false),                                       // 中華民國年
            (#"\b(19\d{2}|20\d{2})\b"#, false)                                          // 獨立年份（優先級最低）
        ]
        
        for (pattern, isHighPriority) in yearPatterns {
            if let year = extractYearWithPattern(pattern, from: sample, isROC: pattern.contains("民國")) {
                // 高優先級的立即返回
                if isHighPriority {
                    return year
                }
                
                // 低優先級的需要驗證（年份要合理）
                if let yearInt = Int(year), yearInt >= 1950 && yearInt <= 2030 {
                    return year
                }
            }
        }
        
        return ""
    }
    
    /// 用特定模式提取年份
    private static func extractYearWithPattern(_ pattern: String, from text: String, isROC: Bool = false) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
            if let swiftRange = Range(captureRange, in: text) {
                var yearStr = String(text[swiftRange])
                
                // 如果是民國年，轉換為西元
                if isROC, let rocYear = Int(yearStr) {
                    let westernYear = rocYear + 1911
                    if westernYear >= 1912 && westernYear <= 2099 {
                        yearStr = String(westernYear)
                    }
                }
                
                return yearStr
            }
        }
        
        return nil
    }
    
    // MARK: - 增強版類型識別
    
    /// 增強版文獻類型識別
    private static func extractTypeEnhanced(from text: String) -> String {
        let sample = String(text.prefix(5000)).lowercased()
        
        // 專書關鍵字
        let bookKeywords = [
            "isbn", "chapter", "edition", "press", "publisher", 
            "圖書", "出版社", "印行", "專書", "編著", "table of contents", "目錄"
        ]
        
        // 期刊關鍵字
        let journalKeywords = [
            "journal", "vol", "no.", "pp.", "issn", "doi", 
            "proceedings", "conference", "abstract", "keywords",
            "卷", "期", "刊", "研討會", "論文集", "摘要", "關鍵字"
        ]
        
        var bookScore = 0
        var journalScore = 0
        
        // 計算專書分數
        for keyword in bookKeywords {
            if sample.contains(keyword) {
                bookScore += 1
            }
        }
        
        // 計算期刊分數
        for keyword in journalKeywords {
            if sample.contains(keyword) {
                journalScore += 1
            }
        }
        
        // 根據分數判斷
        if bookScore > journalScore && bookScore >= 2 {
            return "book"
        } else if journalScore > bookScore {
            return "article"
        }
        
        // 默認判斷：如果有 DOI 通常是 article
        if sample.contains("doi") {
            return "article"
        }
        
        // 如果看起來像論文（有摘要），默認為 article
        if sample.contains("abstract") || sample.contains("摘要") {
            return "article"
        }
        
        return "misc"
    }
}
