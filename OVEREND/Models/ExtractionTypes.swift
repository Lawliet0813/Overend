//
//  ExtractionTypes.swift
//  OVEREND
//
//  AI 提取相關支援類型
//

import Foundation

// MARK: - 修正資料

/// 使用者修正資料結構
struct CorrectionData {
    var title: String = ""
    var authors: String = ""
    var year: String = ""
    var journal: String = ""
    var doi: String = ""
    var rating: Int = 0
    var note: String = ""
    
    /// 是否有任何修正
    var hasAnyCorrection: Bool {
        !title.isEmpty || !authors.isEmpty || !year.isEmpty || !journal.isEmpty || !doi.isEmpty
    }
    
    /// 從 ExtractionLog 初始化（用於編輯）
    init(from log: ExtractionLog? = nil) {
        if let log = log {
            self.title = log.userCorrectedTitle ?? ""
            self.authors = log.userCorrectedAuthors ?? ""
            self.year = log.userCorrectedYear ?? ""
            self.journal = log.userCorrectedJournal ?? ""
            self.doi = log.userCorrectedDOI ?? ""
            self.rating = Int(log.userRating)
            self.note = log.correctionNote ?? ""
        }
    }
}

// MARK: - 錯誤模式分析

/// 錯誤模式
struct ErrorPattern: Identifiable {
    let id = UUID()
    let field: String           // 欄位名稱（title, authors, year, etc.）
    let aiValue: String         // AI 提取的值
    let correctValue: String    // 正確的值
    let pdfSample: String       // PDF 文字樣本（前 200 字）
    let frequency: Int          // 出現頻率
    
    /// 錯誤類型描述
    var errorType: String {
        if aiValue.isEmpty && !correctValue.isEmpty {
            return "遺漏"
        } else if !aiValue.isEmpty && correctValue.isEmpty {
            return "誤判"
        } else {
            return "錯誤"
        }
    }
}

// MARK: - Prompt 改進建議

/// Prompt 改進建議
struct PromptSuggestion: Identifiable {
    let id = UUID()
    let issue: String           // 問題描述
    let currentPrompt: String   // 當前 prompt（或部分）
    let suggestedPrompt: String // 建議的改進
    let affectedCount: Int      // 影響的樣本數
    let priority: Priority      // 優先級
    
    enum Priority: String, CaseIterable {
        case high = "高"
        case medium = "中"
        case low = "低"
        
        var color: String {
            switch self {
            case .high: return "#F44336"
            case .medium: return "#FF9800"
            case .low: return "#4CAF50"
            }
        }
    }
}

// MARK: - 匯出格式

/// 訓練資料匯出格式
struct TrainingDataExport: Codable {
    let version: String = "1.0"
    let exportDate: String
    let totalSamples: Int
    let samples: [TrainingSample]
    
    struct TrainingSample: Codable {
        let id: String
        let timestamp: String
        let pdfFileName: String?
        let pdfTextSample: String?     // 前 500 字
        let extractionMethod: String?
        
        let aiExtraction: ExtractionFields
        let correctValues: ExtractionFields
        
        let rating: Int
        let needsCorrection: Bool
        let correctionNote: String?
        
        struct ExtractionFields: Codable {
            let title: String?
            let authors: String?
            let year: String?
            let journal: String?
            let doi: String?
        }
    }
    
    /// 從 ExtractionLog 建立訓練資料
    init(from logs: [ExtractionLog]) {
        let formatter = ISO8601DateFormatter()
        self.exportDate = formatter.string(from: Date())
        self.totalSamples = logs.count
        self.samples = logs.map { log in
            TrainingSample(
                id: log.id.uuidString,
                timestamp: formatter.string(from: log.timestamp),
                pdfFileName: log.pdfFileName,
                pdfTextSample: log.pdfText.map { String($0.prefix(500)) },
                extractionMethod: log.extractionMethod,
                aiExtraction: TrainingSample.ExtractionFields(
                    title: log.aiTitle,
                    authors: log.aiAuthors,
                    year: log.aiYear,
                    journal: log.aiJournal,
                    doi: log.aiDOI
                ),
                correctValues: TrainingSample.ExtractionFields(
                    title: log.userCorrectedTitle ?? log.aiTitle,
                    authors: log.userCorrectedAuthors ?? log.aiAuthors,
                    year: log.userCorrectedYear ?? log.aiYear,
                    journal: log.userCorrectedJournal ?? log.aiJournal,
                    doi: log.userCorrectedDOI ?? log.aiDOI
                ),
                rating: Int(log.userRating),
                needsCorrection: log.needsCorrection,
                correctionNote: log.correctionNote
            )
        }
    }
    
    /// 匯出為 JSON 資料
    func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

// MARK: - 分析結果

/// 提取方法準確率
struct MethodAccuracy: Identifiable {
    let id = UUID()
    let method: String
    let displayName: String
    let totalCount: Int
    let averageRating: Double
    let correctionRate: Double  // 需要修正的比例
    
    var accuracyPercentage: Double {
        (averageRating / 5.0) * 100
    }
}

/// 分析摘要
struct AnalyticsSummary {
    let totalExtractions: Int
    let ratedExtractions: Int
    let correctedExtractions: Int
    let averageRating: Double
    let methodAccuracies: [MethodAccuracy]
    let commonErrors: [ErrorPattern]
    let suggestions: [PromptSuggestion]
    
    /// 整體準確率
    var overallAccuracy: Double {
        guard ratedExtractions > 0 else { return 0 }
        return (averageRating / 5.0) * 100
    }
    
    /// 修正率
    var correctionRate: Double {
        guard totalExtractions > 0 else { return 0 }
        return Double(correctedExtractions) / Double(totalExtractions) * 100
    }
}
