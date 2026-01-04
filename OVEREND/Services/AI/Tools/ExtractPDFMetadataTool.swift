//
//  ExtractPDFMetadataTool.swift
//  OVEREND
//
//  使用 Apple Foundation Models Tool Calling 提取 PDF 書目資訊
//

import Foundation
import FoundationModels

// MARK: - 文件類型

/// 學術文件類型
@available(macOS 26.0, *)
@Generable
public enum AcademicDocumentType: String, CaseIterable, Sendable {
    case article        // 期刊文章
    case book           // 書籍
    case inproceedings  // 會議論文
    case thesis         // 學位論文
    case misc           // 其他
    
    public var displayName: String {
        switch self {
        case .article: return "期刊文章"
        case .book: return "書籍"
        case .inproceedings: return "會議論文"
        case .thesis: return "學位論文"
        case .misc: return "其他"
        }
    }
}

// MARK: - PDF 元數據提取工具

/// PDF 元數據提取工具 - 實作 Tool protocol
/// 
/// 模型會在分析 PDF 內容後調用此工具，直接填充各個書目欄位
@available(macOS 26.0, *)
@MainActor
public final class ExtractPDFMetadataTool: Tool {
    
    public let name = "extractPDFMetadata"
    public let description = """
        使用此工具來回報從 PDF 文獻中提取的「真實」書目資訊。
        
        ⚠️ 嚴格禁止：
        - 禁止使用佔位符如「論文標題」「文章標題」「作者1」「作者2」「Author 1」等
        - 禁止編造不存在於文獻中的資訊
        - 如果無法確定某個欄位，請填入 null 或空字串，絕對不要猜測
        
        ✅ 正確做法：
        - 標題必須是從 PDF 中識別到的實際完整標題
        - 作者必須是從 PDF 中識別到的真實作者姓名
        - 年份必須是從 PDF 中找到的實際出版年份
        """
    
