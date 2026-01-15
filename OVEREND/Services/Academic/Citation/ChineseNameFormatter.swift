//
//  ChineseNameFormatter.swift
//  OVEREND
//
//  中文姓名格式化與消歧義服務
//  處理學術引用中的中文姓名特殊規則
//

import Foundation

// MARK: - Name Structure

/// 姓名結構
struct ParsedName: Equatable {
    var family: String      // 姓
    var given: String       // 名
    var literal: String?    // 原始格式（用於無法解析時）
    var language: NameLanguage
    
    enum NameLanguage {
        case chinese        // 中文姓名
        case english        // 英文姓名
        case japanese       // 日文姓名
        case korean         // 韓文姓名
        case unknown
    }
    
    /// APA 格式輸出
    var apaFormat: String {
        switch language {
        case .chinese, .japanese, .korean:
            // 東亞姓名：姓+名（無逗號）
            return "\(family)\(given)"
        case .english, .unknown:
            // 西方姓名：姓, 名字首字母.
            let initials = given.split(separator: " ")
                .map { String($0.prefix(1)).uppercased() + "." }
                .joined(separator: " ")
            return "\(family), \(initials)"
        }
    }
    
    /// MLA 格式輸出
    var mlaFormat: String {
        switch language {
        case .chinese, .japanese, .korean:
            return "\(family)\(given)"
        case .english, .unknown:
            return "\(family), \(given)"
        }
    }
    
    /// BibTeX 格式輸出
    var bibTeXFormat: String {
        if let literal = literal {
            return literal
        }
        switch language {
        case .chinese, .japanese, .korean:
            return "\(family)\(given)"
        case .english, .unknown:
            return "\(family), \(given)"
        }
    }
}

// MARK: - Chinese Name Formatter

/// 中文姓名格式化器
class ChineseNameFormatter {
    
    // MARK: - Singleton
    
    static let shared = ChineseNameFormatter()
    
    // MARK: - Properties
    
    /// 常見中文複姓列表
    private let compoundSurnames: Set<String> = [
        "歐陽", "司馬", "上官", "夏侯", "諸葛", "東方", "皇甫", "尉遲",
        "公孫", "令狐", "軒轅", "濮陽", "公冶", "宗政", "濮陽", "淳于",
        "單于", "太叔", "申屠", "公孫", "仲孫", "軒轅", "司徒", "司空",
        "宇文", "長孫", "慕容", "鮮于", "閭丘", "司寇", "子車", "微生",
        "赫連", "呼延", "澹台", "公西", "巫馬", "端木", "顓孫", "百里"
    ]
    
    /// 常見單姓列表（部分）
    private let commonSurnames: Set<String> = [
        "王", "李", "張", "劉", "陳", "楊", "黃", "趙", "吳", "周",
        "徐", "孫", "馬", "朱", "胡", "郭", "何", "林", "高", "羅",
        "鄭", "梁", "謝", "宋", "唐", "許", "鄧", "韓", "馮", "曹",
        "彭", "曾", "蕭", "田", "董", "潘", "袁", "蔡", "蔣", "余",
        "杜", "葉", "程", "魏", "蘇", "呂", "丁", "任", "盧", "姚",
        "沈", "鍾", "姜", "崔", "譚", "陸", "范", "汪", "廖", "石",
        "金", "韋", "賈", "夏", "傅", "方", "鄒", "熊", "白", "孟",
        "秦", "邱", "侯", "江", "尹", "薛", "閻", "段", "雷", "龍",
        "史", "陶", "賀", "毛", "郝", "顧", "龔", "邵", "萬", "錢",
        "嚴", "洪", "戴", "武", "莫", "孔", "向", "湯", "康", "易"
    ]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 解析姓名字串
    /// - Parameters:
    ///   - name: 姓名字串
    ///   - knownLanguage: 已知的語言（如果有）
    /// - Returns: 解析後的姓名結構
    func parse(_ name: String, knownLanguage: ParsedName.NameLanguage? = nil) -> ParsedName {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        // 偵測語言
        let language = knownLanguage ?? detectLanguage(trimmed)
        
        switch language {
        case .chinese:
            return parseChineseName(trimmed)
        case .english:
            return parseEnglishName(trimmed)
        case .japanese:
            return parseJapaneseName(trimmed)
        case .korean:
            return parseKoreanName(trimmed)
        case .unknown:
            // 嘗試自動判斷
            if containsChinese(trimmed) {
                return parseChineseName(trimmed)
            } else {
                return parseEnglishName(trimmed)
            }
        }
    }
    
