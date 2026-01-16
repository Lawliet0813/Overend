//
//  AICommandExecutor.swift
//  OVEREND
//
//  AI 指令執行器 - 整合 Gemini API 處理指令
//

import Foundation
import AppKit
import Combine
import FoundationModels

/// AI 服務提供者類型
enum AIProvider {
    case apple      // Apple Intelligence (預設)
    case gemini     // Google Gemini (備選)
}

/// AI 指令執行器
class AICommandExecutor: ObservableObject {
    @Published var isExecuting = false
    @Published var lastResult: AICommandResult?
    @Published var error: Error?

    /// 當前使用的 AI 服務
    @Published var currentProvider: AIProvider = .apple

    /// Apple AI 是否可用
    @Published var isAppleAIAvailable = false

    private let geminiAPIKey: String
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

    init(apiKey: String = "", preferredProvider: AIProvider = .apple) {
        // 從環境變數或設定檔讀取 API Key
        self.geminiAPIKey = apiKey.isEmpty ?
            ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "" :
            apiKey

        self.currentProvider = preferredProvider

        // 檢查 Apple AI 可用性
        checkAppleAIAvailability()
    }

    /// 檢查 Apple Intelligence 是否可用
    private func checkAppleAIAvailability() {
        if #available(macOS 26.0, *) {
            Task { @MainActor in
                do {
                    _ = LanguageModelSession()
                    isAppleAIAvailable = true
                    print("✅ Apple Intelligence 可用，將作為預設 AI 服務")
                } catch {
                    isAppleAIAvailable = false
                    print("⚠️ Apple Intelligence 不可用，將使用 Gemini")
                    currentProvider = .gemini
                }
            }
        } else {
            isAppleAIAvailable = false
            currentProvider = .gemini
            print("⚠️ macOS 版本過舊，需要 macOS 26.0+，將使用 Gemini")
        }
    }

    // MARK: - 執行指令

    /// 執行 AI 指令
    func execute(command: AICommand, in textView: NSTextView) async throws -> AICommandResult {
        isExecuting = true
        defer { isExecuting = false }

        // 建立完整提示詞
        let fullPrompt = buildPrompt(for: command)

        // 根據當前服務選擇呼叫方式
        let response: String
        switch currentProvider {
        case .apple:
            response = try await callAppleAI(prompt: fullPrompt)
        case .gemini:
            response = try await callGeminiAPI(prompt: fullPrompt)
        }

        // 解析回應
        let result = parseResponse(response, command: command)

        // 應用結果到文字視圖
        await MainActor.run {
            applyResult(result, to: textView, command: command)
            lastResult = result
        }

        return result
    }

    // MARK: - API 呼叫

    /// 呼叫 Apple Intelligence
    private func callAppleAI(prompt: String) async throws -> String {
        guard #available(macOS 26.0, *) else {
            throw AICommandError.appleAINotAvailable("需要 macOS 26.0 或更新版本")
        }

        guard isAppleAIAvailable else {
            throw AICommandError.appleAINotAvailable("Apple Intelligence 不可用")
        }

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            throw AICommandError.appleAIError(error.localizedDescription)
        }
    }

    /// 呼叫 Gemini API
    private func callGeminiAPI(prompt: String) async throws -> String {
        guard !geminiAPIKey.isEmpty else {
            throw AICommandError.apiKeyNotSet
        }

        let url = URL(string: "\(apiEndpoint)?key=\(geminiAPIKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 2048
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AICommandError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AICommandError.httpError(statusCode: httpResponse.statusCode)
        }

        // 解析回應
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AICommandError.invalidResponse
        }

        return text
    }

    // MARK: - 提示詞建構

    private func buildPrompt(for command: AICommand) -> String {
        var prompt = """
        你是一個專業的學術寫作助手，專門幫助使用者改善論文品質。

        指令：\(command.prompt)

        """

        // 添加上下文
        if let selectedText = command.context.selectedText?.string, !selectedText.isEmpty {
            prompt += """

            選取的文字：
            \(selectedText)

            """
        }

        // 添加格式資訊
        if let font = command.context.currentFont {
            prompt += """

            當前字體：\(font.fontName) \(font.pointSize)pt
            """
        }

        if let paragraphStyle = command.context.currentParagraphStyle {
            prompt += """

            段落格式：
            - 首行縮排：\(paragraphStyle.firstLineHeadIndent)pt
            - 行距倍數：\(paragraphStyle.lineHeightMultiple)
            - 段落間距：\(paragraphStyle.paragraphSpacing)pt
            """
        }

        // 根據指令類型添加特定指引
        switch command.category {
        case .formatting:
            prompt += """

            請以 JSON 格式返回格式修改指令，格式如下：
            {
                "action": "format",
                "changes": {
                    "firstLineIndent": 28.35,
                    "lineSpacing": 2.0,
                    "paragraphSpacing": 0
                }
            }
            """
        case .citation:
            prompt += """

            請返回正確格式的文獻引用。
            """
        default:
            prompt += """

            請提供改進後的文字內容。
            """
        }

        return prompt
    }

    // MARK: - 回應解析

    private func parseResponse(_ response: String, command: AICommand) -> AICommandResult {
        // 嘗試解析 JSON 格式的指令
        if let jsonData = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            return parseJSONCommand(json, originalCommand: command)
        }

        // 純文字回應
        return AICommandResult(
            type: .textReplacement,
            content: response,
            originalCommand: command
        )
    }

    private func parseJSONCommand(_ json: [String: Any], originalCommand: AICommand) -> AICommandResult {
        guard let action = json["action"] as? String else {
            return AICommandResult(
                type: .textReplacement,
                content: json.description,
                originalCommand: originalCommand
            )
        }

        switch action {
        case "format":
            if let changes = json["changes"] as? [String: Any] {
                return AICommandResult(
                    type: .formatChange,
                    content: changes.description,
                    formatChanges: changes,
                    originalCommand: originalCommand
                )
            }
        default:
            break
        }

        return AICommandResult(
            type: .textReplacement,
            content: json.description,
            originalCommand: originalCommand
        )
    }

    // MARK: - 應用結果

    private func applyResult(_ result: AICommandResult, to textView: NSTextView, command: AICommand) {
        guard let textStorage = textView.textStorage else { return }

        let selectedRange = command.context.selectedRange

        textStorage.beginEditing()

        switch result.type {
        case .textReplacement:
            // 替換文字
            let newText = NSAttributedString(
                string: result.content,
                attributes: textView.typingAttributes
            )
            textStorage.replaceCharacters(in: selectedRange, with: newText)

        case .formatChange:
            // 修改格式
            if let changes = result.formatChanges {
                applyFormatChanges(changes, to: textStorage, range: selectedRange)
            }

        case .suggestion:
            // 顯示建議（不直接修改）
            print("AI 建議：\(result.content)")
        }

        textStorage.endEditing()
    }

    private func applyFormatChanges(_ changes: [String: Any], to textStorage: NSTextStorage, range: NSRange) {
        // 獲取段落範圍
        let paragraphRange = (textStorage.string as NSString).paragraphRange(for: range)

        // 獲取或創建段落樣式
        let existingStyle = textStorage.attribute(
            .paragraphStyle,
            at: paragraphRange.location,
            effectiveRange: nil
        ) as? NSParagraphStyle

        let paragraphStyle = (existingStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()

        // 應用修改
        if let firstLineIndent = changes["firstLineIndent"] as? CGFloat {
            paragraphStyle.firstLineHeadIndent = firstLineIndent
        }

        if let lineSpacing = changes["lineSpacing"] as? CGFloat {
            paragraphStyle.lineHeightMultiple = lineSpacing
        }

        if let paragraphSpacing = changes["paragraphSpacing"] as? CGFloat {
            paragraphStyle.paragraphSpacing = paragraphSpacing
        }

        if let alignment = changes["alignment"] as? Int,
           let textAlignment = NSTextAlignment(rawValue: alignment) {
            paragraphStyle.alignment = textAlignment
        }

        // 套用樣式
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
    }
}

