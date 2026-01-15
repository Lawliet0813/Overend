//
//  HayagrivaService.swift
//  OVEREND
//
//  Swift wrapper for Hayagriva bibliography processing via Rust core
//

import Foundation
import Combine

/// Service for BibTeX parsing and bibliography formatting
/// Uses the Rust OverendCore with Hayagriva crate
@available(macOS 13.0, iOS 16.0, *)
@MainActor
class HayagrivaService: ObservableObject {

    // MARK: - Singleton

    static let shared = HayagrivaService()

    // MARK: - State

    @Published private(set) var isProcessing = false
    @Published private(set) var lastError: String?

    // MARK: - Bridge

    private let bridge = OverendCoreBridge.shared
    
    // MARK: - Initialization

    private init() {
        // Bridge is already initialized as singleton
    }
    
    // MARK: - BibTeX Parsing
    
    /// Parse BibTeX content into structured entries
    /// - Parameter bibtexContent: BibTeX file content
    /// - Returns: Array of bibliography entries
    func parseBibtex(_ bibtexContent: String) throws -> [BibEntry] {
        isProcessing = true
        lastError = nil

        defer { isProcessing = false }

        do {
            return try bridge.parseBibTeX(bibtexContent)
        } catch {
            lastError = error.localizedDescription
            throw HayagrivaServiceError.parseFailed(error.localizedDescription)
        }
    }

    /// Parse BibTeX file from URL
    /// - Parameter fileURL: URL to BibTeX file
    /// - Returns: Array of bibliography entries
    func parseBibtexFile(at fileURL: URL) throws -> [BibEntry] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return try parseBibtex(content)
    }
    
    // MARK: - Citation Formatting
    
    /// Format in-text citations
    /// - Parameters:
    ///   - bibtexContent: BibTeX source
    ///   - citeKeys: List of citation keys to format
    ///   - style: Citation style name (e.g., "apa", "mla")
    /// - Returns: Formatted citation string (e.g., "(Smith, 2020)")
    func formatCitation(
        bibtexContent: String,
        citeKeys: [String],
        style: String = "apa"
    ) throws -> String {
        isProcessing = true
        lastError = nil

        defer { isProcessing = false }

        do {
            return try bridge.formatCitation(
                bibtexContent: bibtexContent,
                citeKeys: citeKeys,
                style: style
            )
        } catch {
            lastError = error.localizedDescription
            throw HayagrivaServiceError.formatFailed(error.localizedDescription)
        }
    }

    // MARK: - Bibliography Generation

    /// Generate a formatted bibliography list
    /// - Parameters:
    ///   - bibtexContent: BibTeX source
    ///   - style: Citation style name (e.g., "apa", "mla")
    /// - Returns: List of formatted bibliography entries
    func generateBibliography(
        bibtexContent: String,
        style: String = "apa"
    ) throws -> [String] {
        isProcessing = true
        lastError = nil

        defer { isProcessing = false }

        do {
            return try bridge.generateBibliography(
                bibtexContent: bibtexContent,
                style: style
            )
        } catch {
            lastError = error.localizedDescription
            throw HayagrivaServiceError.formatFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Conversion
    
    /// Convert BibEntry to app's LibraryEntry format
    /// - Parameter entry: BibEntry from Rust
    /// - Returns: Dictionary representation
    func convertToLibraryEntry(_ entry: BibEntry) -> [String: Any] {
        return [
            "key": entry.key,
            "title": entry.title ?? "",
            "authors": entry.authors.joined(separator: "; "),
            "year": entry.year ?? "",
            "entryType": entry.entryType,
            "journal": entry.journal ?? "",
            "volume": entry.volume ?? "",
            "pages": entry.pages ?? "",
            "doi": entry.doi ?? "",
            "url": entry.url ?? ""
        ]
    }
}

// MARK: - Errors

enum HayagrivaServiceError: LocalizedError {
    case parseFailed(String)
    case formatFailed(String)
    case fileNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .parseFailed(let message):
            return "BibTeX 解析失敗: \(message)"
        case .formatFailed(let message):
            return "引用格式化失敗: \(message)"
        case .fileNotFound(let path):
            return "找不到檔案: \(path)"
        }
    }
}
