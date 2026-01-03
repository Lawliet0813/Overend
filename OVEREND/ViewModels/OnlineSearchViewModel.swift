//
//  OnlineSearchViewModel.swift
//  OVEREND
//
//  Created by Antigravity on 2025/12/28.
//

import Foundation
import Combine

@MainActor
class OnlineSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [SearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDatabase = "Airiti" // Future proofing
    
    private let airitiService = AiritiService.shared
    
    func search() async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        results = []
        
        do {
            // In the future, switch based on selectedDatabase
            results = try await airitiService.search(query: query)
            if results.isEmpty {
                errorMessage = "未找到相關結果"
            }
        } catch {
            errorMessage = "搜尋發生錯誤: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func importResult(_ result: SearchResult, to entryViewModel: EntryViewModel) async {
        // Convert SearchResult to Entry fields
        var fields: [String: String] = [
            "title": result.title,
            "author": result.formattedAuthors,
            "year": result.year,
            "journal": result.publication,
            "url": result.url ?? ""
        ]

        if let doi = result.doi {
            fields["doi"] = doi
        }

        // Generate a simple citation key
        let key = generateCitationKey(result)

        await entryViewModel.createEntry(citationKey: key, entryType: "article", fields: fields)
    }
    
    private func generateCitationKey(_ result: SearchResult) -> String {
        // Simple key generation: AuthorYearTitle
        let author = result.authors.first?.components(separatedBy: " ").last ?? "Unknown"
        let year = result.year.isEmpty ? "0000" : result.year
        let titleWord = result.title.components(separatedBy: " ").first ?? "Untitled"
        return "\(author)\(year)\(titleWord)".filter { $0.isLetter || $0.isNumber }
    }
}
