//
//  ZoteroBridge.swift
//  OVEREND
//
//  Zotero 橋接服務 - 透過 Better BibTeX JSON-RPC 介面
//
//  功能：
//  - 即時搜尋 Zotero 文獻庫
//  - 取得引文鍵 (Citation Key)
//  - 匯入文獻至 OVEREND
//
//  需求：
//  - 使用者需安裝 Zotero 並執行
//  - 需安裝 Better BibTeX 插件 (https://retorque.re/zotero-better-bibtex/)
//

import Foundation
import CoreData
import Combine

// MARK: - Zotero 項目

/// Zotero 文獻項目
struct ZoteroItem: Identifiable, Codable {
    let id: String                    // Zotero 項目 ID
    let itemType: String              // 項目類型
    let title: String                 // 標題
    let creators: [ZoteroCreator]     // 作者列表
    let date: String?                 // 出版日期
    let citationKey: String?          // 引文鍵（由 BBT 產生）
    let DOI: String?                  // DOI
    let abstractNote: String?         // 摘要
    let publicationTitle: String?     // 期刊/出版物名稱
    let volume: String?               // 卷
    let issue: String?                // 期
    let pages: String?                // 頁碼
    let publisher: String?            // 出版社
    let url: String?                  // URL
    let extra: String?                // 額外資訊
    
    enum CodingKeys: String, CodingKey {
        case id = "key"
        case itemType, title, creators, date
        case citationKey = "citekey"
        case DOI, abstractNote, publicationTitle
        case volume, issue, pages, publisher, url, extra
    }
    
    /// 作者字串
    var authorString: String {
        creators
            .filter { $0.creatorType == "author" }
            .map { creator in
                if let lastName = creator.lastName {
                    if let firstName = creator.firstName {
                        return "\(lastName), \(firstName)"
                    }
                    return lastName
                }
                return creator.name ?? ""
            }
            .joined(separator: "; ")
    }
    
    /// 年份
    var year: String? {
        guard let date = date else { return nil }
        // 嘗試提取年份（前 4 位數字）
        let pattern = #"\b(\d{4})\b"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: date, range: NSRange(date.startIndex..., in: date)),
           let range = Range(match.range(at: 1), in: date) {
            return String(date[range])
        }
        return nil
    }
    
    /// BibTeX 類型
    var bibTeXType: String {
        switch itemType {
        case "journalArticle": return "article"
        case "book": return "book"
        case "bookSection": return "incollection"
        case "conferencePaper": return "inproceedings"
        case "thesis": return "phdthesis"
        case "report": return "techreport"
        case "webpage": return "misc"
        default: return "misc"
        }
    }
}

/// Zotero 作者
struct ZoteroCreator: Codable {
    let creatorType: String       // "author", "editor" 等
    let firstName: String?
    let lastName: String?
    let name: String?             // 用於機構作者
}

// MARK: - JSON-RPC 結構

/// JSON-RPC 請求
private struct JSONRPCRequest: Codable {
    let jsonrpc: String = "2.0"
    let method: String
    let params: [String]
    let id: Int
    
    enum CodingKeys: String, CodingKey {
        case jsonrpc, method, params, id
    }
}

/// JSON-RPC 回應
private struct JSONRPCResponse<T: Codable>: Codable {
    let jsonrpc: String
    let result: T?
    let error: JSONRPCError?
    let id: Int
}

/// JSON-RPC 錯誤
private struct JSONRPCError: Codable {
    let code: Int
    let message: String
}

// MARK: - Zotero Bridge 服務

/// Zotero 橋接服務
@MainActor
class ZoteroBridge: ObservableObject {
    
    // MARK: - 單例
    
    static let shared = ZoteroBridge()
    
    // MARK: - 狀態
    
    @Published var isConnected: Bool = false
    @Published var isChecking: Bool = false
    @Published var isSearching: Bool = false
    @Published var lastError: String?
    @Published var searchResults: [ZoteroItem] = []
    
    // MARK: - 設定
    
    /// Better BibTeX JSON-RPC 端點
    private let rpcEndpoint = "http://localhost:23119/better-bibtex/json-rpc"
    
    /// 請求逾時時間（秒）
    private let requestTimeout: TimeInterval = 5
    
    /// 請求 ID 計數器
    private var requestID = 0
    
    // MARK: - 初始化
    
    private init() {
        // 啟動時檢查連線
        Task {
            await checkConnection()
        }
    }
    
    // MARK: - 連線管理
    
