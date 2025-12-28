//
//  SearchResult.swift
//  OVEREND
//
//  Created by Antigravity on 2025/12/28.
//

import Foundation

struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let authors: [String]
    let year: String
    let publication: String
    let doi: String?
    let url: String?
    let source: String // e.g., "Airiti", "Google Scholar"
    
    var formattedAuthors: String {
        authors.joined(separator: ", ")
    }
}
