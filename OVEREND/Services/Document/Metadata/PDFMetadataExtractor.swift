import Foundation
import PDFKit

// MARK: - PDF Metadata Models

public struct PDFMetadata {
    public enum MetadataConfidence: String, Codable {
        case high
        case medium
        case low
        
        public var color: String {
            switch self {
            case .high: return "#10B981" // Green
            case .medium: return "#F59E0B" // Amber
            case .low: return "#EF4444" // Red
            }
        }
        
        public var label: String {
            switch self {
            case .high: return "高"
            case .medium: return "中"
            case .low: return "低"
            }
        }
    }
    
    public var title: String
    public var authors: [String] = []
    public var doi: String?
    public var journal: String?
    public var year: String?
    public var abstract: String?
    public var volume: String?
    public var pages: String?
    public var entryType: String = "article"
    public var confidence: MetadataConfidence = .medium
    public var keywords: [String] = []
    public var strategy: String = "offline"  // 提取策略：offline, doi, crossref, etc.
    
    public init(
        title: String? = nil,
        authors: [String] = [],
        year: String? = nil,
        doi: String? = nil,
        abstract: String? = nil,
        journal: String? = nil,
        volume: String? = nil,
        pages: String? = nil,
        entryType: String = "article",
        confidence: MetadataConfidence = .medium
    ) {
        self.title = title ?? "Untitled"
        self.authors = authors
        self.year = year
        self.doi = doi
        self.abstract = abstract
        self.journal = journal
        self.volume = volume
        self.pages = pages
        self.entryType = entryType
        self.confidence = confidence
        self.strategy = "offline"  // 預設為離線提取
    }
}

// MARK: - PDF Metadata Service (Coordinator)

/// PDF 元數據服務 (統一入口)
public class PDFMetadataService {
    public static let shared = PDFMetadataService()

    private let extractor = PDFMetadataExtractor.shared
    private let crossRefMetadataService = CrossRefMetadataService.shared
    
    public init() {}
    
    /// 提取 PDF 元數據
    public func extract(from url: URL) async -> PDFMetadata {
        // 1. 執行離線提取
        var metadata = await extractor.extract(from: url)
        
        // 2. 如果發現 DOI，嘗試聯網獲取更精確資訊
        if let doi = metadata.doi, !doi.isEmpty {
            if let onlineData = await crossRefMetadataService.fetchMetadata(doi: doi) {
                print("✅ CrossRef Hit for DOI: \(doi)")
                if !onlineData.title.isEmpty { metadata.title = onlineData.title }
                if !onlineData.authors.isEmpty { metadata.authors = onlineData.authors }
                if let journal = onlineData.journal { metadata.journal = journal }
                if let year = onlineData.year { metadata.year = year }
                if let abstract = onlineData.abstract { metadata.abstract = abstract } // Merge Abstract
                metadata.confidence = .high // DOI 確認後提高信心度
            }
        }
        
        return metadata
    }
}

// MARK: - PDF Metadata Extractor (Algorithm)

public class PDFMetadataExtractor {
    public static let shared = PDFMetadataExtractor()
    
    public init() {}
    
