//
//  CrossRefService.swift
//  OVEREND
//
//  CrossRef API 服務 - 用於 DOI 文獻查詢
//

import Foundation

enum CrossRefError: Error {
    case invalidDOI
    case networkError(Error)
    case decodingError(Error)
    case notFound
}

class CrossRefService {
    static let shared = CrossRefService()
    
    private let baseURL = "https://api.crossref.org/works/"
    
    /// 透過 DOI 查詢文獻資訊
    func fetchMetadata(doi: String) async throws -> ImportedEntry {
        let cleanDOI = doi.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://doi.org/", with: "")
            .replacingOccurrences(of: "doi:", with: "")
        
        guard let url = URL(string: baseURL + cleanDOI) else {
            throw CrossRefError.invalidDOI
        }
        
        var request = URLRequest(url: url)
        request.setValue("OVEREND/1.0 (mailto:support@overend.app)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CrossRefError.notFound
            }
            
            let result = try JSONDecoder().decode(CrossRefResponse.self, from: data)
            return convertToEntry(result.message)
            
        } catch let error as CrossRefError {
            throw error
        } catch {
            throw CrossRefError.networkError(error)
        }
    }
    
    private func convertToEntry(_ item: CrossRefWork) -> ImportedEntry {
        var fields: [String: String] = [:]
        
        // 標題
        if let title = item.title?.first {
            fields["title"] = title
        }
        
        // 作者
        if let authors = item.author {
            let authorString = authors.map { "\($0.family ?? ""), \($0.given ?? "")" }.joined(separator: " and ")
            fields["author"] = authorString
        }
        
        // 年份
        if let year = item.published?.dateParts?.first?.first {
            fields["year"] = String(year)
        }
        
        // 期刊/會議名稱
        if let containerTitle = item.containerTitle?.first {
            if item.type == "journal-article" {
                fields["journal"] = containerTitle
            } else {
                fields["booktitle"] = containerTitle
            }
        }
        
        // 卷期頁
        if let volume = item.volume { fields["volume"] = volume }
        if let issue = item.issue { fields["number"] = issue }
        if let page = item.page { fields["pages"] = page }
        
        // DOI & URL
        fields["doi"] = item.DOI
        fields["url"] = item.URL
        
        // 出版商
        if let publisher = item.publisher {
            fields["publisher"] = publisher
        }
        
        // 類型轉換
        let type = mapType(item.type)
        
        // 生成簡單 Citation Key
        let authorKey = item.author?.first?.family ?? "Unknown"
        let yearKey = fields["year"] ?? "n.d."
        let citationKey = "\(authorKey)\(yearKey)"
        
        return ImportedEntry(type: type, fields: fields, citationKey: citationKey)
    }
    
    private func mapType(_ crossRefType: String) -> String {
        switch crossRefType {
        case "journal-article": return "article"
        case "book-chapter": return "incollection"
        case "book": return "book"
        case "proceedings-article": return "inproceedings"
        case "dissertation": return "phdthesis"
        default: return "misc"
        }
    }
}

/// 匯入的文獻資料結構（非 Core Data）
struct ImportedEntry {
    let type: String
    let fields: [String: String]
    let citationKey: String
}

// MARK: - CrossRef API Response Models

struct CrossRefResponse: Codable {
    let message: CrossRefWork
}

struct CrossRefWork: Codable {
    let title: [String]?
    let author: [CrossRefAuthor]?
    let published: CrossRefDate?
    let containerTitle: [String]?
    let type: String
    let DOI: String?
    let URL: String?
    let volume: String?
    let issue: String?
    let page: String?
    let publisher: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case author
        case published = "published-print" // 優先使用印刷日期
        case containerTitle = "container-title"
        case type
        case DOI
        case URL
        case volume
        case issue
        case page
        case publisher
    }
}

struct CrossRefAuthor: Codable {
    let given: String?
    let family: String?
}

struct CrossRefDate: Codable {
    let dateParts: [[Int]]?
    
    enum CodingKeys: String, CodingKey {
        case dateParts = "date-parts"
    }
}
