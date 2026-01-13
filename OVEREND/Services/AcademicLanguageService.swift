//
//  AcademicLanguageService.swift
//  OVEREND
//
//  學術語言轉換服務 - 使用 Apple Foundation Models
//
//  支援功能：
//  - 中英文學術表達轉換
//  - 雙語對照生成
//  - 學術風格保持
//

import Foundation
import SwiftUI
import Combine
import FoundationModels

// MARK: - 語言類型

/// 學術語言類型
enum AcademicLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-TW"    // 繁體中文
    case english = "en"       // 英文
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .chinese: return "繁體中文"
        case .english: return "English"
        }
    }
    
    var promptLanguage: String {
        switch self {
        case .chinese: return "繁體中文"
        case .english: return "English"
        }
    }
}

// MARK: - 翻譯結果

/// 雙語對照結果
struct BilingualResult {
    let original: String
    let translated: String
    let sourceLanguage: AcademicLanguage
    let targetLanguage: AcademicLanguage
    let notes: [TranslationNote]?
    
    /// 翻譯註記（解釋翻譯選擇）
    struct TranslationNote {
        let term: String
        let explanation: String
    }
}

/// 翻譯選項
struct TranslationOptions {
    var preserveStyle: Bool = true           // 保持學術風格
    var fieldContext: AcademicField?         // 學科領域
    var formalityLevel: FormalityLevel = .formal  // 正式程度
    
    enum FormalityLevel: String, CaseIterable {
        case formal = "formal"           // 正式（論文）
        case semiformal = "semiformal"   // 半正式（報告）
        case informal = "informal"       // 非正式（筆記）
        
        var displayName: String {
            switch self {
            case .formal: return "正式（論文）"
            case .semiformal: return "半正式（報告）"
            case .informal: return "非正式（筆記）"
            }
        }
    }
}

/// 學術領域
enum AcademicField: String, CaseIterable, Identifiable {
    case humanities = "humanities"           // 人文學科
    case socialSciences = "social_sciences"  // 社會科學
    case naturalSciences = "natural_sciences" // 自然科學
    case engineering = "engineering"         // 工程
    case medicine = "medicine"               // 醫學
    case law = "law"                         // 法律
    case education = "education"             // 教育
    case business = "business"               // 商業管理
    case arts = "arts"                       // 藝術
    
    var id: String { rawValue }
    
    var displayName: String {
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
    
    var englishName: String {
        switch self {
        case .humanities: return "Humanities"
        case .socialSciences: return "Social Sciences"
        case .naturalSciences: return "Natural Sciences"
        case .engineering: return "Engineering"
        case .medicine: return "Medicine"
        case .law: return "Law"
        case .education: return "Education"
        case .business: return "Business & Management"
        case .arts: return "Arts"
        }
    }
}

// MARK: - 學術語言服務

/// 學術語言轉換服務 - 使用 Apple Foundation Models
@available(macOS 26.0, *)
@MainActor
class AcademicLanguageService: ObservableObject {
    
    static let shared = AcademicLanguageService()
    
    // MARK: - 狀態
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - 學術表達翻譯
    
