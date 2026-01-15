//
//  BibTeXParser.swift
//  OVEREND
//
//  BibTeX 解析器 - 將 .bib 文件解析為書目
//

import Foundation
import CoreData

/// BibTeX 書目結構（用於解析）
struct BibTeXEntry {
    var type: String
    var citationKey: String
    var fields: [String: String]
}

class BibTeXParser {
    enum ParserError: Error {
        case invalidFormat
        case emptyContent
        case invalidEntry(line: Int)
    }

    /// 解析 BibTeX 文件內容
    /// - Parameter bibContent: .bib 文件的字符串內容
    /// - Returns: 解析後的書目數組
    static func parse(_ bibContent: String) throws -> [BibTeXEntry] {
        guard !bibContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParserError.emptyContent
        }

        var entries: [BibTeXEntry] = []

        // 正則表達式匹配 @type{key, ...}
        // 支持嵌套大括號和跨行
        let pattern = #"@(\w+)\s*\{\s*([^,\s]+)\s*,\s*((?:[^{}]|\{[^}]*\})*)\s*\}"#
        let regex = try NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )

        let nsString = bibContent as NSString
        let matches = regex.matches(
            in: bibContent,
            range: NSRange(location: 0, length: nsString.length)
        )

        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }

            // 提取類型
            guard let typeRange = Range(match.range(at: 1), in: bibContent) else { continue }
            let type = String(bibContent[typeRange]).lowercased()

            // 提取引用鍵
            guard let keyRange = Range(match.range(at: 2), in: bibContent) else { continue }
            let key = String(bibContent[keyRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            // 提取字段
            guard let fieldsRange = Range(match.range(at: 3), in: bibContent) else { continue }
            let fieldsString = String(bibContent[fieldsRange])

            let fields = try parseFields(fieldsString)

            entries.append(BibTeXEntry(
                type: type,
                citationKey: key,
                fields: fields
            ))
        }

        return entries
    }

    /// 解析字段字符串
    /// - Parameter fieldsString: 字段部分的字符串
    /// - Returns: 字段字典
    private static func parseFields(_ fieldsString: String) throws -> [String: String] {
        var fields: [String: String] = [:]

        // 正則表達式匹配 field = {value} 或 field = "value"
        // 支持嵌套大括號
        let pattern = #"(\w+)\s*=\s*(?:\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}|"([^"]*)")"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])

        let nsString = fieldsString as NSString
        let matches = regex.matches(
            in: fieldsString,
            range: NSRange(location: 0, length: nsString.length)
        )

        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }

            // 提取字段名
            guard let fieldRange = Range(match.range(at: 1), in: fieldsString) else { continue }
            let field = String(fieldsString[fieldRange]).lowercased()

            var value = ""

            // 大括號值（優先）
            if match.range(at: 2).length > 0,
               let valueRange = Range(match.range(at: 2), in: fieldsString) {
                value = String(fieldsString[valueRange])
            }
            // 引號值
            else if match.range(at: 3).length > 0,
                    let valueRange = Range(match.range(at: 3), in: fieldsString) {
                value = String(fieldsString[valueRange])
            }

            // 清理值（移除多餘空白）
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)

            fields[field] = value
        }

        return fields
    }

    /// 從文件讀取並解析 BibTeX
    /// - Parameter fileURL: .bib 文件路徑
    /// - Returns: 解析後的書目數組
    static func parseFile(at fileURL: URL) throws -> [BibTeXEntry] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return try parse(content)
    }

    /// 驗證 BibTeX 條目是否有效
    /// - Parameter entry: BibTeX 書目
    /// - Returns: 是否有效
    static func validate(entry: BibTeXEntry) -> Bool {
        // 檢查類型是否支持
        guard Constants.BibTeX.supportedTypes.contains(entry.type) else {
            return false
        }

        // 檢查必需字段
        if let requiredFields = Constants.BibTeX.requiredFields[entry.type] {
            for field in requiredFields {
                if entry.fields[field] == nil || entry.fields[field]?.isEmpty == true {
                    return false
                }
            }
        }

        return true
    }

    /// 清理 LaTeX 特殊字符
    /// - Parameter text: 原始文本
    /// - Returns: 清理後的文本
    static func cleanLaTeX(_ text: String) -> String {
        var cleaned = text

        // 移除常見 LaTeX 命令
        let replacements: [String: String] = [
            "\\\\textit\\{([^}]*)\\}": "$1",
            "\\\\textbf\\{([^}]*)\\}": "$1",
            "\\\\emph\\{([^}]*)\\}": "$1",
            "\\\\'\\{([a-zA-Z])\\}": "$1",
            "\\\\`\\{([a-zA-Z])\\}": "$1",
            "\\\\~\\{([a-zA-Z])\\}": "$1",
            "\\\\\\^\\{([a-zA-Z])\\}": "$1"
        ]

        for (pattern, replacement) in replacements {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(cleaned.startIndex..., in: cleaned)
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    range: range,
                    withTemplate: replacement
                )
            }
        }

        return cleaned
    }
}

// MARK: - 擴展：批量導入

extension BibTeXParser {
    /// 批量導入到 Core Data
    /// - Parameters:
    ///   - entries: 解析後的 BibTeX 書目
    ///   - library: 目標文獻庫
    ///   - context: Core Data 上下文
    /// - Returns: 成功導入的數量
    @discardableResult
    static func importEntries(
        _ entries: [BibTeXEntry],
        into library: Library,
        context: NSManagedObjectContext
    ) throws -> Int {
        var importedCount = 0
        var importedEntryIDs: [UUID] = []

        for bibEntry in entries {
            // 檢查是否已存在相同 Citation Key
            if Entry.find(byCitationKey: bibEntry.citationKey, in: context) != nil {
                print("跳過重複書目: \(bibEntry.citationKey)")
                continue
            }

            // 創建新書目
            let newEntry = Entry(
                context: context,
                citationKey: bibEntry.citationKey,
                entryType: bibEntry.type,
                fields: bibEntry.fields,
                library: library
            )

            importedCount += 1
            importedEntryIDs.append(newEntry.id)
        }

        // 保存
        try context.save()
        
        // 發送匯入通知，觸發 Agent 自動分析
        if !importedEntryIDs.isEmpty {
            if #available(macOS 26.0, *) {
                AgentAutoTrigger.notifyImport(
                    entryIDs: importedEntryIDs,
                    libraryID: library.id,
                    source: .bibtex
                )
            }
        }

        return importedCount
    }
}