    /// 檢查 Zotero 是否運行且 BBT 可用
    func checkConnection() async -> Bool {
        isChecking = true
        defer { isChecking = false }
        
        do {
            // 發送簡單請求測試連線
            let _: [ZoteroItem] = try await searchInternal(query: "test")
            isConnected = true
            lastError = nil
            AppLogger.success("✅ ZoteroBridge: 已連線至 Zotero/Better BibTeX")
            return true
        } catch ZoteroBridgeError.connectionFailed {
            isConnected = false
            lastError = "無法連線至 Zotero。請確認 Zotero 正在運行且已安裝 Better BibTeX 插件。"
            AppLogger.debug("⚠️ ZoteroBridge: 無法連線（Zotero 可能未運行）")
            return false
        } catch {
            isConnected = false
            lastError = error.localizedDescription
            AppLogger.debug("⚠️ ZoteroBridge: 連線錯誤 - \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 搜尋
    
    /// 搜尋 Zotero 文獻
    /// - Parameter query: 搜尋關鍵字
    /// - Returns: 匹配的文獻項目
    func search(query: String) async throws -> [ZoteroItem] {
        guard !query.isEmpty else { return [] }
        
        // 如果未連線，嘗試連線
        if !isConnected {
            let connected = await checkConnection()
            guard connected else {
                throw ZoteroBridgeError.notConnected
            }
        }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            let items = try await searchInternal(query: query)
            searchResults = items
            return items
        } catch {
            lastError = "搜尋失敗：\(error.localizedDescription)"
            throw error
        }
    }
    
    /// 內部搜尋方法（處理 JSON-RPC 調用）
    private func searchInternal(query: String) async throws -> [ZoteroItem] {
        requestID += 1
        
        let request = JSONRPCRequest(
            method: "item.search",
            params: [query],
            id: requestID
        )
        
        guard let url = URL(string: rpcEndpoint) else {
            throw ZoteroBridgeError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = requestTimeout
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ZoteroBridgeError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw ZoteroBridgeError.httpError(httpResponse.statusCode)
            }
            
            // 解析 JSON 回應
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ZoteroBridgeError.parseError
            }
            
            // 檢查錯誤
            if let error = json["error"] as? [String: Any],
               let code = error["code"] as? Int,
               let message = error["message"] as? String {
                throw ZoteroBridgeError.rpcError(code, message)
            }
            
            // 解析結果
            guard let result = json["result"] as? [[String: Any]] else {
                return []
            }
            
            return parseZoteroItems(from: result)
            
        } catch let error as URLError {
            if error.code == .cannotConnectToHost || error.code == .timedOut {
                throw ZoteroBridgeError.connectionFailed
            }
            throw error
        }
    }
    
    /// 取得引文鍵
    /// - Parameter itemID: Zotero 項目 ID
    /// - Returns: 引文鍵
    func getCitationKey(for itemID: String) async throws -> String {
        guard isConnected else {
            throw ZoteroBridgeError.notConnected
        }
        
        let response: String = try await sendRPCRequest(
            method: "item.citationkey",
            params: [itemID]
        )
        
        return response
    }
    
    // MARK: - 匯入
    
    /// 匯入 Zotero 項目至 OVEREND
    /// - Parameters:
    ///   - items: 要匯入的項目
    ///   - library: 目標文獻庫
    ///   - context: Core Data 上下文
    /// - Returns: 成功匯入的數量
    func importItems(
        _ items: [ZoteroItem],
        into library: Library,
        context: NSManagedObjectContext
    ) throws -> Int {
        var importedCount = 0
        var importedEntryIDs: [UUID] = []
        
        for item in items {
            // 生成或使用 Citation Key
            let citationKey = item.citationKey ?? generateCitationKey(from: item)
            
            // 檢查是否已存在
            if Entry.find(byCitationKey: citationKey, in: context) != nil {
                AppLogger.debug("⚠️ ZoteroBridge: 跳過重複書目: \(citationKey)")
                continue
            }
            
            // 建立欄位字典
            var fields: [String: String] = [:]
            
            fields["title"] = item.title
            
            if !item.authorString.isEmpty {
                fields["author"] = item.authorString
            }
            if let year = item.year {
                fields["year"] = year
            }
            if let journal = item.publicationTitle {
                fields["journal"] = journal
            }
            if let volume = item.volume {
                fields["volume"] = volume
            }
            if let issue = item.issue {
                fields["number"] = issue
            }
            if let pages = item.pages {
                fields["pages"] = pages
            }
            if let doi = item.DOI {
                fields["doi"] = doi
            }
            if let url = item.url {
                fields["url"] = url
            }
            if let abstract = item.abstractNote {
                fields["abstract"] = abstract
            }
            if let publisher = item.publisher {
                fields["publisher"] = publisher
            }
            
            // 建立 Entry
            let newEntry = Entry(
                context: context,
                citationKey: citationKey,
                entryType: item.bibTeXType,
                fields: fields,
                library: library
            )
            
            importedCount += 1
            importedEntryIDs.append(newEntry.id)
        }
        
        // 儲存
        try context.save()
        
        // 觸發 Agent 自動分析
        if !importedEntryIDs.isEmpty {
            if #available(macOS 26.0, *) {
                AgentAutoTrigger.notifyImport(
                    entryIDs: importedEntryIDs,
                    libraryID: library.id,
                    source: ImportSource.zotero
                )
            }
        }
        