    /// 提取元數據 (離線)
    public func extract(from url: URL) async -> PDFMetadata {
        guard let doc = PDFDocument(url: url) else { return PDFMetadata() }
        
        var metadata = PDFMetadata()
        var confidence: PDFMetadata.MetadataConfidence = .low
        
        // 第 1 層：讀取 PDF DocumentAttributes
        var metadataTitle: String?
        if let attrs = doc.documentAttributes {
            if let title = attrs[PDFDocumentAttribute.titleAttribute] as? String, !title.isEmpty {
                if isValidTitle(title) {
                    metadataTitle = title
                    metadata.title = title
                }
            }
            if let author = attrs[PDFDocumentAttribute.authorAttribute] as? String, !author.isEmpty {
                metadata.authors = author.components(separatedBy: CharacterSet(charactersIn: ";,")).map { $0.trimmingCharacters(in: .whitespaces) }
            }
            if let subject = attrs[PDFDocumentAttribute.subjectAttribute] as? String {
                metadata.journal = subject
            }
            if let keywords = attrs[PDFDocumentAttribute.keywordsAttribute] as? String {
                metadata.keywords = keywords.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
        }
        
        // 第 2 層：進階演算法解析 (Advanced Algorithms)
        if let page1 = doc.page(at: 0) {
            // Strategy 3: 相對位置錨點法 (最優先 - 針對格式固定的論文)
            let anchorResult = analyzeAnchors(page: page1)
            
            // Strategy 2: 權重評分系統 (針對一般期刊/報告)
            let scoringResult = analyzeWeightedScoring(page: page1)
            
            // 整合 DOI (使用 Regex 掃描全文)
            if let text = page1.string {
                if let doi = extractDOI(text) {
                    metadata.doi = doi
                    confidence = .medium
                }
                if let year = extractYearWithContext(text) {
                    metadata.year = year
                }
                // 3. Abstract Extraction (Offline)
                if let abstract = analyzeAbstract(text: text) {
                    metadata.abstract = abstract
                }
            }
            
            // 決策整合 (Decision Fusion)
            
            // 1. Title Decision
            // 如果錨點法有找到標題，優先使用 (通常最準)
            if let anchorTitle = anchorResult.title, !anchorTitle.isEmpty {
                metadata.title = anchorTitle
                confidence = .high
            } 
            // 否則使用加權評分法的最高分候選
            else if let bestScoreTitle = scoringResult.title {
                if isValidTitle(bestScoreTitle) {
                     // 如果 Metadata 裡的標題看起來是垃圾 (Untitled, etc)，就覆蓋它
                    if metadata.title == "Untitled" || metadata.title.isEmpty || !isValidTitle(metadata.title) {
                        metadata.title = bestScoreTitle
                        if confidence == .low { confidence = .medium }
                    }
                }
            }
            
            // 2. Author Decision
            if !anchorResult.authors.isEmpty {
                metadata.authors = anchorResult.authors
                if confidence == .medium { confidence = .high }
            } else if metadata.authors.isEmpty {
                // 如果沒找到作者，嘗試使用加權評分法找到標題後面的區塊 (Heuristic)
                if let bestTitle = scoringResult.title, let text = page1.string {
                    let lines = text.components(separatedBy: .newlines)
                    if let index = lines.firstIndex(where: { $0.contains(bestTitle) }) {
                         let nextLines = lines.dropFirst(index + 1).prefix(5).map { String($0) }
                         metadata.authors = extractAuthorsFromLines(nextLines)
                    }
                }
            }
        }
        
        metadata.confidence = confidence
        return metadata
    }
    
    // Helper: Validate Title (Filter out garbage metadata)
    private func isValidTitle(_ title: String) -> Bool {
        let lower = title.lowercased()
        let invalidPrefixes = [
            "microsoft word -", "slide", "presentation", "untitled", 
            "bachelor", "master", "phd", "thesis", "dissertation",
            "研究生", "student", "author", "指導教授", "研 究 生"
        ]
        let invalidSuffixes = [".docx", ".doc", ".pdf", ".pptx"]
        
        if invalidPrefixes.contains(where: { lower.hasPrefix($0) }) { return false }
        if invalidSuffixes.contains(where: { lower.hasSuffix($0) }) { return false }
        
        let alphanumeric = lower.filter { $0.isNumber || $0.isLetter }
        if alphanumeric.isEmpty || alphanumeric.allSatisfy({ $0.isNumber }) { return false } // Only numbers or empty
        
        // 1. Spaced Characters check (e.g. "n a l C")
        // Regex: Single char followed by space, repeated
        let spacedPattern = #"^([a-z]\s)+[a-z]$"# 
        if lower.range(of: spacedPattern, options: .regularExpression) != nil {
            return false
        }
        
        // 2. High space density check
        let spaces = lower.filter { $0.isWhitespace }.count
        if spaces > 0 {
             let ratio = Double(spaces) / Double(lower.count)
             if ratio > 0.35 && lower.count < 30 { return false } // Strict for short titles
        }
        
        // 3. Length check
        if lower.count < 4 { return false } // Too short

        return true
    }
    
    // MARK: - Strategy 2: Weighted Scoring System (權重評分系統)
    
    private struct ScoredCandidate {
        let text: String
        let score: Double
    }
    
    private func analyzeWeightedScoring(page: PDFPage) -> (title: String?, authors: [String]) {
        guard let attributedString = page.attributedString else { return (nil, []) }
        
        let string = attributedString.string
        let fullRange = NSRange(location: 0, length: string.utf16.count)
        let pageHeight = page.bounds(for: .mediaBox).height
        let pageWidth = page.bounds(for: .mediaBox).width
        
        var candidates: [ScoredCandidate] = []
        
        // 逐行分析
        string.enumerateSubstrings(in: string.startIndex..<string.endIndex, options: [.byLines, .localized]) { (line, range, _, stop) in
            guard let line = line, !line.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            let nsRange = NSRange(range, in: string)
            
            // 獲取該行的屬性 (取第一個字的屬性作為代表)
            var currentScore: Double = 0
            var fontSize: CGFloat = 12
            
             // 嘗試獲取 Font
            if let font = attributedString.attribute(.font, at: nsRange.location, effectiveRange: nil) as? NSFont {
                fontSize = font.pointSize
            }
            
            // 1. 字體大小權重 (Font Size)
            currentScore += Double(fontSize) * 2.5
            
            // 2. 位置權重 (Position) - 黃金區間 (10% ~ 40% height)
            // 由於 attributedString 很難直接對應 Y 軸，我們這裡用 "行數/總字數" 的相對位置做近似估計，或者如果能取到 bounds
            // 這裡做個近似：前面 30% 的字元通常是頭部
            if nsRange.location < Int(Double(fullRange.length) * 0.3) {
                currentScore += 20
            }
            
            // 3. 長度懲罰 (Length Penalty)
            if line.count < 5 { currentScore -= 50 } // 太短
            if line.count > 100 { currentScore -= 20 } // 太長可能是內文
            
            // 4. 黑名單 (Negative Keywords)
            let lower = line.lowercased()
            if lower.contains("journal") || lower.contains("issn") || lower.contains("vol.") || lower.contains("doi") {
                currentScore -= 100
            }
            
            // 5. 格式加分
            if lower != line { // 有大寫字母
                currentScore += 5
            }
            
            candidates.append(ScoredCandidate(text: line, score: currentScore))
        }
        
        // 取出分數最高的
        let bestCandidate = candidates.max(by: { $0.score < $1.score })
        return (bestCandidate?.text, [])
    }
    
    // MARK: - Strategy 3: Relative Position Anchoring (相對位置錨點法)
    
    private struct AnchorResult {
        var title: String?
        var authors: [String] = []
    }
    
    private func analyzeAnchors(page: PDFPage) -> AnchorResult {
        var result = AnchorResult()
        guard let text = page.string else { return result }
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        
        // 定義錨點關鍵字 (Thesis specific)
        let authorAnchors = ["研究生", "Student", "Author", "Written by"]
        let advisorAnchors = ["指導教授", "Advisor", "Supervised by"]
        
        for (index, line) in lines.enumerated() {
            // 1. Author Detection via Anchors
            for anchor in authorAnchors {
                if line.caseInsensitiveContains(anchor) {
                    // Case A: 同一行 (e.g., "研究生：孫碩昱")
                    let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                    if parts.count > 1 {
                        let name = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: ": "))
                        if !name.isEmpty {
                            result.authors.append(formatChineseNames(name))
                        }
                    } 
                    // Case B: 下一行 (e.g., "研究生\n孫碩昱")
                    else if index + 1 < lines.count {
                        let nextLine = lines[index + 1]
                        if !nextLine.isEmpty && nextLine.count < 20 {
                             result.authors.append(formatChineseNames(nextLine))
                        }
                    }
                }
            }
            
            // 2. Title Inference (Reverse Lookup)
            // 如果找到作者錨點，往上看字體最大或長度最適合的行，通常就是標題
            // 這裡簡化：取錨點上方最近的非空長行 (假設是標題)
            if result.title == nil && (line.caseInsensitiveContains(authorAnchors.first!) || line.caseInsensitiveContains(advisorAnchors.first!)) {
                // 回朔尋找標題 using WeightedScoring logic locally on previous lines?
                // 這裡用簡單 heuristic: 往上找最近的一行長度 > 5 的字
                for i in (0..<index).reversed() {
                    let prev = lines[i]
                    if prev.count > 5 {
                        // 避開學校名稱
                        if !prev.contains("大學") && !prev.contains("Institute") {
                            result.title = prev
                            break
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Strategy 4: Abstract Extraction
    
    private func analyzeAbstract(text: String) -> String? {
        let patterns = ["Abstract", "ABSTRACT", "摘要"]
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            for pattern in patterns {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                // Check for exact match or "Abstract:"
                if cleanLine.caseInsensitiveCompare(pattern) == .orderedSame ||
                   cleanLine.lowercased().hasPrefix(pattern.lowercased() + ":") ||
                   cleanLine.lowercased().hasPrefix(pattern.lowercased() + " :") {
                    
                    // Found abstract header, collect following lines
                    var abstractLines: [String] = []
                    
                    // If the header line has content after the colon, include it
                    let parts = cleanLine.split(separator: ":", maxSplits: 1).map(String.init)
                    if parts.count > 1 {
                        let content = parts[1].trimmingCharacters(in: .whitespaces)
                        if !content.isEmpty {
                            abstractLines.append(content)
                        }
                    }
                    
                    // Collect up to 20 lines or until suspicious section header
                    let maxLines = 20
                    var currentLineIndex = index + 1
                    
                    while currentLineIndex < lines.count && abstractLines.count < maxLines {
                        let nextLine = lines[currentLineIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Stop if we hit another section header
                        let lowerNext = nextLine.lowercased()
                        if lowerNext == "introduction" || lowerNext == "1. introduction" || lowerNext == "緒論" || lowerNext == "前言" {
                            break
                        }
                        
                        if !nextLine.isEmpty {
                            abstractLines.append(nextLine)
                        }
                        currentLineIndex += 1
                    }
                    
                    if !abstractLines.isEmpty {
                        return abstractLines.joined(separator: " ")
                    }
                }
            }
        }
        return nil
    }

    private func extractDOI(_ text: String) -> String? {
        let doiPatterns = [
            #"doi:\s*10\.\d{4,}/[^\s\]\"'>]+"#,
            #"DOI:\s*10\.\d{4,}/[^\s\]\"'>]+"#,
            #"\b(10\.\d{4,}/[^\s\]\"'>]+)\b"#
        ]
        
        for pattern in doiPatterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                 var found = String(text[range])
                 found = found.replacingOccurrences(of: "doi:", with: "", options: .caseInsensitive)
                 found = found.replacingOccurrences(of: "DOI:", with: "")
                 found = found.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:\">"))
                 return found.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    // MARK: - Helpers
    

    
    // 2. Extract Year (Context-aware)
    private func extractYearWithContext(_ text: String) -> String? {
        // 優先尋找四位數字年份，且前後有非數字字元 (避免 DOI 或其他數字)
        let yearPattern = #"\b(19|20)\d{2}\b"# // 1900-2099
        
        if let match = text.range(of: yearPattern, options: .regularExpression) {
            return String(text[match])
        }
        
        // 如果沒有找到，嘗試尋找括號內的年份 (常見於參考文獻或版權資訊)
        let bracketYearPattern = #"\((19|20)\d{2}\)"#
        if let match = text.range(of: bracketYearPattern, options: .regularExpression) {
            let fullMatch = String(text[match])
            return fullMatch.filter { $0.isNumber }
        }
        
        return nil
    }
    
    // Helper: Author Extraction Heuristics (Enhanced with Chinese Name Support)
    private func extractAuthorsFromLines(_ lines: [String]) -> [String] {
        var foundAuthors: [String] = []
        
        for line in lines {
            var cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Clean common prefixes
            let prefixesToRemove = ["研 究 生", "研究生", "指導教授", "Student", "Author", "By"]
            for prefix in prefixesToRemove {
                if cleanLine.lowercased().hasPrefix(prefix.lowercased()) {
                    if let range = cleanLine.range(of: prefix, options: [.caseInsensitive]) {
                        // Remove prefix and any following usually colon or space
                        let afterPrefix = cleanLine[range.upperBound...].trimmingCharacters(in: CharacterSet(charactersIn: ":： ").union(.whitespaces))
                        cleanLine = afterPrefix
                    }
                }
            }
            
            let lower = cleanLine.lowercased()
            // Skip invalid lines
            if lower.contains("@") || lower.contains("university") || lower.contains("department") || 
               lower.contains("received") || lower.contains("correspondence") || lower.contains("abstract") {
                continue
            }
            
            // ... (rest remains same)
            
            // Check for name-like patterns
            let hasDigit = cleanLine.rangeOfCharacter(from: .decimalDigits) != nil
            // Allow lines without digits, or very short lines (Chinese names)
            if !hasDigit && cleanLine.split(separator: " ").count < 15 {
                 // Chinese Name Clean up
                 if cleanLine.count < 80 {
                     let formatted = formatChineseNames(cleanLine)
                     if formatted != cleanLine {
                         // Detected Chinese names
                         foundAuthors.append(contentsOf: formatted.components(separatedBy: "、"))
                         continue
                     }
                 }
                 
                 // Western Name Clean up
                 let names = cleanLine.components(separatedBy: CharacterSet(charactersIn: ",&")).map { $0.trimmingCharacters(in: .whitespaces) }
                 let validNames = names.filter { $0.count > 2 && $0.contains(" ") && $0.filter { $0.isNumber }.isEmpty } 
                 if !validNames.isEmpty {
                     foundAuthors.append(contentsOf: validNames)
                 }
            }
        }
        return foundAuthors
    }
    
    // Helper: Chinese Name Formatting
    private func formatChineseNames(_ authorString: String) -> String {
        let authors = authorString.components(separatedBy: CharacterSet(charactersIn: ",、"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let formatted = authors.map { author -> String in
            let chineseCharacters = author.filter { ("\u{4E00}"..."\u{9FFF}").contains($0) }
            // If strictly Chinese and length 2-4
            if chineseCharacters.count == author.count && author.count >= 2 && author.count <= 4 {
                let firstChar = String(author.prefix(1))
                let restChars = String(author.dropFirst())
                return "\(firstChar) \(restChars)" // Format as "Surname Name"
            }
            return author
        }
        return formatted.joined(separator: "、")
    }
    
    /// 生成 BibTeX
    public static func generateBibTeX(from metadata: PDFMetadata, citationKey: String) -> String {
        var bib = "@\(metadata.entryType){\(citationKey),\n"
        bib += "  title = {\(metadata.title)},\n"
        if !metadata.authors.isEmpty {
            bib += "  author = {\(metadata.authors.joined(separator: " and "))},\n"
        }
        if let year = metadata.year { bib += "  year = {\(year)},\n" }
        if let journal = metadata.journal { bib += "  journal = {\(journal)},\n" }
        if let doi = metadata.doi { bib += "  doi = {\(doi)},\n" }
        if let abstract = metadata.abstract { bib += "  abstract = {\(abstract)},\n" }
        bib += "}"
        return bib
    }
}

// MARK: - CrossRef Metadata Service (用於 PDF 元數據提取)

// MARK: - CrossRef Metadata Service (Enhanced)

public class CrossRefMetadataService {
    public static let shared = CrossRefMetadataService()
    private let baseURL = "https://api.crossref.org/works/"
    
    public init() {}
    
    public func fetchMetadata(doi: String) async -> PDFMetadata? {
        var cleanDOI = doi.trimmingCharacters(in: .whitespacesAndNewlines)
        // Basic cleaning
        if cleanDOI.lowercased().hasPrefix("doi:") {
            cleanDOI = String(cleanDOI.dropFirst(4))
        }
        cleanDOI = cleanDOI.replacingOccurrences(of: "https://doi.org/", with: "")
        cleanDOI = cleanDOI.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:\">")) // Remove trailing punctuation
        
        guard let url = URL(string: baseURL + cleanDOI) else { return nil }
        
        do {
            var request = URLRequest(url: url)
            request.addValue("OVEREND/1.0 (mailto:support@overend.app)", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 15
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? [String: Any] {
                
                var metadata = PDFMetadata()
                metadata.doi = cleanDOI
                metadata.strategy = "crossref"
                
                // Title
                if let titles = message["title"] as? [String], let title = titles.first {
                    metadata.title = title
                }
                
                // Authors
                if let authorArray = message["author"] as? [[String: Any]] {
                    metadata.authors = authorArray.compactMap { authorDict in
                        let given = authorDict["given"] as? String ?? ""
                        let family = authorDict["family"] as? String ?? ""
                        if family.isEmpty { return nil }
                        return "\(family), \(given)".trimmingCharacters(in: CharacterSet(charactersIn: ", "))
                    }
                }
                
                // Journal / Container
                if let containerTitles = message["container-title"] as? [String], let journal = containerTitles.first {
                    metadata.journal = journal
                }
                
                // Date/Year
                if let published = message["published-print"] as? [String: Any] ?? message["published-online"] as? [String: Any] ?? message["created"] as? [String: Any],
                   let dateParts = published["date-parts"] as? [[Int]],
                   let yearInt = dateParts.first?.first {
                    metadata.year = String(yearInt)
                }
                
                // Abstract (New)
                if let abstract = message["abstract"] as? String {
                     // CrossRef abstract often contains XML tags like <jats:p>
                    let cleanAbstract = abstract
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanAbstract.isEmpty {
                        metadata.abstract = cleanAbstract
                    }
                }
                
                // Additional Fields
                if let volume = message["volume"] as? String { metadata.volume = volume }
                if let pages = message["page"] as? String { metadata.pages = pages }
                
                // Entry Type Mapping
                let type = message["type"] as? String ?? "article"
                switch type {
                case "journal-article": metadata.entryType = "article"
                case "book", "monograph": metadata.entryType = "book"
                case "proceedings-article": metadata.entryType = "inproceedings"
                case "dissertation": metadata.entryType = "phdthesis"
                case "report": metadata.entryType = "techreport"
                default: metadata.entryType = "misc"
                }
                
                return metadata
            }
        } catch {
            print("CrossRefService Error: \(error)")
        }
        return nil
    }
}

// MARK: - Helpers

extension String {
    fileprivate func caseInsensitiveContains(_ other: String) -> Bool {
        return self.range(of: other, options: .caseInsensitive) != nil
    }
}