    /// 翻譯學術表達
    /// - Parameters:
    ///   - text: 原始文字
    ///   - from: 來源語言
    ///   - to: 目標語言
    ///   - preserveStyle: 是否保持學術風格
    /// - Returns: 翻譯後的文字
    func translateAcademicExpression(
        text: String,
        from: AcademicLanguage,
        to: AcademicLanguage,
        preserveStyle: Bool = true
    ) async throws -> String {
        guard !text.isEmpty else {
            throw AcademicLanguageError.emptyInput
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let session = LanguageModelSession()
        
        let styleInstruction = preserveStyle 
            ? "請保持學術寫作的嚴謹性、客觀性和正式性。"
            : "可以適度調整風格以提高可讀性。"
        
        let prompt: String
        
        if from == .chinese && to == .english {
            prompt = """
            你是專業的學術翻譯專家，專精於將繁體中文學術文本翻譯為英文。
            
            請將以下繁體中文學術文本翻譯為英文：
            
            ---
            \(text)
            ---
            
            翻譯要求：
            1. \(styleInstruction)
            2. 專業術語需使用學術領域的標準英文表達
            3. 保持原文的邏輯結構和論證層次
            4. 使用適當的學術連接詞和過渡語
            5. 避免口語化表達，使用正式學術英文
            
            只回覆翻譯結果，不要其他說明。
            """
        } else if from == .english && to == .chinese {
            prompt = """
            你是專業的學術翻譯專家，專精於將英文學術文本翻譯為繁體中文。
            
            請將以下英文學術文本翻譯為繁體中文：
            
            ---
            \(text)
            ---
            
            翻譯要求：
            1. \(styleInstruction)
            2. 專業術語需使用台灣學術界常用的繁體中文表達
            3. 遵循教育部學術用語規範
            4. 保持原文的邏輯結構和論證層次
            5. 使用適當的學術連接詞（如：然而、因此、綜上所述）
            6. 避免簡體中文用語，使用台灣繁體中文
            
            只回覆翻譯結果，不要其他說明。
            """
        } else {
            throw AcademicLanguageError.sameLanguage
        }
        
        do {
            let response = try await session.respond(to: prompt)
            var result = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 如果目標語言是中文，套用術語防火牆校正
            if to == .chinese {
                result = TerminologyFirewall.shared.quickCorrect(result, field: nil)
            }
            
            return result
        } catch {
            throw AcademicLanguageError.translationFailed(error.localizedDescription)
        }
    }
    
    /// 翻譯學術表達（帶選項）
    /// - Parameters:
    ///   - text: 原始文字
    ///   - from: 來源語言
    ///   - to: 目標語言
    ///   - options: 翻譯選項
    /// - Returns: 翻譯後的文字
    func translateAcademicExpression(
        text: String,
        from: AcademicLanguage,
        to: AcademicLanguage,
        options: TranslationOptions
    ) async throws -> String {
        guard !text.isEmpty else {
            throw AcademicLanguageError.emptyInput
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let session = LanguageModelSession()
        
        // 建構領域特定提示
        var fieldContext = ""
        if let field = options.fieldContext {
            fieldContext = "這是\(field.displayName)（\(field.englishName)）領域的文本。請使用該領域的專業術語。"
        }
        
        // 正式程度提示
        let formalityPrompt: String
        switch options.formalityLevel {
        case .formal:
            formalityPrompt = "使用最正式的學術寫作風格，適用於期刊論文投稿。"
        case .semiformal:
            formalityPrompt = "使用半正式的學術風格，適用於研究報告或課堂報告。"
        case .informal:
            formalityPrompt = "使用清晰易懂的表達，可適度簡化專業術語。"
        }
        
        let prompt: String
        
        if from == .chinese && to == .english {
            prompt = """
            你是專業的學術翻譯專家。
            
            \(fieldContext)
            
            請將以下繁體中文學術文本翻譯為英文：
            
            ---
            \(text)
            ---
            
            翻譯要求：
            1. \(formalityPrompt)
            2. 專業術語需使用學術領域的標準英文表達
            3. 保持原文的邏輯結構
            \(options.preserveStyle ? "4. 保持學術寫作的客觀性和嚴謹性" : "")
            
            只回覆翻譯結果，不要其他說明。
            """
        } else if from == .english && to == .chinese {
            prompt = """
            你是專業的學術翻譯專家。
            
            \(fieldContext)
            
            請將以下英文學術文本翻譯為繁體中文：
            
            ---
            \(text)
            ---
            
            翻譯要求：
            1. \(formalityPrompt)
            2. 使用台灣學術界常用的繁體中文術語
            3. 遵循教育部學術用語規範
            4. 保持原文的邏輯結構
            \(options.preserveStyle ? "5. 保持學術寫作的客觀性和嚴謹性" : "")
            
            只回覆翻譯結果，不要其他說明。
            """
        } else {
            throw AcademicLanguageError.sameLanguage
        }
        
        do {
            let response = try await session.respond(to: prompt)
            var result = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 如果目標語言是中文，套用術語防火牆校正（帶學科領域上下文）
            if to == .chinese {
                result = TerminologyFirewall.shared.quickCorrect(result, field: options.fieldContext)
            }
            
            return result
        } catch {
            throw AcademicLanguageError.translationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 雙語對照生成
    
    /// 生成雙語對照
    /// - Parameters:
    ///   - text: 原始文字
    ///   - sourceLanguage: 來源語言
    /// - Returns: 雙語對照結果
    func generateBilingualComparison(
        text: String,
        sourceLanguage: AcademicLanguage
    ) async throws -> BilingualResult {
        guard !text.isEmpty else {
            throw AcademicLanguageError.emptyInput
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let targetLanguage: AcademicLanguage = sourceLanguage == .chinese ? .english : .chinese
        
        let session = LanguageModelSession()
        
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
            
            術語說明只需列出 3-5 個最重要或可能有爭議的翻譯選擇。請使用台灣學術界常用的譯法。
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
        } catch let error as AcademicLanguageError {
            throw error
        } catch {
            throw AcademicLanguageError.translationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 術語對照建議
    
    /// 獲取術語翻譯建議
    /// - Parameters:
    ///   - term: 術語
    ///   - context: 上下文
    ///   - field: 學術領域
    /// - Returns: 翻譯建議列表
    func suggestTermTranslations(
        term: String,
        context: String? = nil,
        field: AcademicField? = nil
    ) async throws -> [TermSuggestion] {
        isProcessing = true
        defer { isProcessing = false }
        
        let session = LanguageModelSession()
        
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
            return try parseTermSuggestions(response.content)
        } catch {
            throw AcademicLanguageError.translationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 私有方法
    
    /// 解析雙語對照回應
    private func parseBilingualResponse(
        _ response: String,
        original: String,
        sourceLanguage: AcademicLanguage,
        targetLanguage: AcademicLanguage
    ) throws -> BilingualResult {
        // 清理回應
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 提取 JSON
        if let jsonStart = cleanedResponse.firstIndex(of: "{"),
           let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translation = json["translation"] as? String else {
            // 如果 JSON 解析失敗，返回純翻譯結果
            return BilingualResult(
                original: original,
                translated: response.trimmingCharacters(in: .whitespacesAndNewlines),
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                notes: nil
            )
        }
        
        // 解析註記
        var notes: [BilingualResult.TranslationNote]? = nil
        if let notesArray = json["notes"] as? [[String: String]] {
            notes = notesArray.compactMap { noteDict in
                guard let term = noteDict["term"],
                      let explanation = noteDict["explanation"] else {
                    return nil
                }
                return BilingualResult.TranslationNote(term: term, explanation: explanation)
            }
        }
        
        return BilingualResult(
            original: original,
            translated: translation,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            notes: notes
        )
    }
    
    /// 解析術語建議
    private func parseTermSuggestions(_ response: String) throws -> [TermSuggestion] {
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 提取 JSON 陣列
        if let jsonStart = cleanedResponse.firstIndex(of: "["),
           let jsonEnd = cleanedResponse.lastIndex(of: "]") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            throw AcademicLanguageError.parseError
        }
        
        return jsonArray.compactMap { dict in
            guard let translation = dict["translation"] else { return nil }
            return TermSuggestion(
                translation: translation,
                usage: dict["usage"],
                source: dict["source"]
            )
        }
    }
}

// MARK: - 術語建議

/// 術語翻譯建議
struct TermSuggestion: Identifiable {
    let id = UUID()
    let translation: String
    let usage: String?
    let source: String?
}

// MARK: - 錯誤類型

/// 學術語言服務錯誤
enum AcademicLanguageError: LocalizedError {
    case emptyInput
    case sameLanguage
    case translationFailed(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "請輸入要翻譯的文字"
        case .sameLanguage:
            return "來源語言和目標語言相同"
        case .translationFailed(let message):
            return "翻譯失敗：\(message)"
        case .parseError:
            return "無法解析翻譯結果"
        }
    }
}
