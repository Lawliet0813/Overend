//
//  TypstService.swift
//  OVEREND
//
//  Swift wrapper for Typst compilation via Rust core
//

import Foundation

/// Service for Typst document compilation to PDF
/// Uses the Rust OverendCore for high-performance typesetting
@MainActor
class TypstService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = TypstService()
    
    // MARK: - State
    
    @Published private(set) var isCompiling = false
    @Published private(set) var lastError: String?
    
    // MARK: - Rust Engine
    
    private let engine: OverendEngine
    
    // MARK: - Initialization
    
    private init() {
        engine = OverendEngine()
    }
    
    // MARK: - Public Methods
    
    /// Compile Typst source to PDF data
    /// - Parameters:
    ///   - source: Typst markup source code
    ///   - fontData: Optional font data (e.g., Noto Serif TC for Traditional Chinese)
    /// - Returns: PDF data on success
    func compile(source: String, fontData: Data? = nil) async throws -> Data {
        isCompiling = true
        lastError = nil
        
        defer { isCompiling = false }
        
        do {
            // Call Rust core - UniFFI converts Data automatically
            let pdfData = try engine.compileTypst(
                source: source,
                fontData: fontData
            )
            
            return pdfData
        } catch let error as TypstError {
            let message = error.localizedDescription
            lastError = message
            throw TypstServiceError.compilationFailed(message)
        }
    }
    
    /// Compile Typst source and save to file
    /// - Parameters:
    ///   - source: Typst markup source code
    ///   - outputURL: Destination URL for PDF
    ///   - fontData: Optional font data
    func compileToFile(source: String, outputURL: URL, fontData: Data? = nil) async throws {
        let pdfData = try await compile(source: source, fontData: fontData)
        try pdfData.write(to: outputURL)
    }
    
    /// Load font data from App Bundle
    /// - Parameter fontName: Name of the font file (without extension)
    /// - Returns: Font data or nil if not found
    func loadBundledFont(named fontName: String) -> Data? {
        if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
            return try? Data(contentsOf: url)
        }
        if let url = Bundle.main.url(forResource: fontName, withExtension: "otf") {
            return try? Data(contentsOf: url)
        }
        return nil
    }
    
    /// Test if the Rust engine is working
    func testEngine() -> String {
        return engine.helloWorld()
    }
}

// MARK: - Errors

enum TypstServiceError: LocalizedError {
    case compilationFailed(String)
    case fontLoadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .compilationFailed(let message):
            return "Typst 編譯失敗: \(message)"
        case .fontLoadFailed(let fontName):
            return "無法載入字體: \(fontName)"
        }
    }
}
