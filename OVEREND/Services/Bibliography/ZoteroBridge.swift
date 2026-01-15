import Foundation
import Combine
import CoreData

// MARK: - Zotero Models

/// Zotero item representation
struct ZoteroItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let itemType: String
    let authors: [String]
    let year: String?
    let publicationTitle: String?
    let citationKey: String?
    let abstract: String?
    let doi: String?
    let url: String?
    let tags: [String]
    
    var authorString: String {
        authors.joined(separator: ", ")
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "key"
        case title
        case itemType
        case authors = "creators"
        case year = "date"
        case publicationTitle
        case citationKey = "citekey"
        case abstract = "abstractNote"
        case doi = "DOI"
        case url
        case tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled"
        itemType = try container.decodeIfPresent(String.self, forKey: .itemType) ?? "misc"
        
        // Parse creators array
        if let creators = try? container.decode([[String: String]].self, forKey: .authors) {
            authors = creators.compactMap { creator in
                if let lastName = creator["lastName"], let firstName = creator["firstName"] {
                    return "\(lastName), \(firstName)"
                } else if let name = creator["name"] {
                    return name
                }
                return nil
            }
        } else {
            authors = []
        }
        
        // Parse year from date string (e.g., "2023-05-15" -> "2023")
        if let dateString = try container.decodeIfPresent(String.self, forKey: .year) {
            year = String(dateString.prefix(4))
        } else {
            year = nil
        }
        
        publicationTitle = try container.decodeIfPresent(String.self, forKey: .publicationTitle)
        citationKey = try container.decodeIfPresent(String.self, forKey: .citationKey)
        abstract = try container.decodeIfPresent(String.self, forKey: .abstract)
        doi = try container.decodeIfPresent(String.self, forKey: .doi)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        
        // Parse tags
        if let tagDicts = try? container.decode([[String: String]].self, forKey: .tags) {
            tags = tagDicts.compactMap { $0["tag"] }
        } else {
            tags = []
        }
    }
    
    init(id: String, title: String, itemType: String, authors: [String], year: String?, publicationTitle: String?, citationKey: String?, abstract: String?, doi: String? = nil, url: String? = nil, tags: [String] = []) {
        self.id = id
        self.title = title
        self.itemType = itemType
        self.authors = authors
        self.year = year
        self.publicationTitle = publicationTitle
        self.citationKey = citationKey
        self.abstract = abstract
        self.doi = doi
        self.url = url
        self.tags = tags
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(itemType, forKey: .itemType)
        try container.encodeIfPresent(year, forKey: .year)
        try container.encodeIfPresent(publicationTitle, forKey: .publicationTitle)
        try container.encodeIfPresent(citationKey, forKey: .citationKey)
        try container.encodeIfPresent(abstract, forKey: .abstract)
        try container.encodeIfPresent(doi, forKey: .doi)
        try container.encodeIfPresent(url, forKey: .url)
    }
}

// MARK: - JSON-RPC Response Models

/// Better BibTeX JSON-RPC Response
struct BBTResponse<T: Decodable>: Decodable {
    let jsonrpc: String
    let id: Int
    let result: T?
    let error: BBTError?
}

struct BBTError: Decodable, Error, LocalizedError {
    let code: Int
    let message: String
    
    var errorDescription: String? {
        "Zotero Error (\(code)): \(message)"
    }
}

/// BBT Search Result Item (raw format from API)
struct BBTSearchItem: Decodable {
    let id: String
    let type: String
    let title: String?
    let author: [CSLAuthor]?
    let issued: CSLDate?
    let containerTitle: String?
    let abstract: String?
    let DOI: String?
    let URL: String?
    let citekey: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case author
        case issued
        case containerTitle = "container-title"
        case abstract
        case DOI
        case URL
        case citekey
    }
    
    struct CSLAuthor: Decodable {
        let family: String?
        let given: String?
        let literal: String?
    }
    
    struct CSLDate: Decodable {
        let dateParts: [[Int]]?
        
        enum CodingKeys: String, CodingKey {
            case dateParts = "date-parts"
        }
    }
    
    func toZoteroItem() -> ZoteroItem {
        let authorsList = author?.compactMap { creator -> String? in
            if let family = creator.family, let given = creator.given {
                return "\(family), \(given)"
            } else if let literal = creator.literal {
                return literal
            } else if let family = creator.family {
                return family
            }
            return nil
        } ?? []
        
        let year = issued?.dateParts?.first?.first.map { String($0) }
        
        return ZoteroItem(
            id: id,
            title: title ?? "Untitled",
            itemType: type,
            authors: authorsList,
            year: year,
            publicationTitle: containerTitle,
            citationKey: citekey,
            abstract: abstract,
            doi: DOI,
            url: URL,
            tags: [] // CSL-JSON tags are in 'keyword' usually, ignoring for now
        )
    }
}