// MARK: - 結果模型

struct AICommandResult {
    enum ResultType {
        case textReplacement  // 文字替換
        case formatChange     // 格式修改
        case suggestion       // 建議（不直接修改）
    }

    let id = UUID()
    let type: ResultType
    let content: String
    let formatChanges: [String: Any]?
    let originalCommand: AICommand
    let timestamp = Date()

    init(
        type: ResultType,
        content: String,
        formatChanges: [String: Any]? = nil,
        originalCommand: AICommand
    ) {
        self.type = type
        self.content = content
        self.formatChanges = formatChanges
        self.originalCommand = originalCommand
    }
}

// MARK: - 錯誤類型

enum AICommandError: LocalizedError {
    case appleAINotAvailable(String)
    case appleAIError(String)
    case apiKeyNotSet
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .appleAINotAvailable(let message):
            return "Apple Intelligence 不可用：\(message)"
        case .appleAIError(let message):
            return "Apple Intelligence 錯誤：\(message)"
        case .apiKeyNotSet:
            return "未設定 Gemini API Key。請在環境變數中設定 GEMINI_API_KEY。"
        case .invalidResponse:
            return "無法解析 API 回應"
        case .httpError(let statusCode):
            return "HTTP 錯誤：\(statusCode)"
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        }
    }
}
