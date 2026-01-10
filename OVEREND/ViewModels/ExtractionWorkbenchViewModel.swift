//
//  ExtractionWorkbenchViewModel.swift
//  OVEREND
//
//  AI 提取工作台 ViewModel
//

import Foundation
import CoreData
import Combine

/// AI 提取工作台 ViewModel
@MainActor
class ExtractionWorkbenchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var pendingExtractions: [ExtractionLog] = []
    @Published var currentIndex = 0
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    private var library: Library?
    
    // MARK: - Computed Properties
    
    /// 當前的 ExtractionLog
    var currentExtraction: ExtractionLog? {
        guard currentIndex >= 0 && currentIndex < pendingExtractions.count else { return nil }
        return pendingExtractions[currentIndex]
    }
    
    /// 當前 PDF 的 URL
    var currentPDF: URL? {
        guard let filePath = currentExtraction?.pdfFilePath else { return nil }
        return URL(fileURLWithPath: filePath)
    }
    
    /// 是否已完成所有項目
    var isAllCompleted: Bool {
        pendingExtractions.isEmpty || currentIndex >= pendingExtractions.count
    }
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext, library: Library? = nil) {
        self.context = context
        self.library = library
    }
    
    /// 從 PDFMetadata 添加待處理項目
    func addPendingExtraction(
        metadata: PDFMetadata,
        pdfURL: URL,
        pdfText: String?,
        logs: String?
    ) {
        let log = ExtractionLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.pdfFileName = pdfURL.lastPathComponent
        log.pdfFilePath = pdfURL.path
        log.pdfText = pdfText
        
        // 設置 AI 提取結果
        log.aiTitle = metadata.title
        log.aiAuthors = metadata.authors.joined(separator: "; ")
        log.aiYear = metadata.year
        log.aiJournal = metadata.journal
        log.aiDOI = metadata.doi
        log.aiAbstract = metadata.abstract
        log.aiVolume = metadata.volume
        log.aiPages = metadata.pages
        log.aiEntryType = metadata.entryType
        
        // 設置提取方法和信心度
        log.extractionMethod = mapStrategy(metadata.strategy)
        log.aiConfidence = mapConfidence(metadata.confidence)
        
        // 儲存原始回應（如果有）
        log.aiRawResponse = logs
        
        pendingExtractions.append(log)
        
        try? context.save()
    }
    
    // MARK: - Navigation
    
    /// 前往上一個 PDF
    func previousPDF() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }
    
    /// 前往下一個 PDF
    func nextPDF() {
        guard currentIndex < pendingExtractions.count - 1 else { return }
        currentIndex += 1
    }
    
    /// 跳過當前項目
    func skipCurrent() {
        guard let extraction = currentExtraction else { return }
        
        // 移除當前項目（但保留 log）
        pendingExtractions.remove(at: currentIndex)
        
        // 調整索引
        if currentIndex >= pendingExtractions.count && currentIndex > 0 {
            currentIndex = pendingExtractions.count - 1
        }
    }
    
    // MARK: - Data Operations
    
    /// 儲存使用者修正
    func saveCorrection(_ data: CorrectionData) {
        guard let extraction = currentExtraction else { return }
        
        extraction.userCorrectedTitle = data.title.isEmpty ? nil : data.title
        extraction.userCorrectedAuthors = data.authors.isEmpty ? nil : data.authors
        extraction.userCorrectedYear = data.year.isEmpty ? nil : data.year
        extraction.userCorrectedJournal = data.journal.isEmpty ? nil : data.journal
        extraction.userCorrectedDOI = data.doi.isEmpty ? nil : data.doi
        extraction.correctionNote = data.note.isEmpty ? nil : data.note
        extraction.needsCorrection = data.hasAnyCorrection
        
        try? context.save()
    }
    
    /// 儲存評分
    func saveRating(_ rating: Int) {
        guard let extraction = currentExtraction else { return }
        extraction.userRating = Int16(rating)
        try? context.save()
    }
    
    /// 確認並建立 Entry
    func confirmAndCreateEntry() {
        guard let extraction = currentExtraction,
              let library = self.library ?? fetchDefaultLibrary() else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // 建立 Entry
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.library = library
        
        // 使用最終值（優先使用修正值）
        entry.entryType = extraction.aiEntryType ?? "misc"
        
        // 設置欄位
        var fields: [String: String] = [
            "title": extraction.finalTitle
        ]
        
        let authors = extraction.finalAuthors
        if !authors.isEmpty {
            fields["author"] = authors.replacingOccurrences(of: "; ", with: " and ")
        }
        
        if let year = extraction.finalYear {
            fields["year"] = year
        }
        
        if let journal = extraction.finalJournal {
            fields["journal"] = journal
        }
        
        if let doi = extraction.finalDOI {
            fields["doi"] = doi
        }
        
        entry.fields = fields
        
        // 生成 Citation Key
        entry.citationKey = generateCitationKey(from: extraction)
        
        // 生成 BibTeX
        entry.bibtexRaw = entry.generateBibTeX()
        
        // 建立關聯
        entry.extractionLog = extraction
        extraction.entry = entry
        
        // 附加 PDF
        if let pdfURL = currentPDF {
            try? PDFService.addPDFAttachment(from: pdfURL, to: entry, context: context)
        }
        
        try? context.save()
        
        // 移動到下一個
        pendingExtractions.remove(at: currentIndex)
        if currentIndex >= pendingExtractions.count && currentIndex > 0 {
            currentIndex = pendingExtractions.count - 1
        }
        
        ToastManager.shared.showSuccess("成功建立書目條目")
    }
    
    // MARK: - Export
    
    /// 匯出訓練資料
    func exportTrainingData() -> URL? {
        let logs = ExtractionLog.fetchAll(context: context)
        let exportData = TrainingDataExport(from: logs)
        
        do {
            let jsonData = try exportData.toJSONData()
            
            // 建立匯出目錄
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let exportDir = documentsURL.appendingPathComponent("OVEREND_Exports", isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: exportDir.path) {
                try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
            }
            
            // 生成檔名
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "training_data_\(formatter.string(from: Date())).json"
            let fileURL = exportDir.appendingPathComponent(fileName)
            
            // 寫入檔案
            try jsonData.write(to: fileURL)
            
            return fileURL
        } catch {
            #if DEBUG
            print("匯出訓練資料失敗：\(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchDefaultLibrary() -> Library? {
        let request = Library.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            // 嘗試獲取任何一個
            let anyRequest = Library.fetchRequest()
            anyRequest.fetchLimit = 1
            return try? context.fetch(anyRequest).first
        }
    }
    
    private func generateCitationKey(from extraction: ExtractionLog) -> String {
        var key = ""
        
        // 使用第一作者的姓氏
        let authors = extraction.finalAuthors
        if !authors.isEmpty {
            let firstAuthor = authors.components(separatedBy: ";").first ?? authors
            let lastName = firstAuthor.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: " ").last ?? firstAuthor
            key = lastName.lowercased()
        }
        
        // 添加年份
        if let year = extraction.finalYear {
            key += year
        }
        
        // 添加標題的前幾個單詞
        let titleWords = extraction.finalTitle
            .components(separatedBy: .whitespaces)
            .prefix(2)
            .map { $0.lowercased() }
            .joined()
        key += titleWords
        
        // 清理非字母數字字符
        key = key.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        
        // 如果 key 太短，添加時間戳
        if key.count < 5 {
            key += "\(Int(Date().timeIntervalSince1970) % 10000)"
        }
        
        return key.isEmpty ? "entry\(Int(Date().timeIntervalSince1970))" : key
    }
    
    private func mapStrategy(_ strategy: String) -> String {
        switch strategy.lowercased() {
        case "apple intelligence": return "apple_ai"
        case "doi lookup": return "doi"
        case "regex fallback": return "regex"
        case "pdf attributes": return "pdf_attributes"
        case "filename fallback": return "filename"
        default: return strategy.lowercased().replacingOccurrences(of: " ", with: "_")
        }
    }
    
    private func mapConfidence(_ confidence: PDFMetadata.MetadataConfidence) -> String {
        switch confidence {
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        }
    }
}