    /// 解析多個作者
    /// - Parameters:
    ///   - authorString: 作者字串（可用 "and", "、", "," 分隔）
    ///   - knownLanguage: 已知的語言
    /// - Returns: 解析後的姓名陣列
    func parseAuthors(_ authorString: String, knownLanguage: ParsedName.NameLanguage? = nil) -> [ParsedName] {
        // 分割作者
        let separators = CharacterSet(charactersIn: "、；;")
        var names = authorString.components(separatedBy: " and ")
            .flatMap { $0.components(separatedBy: separators) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // 如果只有一個結果且包含逗號，嘗試用逗號分割
        if names.count == 1 && names[0].contains(",") {
            let parts = names[0].components(separatedBy: ",")
            // 檢查是否為「姓, 名」格式
            if parts.count == 2 && !containsChinese(names[0]) {
                // 可能是單一英文姓名
            } else {
                // 可能是多個姓名
                names = parts.map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
        }
        
        return names.map { parse($0, knownLanguage: knownLanguage) }
    }
    
    /// 格式化為 APA 格式（多作者）
    func formatAPA(_ names: [ParsedName], maxAuthors: Int = 20) -> String {
        guard !names.isEmpty else { return "" }
        
        if names.count == 1 {
            return names[0].apaFormat
        }
        
        if names.count == 2 {
            return "\(names[0].apaFormat) & \(names[1].apaFormat)"
        }
        
        if names.count <= maxAuthors {
            let allButLast = names.dropLast().map { $0.apaFormat }.joined(separator: ", ")
            return "\(allButLast), & \(names.last!.apaFormat)"
        }
        
        // 超過 20 位作者
        let first19 = names.prefix(19).map { $0.apaFormat }.joined(separator: ", ")
        return "\(first19), ... \(names.last!.apaFormat)"
    }
    
    /// 偵測姓名語言
    func detectLanguage(_ name: String) -> ParsedName.NameLanguage {
        // 檢查是否包含中文字符
        if containsChinese(name) {
            // 進一步區分中日韓
            if containsJapaneseKana(name) {
                return .japanese
            }
            if containsKoreanHangul(name) {
                return .korean
            }
            return .chinese
        }
        
        // 檢查是否為純英文
        if name.range(of: "[a-zA-Z]", options: .regularExpression) != nil {
            return .english
        }
        
        return .unknown
    }
    
    /// 檢查姓名是否需要消歧義
    /// - Parameters:
    ///   - name1: 第一個姓名
    ///   - name2: 第二個姓名
    /// - Returns: 是否需要消歧義處理
    func needsDisambiguation(_ name1: ParsedName, _ name2: ParsedName) -> Bool {
        // 同姓且首字母相同
        return name1.family == name2.family &&
               name1.given.prefix(1) == name2.given.prefix(1)
    }
    
    /// 生成消歧義格式
    func disambiguatedFormat(_ name: ParsedName, style: CitationStyle = .apa) -> String {
        switch name.language {
        case .chinese, .japanese, .korean:
            // 東亞姓名：顯示完整姓名
            return "\(name.family)\(name.given)"
        case .english, .unknown:
            // 英文姓名：顯示更多名字
            switch style {
            case .apa:
                return "\(name.family), \(name.given)"
            case .mla:
                return "\(name.given) \(name.family)"
            case .chicago:
                return "\(name.family), \(name.given)"
            }
        }
    }
    
    // MARK: - Citation Style
    
    enum CitationStyle {
        case apa
        case mla
        case chicago
    }
    
    // MARK: - Private Methods
    
    /// 解析中文姓名
    private func parseChineseName(_ name: String) -> ParsedName {
        // 移除空格
        let cleanName = name.replacingOccurrences(of: " ", with: "")
        
        // 檢查複姓
        for surname in compoundSurnames {
            if cleanName.hasPrefix(surname) {
                let given = String(cleanName.dropFirst(surname.count))
                return ParsedName(
                    family: surname,
                    given: given,
                    literal: nil,
                    language: .chinese
                )
            }
        }
        
        // 單姓
        if !cleanName.isEmpty {
            let family = String(cleanName.prefix(1))
            let given = String(cleanName.dropFirst())
            return ParsedName(
                family: family,
                given: given,
                literal: nil,
                language: .chinese
            )
        }
        
        return ParsedName(family: "", given: "", literal: name, language: .chinese)
    }
    
    /// 解析英文姓名
    private func parseEnglishName(_ name: String) -> ParsedName {
        // 檢查「姓, 名」格式
        if name.contains(",") {
            let parts = name.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 {
                return ParsedName(
                    family: parts[0],
                    given: parts[1],
                    literal: nil,
                    language: .english
                )
            }
        }
        
        // 檢查「名 姓」格式
        let parts = name.split(separator: " ").map(String.init)
        if parts.count >= 2 {
            // 假設最後一個詞是姓
            let family = parts.last!
            let given = parts.dropLast().joined(separator: " ")
            return ParsedName(
                family: family,
                given: given,
                literal: nil,
                language: .english
            )
        }
        
        return ParsedName(family: name, given: "", literal: name, language: .english)
    }
    
    /// 解析日文姓名
    private func parseJapaneseName(_ name: String) -> ParsedName {
        // 日文姓名處理類似中文，但可能包含假名
        let cleanName = name.replacingOccurrences(of: " ", with: "")
        
        // 簡化處理：假設前 1-2 個字符為姓
        if cleanName.count >= 2 {
            // 嘗試識別常見日本姓氏長度
            let family = String(cleanName.prefix(min(2, cleanName.count)))
            let given = String(cleanName.dropFirst(family.count))
            return ParsedName(
                family: family,
                given: given,
                literal: nil,
                language: .japanese
            )
        }
        
        return ParsedName(family: "", given: "", literal: name, language: .japanese)
    }
    
    /// 解析韓文姓名
    private func parseKoreanName(_ name: String) -> ParsedName {
        let cleanName = name.replacingOccurrences(of: " ", with: "")
        
        // 韓文姓名通常是單姓 + 雙名
        if cleanName.count >= 2 {
            let family = String(cleanName.prefix(1))
            let given = String(cleanName.dropFirst())
            return ParsedName(
                family: family,
                given: given,
                literal: nil,
                language: .korean
            )
        }
        
        return ParsedName(family: "", given: "", literal: name, language: .korean)
    }
    
    // MARK: - Character Detection
    
    /// 檢查是否包含中文字符
    private func containsChinese(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // CJK 統一漢字範圍
            if (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF) ||
               (scalar.value >= 0x3400 && scalar.value <= 0x4DBF) ||
               (scalar.value >= 0x20000 && scalar.value <= 0x2A6DF) {
                return true
            }
        }
        return false
    }
    
    /// 檢查是否包含日文假名
    private func containsJapaneseKana(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // 平假名和片假名範圍
            if (scalar.value >= 0x3040 && scalar.value <= 0x309F) ||
               (scalar.value >= 0x30A0 && scalar.value <= 0x30FF) {
                return true
            }
        }
        return false
    }
    