        AppLogger.success("✅ ZoteroBridge: 成功匯入 \(importedCount) 筆書目")
        return importedCount
    }
    
    // MARK: - 私有方法
    
    /// 發送 JSON-RPC 請求
    private func sendRPCRequest<T: Codable>(method: String, params: [String]) async throws -> T {
        requestID += 1
        
        let request = JSONRPCRequest(
            method: method,
            params: params,
            id: requestID
        )
        
        guard let url = URL(string: rpcEndpoint) else {
            throw ZoteroBridgeError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = requestTimeout
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ZoteroBridgeError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw ZoteroBridgeError.httpError(httpResponse.statusCode)
            }
            
            // 嘗試解析為泛型回應
            if let directResult = try? JSONDecoder().decode(JSONRPCResponse<T>.self, from: data) {
                if let error = directResult.error {
                    throw ZoteroBridgeError.rpcError(error.code, error.message)
                }
                if let result = directResult.result {
                    return result
                }
            }
            
            // 嘗試解析為 Any 型別
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let result = json["result"] {
                // 將結果轉回 Data 再解碼
                let resultData = try JSONSerialization.data(withJSONObject: result)
                return try JSONDecoder().decode(T.self, from: resultData)
            }
            
            throw ZoteroBridgeError.parseError
            
        } catch let error as URLError {
            if error.code == .cannotConnectToHost || error.code == .timedOut {
                throw ZoteroBridgeError.connectionFailed
            }
            throw error
        }
    }
    
    /// 解析 Zotero 項目回應
    private func parseZoteroItems(from response: [[String: Any]]) -> [ZoteroItem] {
        var items: [ZoteroItem] = []
        
        for itemDict in response {
            guard let id = itemDict["key"] as? String,
                  let title = itemDict["title"] as? String,
                  let itemType = itemDict["itemType"] as? String else {
                continue
            }
            
            // 解析作者
            var creators: [ZoteroCreator] = []
            if let creatorsArray = itemDict["creators"] as? [[String: String]] {
                for creatorDict in creatorsArray {
                    let creator = ZoteroCreator(
                        creatorType: creatorDict["creatorType"] ?? "author",
                        firstName: creatorDict["firstName"],
                        lastName: creatorDict["lastName"],
                        name: creatorDict["name"]
                    )
                    creators.append(creator)
                }
            }
            
            let item = ZoteroItem(
                id: id,
                itemType: itemType,
                title: title,
                creators: creators,
                date: itemDict["date"] as? String,
                citationKey: itemDict["citekey"] as? String,
                DOI: itemDict["DOI"] as? String,
                abstractNote: itemDict["abstractNote"] as? String,
                publicationTitle: itemDict["publicationTitle"] as? String,
                volume: itemDict["volume"] as? String,
                issue: itemDict["issue"] as? String,
                pages: itemDict["pages"] as? String,
                publisher: itemDict["publisher"] as? String,
                url: itemDict["url"] as? String,
                extra: itemDict["extra"] as? String
            )
            
            items.append(item)
        }
        
        return items
    }
    
    /// 從 Zotero 項目生成 Citation Key
    private func generateCitationKey(from item: ZoteroItem) -> String {
        var key = ""
        
        // 作者姓氏
        if let firstCreator = item.creators.first {
            if let lastName = firstCreator.lastName {
                key += lastName.lowercased().prefix(10)
            } else if let name = firstCreator.name {
                key += name.lowercased().prefix(10)
            }
        }
        
        // 年份
        if let year = item.year {
            key += year
        }
        
        // 標題首詞
        let titleWords = item.title.components(separatedBy: .whitespaces)
        let stopWords = Set(["the", "a", "an", "of", "and", "in", "on", "for"])
        for word in titleWords {
            let cleanWord = word.lowercased().filter { $0.isLetter }
            if !stopWords.contains(cleanWord) && !cleanWord.isEmpty {
                key += cleanWord.prefix(6)
                break
            }
        }
        
        if key.isEmpty {
            key = "zotero_\(item.id)"
        }
        
        return key
    }
}

// MARK: - 錯誤類型

/// Zotero Bridge 錯誤
enum ZoteroBridgeError: LocalizedError {
    case notConnected
    case connectionFailed
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case rpcError(Int, String)
    case parseError
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "未連線至 Zotero"
        case .connectionFailed:
            return "無法連線至 Zotero。請確認 Zotero 正在運行且已安裝 Better BibTeX 插件。"
        case .invalidURL:
            return "無效的端點 URL"
        case .invalidResponse:
            return "無效的伺服器回應"
        case .httpError(let code):
            return "HTTP 錯誤：\(code)"
        case .rpcError(let code, let message):
            return "RPC 錯誤 (\(code)): \(message)"
        case .parseError:
            return "無法解析回應資料"
        case .importFailed(let message):
            return "匯入失敗：\(message)"
        }
    }
}
