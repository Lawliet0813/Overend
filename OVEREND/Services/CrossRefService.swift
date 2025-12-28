//
//  CrossRefService.swift
//  OVEREND
//
//  CrossRef API 服務 - 透過 DOI 查詢完整書目資訊
//

import Foundation

class CrossRefService {
    private static let baseURL = "https://api.crossref.org/works/"
    
    /// 通過 DOI 查詢完整書目資訊
    static func fetchMetadata(doi: String) async throws -> CrossRefMetadata {
        // 清理 DOI（移除前綴）
        let cleanDOI = doi.replacingOccurrences(of: "https://doi.org/", with: "")
                         .replacingOccurrences(of: "http://dx.doi.org/", with: "")
                         .replacingOccurrences(of: "doi:", with: "", options: .caseInsensitive)
                         .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 構建 URL（需要 URL 編碼）
        guard let encodedDOI = cleanDOI.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)\(encodedDOI)") else {
            throw CrossRefError.invalidDOI
        }
        
        // 設置請求（加上禮貌的 User-Agent）
        var request = URLRequest(url: url)
        request.setValue("OVEREND/1.0 (mailto:overend@example.com)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        print("📡 查詢 CrossRef API: \(cleanDOI)")
        
        // 發送請求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 檢查回應
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CrossRefError.networkError
        }
        
        print("📊 CrossRef 回應狀態: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw CrossRefError.doiNotFound
            }
            throw CrossRefError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // 解析 JSON
        let decoder = JSONDecoder()
        let result = try decoder.decode(CrossRefResponse.self, from: data)
        
        print("✅ CrossRef 查詢成功: \(result.message.title?.first ?? "Unknown")")
        
        return result.message
    }
}

// MARK: - Data Models

struct CrossRefResponse: Codable {
    let status: String
    let message: CrossRefMetadata
}

struct CrossRefMetadata: Codable {
    let title: [String]?
    let author: [CrossRefAuthor]?
    let published: CrossRefDate?
    let containerTitle: [String]?
    let volume: String?
    let issue: String?
    let page: String?
    let publisher: String?
    let type: String?
    let DOI: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case author
        case published = "published-print"
        case containerTitle = "container-title"
        case volume
        case issue
        case page
        case publisher
        case type
        case DOI
    }
    
    // 備用：如果沒有 published-print，嘗試其他日期欄位
    struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decodeIfPresent([String].self, forKey: .title)
        author = try container.decodeIfPresent([CrossRefAuthor].self, forKey: .author)
        containerTitle = try container.decodeIfPresent([String].self, forKey: .containerTitle)
        volume = try container.decodeIfPresent(String.self, forKey: .volume)
        issue = try container.decodeIfPresent(String.self, forKey: .issue)
        page = try container.decodeIfPresent(String.self, forKey: .page)
        publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        DOI = try container.decodeIfPresent(String.self, forKey: .DOI)
        
        // 嘗試多個日期欄位
        if let pub = try? container.decodeIfPresent(CrossRefDate.self, forKey: .published) {
            published = pub
        } else {
            // 嘗試其他日期欄位
            let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)
            if let key = DynamicCodingKeys(stringValue: "published-online"),
               let pub = try? dynamicContainer.decodeIfPresent(CrossRefDate.self, forKey: key) {
                published = pub
            } else if let key = DynamicCodingKeys(stringValue: "created"),
                      let pub = try? dynamicContainer.decodeIfPresent(CrossRefDate.self, forKey: key) {
                published = pub
            } else {
                published = nil
            }
        }
    }
}

struct CrossRefAuthor: Codable {
    let given: String?
    let family: String?
    
    var fullName: String {
        if let given = given, let family = family {
            return "\(family) \(given)"
        } else if let family = family {
            return family
        } else if let given = given {
            return given
        } else {
            return "Unknown"
        }
    }
    
    var chineseName: String {
        // 如果是中文名字，使用不同格式
        if let family = family, let given = given {
            // 檢查是否為中文
            let isChinese = family.range(of: "[\u{4E00}-\u{9FFF}]", options: .regularExpression) != nil
            if isChinese {
                return "\(family)\(given)" // 中文不加空格
            }
            return "\(family) \(given)"
        }
        return fullName
    }
}

struct CrossRefDate: Codable {
    let dateParts: [[Int]]?
    
    enum CodingKeys: String, CodingKey {
        case dateParts = "date-parts"
    }
    
    var year: String? {
        guard let parts = dateParts?.first,
              !parts.isEmpty else {
            return nil
        }
        return String(parts[0])
    }
    
    var fullDate: String? {
        guard let parts = dateParts?.first,
              parts.count >= 3 else {
            return nil
        }
        return "\(parts[0])-\(String(format: "%02d", parts[1]))-\(String(format: "%02d", parts[2]))"
    }
}

enum CrossRefError: Error {
    case invalidDOI
    case apiError(statusCode: Int)
    case networkError
    case doiNotFound
    
    var localizedDescription: String {
        switch self {
        case .invalidDOI:
            return "無效的 DOI"
        case .apiError(let code):
            return "API 錯誤 (狀態碼: \(code))"
        case .networkError:
            return "網路錯誤"
        case .doiNotFound:
            return "DOI 不存在"
        }
    }
}
