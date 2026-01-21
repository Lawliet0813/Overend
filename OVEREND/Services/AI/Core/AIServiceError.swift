//
//  AIServiceError.swift
//  OVEREND
//
//  統一 AI 服務錯誤類型
//

import Foundation

/// 統一 AI 服務錯誤
enum AIServiceError: LocalizedError, Equatable {
    // MARK: - 通用錯誤
    case notAvailable
    case processingFailed(String)
    case emptyInput
    case invalidResponse
    case networkError(String)
    
    // MARK: - 寫作領域
    case writingSuggestionFailed(String)
    
    // MARK: - 引用領域
    case citationFormatError(String)
    case unsupportedCitationStyle
    
    // MARK: - 翻譯領域
    case translationFailed(String)
    case sameLanguage
    case unsupportedLanguage
    
    // MARK: - 規範檢查
    case complianceCheckFailed(String)
    case emptyDocument
    
    // MARK: - 文件處理
    case metadataExtractionFailed(String)
    case summaryGenerationFailed(String)
    
    // MARK: - 公式領域
    case formulaGenerationFailed(String)
    case invalidLatex(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Apple Intelligence 不可用。請確認您的裝置支援且已啟用。"
        case .processingFailed(let message):
            return "處理失敗：\(message)"
        case .emptyInput:
            return "請輸入文字內容"
        case .invalidResponse:
            return "無法解析 AI 回應"
        case .networkError(let message):
            return "網路錯誤：\(message)"
            
        case .writingSuggestionFailed(let message):
            return "寫作建議失敗：\(message)"
            
        case .citationFormatError(let message):
            return "引用格式錯誤：\(message)"
        case .unsupportedCitationStyle:
            return "不支援的引用格式"
            
        case .translationFailed(let message):
            return "翻譯失敗：\(message)"
        case .sameLanguage:
            return "來源語言和目標語言相同"
        case .unsupportedLanguage:
            return "不支援的語言"
            
        case .complianceCheckFailed(let message):
            return "規範檢查失敗：\(message)"
        case .emptyDocument:
            return "請輸入文件內容"
            
        case .metadataExtractionFailed(let message):
            return "元數據提取失敗：\(message)"
        case .summaryGenerationFailed(let message):
            return "摘要生成失敗：\(message)"
            
        case .formulaGenerationFailed(let message):
            return "公式生成失敗：\(message)"
        case .invalidLatex(let message):
            return "無效的 LaTeX：\(message)"
        }
    }
}