    /// 工具參數 - 直接包含所有書目欄位，讓模型填充
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "文獻的完整原始標題。必須是從 PDF 內容中識別到的實際標題，禁止使用佔位符如「論文標題」「文章標題」「未知標題」等。如果無法識別標題，請填入空字串。")
        public let title: String
        
        @Guide(description: "作者姓名列表，每位作者為獨立字串。必須是 PDF 中出現的真實人名，禁止使用佔位符如「作者1」「作者2」「Author 1」「張三」等假名。如果無法識別作者，請回傳空陣列 []。")
        public let authors: [String]
        
        @Guide(description: "出版年份，四位數字。必須是從 PDF 內容中找到的實際年份，禁止猜測。如果無法確定，請填入 null。")
        public let year: String?
        
        @Guide(description: "期刊名稱、會議名稱或出版社。必須是 PDF 中出現的實際名稱，禁止猜測。如果無法確定，請填入 null。")
        public let journal: String?
        
        @Guide(description: "DOI 識別碼，標準格式如 10.1000/xyz，不含 URL 前綴。必須是 PDF 中出現的實際 DOI。如果無法找到，請填入 null。")
        public let doi: String?
        
        @Guide(description: "文獻類型：article（期刊文章）、book（書籍）、inproceedings（會議論文）、thesis（學位論文）、misc（其他）")
        public let documentType: AcademicDocumentType
    }
    
    /// 提取結果（供外部讀取）
    public private(set) var extractedResult: ExtractedDocumentMetadata?
    
    public init() {}
    
    // MARK: - 佔位符檢測
    
    /// 已知的佔位符模式（用於拒絕假資料）
    private static let titlePlaceholders: Set<String> = [
        "論文標題", "文章標題", "書籍標題", "標題", "未知標題", "無標題",
        "Title", "Article Title", "Paper Title", "Book Title", "Unknown Title",
        "測試標題", "範例標題", "Example Title", "Sample Title"
    ]
    
    private static let authorPlaceholders: Set<String> = [
        "作者1", "作者2", "作者3", "作者", "未知作者",
        "Author 1", "Author 2", "Author 3", "Author", "Unknown Author",
        "張三", "李四", "王五", "某某人", "佚名",
        "John Doe", "Jane Doe", "First Author", "Second Author"
    ]
    
    /// 檢查標題是否為佔位符
    private func isPlaceholderTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 檢查是否在已知佔位符列表中
        if Self.titlePlaceholders.contains(trimmed) {
            return true
        }
        
        // 檢查是否過短（真實標題通常 > 5 個字符）
        if trimmed.count < 5 {
            return true
        }
        
        // 檢查是否包含典型佔位符關鍵詞
        let lowerTitle = trimmed.lowercased()
        let placeholderKeywords = ["論文標題", "文章標題", "書籍標題", "paper title", "article title", "unknown"]
        for keyword in placeholderKeywords {
            if lowerTitle.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// 檢查作者是否為佔位符
    private func isPlaceholderAuthor(_ author: String) -> Bool {
        let trimmed = author.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 檢查是否在已知佔位符列表中
        if Self.authorPlaceholders.contains(trimmed) {
            return true
        }
        
        // 檢查是否為「作者+數字」模式
        let authorNumberPattern = #"^(作者|Author|author)\s*\d*$"#
        if trimmed.range(of: authorNumberPattern, options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    /// 過濾掉佔位符作者
    private func filterPlaceholderAuthors(_ authors: [String]) -> [String] {
        return authors.filter { !isPlaceholderAuthor($0) }
    }
    
    /// 工具被調用時執行 - 將參數轉換為 ExtractedDocumentMetadata
    public func call(arguments: Arguments) async throws -> String {
        print("🔧 Tool Called: extractPDFMetadata")
        print("   - 標題: \(arguments.title)")
        print("   - 作者: \(arguments.authors.joined(separator: ", "))")
        print("   - 年份: \(arguments.year ?? "未知")")
        print("   - 類型: \(arguments.documentType.displayName)")
        
        // ⚠️ 佔位符檢測
        let titleIsPlaceholder = isPlaceholderTitle(arguments.title)
        let filteredAuthors = filterPlaceholderAuthors(arguments.authors)
        
        if titleIsPlaceholder {
            print("⚠️ 偵測到佔位符標題: \(arguments.title)，已拒絕")
        }
        
        if filteredAuthors.count < arguments.authors.count {
            let removed = arguments.authors.count - filteredAuthors.count
            print("⚠️ 過濾掉 \(removed) 個佔位符作者")
        }
        
        var metadata = ExtractedDocumentMetadata()
        
        // 只有非佔位符的標題才保留
        if !titleIsPlaceholder {
            metadata.title = arguments.title
        }
        
        // 使用過濾後的作者列表
        metadata.authors = filteredAuthors
        metadata.year = arguments.year
        metadata.journal = arguments.journal
        metadata.doi = arguments.doi
        metadata.entryType = arguments.documentType.rawValue
        
        extractedResult = metadata
        
        if titleIsPlaceholder && filteredAuthors.isEmpty {
            return "⚠️ 提取結果包含佔位符，已被過濾。請確保從實際 PDF 內容中提取資訊。"
        }
        
        return "已成功提取書目資訊：\(metadata.title ?? "(標題被過濾)")"
    }
}

// MARK: - Session 工廠

@available(macOS 26.0, *)
extension ExtractPDFMetadataTool {
    
    /// 建立用於元數據提取的 Session
    public static func createSession(with tool: ExtractPDFMetadataTool) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是學術文獻書目識別專家。你的任務是從 PDF 文字內容中識別並提取真實的書目資訊。"
                
                """
                ⚠️ 絕對禁止的行為（違反將導致失敗）：
                - 禁止使用任何佔位符，例如：
                  • 「論文標題」「文章標題」「書籍標題」「Paper Title」「Article Title」
                  • 「作者1」「作者2」「Author 1」「Author 2」「張三」「李四」
                  • 任何明顯不是真實資訊的內容
                - 禁止編造或猜測任何資訊
                - 禁止使用範例資料或測試資料
                
                ✅ 正確的提取方式：
                - 仔細閱讀 PDF 內容，找出實際的標題、作者、年份等資訊
                - 如果某個欄位無法從 PDF 內容中確定，請填入 null 或空值
                - 標題通常出現在文獻開頭，字體較大或加粗
                - 作者名稱通常出現在標題下方
                - 年份可能出現在日期、版權聲明或引用資訊中
                - DOI 通常以 10. 開頭
                
                提取規則：
                - title: 從 PDF 中找到的實際標題（如果找不到就填空字串）
                - authors: 從 PDF 中找到的真實作者名單（如果找不到就填空陣列 []）
                - year: 四位數出版年份（如果找不到就填 null）
                - journal: 期刊、會議或出版社名稱（如果找不到就填 null）
                - doi: DOI 識別碼（如果找不到就填 null）
                - documentType: 根據內容判斷文獻類型
                """
                
                "分析完成後，立即調用 extractPDFMetadata 工具回報結果，不要輸出其他文字。"
            }
        )
    }
}
