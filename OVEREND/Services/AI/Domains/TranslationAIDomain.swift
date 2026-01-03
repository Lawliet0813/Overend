//
//  TranslationAIDomain.swift
//  OVEREND
//
//  翻譯 AI 領域 - 整合所有翻譯相關的 AI 功能
//
//  整合來源：
//  - AcademicLanguageService
//

import Foundation
import FoundationModels

// MARK: - 語言類型

/// 翻譯語言
public enum TranslationLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-TW"    // 繁體中文
    case english = "en"       // 英文
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .chinese: return "繁體中文"
        case .english: return "English"
        }
    }
}

/// 翻譯選項
public struct AcademicTranslationOptions {
    public var preserveStyle: Bool = true
    public var field: AcademicFieldType?
    public var formality: FormalityLevel = .formal
    
    public init() {}
    
    public enum FormalityLevel: String {
        case formal = "formal"
        case semiformal = "semiformal"
        case informal = "informal"
        
        var promptInstruction: String {
            switch self {
            case .formal:
                return "使用最正式的學術寫作風格"
            case .semiformal:
                return "使用半正式的學術風格"
            case .informal:
                return "使用清晰易懂的表達"
            }
        }
    }
}

/// 學術領域類型
public enum AcademicFieldType: String, CaseIterable, Identifiable {
    case humanities = "humanities"
    case socialSciences = "social_sciences"
    case naturalSciences = "natural_sciences"
    case engineering = "engineering"
    case medicine = "medicine"
    case law = "law"
    case education = "education"
    case business = "business"
    case arts = "arts"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .humanities: return "人文學科"
        case .socialSciences: return "社會科學"
        case .naturalSciences: return "自然科學"
        case .engineering: return "工程"
        case .medicine: return "醫學"
        case .law: return "法律"
        case .education: return "教育"
        case .business: return "商業管理"
        case .arts: return "藝術"
        }
    }
}

// MARK: - 翻譯結果

/// 雙語對照結果
public struct BilingualTranslationResult {
    public let original: String
    public let translated: String
    public let sourceLanguage: TranslationLanguage
    public let targetLanguage: TranslationLanguage
    public let notes: [TermNote]?
    
    public struct TermNote {
        public let term: String
        public let explanation: String
    }
}

/// 術語建議
public struct TermTranslationSuggestion: Identifiable {
    public let id = UUID()
    public let translation: String
    public let usage: String?
    public let source: String?
}

// MARK: - 翻譯 AI 領域

/// 翻譯 AI 領域
@available(macOS 26.0, *)
@MainActor
public class TranslationAIDomain {
    
    private weak var service: UnifiedAIService?
    
    init(service: UnifiedAIService) {
        self.service = service
    }
    
    // MARK: - 學術翻譯
    
