//
//  GeminiService.swift
//  OVEREND
//
//  Gemini API 服務 - 作為 Apple Intelligence 的後備方案
//  處理超過本地 AI 上下文視窗的長文本
//

import Foundation
import Combine

/// Gemini API 服務
@MainActor
public class GeminiService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = GeminiService()
    
    // MARK: - 屬性
    @Published var isConfigured: Bool = false
    @Published var isProcessing: Bool = false
    
    private var apiKey: String = ""
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let defaultModel = "gemini-2.0-flash"
    
    // 快取
    private var responseCache: [String: CachedResponse] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 分鐘
    
    private struct CachedResponse {
        let content: String
        let timestamp: Date
    }
    
    // MARK: - 初始化
    
    private init() {
        loadAPIKey()
    }
    
    // MARK: - 配置
    
    /// 設定 API Key
    func configure(apiKey: String) {
        // 防止儲存遮蔽字串
        guard apiKey != "••••••••••••••••" else { return }
        
        self.apiKey = apiKey
        self.isConfigured = !apiKey.isEmpty
        saveAPIKey()
    }
    
    /// 從 Keychain 載入 API Key
    private func loadAPIKey() {
        if let key = KeychainHelper.load(key: "gemini_api_key") {
            // 檢查是否為無效的遮蔽字串
            if key == "••••••••••••••••" {
                self.apiKey = ""
                self.isConfigured = false
                KeychainHelper.delete(key: "gemini_api_key")
            } else {
                self.apiKey = key
                self.isConfigured = !key.isEmpty
            }
        }
    }
    
    /// 儲存 API Key 到 Keychain
    private func saveAPIKey() {
        KeychainHelper.save(key: "gemini_api_key", value: apiKey)
    }
    
    // MARK: - API 呼叫
    
    /// 生成文字回應
    func generateContent(prompt: String, systemInstruction: String? = nil) async throws -> String {
        guard isConfigured else {
            throw GeminiError.notConfigured
        }
        
        // 檢查快取
        let cacheKey = "\(prompt.prefix(100))_\(systemInstruction?.prefix(50) ?? "")"
        if let cached = responseCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.content
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let url = URL(string: "\(baseURL)/\(defaultModel):generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 構建請求體
        var requestBody: [String: Any] = [
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
        
        if let systemInstruction = systemInstruction {
            requestBody["systemInstruction"] = [
                "parts": [
                    ["text": systemInstruction]
                ]
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.httpError(httpResponse.statusCode)
        }
        
        // 解析回應
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        // 快取結果
        responseCache[cacheKey] = CachedResponse(content: text, timestamp: Date())
        
        return text
    }
    
    // MARK: - 優化的 AI 提示方法
    
    /// 翻譯文字（優化提示）
    func translate(text: String, from: String, to: String) async throws -> String {
        let prompt = """
        ## 任務
        將以下學術文本從 \(from) 翻譯成 \(to)。
        
        ## 要求
        1. 保持學術語氣和正式文風
        2. 準確翻譯專業術語，必要時在括號中保留原文
        3. 維持原文的段落結構和標點風格
        4. 確保譯文流暢自然，符合目標語言的學術寫作習慣
        
        ## 原文
        \(text)
        
        ## 輸出格式
        直接輸出翻譯後的文字，不要包含說明、標題或其他額外內容。
        """
        
        return try await generateContent(
            prompt: prompt,
            systemInstruction: """
            你是專業的學術翻譯專家，具備以下專長：
            - 精通多語言學術文獻翻譯
            - 熟悉各領域專業術語的標準譯法
            - 擅長保持原文的學術風格和論述邏輯
            - 能夠準確傳達原文的細微含義
            """
        )
    }
    
    /// 摘要文字（優化提示）
    func summarize(text: String, maxLength: Int = 200) async throws -> String {
        let prompt = """
        ## 任務
        為以下學術文本生成精準摘要。
        
        ## 要求
        1. 控制在 \(maxLength) 字以內
        2. 提取核心論點和主要發現
        3. 保持客觀學術語氣
        4. 按重要性排列資訊
        
        ## 原文
        \(text)
        
        ## 輸出格式
        直接輸出摘要內容，不要包含標題或額外說明。
        """
        
        return try await generateContent(
            prompt: prompt,
            systemInstruction: """
            你是專業的學術摘要專家，具備以下專長：
            - 快速識別文本的核心論點和關鍵發現
            - 區分主要論述與輔助細節
            - 用精煉的語言傳達複雜概念
            - 保持摘要的完整性和可讀性
            """
        )
    }
    
    /// 分析寫作（優化提示）
    func analyzeWriting(text: String) async throws -> String {
        let prompt = """
        ## 任務
        對以下學術寫作進行全面分析，提供具體改進建議。
        
        ## 分析重點
        1. **語法問題**: 識別語法錯誤、用詞不當、句子結構問題
        2. **風格問題**: 評估學術語氣、論述清晰度、段落銜接
        3. **整體反饋**: 提供改進優先順序和具體修改方向
        
        ## 待分析文本
        \(text)
        
        ## 輸出格式（嚴格 JSON）
        ```json
        {
            "grammarIssues": [
                {
                    "original": "原文片段",
                    "suggestion": "修改建議",
                    "explanation": "問題說明",
                    "severity": "high|medium|low"
                }
            ],
            "styleIssues": [
                {
                    "original": "原文片段",
                    "suggestion": "修改建議",
                    "reason": "改進理由",
                    "category": "clarity|tone|structure|flow"
                }
            ],
            "overallFeedback": "整體評價與優先改進建議",
            "score": {
                "grammar": 0-100,
                "style": 0-100,
                "clarity": 0-100
            }
        }
        ```
        
        只輸出 JSON，不要包含 markdown 標記或其他文字。
        """
        
        return try await generateContent(
            prompt: prompt,
            systemInstruction: """
            你是學術寫作審閱專家，具備以下專長：
            - 精通繁體中文學術論文的寫作規範
            - 熟悉各學科的學術寫作風格指南
            - 能夠提供具體、可操作的修改建議
            - 善於平衡嚴謹性與可讀性的要求
            """
        )
    }
    
    /// 回答文獻問題（優化提示）
    func answerQuestion(question: String, context: String) async throws -> String {
        let prompt = """
        ## 任務
        根據提供的文獻資料，回答研究問題。
        
        ## 文獻資料
        \(context)
        
        ## 研究問題
        \(question)
        
        ## 回答要求
        1. 直接引用文獻中的具體資訊作為證據
        2. 使用繁體中文回答
        3. 區分「文獻明確指出」與「合理推論」
        4. 若資訊不足以回答，明確說明並指出需要哪些額外資料
        5. 提供相關的延伸閱讀方向（如適用）
        
        ## 輸出格式
        以清晰的段落回答，必要時使用條列式呈現重點。
        """
        
        return try await generateContent(
            prompt: prompt,
            systemInstruction: """
            你是學術研究助理，具備以下專長：
            - 快速理解和分析學術文獻
            - 精確回答研究相關問題
            - 誠實指出知識邊界和資訊限制
            - 提供有價值的研究洞見和建議
            """
        )
    }
    
    // MARK: - Files API (PDF 處理)
    
    /// 上傳檔案到 Gemini Files API
    func uploadFile(fileURL: URL, displayName: String? = nil) async throws -> GeminiFile {
        guard isConfigured else {
            throw GeminiError.notConfigured
        }
        
        let fileData = try Data(contentsOf: fileURL)
        let mimeType = mimeTypeForURL(fileURL)
        let fileName = displayName ?? fileURL.lastPathComponent
        
        // Step 1: 開始可續傳上傳
        let startURL = URL(string: "https://generativelanguage.googleapis.com/upload/v1beta/files")!
        
        var startRequest = URLRequest(url: startURL)
        startRequest.httpMethod = "POST"
        startRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        startRequest.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        startRequest.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        startRequest.setValue(String(fileData.count), forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        startRequest.setValue(mimeType, forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")
        startRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let metadata: [String: Any] = ["file": ["display_name": fileName]]
        startRequest.httpBody = try JSONSerialization.data(withJSONObject: metadata)
        
        let (_, startResponse) = try await URLSession.shared.data(for: startRequest)
        
        guard let httpResponse = startResponse as? HTTPURLResponse,
              let uploadURL = httpResponse.value(forHTTPHeaderField: "X-Goog-Upload-URL") else {
            throw GeminiError.invalidResponse
        }
        
        // Step 2: 上傳實際檔案
        var uploadRequest = URLRequest(url: URL(string: uploadURL)!)
        uploadRequest.httpMethod = "POST"
        uploadRequest.setValue(String(fileData.count), forHTTPHeaderField: "Content-Length")
        uploadRequest.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        uploadRequest.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        uploadRequest.httpBody = fileData
        
        let (uploadData, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)
        
        guard let uploadHttpResponse = uploadResponse as? HTTPURLResponse,
              uploadHttpResponse.statusCode == 200 else {
            throw GeminiError.httpError((uploadResponse as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        // Step 3: 解析回應
        guard let json = try? JSONSerialization.jsonObject(with: uploadData) as? [String: Any],
              let file = json["file"] as? [String: Any],
              let uri = file["uri"] as? String,
              let name = file["name"] as? String else {
            throw GeminiError.parseError
        }
        
        return GeminiFile(
            name: name,
            uri: uri,
            mimeType: mimeType,
            displayName: fileName
        )
    }
    
    /// 使用已上傳的檔案生成內容
    func generateContentWithFile(file: GeminiFile, prompt: String, systemInstruction: String? = nil) async throws -> String {
        guard isConfigured else {
            throw GeminiError.notConfigured
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let url = URL(string: "\(baseURL)/\(defaultModel):generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "file_data": [
                                "mime_type": file.mimeType,
                                "file_uri": file.uri
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 4096
            ]
        ]
        
        if let systemInstruction = systemInstruction {
            requestBody["systemInstruction"] = [
                "parts": [
                    ["text": systemInstruction]
                ]
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        return text
    }
    
    /// 從 PDF 提取書目元數據（優化提示）
    func extractPDFMetadata(from fileURL: URL) async throws -> ExtractedBibTeX {
        // 1. 上傳 PDF
        let file = try await uploadFile(fileURL: fileURL)
        
        // 2. 使用優化的提示提取元數據
        let prompt = """
        ## 任務
        分析這份學術 PDF 文件，提取完整的書目資訊。
        
        ## 分析步驟
        1. **識別文獻類型**: 根據內容判斷是期刊論文、會議論文、學位論文、書籍還是技術報告
        2. **提取基本資訊**: 標題、作者、年份、DOI
        3. **提取出版資訊**: 期刊/會議名稱、卷號、期號、頁碼、出版社
        4. **提取學術資訊**: 摘要、關鍵詞、機構/學校
        
        ## 特別注意
        - 標題：找出主標題和副標題（如有），使用完整格式
        - 作者：使用 BibTeX 格式「姓, 名」，多作者用「 and 」連接
        - DOI：通常以 10.xxxx/ 開頭，確保完整複製
        - 年份：使用 4 位數字格式
        - 摘要：限制 500 字以內，保留核心論點
        
        ## 輸出格式（嚴格 JSON）
        {
            "entryType": "article|book|inproceedings|phdthesis|mastersthesis|techreport|misc",
            "citationKey": "第一作者姓氏 + 年份，如 Chen2024",
            "title": "完整論文標題",
            "author": "作者1姓, 作者1名 and 作者2姓, 作者2名",
            "year": "2024",
            "journal": "期刊名稱（期刊論文適用）",
            "booktitle": "會議或書籍名稱（會議論文適用）",
            "volume": "卷號",
            "pages": "起始頁-結束頁",
            "doi": "10.xxxx/xxxxx",
            "abstract": "摘要內容（500字內）",
            "school": "學校名稱（學位論文適用）",
            "publisher": "出版社名稱",
            "keywords": ["關鍵詞1", "關鍵詞2", "關鍵詞3"]
        }
        
        ## 重要規則
        - 只輸出 JSON，不要包含任何其他文字或 markdown 標記
        - 無法確定的欄位填入空字串 "" 或空陣列 []
        - 不要猜測或編造資訊
        - 確保 JSON 格式正確可解析
        """
        
        let response = try await generateContentWithFile(
            file: file,
            prompt: prompt,
            systemInstruction: """
            你是專業的學術文獻分析專家，具備以下專長：
            - 精通各學科學術文獻的閱讀與分析
            - 熟悉 BibTeX 格式規範和各種文獻類型
            - 能夠準確識別論文的關鍵書目資訊
            - 嚴格遵守輸出格式要求，確保資料可機器解析
            """
        )
        
        // 3. 解析回應
        return try parseExtractedBibTeX(from: response)
    }
    
    /// 解析提取的 BibTeX JSON
    private func parseExtractedBibTeX(from jsonString: String) throws -> ExtractedBibTeX {
        // 移除可能的 markdown 標記
        let cleanJson = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.parseError
        }
        
        return ExtractedBibTeX(
            entryType: json["entryType"] as? String ?? "article",
            citationKey: json["citationKey"] as? String ?? "Unknown\(Date().timeIntervalSince1970.hashValue)",
            title: json["title"] as? String ?? "",
            author: json["author"] as? String ?? "",
            year: json["year"] as? String ?? "",
            journal: json["journal"] as? String ?? "",
            booktitle: json["booktitle"] as? String ?? "",
            volume: json["volume"] as? String ?? "",
            pages: json["pages"] as? String ?? "",
            doi: json["doi"] as? String ?? "",
            abstract: json["abstract"] as? String ?? "",
            school: json["school"] as? String ?? "",
            publisher: json["publisher"] as? String ?? "",
            keywords: json["keywords"] as? [String] ?? []
        )
    }
    
    /// 取得檔案的 MIME 類型
    private func mimeTypeForURL(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "txt": return "text/plain"
        case "html", "htm": return "text/html"
        case "md": return "text/markdown"
        default: return "application/octet-stream"
        }
    }
    
    // MARK: - 清理
    
    func clearCache() {
        responseCache.removeAll()
    }
}

// MARK: - 錯誤類型

enum GeminiError: LocalizedError {
    case notConfigured
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Gemini API 尚未配置"
        case .invalidResponse:
            return "無效的 API 回應"
        case .httpError(let code):
            return "HTTP 錯誤: \(code)"
        case .apiError(let message):
            return "API 錯誤: \(message)"
        case .parseError:
            return "回應解析失敗"
        }
    }
}

// MARK: - Keychain Helper

private struct KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - 資料模型

/// Gemini 上傳檔案資訊
struct GeminiFile {
    let name: String
    let uri: String
    let mimeType: String
    let displayName: String
}

/// 從 PDF 提取的 BibTeX 資料
struct ExtractedBibTeX {
    let entryType: String
    let citationKey: String
    let title: String
    let author: String
    let year: String
    let journal: String
    let booktitle: String
    let volume: String
    let pages: String
    let doi: String
    let abstract: String
    let school: String
    let publisher: String
    let keywords: [String]
    
    /// 轉換為 BibTeX 格式字串
    var toBibTeX: String {
        var bibtex = "@\(entryType){\(citationKey),\n"
        
        if !title.isEmpty { bibtex += "  title = {\(title)},\n" }
        if !author.isEmpty { bibtex += "  author = {\(author)},\n" }
        if !year.isEmpty { bibtex += "  year = {\(year)},\n" }
        if !journal.isEmpty { bibtex += "  journal = {\(journal)},\n" }
        if !booktitle.isEmpty { bibtex += "  booktitle = {\(booktitle)},\n" }
        if !volume.isEmpty { bibtex += "  volume = {\(volume)},\n" }
        if !pages.isEmpty { bibtex += "  pages = {\(pages)},\n" }
        if !doi.isEmpty { bibtex += "  doi = {\(doi)},\n" }
        if !abstract.isEmpty { bibtex += "  abstract = {\(abstract)},\n" }
        if !school.isEmpty { bibtex += "  school = {\(school)},\n" }
        if !publisher.isEmpty { bibtex += "  publisher = {\(publisher)},\n" }
        if !keywords.isEmpty { bibtex += "  keywords = {\(keywords.joined(separator: ", "))},\n" }
        
        bibtex += "}"
        return bibtex
    }
    
    /// 轉換為 Entry fields 字典
    var toFields: [String: String] {
        var fields: [String: String] = [:]
        
        if !title.isEmpty { fields["title"] = title }
        if !author.isEmpty { fields["author"] = author }
        if !year.isEmpty { fields["year"] = year }
        if !journal.isEmpty { fields["journal"] = journal }
        if !booktitle.isEmpty { fields["booktitle"] = booktitle }
        if !volume.isEmpty { fields["volume"] = volume }
        if !pages.isEmpty { fields["pages"] = pages }
        if !doi.isEmpty { fields["doi"] = doi }
        if !abstract.isEmpty { fields["abstract"] = abstract }
        if !school.isEmpty { fields["school"] = school }
        if !publisher.isEmpty { fields["publisher"] = publisher }
        if !keywords.isEmpty { fields["keywords"] = keywords.joined(separator: ", ") }
        
        return fields
    }
}
