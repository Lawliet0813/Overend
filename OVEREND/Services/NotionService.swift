//
//  NotionService.swift
//  OVEREND
//
//  Notion API 整合服務
//

import Foundation
import Combine

struct NotionConfig {
    static let apiKeyKey = "NotionAPIKey"
    static let databaseIdKey = "NotionDatabaseID"
    static let autoCreateKey = "NotionAutoCreate"
    
    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: apiKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyKey) }
    }
    
    static var databaseId: String {
        get { UserDefaults.standard.string(forKey: databaseIdKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: databaseIdKey) }
    }
    
    static var diaryPageId: String {
        get { UserDefaults.standard.string(forKey: "NotionDiaryPageID") ?? "2db55714413f80d0bd52ee67dafdb6cb" }
        set { UserDefaults.standard.set(newValue, forKey: "NotionDiaryPageID") }
    }
    
    static var isAutoCreateEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoCreateKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoCreateKey) }
    }
    
    static var isValid: Bool {
        !apiKey.isEmpty && !databaseId.isEmpty
    }
}

class NotionService {
    static let shared = NotionService()
    
    private init() {}
    
    /// 測試連接
    func testConnection() async throws -> Bool {
        guard NotionConfig.isValid else {
            throw NSError(domain: "NotionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "請先設定 API Key 和 Database ID"])
        }
        
        let url = URL(string: "https://api.notion.com/v1/databases/\(NotionConfig.databaseId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(NotionConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return true
        } else {
            return false
        }
    }
    
    /// 同步開發日記
    func syncDiaryEntry(content: String) async throws {
        guard !NotionConfig.apiKey.isEmpty, !NotionConfig.diaryPageId.isEmpty else {
            throw NSError(domain: "NotionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "請先設定 API Key 和 Diary Page ID"])
        }
        
        let url = URL(string: "https://api.notion.com/v1/blocks/\(NotionConfig.diaryPageId)/children")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(NotionConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        
        let blocks = convertMarkdownToBlocks(content)
        let body: [String: Any] = ["children": blocks]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "NotionService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Notion API Error: \(errorText)"])
        }
    }
    
    /// 創建測試記錄
    func createRecord(metadata: PDFMetadata, fileURL: URL, processingTime: TimeInterval, logs: String) async throws {
        guard NotionConfig.isValid else { return }
        
        let url = URL(string: "https://api.notion.com/v1/pages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(NotionConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        
        let filename = fileURL.deletingPathExtension().lastPathComponent
        let pdfType = determinePDFType(from: metadata)
        let language = determineLanguage(from: metadata)
        
        let body: [String: Any] = [
            "parent": ["database_id": NotionConfig.databaseId],
            "properties": [
                "檔案名稱": [
                    "title": [
                        ["text": ["content": filename]]
                    ]
                ],
                "PDF 類型": [
                    "select": ["name": pdfType]
                ],
                "語言": [
                    "select": ["name": language]
                ],
                "提取策略": [
                    "select": ["name": metadata.strategy]
                ],
                "測試日期": [
                    "date": ["start": ISO8601DateFormatter().string(from: Date())]
                ],
                "處理時間": [
                    "number": Double(String(format: "%.2f", processingTime)) ?? 0.0
                ],
                "狀態": [
                    "status": ["name": "待測試"]
                ],
                // 預填系統提取值（作為文字區塊或屬性，這裡假設模板有對應屬性，如果沒有則忽略）
                // 為了符合模板的「詳細比對」區塊，我們將這些資訊放入頁面內容中
            ],
            "children": [
                createHeadingBlock("📌 基本資訊"),
                createBulletBlock("測試編號: \(UUID().uuidString.prefix(8))"),
                createBulletBlock("測試環境: macOS \(ProcessInfo.processInfo.operatingSystemVersionString), OVEREND 1.1.0"),
                
                createHeadingBlock("📝 系統提取結果"),
                createToggleBlock("標題", content: metadata.title),
                createToggleBlock("作者", content: metadata.authors.joined(separator: ", ")),
                createToggleBlock("年份", content: metadata.year ?? "未提取"),
                createToggleBlock("DOI", content: metadata.doi ?? "未提取"),
                createToggleBlock("出版資訊", content: metadata.journal ?? "未提取"),
                
                createHeadingBlock("📊 準確度評分"),
                createParagraphBlock("（請在此處填寫評分表格）"),
                
                createHeadingBlock("🔍 問題與觀察"),
                createBulletBlock("提取失敗原因："),
                createBulletBlock("特殊情況："),
                createBulletBlock("改進建議："),
                
                createHeadingBlock("📜 系統日誌"),
                createCodeBlock(logs)
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "NotionService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Notion API Error: \(errorText)"])
        }
    }
    
