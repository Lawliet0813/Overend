//
//  TypstService.swift
//  OVEREND
//
//  Swift wrapper for Typst compilation via Rust core
//

import Foundation
import Combine

import AppKit

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
    ///   - auxFiles: Optional map of auxiliary files (filename -> data)
    /// - Returns: PDF data on success
    func compile(source: String, fontData: Data? = nil, auxFiles: [String: Data]? = nil) async throws -> Data {
        isCompiling = true
        lastError = nil
        
        defer { isCompiling = false }
        
        do {
            // Call Rust core - UniFFI converts Data automatically
            let pdfData = try engine.compileTypst(
                source: source,
                fontData: fontData,
                auxFiles: auxFiles
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
    ///   - auxFiles: Optional map of auxiliary files
    func compileToFile(source: String, outputURL: URL, fontData: Data? = nil, auxFiles: [String: Data]? = nil) async throws {
        let pdfData = try await compile(source: source, fontData: fontData, auxFiles: auxFiles)
        try pdfData.write(to: outputURL)
    }

    /// Compile from NSAttributedString and FormatTemplate
    /// - Parameters:
    ///   - attributedString: The content to compile
    ///   - template: The formatting template
    ///   - outputURL: Optional destination URL. If provided, writes to file.
    /// - Returns: PDF Data

    func compileFromAttributedString(
        _ attributedString: NSAttributedString,
        template: FormatTemplate,
        bibContent: String? = nil,
        to outputURL: URL? = nil
    ) async throws -> Data {
        // 1. Convert to Typst markup
        var typstSource = TypstConverter.toTypst(attributedString, template: template)
        
        // 1.5 Prepare Auxiliary Files (Bibliography)
        var auxFiles: [String: Data]? = nil
        
        if let bibContent = bibContent {
            // Create in-memory file
            if let bibData = bibContent.data(using: .utf8) {
                auxFiles = ["references.bib": bibData]
                
                // Inject relative path bibliography command
                typstSource += "\n\n#bibliography(\"references.bib\")"
                print("📚 Injected in-memory bibliography: references.bib")
            }
        }
        
        print("📄 Typst Source Generated:\n\(typstSource.prefix(500))...")
        
        // 2. Load bundled fonts (prioritize Noto Serif TC for Chinese)
        var fontData: Data?
        let fontNames = ["NotoSerifTC-Regular", "NotoSerifTC-Bold", "SourceHanSerifTC-Regular"]
        
        for name in fontNames {
            if let data = loadBundledFont(named: name) {
                fontData = data
                print("✅ Loaded font: \(name)")
                break
            }
        }
        
        if fontData == nil {
            print("⚠️ Warning: No bundled CJK font found. Typst rendering might fail for Chinese characters.")
        }
        
        // 3. Compile with auxiliary files
        // Note: We need to update compile() signature too
        let pdfData = try await compile(source: typstSource, fontData: fontData, auxFiles: auxFiles)
        
        // 4. Write to file if URL provided
        if let url = outputURL {
            try pdfData.write(to: url)
        }
        
        return pdfData
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