// MARK: - Zotero Bridge

/// Bridge to communicate with Zotero via Better BibTeX (BBT) JSON-RPC
/// Requires Zotero + BBT plugin installed and running.
class ZoteroBridge: ObservableObject {
    static let shared = ZoteroBridge()
    
    private let endpoint = URL(string: "http://localhost:23119/better-bibtex/json-rpc")!
    private let session: URLSession
    
    @Published var isConnected: Bool = false
    @Published var isChecking: Bool = false
    @Published var isSearching: Bool = false
    @Published var lastError: String?
    @Published var searchResults: [ZoteroItem] = []
    
    // MARK: - Errors
    
    enum BridgeError: LocalizedError {
        case notConnected
        case invalidResponse
        case apiError(BBTError)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .notConnected:
                return "Zotero 未連線。請確認 Zotero 已啟動且 Better BibTeX 外掛已安裝。"
            case .invalidResponse:
                return "無法解析 Zotero 回應"
            case .apiError(let error):
                return error.errorDescription
            case .networkError(let error):
                return "網路錯誤: \(error.localizedDescription)"
            }
        }
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Connection
    
    /// Check if Zotero is reachable
    func checkConnection() async {
        await MainActor.run { 
            isChecking = true
            lastError = nil
        }
        
        do {
            // Use a simple ping-like request
            let payload: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "item.search",
                "params": ["test"],
                "id": 1
            ]
            
            let _ = try await sendRequest(payload: payload)
            
            await MainActor.run {
                self.isConnected = true
                self.lastError = nil
                self.isChecking = false
            }
        } catch {
            await MainActor.run {
                self.isConnected = false
                self.lastError = error.localizedDescription
                self.isChecking = false
            }
        }
    }
    
    // MARK: - Search
    
    /// Search for items in Zotero
    /// - Parameter query: Search query string
    /// - Returns: Array of matching ZoteroItem
    func search(query: String) async throws -> [ZoteroItem] {
        await MainActor.run {
            isSearching = true
            searchResults = []
            lastError = nil
        }
        
        defer {
            Task { @MainActor in
                isSearching = false
            }
        }
        
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "item.search",
            "params": [query, "*"],
            "id": Int.random(in: 1...10000)
        ]
        
        let data = try await sendRequest(payload: payload)
        
        #if DEBUG
        if let jsonStr = String(data: data, encoding: .utf8) {
            print("BBT Search Response: \(jsonStr)")
        }
        #endif
        
        // Parse BBT response
        let decoder = JSONDecoder()
        
        // Try to parse as array of search items
        do {
            let response = try decoder.decode(BBTResponse<[BBTSearchItem]>.self, from: data)
            
            if let error = response.error {
                throw BridgeError.apiError(error)
            }
            
            let items = response.result?.map { $0.toZoteroItem() } ?? []
            
            await MainActor.run {
                self.searchResults = items
            }
            
            return items
        } catch {
            #if DEBUG
            print("BBT Decoding Error: \(error)")
            #endif
            // Continue to fallback
        }
        
        // Fallback: try alternative response format
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let resultArray = json["result"] as? [[String: Any]] {
            let items = resultArray.compactMap { parseItemFromDict($0) }
            
            await MainActor.run {
                self.searchResults = items
            }
            
            return items
        }
        
        throw BridgeError.invalidResponse
    }
    
    // MARK: - Citation Key
    
    /// Get citation key for an item
    /// - Parameter itemKey: The Zotero item key
    /// - Returns: The BibTeX citation key
    func getCitationKey(for itemKey: String) async throws -> String {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "item.citationkey",
            "params": [[itemKey]],
            "id": Int.random(in: 1...10000)
        ]
        
        let data = try await sendRequest(payload: payload)
        
        if let response = try? JSONDecoder().decode(BBTResponse<[String: String]>.self, from: data),
           let result = response.result,
           let citationKey = result[itemKey] {
            return citationKey
        }
        
        // Fallback parsing
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let result = json["result"] as? [String: String],
           let citationKey = result[itemKey] {
            return citationKey
        }
        
        throw BridgeError.invalidResponse
    }
    
    /// Get citation keys for multiple items
    /// - Parameter itemKeys: Array of Zotero item keys
    /// - Returns: Dictionary mapping item keys to citation keys
    func getCitationKeys(for itemKeys: [String]) async throws -> [String: String] {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "item.citationkey",
            "params": [itemKeys],
            "id": Int.random(in: 1...10000)
        ]
        
        let data = try await sendRequest(payload: payload)
        
        if let response = try? JSONDecoder().decode(BBTResponse<[String: String]>.self, from: data),
           let result = response.result {
            return result
        }
        
        // Fallback parsing
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let result = json["result"] as? [String: String] {
            return result
        }
        
        throw BridgeError.invalidResponse
    }
    
    // MARK: - Export
    
    /// Export items as BibTeX
    /// - Parameter itemKeys: Array of Zotero item keys
    /// - Returns: BibTeX string
    func exportAsBibTeX(itemKeys: [String]) async throws -> String {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "item.export",
            "params": [itemKeys, "biblatex"],
            "id": Int.random(in: 1...10000)
        ]
        
        let data = try await sendRequest(payload: payload)
        
        if let response = try? JSONDecoder().decode(BBTResponse<String>.self, from: data),
           let result = response.result {
            return result
        }
        
        // Fallback parsing
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let result = json["result"] as? String {
            return result
        }
        
        throw BridgeError.invalidResponse
    }
    
    // MARK: - Import to Core Data
    
    /// Import items into a library
    func importItems(_ items: [ZoteroItem], into library: Library, context: NSManagedObjectContext) throws -> Int {
        var count = 0
        
        for item in items {
            var fields: [String: String] = ["title": item.title]
            if !item.authors.isEmpty {
                fields["author"] = item.authors.joined(separator: " and ")
            }
            if let year = item.year {
                fields["year"] = year
            }
            if let journal = item.publicationTitle {
                fields["journal"] = journal
            }
            if let abstract = item.abstract {
                fields["abstract"] = abstract
            }
            if let doi = item.doi {
                fields["doi"] = doi
            }
            if let url = item.url {
                fields["url"] = url
            }
            
            let citationKey = item.citationKey ?? "zotero_\(item.id)"
            let entryType = mapItemType(item.itemType)
            
            let _ = Entry(
                context: context,
                citationKey: citationKey,
                entryType: entryType,
                fields: fields,
                library: library
            )
            
            count += 1
        }
        
        try context.save()
        return count
    }
    
    // MARK: - Private Methods
    
    private func sendRequest(payload: [String: Any]) async throws -> Data {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BridgeError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw BridgeError.notConnected
            }
            
            return data
        } catch let error as BridgeError {
            throw error
        } catch {
            throw BridgeError.networkError(error)
        }
    }
    
    private func parseItemFromDict(_ dict: [String: Any]) -> ZoteroItem? {
        guard let key = dict["key"] as? String,
              let title = dict["title"] as? String else {
            return nil
        }
        
        let itemType = dict["itemType"] as? String ?? "misc"
        
        var authors: [String] = []
        if let creators = dict["creators"] as? [[String: String]] {
            authors = creators.compactMap { creator in
                if let lastName = creator["lastName"], let firstName = creator["firstName"] {
                    return "\(lastName), \(firstName)"
                } else if let name = creator["name"] {
                    return name
                }
                return nil
            }
        }
        
        var year: String?
        if let dateString = dict["date"] as? String {
            year = String(dateString.prefix(4))
        }
        
        return ZoteroItem(
            id: key,
            title: title,
            itemType: itemType,
            authors: authors,
            year: year,
            publicationTitle: dict["publicationTitle"] as? String,
            citationKey: dict["citekey"] as? String,
            abstract: dict["abstractNote"] as? String,
            doi: dict["DOI"] as? String,
            url: dict["url"] as? String,
            tags: (dict["tags"] as? [[String: String]])?.compactMap { $0["tag"] } ?? []
        )
    }
    
    private func mapItemType(_ zoteroType: String) -> String {
        switch zoteroType {
        case "article-journal", "journalArticle": return "article"
        case "book": return "book"
        case "chapter", "bookSection": return "incollection"
        case "paper-conference", "conferencePaper": return "inproceedings"
        case "thesis", "phdthesis": return "phdthesis"
        case "report", "techreport": return "techreport"
        case "webpage", "online": return "online"
        case "patent": return "patent"
        case "presentation": return "misc"
        case "document": return "misc"
        default: return "misc"
        }
    }
}
