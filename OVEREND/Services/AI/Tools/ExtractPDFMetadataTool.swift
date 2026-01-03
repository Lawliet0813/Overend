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
        使用此工具來回報從 PDF 文獻中提取的書目資訊。
        分析完 PDF 內容後，調用此工具並填入識別到的標題、作者、年份等資訊。
        """
    
    /// 工具參數 - 直接包含所有書目欄位，讓模型填充
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "文獻的完整標題，應為原始標題，不要翻譯或縮寫")
        public let title: String
        
        @Guide(description: "作者姓名列表，每位作者為獨立字串")
        public let authors: [String]
        
        @Guide(description: "出版年份，四位數字，如 2024")
        public let year: String?
        
        @Guide(description: "期刊名稱、會議名稱或出版社")
        public let journal: String?
        
        @Guide(description: "DOI 識別碼，標準格式如 10.1000/xyz，不含 URL 前綴")
        public let doi: String?
        
        @Guide(description: "文獻類型：article（期刊文章）、book（書籍）、inproceedings（會議論文）、thesis（學位論文）、misc（其他）")
        public let documentType: AcademicDocumentType
    }
    
    /// 提取結果（供外部讀取）
    public private(set) var extractedResult: ExtractedDocumentMetadata?
    
    public init() {}
    
    /// 工具被調用時執行 - 將參數轉換為 ExtractedDocumentMetadata
    public func call(arguments: Arguments) async throws -> String {
        var metadata = ExtractedDocumentMetadata()
        metadata.title = arguments.title
        metadata.authors = arguments.authors
        metadata.year = arguments.year
        metadata.journal = arguments.journal
        metadata.doi = arguments.doi
        metadata.entryType = arguments.documentType.rawValue
        
        extractedResult = metadata
        
        print("🔧 Tool Called: extractPDFMetadata")
        print("   - 標題: \(arguments.title)")
        print("   - 作者: \(arguments.authors.joined(separator: ", "))")
        print("   - 年份: \(arguments.year ?? "未知")")
        print("   - 類型: \(arguments.documentType.displayName)")
        
        return "已成功提取書目資訊：\(arguments.title)"
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
                "你是學術文獻書目識別專家。"
                
                "分析用戶提供的 PDF 文字內容，從中提取書目資訊。"
                
                """
                提取完成後，你必須調用 extractPDFMetadata 工具來回報結果。
                
                提取規則：
                - title: 文獻的完整標題（必填）
                - authors: 作者列表，每位作者獨立一個字串
                - year: 四位數出版年份
                - journal: 期刊、會議或出版社名稱
                - doi: DOI 識別碼（不含 https://doi.org/ 前綴）
                - documentType: 文獻類型
                """
                
                "重要：分析完成後，直接調用 extractPDFMetadata 工具，不要輸出其他文字。"
            }
        )
    }
}