    // MARK: - Helpers
    
    private func convertMarkdownToBlocks(_ markdown: String) -> [[String: Any]] {
        var blocks: [[String: Any]] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if trimmed.hasPrefix("### ") {
                blocks.append(createHeading3Block(String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(createHeading2Block(String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                blocks.append(createHeadingBlock(String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("- ") {
                blocks.append(createBulletBlock(String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("1. ") {
                // Notion API uses numbered_list_item, but we need to handle numbering. 
                // For simplicity, just use numbered_list_item
                blocks.append(createNumberedListBlock(String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                // Bold paragraph
                let content = String(trimmed.dropFirst(2).dropLast(2))
                blocks.append(createBoldParagraphBlock(content))
            } else if trimmed.hasPrefix("|") {
                // Table row, treat as code for now
                blocks.append(createCodeBlock(trimmed))
            } else {
                blocks.append(createParagraphBlock(trimmed))
            }
        }
        return blocks
    }
    
    private func determinePDFType(from metadata: PDFMetadata) -> String {
        switch metadata.entryType {
        case "article": return "期刊論文 (Journal Article)"
        case "phdthesis", "mastersthesis": return "學位論文 (Thesis)"
        case "techreport": return "研究報告 (Technical Report)"
        case "incollection", "book": return "書籍章節 (Book Chapter)"
        case "inproceedings": return "會議論文 (Conference Paper)"
        default: return "期刊論文 (Journal Article)" // 預設
        }
    }
    
    private func determineLanguage(from metadata: PDFMetadata) -> String {
        // 簡單判斷：如果標題包含中文字符
        if metadata.title.range(of: "\\p{Han}", options: .regularExpression) != nil {
            return "繁體中文"
        }
        return "英文"
    }
    
    private func createHeadingBlock(_ text: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "heading_2",
            "heading_2": [
                "rich_text": [
                    ["type": "text", "text": ["content": text]]
                ]
            ]
        ]
    }
    
    private func createHeading2Block(_ text: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "heading_2",
            "heading_2": [
                "rich_text": [
                    ["type": "text", "text": ["content": text]]
                ]
            ]
        ]
    }
    
    private func createHeading3Block(_ text: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "heading_3",
            "heading_3": [
                "rich_text": [
                    ["type": "text", "text": ["content": text]]
                ]
            ]
        ]
    }
    
    private func createParagraphBlock(_ text: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "paragraph",
            "paragraph": [
                "rich_text": [
                    ["type": "text", "text": ["content": text]]
                ]
            ]
        ]
    }
    
    private func createBoldParagraphBlock(_ text: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "paragraph",
            "paragraph": [
                "rich_text": [
                    ["type": "text", "text": ["content": text], "annotations": ["bold": true]]
                ]
            ]
        ]
    }
    
    private func createBulletBlock(_ text: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": [
                "rich_text": [
                    ["type": "text", "text": ["content": text]]
                ]
            ]
        ]
    }
    
    private func createNumberedListBlock(_ text: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "numbered_list_item",
            "numbered_list_item": [
                "rich_text": [
                    ["type": "text", "text": ["content": text]]
                ]
            ]
        ]
    }
    
    private func createToggleBlock(_ title: String, content: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "toggle",
            "toggle": [
                "rich_text": [
                    ["type": "text", "text": ["content": title]]
                ],
                "children": [
                    [
                        "object": "block",
                        "type": "paragraph",
                        "paragraph": [
                            "rich_text": [
                                ["type": "text", "text": ["content": "系統提取：\(content)"]]
                            ]
                        ]
                    ],
                    [
                        "object": "block",
                        "type": "paragraph",
                        "paragraph": [
                            "rich_text": [
                                ["type": "text", "text": ["content": "正確答案："]]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    }
    
    private func createCodeBlock(_ text: String) -> [String: Any] {
        return [
            "object": "block",
            "type": "code",
            "code": [
                "language": "plain text",
                "rich_text": [
                    ["type": "text", "text": ["content": text]]
                ]
            ]
        ]
    }
}