    /// 檢查是否包含韓文字符
    private func containsKoreanHangul(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // 韓文音節範圍
            if scalar.value >= 0xAC00 && scalar.value <= 0xD7AF {
                return true
            }
        }
        return false
    }
}

// MARK: - CitationService Extension

extension ChineseNameFormatter {
    
    /// 檢查書目條目是否為中文
    func isChinese(entry fields: [String: String]) -> Bool {
        // 檢查 language 欄位
        if let language = fields["language"]?.lowercased() {
            if language.contains("chinese") || 
               language.contains("zh") || 
               language.contains("中文") ||
               language.contains("繁體") ||
               language.contains("簡體") {
                return true
            }
        }
        
        // 檢查標題是否包含中文
        if let title = fields["title"], containsChinese(title) {
            return true
        }
        
        // 檢查作者是否包含中文
        if let author = fields["author"], containsChinese(author) {
            return true
        }
        
        return false
    }
    
    /// 格式化書目條目的作者
    func formatAuthorsForCitation(
        _ authorString: String,
        fields: [String: String],
        style: CitationStyle = .apa
    ) -> String {
        let knownLanguage: ParsedName.NameLanguage? = isChinese(entry: fields) ? .chinese : nil
        let authors = parseAuthors(authorString, knownLanguage: knownLanguage)
        
        switch style {
        case .apa:
            return formatAPA(authors)
        case .mla:
            if authors.isEmpty { return "" }
            if authors.count == 1 {
                return authors[0].mlaFormat
            }
            if authors.count == 2 {
                return "\(authors[0].mlaFormat), and \(authors[1].mlaFormat)"
            }
            return "\(authors[0].mlaFormat), et al."
        case .chicago:
            if authors.isEmpty { return "" }
            if authors.count == 1 {
                return authors[0].mlaFormat
            }
            let allButLast = authors.dropLast().map { $0.mlaFormat }.joined(separator: ", ")
            return "\(allButLast), and \(authors.last!.mlaFormat)"
        }
    }
}