    /// 學術翻譯（使用 Tool Calling）
    /// - Parameters:
    ///   - text: 原始文字
    ///   - from: 來源語言
    ///   - to: 目標語言
    ///   - options: 翻譯選項
    /// - Returns: 翻譯後的文字
    public func translateAcademic(
        text: String,
        from: TranslationLanguage,
        to: TranslationLanguage,
        options: AcademicTranslationOptions = AcademicTranslationOptions()
    ) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        if from == to {
            throw AIServiceError.sameLanguage
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        // 策略 1: Tool Calling
        do {
            let fromLang: ToolTranslationLanguage = from == .chinese ? .chinese : .english
            let toLang: ToolTranslationLanguage = to == .chinese ? .chinese : .english
            
            let tool = TranslateAcademicTool()
            let session = TranslateAcademicTool.createSession(with: tool, from: fromLang, to: toLang)
            
            var fieldContext = ""
            if let field = options.field {
                fieldContext = "（\(field.displayName)領域）"
            }
            
            let prompt = """
            請翻譯以下學術文本\(fieldContext)：
            
            ---
            \(text)
            ---
            """
            
            let _ = try await session.respond(to: prompt)
            
            if let result = tool.result {
                print("✅ Tool Calling 翻譯成功")
                return result.translatedText
            }
        } catch {
            print("⚠️ Tool Calling 失敗: \(error.localizedDescription)，降級到 Prompt 方式")
        }
        
        // 策略 2: Prompt 方式降級
        let session = service.createSession()
        
        var fieldContext = ""
        if let field = options.field {
            fieldContext = "這是\(field.displayName)領域的文本。請使用該領域的專業術語。"
        }
        
        let prompt: String
        
        if from == .chinese && to == .english {
            prompt = """
            你是專業的學術翻譯專家，專精於將繁體中文學術文本翻譯為英文。
            
            \(fieldContext)
            
            請將以下繁體中文學術文本翻譯為英文：
            
            ---
            \(text)
            ---
            
            翻譯要求：
            1. \(options.formality.promptInstruction)
            2. 專業術語需使用學術領域的標準英文表達
            3. 保持原文的邏輯結構和論證層次
            4. 使用適當的學術連接詞和過渡語
            \(options.preserveStyle ? "5. 保持學術寫作的客觀性和嚴謹性" : "")
            
            只回覆翻譯結果，不要其他說明。
            """
        } else {
            prompt = """
            你是專業的學術翻譯專家，專精於將英文學術文本翻譯為繁體中文。
            
            \(fieldContext)
            
            請將以下英文學術文本翻譯為繁體中文：
            
            ---
            \(text)
            ---
            
            翻譯要求：
            1. \(options.formality.promptInstruction)
            2. 使用台灣學術界常用的繁體中文術語
            3. 遵循教育部學術用語規範
            4. 保持原文的邏輯結構
            \(options.preserveStyle ? "5. 保持學術寫作的客觀性和嚴謹性" : "")
            
            只回覆翻譯結果，不要其他說明。
            """
        }
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AIServiceError.translationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 雙語對照
    
    /// 生成雙語對照
    /// - Parameters:
    ///   - text: 原始文字
    ///   - sourceLanguage: 來源語言
    /// - Returns: 雙語對照結果
    public func generateBilingual(
        text: String,
        sourceLanguage: TranslationLanguage
    ) async throws -> BilingualTranslationResult {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        let targetLanguage: TranslationLanguage = sourceLanguage == .chinese ? .english : .chinese
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let prompt: String
        
        if sourceLanguage == .chinese {
            prompt = """
            你是專業的學術翻譯專家。請將以下繁體中文學術文本翻譯為英文，並提供重要術語的翻譯說明。
            
            原文：
            ---
            \(text)
            ---
            
            請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
            {
              "translation": "英文翻譯",
              "notes": [
                {"term": "原文術語", "explanation": "翻譯選擇說明"}
              ]
            }
            
            術語說明只需列出 3-5 個最重要或可能有爭議的翻譯選擇。
            """
        } else {
            prompt = """
            你是專業的學術翻譯專家。請將以下英文學術文本翻譯為繁體中文，並提供重要術語的翻譯說明。
            
            原文：
            ---
            \(text)
            ---
            
            請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
            {
              "translation": "繁體中文翻譯",
              "notes": [
                {"term": "原文術語", "explanation": "翻譯選擇說明（為何選用此繁體中文譯法）"}
              ]
            }
            
            術語說明只需列出 3-5 個最重要的翻譯選擇。請使用台灣學術界常用的譯法。
            """
        }
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseBilingualResponse(
                response.content,
                original: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.translationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 術語建議
    
    /// 獲取術語翻譯建議
    /// - Parameters:
    ///   - term: 術語
    ///   - context: 上下文
    ///   - field: 學術領域
    /// - Returns: 翻譯建議列表
    public func suggestTerms(
        term: String,
        context: String? = nil,
        field: AcademicFieldType? = nil
    ) async throws -> [TermTranslationSuggestion] {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        var fieldContext = ""
        if let field = field {
            fieldContext = "學術領域：\(field.displayName)"
        }
        
        var contextInfo = ""
        if let context = context {
            contextInfo = "上下文：\(context)"
        }
        
        let prompt = """
        你是學術術語翻譯專家。請為以下術語提供翻譯建議。
        
        術語：\(term)
        \(fieldContext)
        \(contextInfo)
        
        請以 JSON 格式回覆 3-5 個翻譯選項（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "translation": "翻譯",
            "usage": "使用場景說明",
            "source": "來源（如：教育部術語、學術慣用）"
          }
        ]
        
        如果輸入是中文，請提供英文翻譯選項；如果是英文，請提供繁體中文翻譯選項。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseTermSuggestionsResponse(response.content)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.translationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 私有方法
    
    private func parseBilingualResponse(
        _ response: String,
        original: String,
        sourceLanguage: TranslationLanguage,
        targetLanguage: TranslationLanguage
    ) throws -> BilingualTranslationResult {
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let jsonStart = cleanedResponse.firstIndex(of: "{"),
           let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translation = json["translation"] as? String else {
            return BilingualTranslationResult(
                original: original,
                translated: response.trimmingCharacters(in: .whitespacesAndNewlines),
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                notes: nil
            )
        }
        
        var notes: [BilingualTranslationResult.TermNote]? = nil
        if let notesArray = json["notes"] as? [[String: String]] {
            notes = notesArray.compactMap { noteDict in
                guard let term = noteDict["term"],
                      let explanation = noteDict["explanation"] else {
                    return nil
                }
                return BilingualTranslationResult.TermNote(term: term, explanation: explanation)
            }
        }
        
        return BilingualTranslationResult(
            original: original,
            translated: translation,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            notes: notes
        )
    }
    
    private func parseTermSuggestionsResponse(_ response: String) throws -> [TermTranslationSuggestion] {
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let jsonStart = cleanedResponse.firstIndex(of: "["),
           let jsonEnd = cleanedResponse.lastIndex(of: "]") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        
        return jsonArray.compactMap { dict in
            guard let translation = dict["translation"] else { return nil }
            return TermTranslationSuggestion(
                translation: translation,
                usage: dict["usage"],
                source: dict["source"]
            )
        }
    }
}
