//
//  Constants.swift
//  OVEREND
//
//  全局常量定義
//

import Foundation

enum Constants {
    // MARK: - 應用資訊
    enum App {
        static let name = "OVEREND"
        static let version = "1.0.0"
        static let buildNumber = "1"
        static let tagline = "讓研究者專注於研究本身，而不是文獻管理"
    }

    // MARK: - Core Data
    enum CoreData {
        static let modelName = "OVEREND"
        static let containerName = "OVEREND"
    }

    // MARK: - BibTeX
    enum BibTeX {
        static let supportedTypes = [
            "article", "book", "booklet", "inbook", "incollection",
            "inproceedings", "conference", "manual", "mastersthesis",
            "phdthesis", "proceedings", "techreport", "unpublished", "misc"
        ]

        static let requiredFields: [String: [String]] = [
            "article": ["author", "title", "journal", "year"],
            "book": ["author", "title", "publisher", "year"],
            "inproceedings": ["author", "title", "booktitle", "year"]
        ]
    }

    // MARK: - 檔案
    enum Files {
        static let maxPDFSize: Int64 = 50 * 1024 * 1024 // 50MB
        static let supportedFormats = ["pdf"]
        static let bibFileExtension = "bib"
    }

    // MARK: - 匯出
    enum Export {
        // PDF 設定
        static let pdfPageWidth: CGFloat = 595.0  // A4 寬度（點）
        static let pdfPageHeight: CGFloat = 842.0 // A4 高度（點）
        static let pdfMargin: CGFloat = 72.0      // 1 英寸邊距

        // DOCX 設定
        static let docxPageWidth: Int = 11906     // 約 A4 寬度（twips）
        static let docxPageHeight: Int = 16838    // 約 A4 高度（twips）
    }

    // MARK: - 搜尋
    enum Search {
        static let minQueryLength = 2
        static let maxResults = 100
    }
}
