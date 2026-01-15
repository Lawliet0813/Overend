import Foundation

/// CSL-JSON Data Model
/// Based on: https://citeproc-js.readthedocs.io/en/latest/csl-json/markup.html
struct CSLItem: Codable, Identifiable {
    let id: String
    let type: String
    let title: String?
    let author: [CSLName]?
    let editor: [CSLName]?
    let issued: CSLDate?
    let containerTitle: String?
    let volume: String?
    let issue: String?
    let page: String?
    let doi: String?
    let url: String?
    let abstract: String?
    let language: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, author, editor, issued, volume, issue, page, doi, url, abstract, language
        case containerTitle = "container-title"
    }
}

struct CSLName: Codable {
    let family: String?
    let given: String?
    let literal: String?
    let isInstitution: Bool?
    
    // Custom logic for CJK names could be added here
}

struct CSLDate: Codable {
    let dateParts: [[Int]]?
    let literal: String?
    
    enum CodingKeys: String, CodingKey {
        case dateParts = "date-parts"
        case literal
    }
    
    var year: Int? {
        return dateParts?.first?.first
    }
}
