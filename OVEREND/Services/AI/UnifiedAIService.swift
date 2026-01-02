//
//  UnifiedAIService.swift
//  OVEREND
//
//  統一 Apple Intelligence 服務入口
//
//  提供所有 AI 功能的統一存取點，按領域組織：
//  - writing: 寫作建議、風格檢查
//  - citation: 引用格式處理
//  - translation: 學術翻譯
//  - standards: 規範檢查
//  - document: 文件處理（摘要、分類等）
//  - formula: LaTeX 公式生成
//

import Foundation
import SwiftUI
import Combine
import FoundationModels

/// 統一 Apple Intelligence 服務
/// 
/// 使用方式：
/// ```swift
/// let ai = UnifiedAIService.shared
/// 
/// // 寫作建議
/// let suggestions = try await ai.writing.getSuggestions(for: text)
/// 
/// // 學術翻譯
/// let translated = try await ai.translation.translateAcademic(text: text, from: .chinese, to: .english)
/// 
/// // 規範檢查
/// let issues = try await ai.standards.quickCheck(text: text)
/// ```
@available(macOS 26.0, *)
@MainActor
public class UnifiedAIService: ObservableObject {
    
    // MARK: - 單例
    
    public static let shared = UnifiedAIService()
    
    // MARK: - 狀態
    
    /// Apple Intelligence 是否可用
    @Published public var isAvailable: Bool = false
    
    /// 是否正在處理
    @Published public var isProcessing: Bool = false
    
    /// 錯誤訊息
    @Published public var errorMessage: String?
    
    // MARK: - 功能領域
    
    /// 寫作 AI 領域
    public lazy var writing: WritingAIDomain = WritingAIDomain(service: self)
    
    /// 引用 AI 領域
    public lazy var citation: CitationAIDomain = CitationAIDomain(service: self)
    
    /// 翻譯 AI 領域
    public lazy var translation: TranslationAIDomain = TranslationAIDomain(service: self)
    
    /// 規範檢查 AI 領域
    public lazy var standards: StandardsAIDomain = StandardsAIDomain(service: self)
    
    /// 文件處理 AI 領域
    public lazy var document: DocumentAIDomain = DocumentAIDomain(service: self)
    
    /// 公式 AI 領域
    public lazy var formula: FormulaAIDomain = FormulaAIDomain(service: self)
    
    // MARK: - 初始化
    
    private init() {
        checkAvailability()
    }
    
    // MARK: - 可用性檢查
    
    /// 檢查 Apple Intelligence 是否可用
    public func checkAvailability() {
        Task {
            do {
                _ = LanguageModelSession()
                isAvailable = true
                print("✅ UnifiedAIService: Apple Intelligence 可用")
            } catch {
                isAvailable = false
                errorMessage = "Apple Intelligence 不可用：\(error.localizedDescription)"
                print("❌ UnifiedAIService: Apple Intelligence 不可用 - \(error)")
            }
        }
    }
    
    /// 確保服務可用
    func ensureAvailable() throws {
        guard isAvailable else {
            throw AIServiceError.notAvailable
        }
    }
    
    /// 建立新的 LanguageModelSession
    func createSession() -> LanguageModelSession {
        return LanguageModelSession()
    }
    
    // MARK: - 處理狀態管理
    
    /// 開始處理
    func startProcessing() {
        isProcessing = true
        errorMessage = nil
    }
    
    /// 結束處理
    func endProcessing() {
        isProcessing = false
    }
    
    /// 設定錯誤
    func setError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

// MARK: - 便捷存取

@available(macOS 26.0, *)
public extension UnifiedAIService {
    
    /// 快速存取 - 檢查是否可用
    static var available: Bool {
        shared.isAvailable
    }
    
    /// 快速存取 - 是否正在處理
    static var processing: Bool {
        shared.isProcessing
    }
}
