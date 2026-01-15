//
//  AiritiService.swift
//  OVEREND
//
//  Created by Antigravity on 2025/12/28.
//

import Foundation

enum AiritiError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError
    case noResults
}

class AiritiService {
    static let shared = AiritiService()
    
    private let baseURL = "https://www.airitilibrary.com/Search/alSearchResults?Type=1&SearchType=1"
    
    private init() {}
    
    func search(query: String) async throws -> [SearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw AiritiError.invalidURL
        }
        
        // Airiti search URL structure
        // We use the basic search for now
        let urlString = "\(baseURL)&q=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            throw AiritiError.invalidURL
        }
        
        print("AiritiService: Requesting URL: \(url.absoluteString)")
        print("AiritiService: Proxy Prefix: \(NetworkService.shared.proxyURLPrefix)")
        
        let request = NetworkService.shared.createRequest(for: url)
        print("AiritiService: Final Request URL: \(request.url?.absoluteString ?? "nil")")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let htmlString = String(data: data, encoding: .utf8) else {
                throw AiritiError.parsingError
            }
            
            return parseHTML(htmlString)
        } catch {
            throw AiritiError.networkError(error)
        }
    }
    
    private func parseHTML(_ html: String) -> [SearchResult] {
        var results: [SearchResult] = []
        
        // This is a simplified regex-based parser.
        // In a real production app, a robust HTML parser (like SwiftSoup) would be better,
        // but we are sticking to standard library as per constraints/simplicity.
        
        // Regex to find search result items.
        // Airiti structure (approximate based on inspection):
        // <h3 class="h4"><a href="...">Title</a></h3>
        // ... <span class="...">Author</span> ...
        // ... <span class="...">Journal Year;Vol(Issue)</span> ...
        
        // Note: HTML parsing with Regex is fragile. This is a best-effort implementation.
        
        // 1. Extract blocks that look like results
        // We'll look for the specific structure Airiti uses for list items
        
        // Let's try to find titles first, as they are usually distinct
        // <h3 class="h4"><a href="/Publication/alDetailedMesh?DocID=...">TITLE</a></h3>
        
        let titlePattern = #"<h3 class="h4">\s*<a href="([^"]+)">\s*(.*?)\s*</a>\s*</h3>"#
        let authorPattern = #"<span>\s*([^<]+)\s*</span>"# // This is too generic, need context
        
        // Since regex parsing of full HTML structure is hard, we will try to split by result row if possible.
        // Assuming each result is in a container.
        
        // Alternative: Find all matches for the title pattern, then look ahead for authors/meta.
        
        guard let regex = try? NSRegularExpression(pattern: titlePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            
            let urlPart = nsString.substring(with: match.range(at: 1))
            let rawTitle = nsString.substring(with: match.range(at: 2))
            
            // Clean up title (remove HTML tags if any remain, though our regex tries to capture inside <a>)
            let title = rawTitle.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Construct full URL
            let fullURL = "https://www.airitilibrary.com" + urlPart
            
            // For now, we can't easily get authors/year without a more complex parser or more context in the regex.
            // We will try to extract a snippet after the title match to find authors.
            
            // Look at the text immediately following the title match
            let searchStart = match.range.location + match.range.length
            let searchLength = min(1000, nsString.length - searchStart) // Look ahead 1000 chars
            let searchRange = NSRange(location: searchStart, length: searchLength)
            let snippet = nsString.substring(with: searchRange)
            
            let authors = extractAuthors(from: snippet)
            let (publication, year) = extractPublicationInfo(from: snippet)
            
            let result = SearchResult(
                title: title,
                authors: authors,
                year: year,
                publication: publication,
                doi: nil, // Hard to extract without specific pattern
                url: fullURL,
                source: "Airiti Library"
            )
            
            results.append(result)
        }
        
        return results
    }
    
    private func extractAuthors(from snippet: String) -> [String] {
        // Airiti usually lists authors after the title, often in a span or div
        // Pattern: <span>Author1;Author2...</span>
        // Or just text.
        // Let's try to find the first significant text block that isn't a label.
        
        // Heuristic: Look for text that looks like names (Chinese or English)
        // This is very hard to do reliably with regex on raw HTML snippets.
        // We will return a placeholder or try a very specific pattern if known.
        
        // Attempt to find the "Author" label or similar context?
        // Airiti: <div ...> Author1;Author2 </div>
        
        // Let's try to capture the content of the first <div> or <p> after the title?
        // Or maybe look for the specific class Airiti uses?
        // Assuming class="author" or similar doesn't exist or is obfuscated.
        
        // Fallback: Return empty for now, or try to implement a better parser later if user provides HTML samples.
        return [] 
    }
    
    private func extractPublicationInfo(from snippet: String) -> (String, String) {
        // Try to find year: 4 digits
        // Pattern: 2023
        
        var year = ""
        let yearPattern = #"\b(19|20)\d{2}\b"#
        if let yearRange = snippet.range(of: yearPattern, options: .regularExpression) {
            year = String(snippet[yearRange])
        }
        
        // Publication: Hard to distinguish from other text without structure
        return ("Unknown Publication", year)
    }
}
