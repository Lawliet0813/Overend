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
        /// 支援的書目類型（24 種）
        static let supportedTypes = [
            // 原有 14 種
            "article", "book", "booklet", "inbook", "incollection",
            "inproceedings", "conference", "manual", "mastersthesis",
            "phdthesis", "proceedings", "techreport", "unpublished", "misc",
            // 新增 10 種高優先級類型
            "webpage", "website", "online",      // 網路資源
            "dataset", "software", "preprint",   // 數位/學術資源
            "report", "patent", "standard", "video"  // 其他
        ]

        /// 必填欄位（14 種類型有驗證）
        static let requiredFields: [String: [String]] = [
            // 學術論文
            "article": ["author", "title", "journal", "year"],
            "inproceedings": ["author", "title", "booktitle", "year"],
            "phdthesis": ["author", "title", "school", "year"],
            "mastersthesis": ["author", "title", "school", "year"],
            "techreport": ["author", "title", "institution", "year"],
            "preprint": ["author", "title", "year"],
            // 書籍
            "book": ["author", "title", "publisher", "year"],
            "incollection": ["author", "title", "booktitle", "publisher", "year"],
            "inbook": ["author", "title", "publisher", "year"],
            // 網路資源
            "webpage": ["title", "url"],
            "website": ["title", "url"],
            "online": ["title", "url"],
            // 數位資源
            "dataset": ["author", "title", "year"],
            "software": ["author", "title"],
            // 其他
            "manual": ["title"],
            "proceedings": ["title", "year"],
            "report": ["author", "title", "institution", "year"],
            "patent": ["author", "title", "number", "year"],
            "standard": ["title", "organization", "year"]
        ]
        
        /// A 級核心欄位（立即需要）
        static let coreFields = [
            "title", "author", "year", "journal", "booktitle", "publisher",
            "volume", "number", "pages", "doi", "url", "abstract", "keywords", "language"
        ]
        
        /// 中文支援欄位
        static let chineseFields = [
            "title_zh", "author_zh", "abstract_zh", "institution_zh"
        ]
        
        /// 識別碼欄位
        static let identifierFields = [
            "doi", "isbn", "issn", "pmid", "arxiv", "url"
        ]
        
        /// 論文特有欄位（台灣學術需求）
        static let thesisFields = [
            "school", "advisor", "degree", "department"
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
