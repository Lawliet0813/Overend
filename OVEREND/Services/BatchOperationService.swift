//
//  BatchOperationService.swift
//  OVEREND
//
//  批次操作服務 - 提供文獻批次處理功能
//

import Foundation
import CoreData

// MARK: - 批次操作類型

/// 批次操作類型
enum BatchAction: String, CaseIterable, Identifiable {
    case delete = "刪除"
    case changeType = "修改類型"
    case addToGroup = "加入群組"
    case addTags = "新增標籤"
    case removeTags = "移除標籤"
    case exportBibTeX = "匯出 BibTeX"
    case reExtractMetadata = "重新提取元數據"
    case validateCompleteness = "驗證完整性"
    case toggleStar = "切換星號"
    
    var id: String { rawValue }
    
    /// 圖示
    var icon: String {
        switch self {
        case .delete: return "trash"
        case .changeType: return "arrow.triangle.2.circlepath"
        case .addToGroup: return "folder.badge.plus"
        case .addTags: return "tag"
        case .removeTags: return "tag.slash"
        case .exportBibTeX: return "square.and.arrow.up"
        case .reExtractMetadata: return "wand.and.stars"
        case .validateCompleteness: return "checkmark.shield"
        case .toggleStar: return "star"
        }
    }
    
    /// 是否為破壞性操作
    var isDestructive: Bool {
        switch self {
        case .delete, .removeTags:
            return true
        default:
            return false
        }
    }
    
    /// 是否需要額外參數
    var requiresParameter: Bool {
        switch self {
        case .changeType, .addToGroup, .addTags, .removeTags:
            return true
        default:
            return false
        }
    }
}

// MARK: - 批次操作服務

/// 批次操作服務
class BatchOperationService {
    
    // MARK: - 類型定義
    
    /// 操作結果
    struct OperationResult {
        let successCount: Int
        let failureCount: Int
        let errors: [String]
        let message: String
        
        var isSuccess: Bool { failureCount == 0 }
    }
    
    /// 驗證結果
    struct ValidationResult {
        let entry: Entry
        let isComplete: Bool
        let missingFields: [String]
    }
    
    // MARK: - 批次刪除
    
    /// 批次刪除文獻
    static func batchDelete(
        entries: [Entry],
        context: NSManagedObjectContext
    ) throws -> OperationResult {
        var successCount = 0
        var errors: [String] = []
        
        for entry in entries {
            do {
                // 刪除附件
                if let attachments = entry.attachments {
                    for attachment in attachments {
                        try? PDFService.deleteAttachment(attachment, context: context)
                    }
                }
                
                context.delete(entry)
                successCount += 1
            } catch {
                errors.append("刪除 \(entry.title) 失敗：\(error.localizedDescription)")
            }
        }
        
        try context.save()
        
        return OperationResult(
            successCount: successCount,
            failureCount: entries.count - successCount,
            errors: errors,
            message: "已刪除 \(successCount) 篇文獻"
        )
    }
    
    // MARK: - 批次修改類型
    
    /// 批次修改書目類型
    static func batchChangeType(
        entries: [Entry],
        newType: String,
        context: NSManagedObjectContext
    ) throws -> OperationResult {
        guard Constants.BibTeX.supportedTypes.contains(newType) else {
            return OperationResult(
                successCount: 0,
                failureCount: entries.count,
                errors: ["不支援的書目類型：\(newType)"],
                message: "操作失敗"
            )
        }
        
        for entry in entries {
            entry.entryType = newType
            entry.bibtexRaw = entry.generateBibTeX()
            entry.updatedAt = Date()
        }
        
        try context.save()
        
        return OperationResult(
            successCount: entries.count,
            failureCount: 0,
            errors: [],
            message: "已將 \(entries.count) 篇文獻類型改為 \(newType)"
        )
    }
    
    // MARK: - 批次加入群組
    
    /// 批次加入群組
    static func batchAddToGroup(
        entries: [Entry],
        group: Group,
        context: NSManagedObjectContext
    ) throws -> OperationResult {
        for entry in entries {
            var currentGroups = entry.groups ?? Set<Group>()
            currentGroups.insert(group)
            entry.groups = currentGroups
            entry.updatedAt = Date()
        }
        
        try context.save()
        
        return OperationResult(
            successCount: entries.count,
            failureCount: 0,
            errors: [],
            message: "已將 \(entries.count) 篇文獻加入「\(group.name)」"
        )
    }
    
    // MARK: - 批次新增標籤
    
    /// 批次新增標籤
    static func batchAddTags(
        entries: [Entry],
        tags: [Tag],
        context: NSManagedObjectContext
    ) throws -> OperationResult {
        for entry in entries {
            var currentTags = entry.tags ?? Set<Tag>()
            for tag in tags {
                currentTags.insert(tag)
            }
            entry.tags = currentTags
            entry.updatedAt = Date()
        }
        
        try context.save()
        
        let tagNames = tags.map { $0.name }.joined(separator: "、")
        return OperationResult(
            successCount: entries.count,
            failureCount: 0,
            errors: [],
            message: "已為 \(entries.count) 篇文獻新增標籤：\(tagNames)"
        )
    }
    
    /// 批次移除標籤
    static func batchRemoveTags(
        entries: [Entry],
        tags: [Tag],
        context: NSManagedObjectContext
    ) throws -> OperationResult {
        for entry in entries {
            var currentTags = entry.tags ?? Set<Tag>()
            for tag in tags {
                currentTags.remove(tag)
            }
            entry.tags = currentTags
            entry.updatedAt = Date()
        }
        
        try context.save()
        
        return OperationResult(
            successCount: entries.count,
            failureCount: 0,
            errors: [],
            message: "已從 \(entries.count) 篇文獻移除標籤"
        )
    }
    
    // MARK: - 批次匯出 BibTeX
    
    /// 批次匯出 BibTeX
    static func batchExportBibTeX(
        entries: [Entry],
        to url: URL
    ) throws -> OperationResult {
        let bibContent = BibTeXGenerator.generate(from: entries)
        try bibContent.write(to: url, atomically: true, encoding: .utf8)
        
        return OperationResult(
            successCount: entries.count,
            failureCount: 0,
            errors: [],
            message: "已匯出 \(entries.count) 篇文獻至 \(url.lastPathComponent)"
        )
    }
    
    /// 生成 BibTeX 字串（不寫入檔案）
    static func generateBibTeXString(entries: [Entry]) -> String {
        return BibTeXGenerator.generate(from: entries)
    }
    
    // MARK: - 批次匯出 RIS
    
    /// 批次匯出 RIS
    static func batchExportRIS(
        entries: [Entry],
        to url: URL
    ) throws -> OperationResult {
        let risContent = generateRISString(entries: entries)
        try risContent.write(to: url, atomically: true, encoding: .utf8)
        
        return OperationResult(
            successCount: entries.count,
            failureCount: 0,
            errors: [],
            message: "已匯出 \(entries.count) 篇文獻至 \(url.lastPathComponent)"
        )
    }
    
    /// 生成 RIS 字串（不寫入檔案）
    static func generateRISString(entries: [Entry]) -> String {
        var risContent = ""
        
        for entry in entries {
            risContent += generateRISEntry(entry: entry)
            risContent += "\n"
        }
        
        return risContent
    }
    
    /// 生成單個 RIS 條目
    private static func generateRISEntry(entry: Entry) -> String {
        var ris = ""
        
        // 類型對應
        let risType: String
        switch entry.entryType.lowercased() {
        case "article":
            risType = "JOUR"
        case "book":
            risType = "BOOK"
        case "inproceedings":
            risType = "CONF"
        case "phdthesis":
            risType = "THES"
        case "mastersthesis":
            risType = "THES"
        case "techreport":
            risType = "RPRT"
        default:
            risType = "GEN"
        }
        
        ris += "TY  - \(risType)\n"
        
        // 標題
        if let title = entry.fields["title"], !title.isEmpty {
            ris += "TI  - \(title)\n"
        }
        
        // 作者
        if let authors = entry.fields["author"], !authors.isEmpty {
            let authorList = authors.components(separatedBy: " and ")
            for author in authorList {
                let trimmed = author.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    ris += "AU  - \(trimmed)\n"
                }
            }
        }
        
        // 年份
        if let year = entry.fields["year"], !year.isEmpty {
            ris += "PY  - \(year)\n"
        }
        
        // 期刊/會議/書名
        if let journal = entry.fields["journal"], !journal.isEmpty {
            ris += "JO  - \(journal)\n"
        } else if let booktitle = entry.fields["booktitle"], !booktitle.isEmpty {
            ris += "JO  - \(booktitle)\n"
        }
        
        // 卷號
        if let volume = entry.fields["volume"], !volume.isEmpty {
            ris += "VL  - \(volume)\n"
        }
        
        // 期號
        if let issue = entry.fields["number"] ?? entry.fields["issue"], !issue.isEmpty {
            ris += "IS  - \(issue)\n"
        }
        
        // 頁碼
        if let pages = entry.fields["pages"], !pages.isEmpty {
            let pageComponents = pages.components(separatedBy: "-")
            ris += "SP  - \(pageComponents.first ?? pages)\n"
            if pageComponents.count > 1 {
                ris += "EP  - \(pageComponents.last ?? "")\n"
            }
        }
        
        // 出版商
        if let publisher = entry.fields["publisher"], !publisher.isEmpty {
            ris += "PB  - \(publisher)\n"
        }
        
        // DOI
        if let doi = entry.fields["doi"], !doi.isEmpty {
            ris += "DO  - \(doi)\n"
        }
        
        // URL
        if let url = entry.fields["url"], !url.isEmpty {
            ris += "UR  - \(url)\n"
        }
        
        // 摘要
        if let abstract = entry.fields["abstract"], !abstract.isEmpty {
            ris += "AB  - \(abstract)\n"
        }
        
        // 關鍵字
        if let keywords = entry.fields["keywords"], !keywords.isEmpty {
            ris += "KW  - \(keywords)\n"
        }
        
        ris += "ER  - \n"
        
        return ris
    }
    
    // MARK: - 批次驗證完整性
    
    /// 批次驗證書目完整性
    static func batchValidateCompleteness(
        entries: [Entry]
    ) -> [ValidationResult] {
        return entries.map { entry in
            let requiredFields = Constants.BibTeX.requiredFields[entry.entryType] ?? []
            let missingFields = requiredFields.filter { field in
                let value = entry.fields[field] ?? ""
                return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            return ValidationResult(
                entry: entry,
                isComplete: missingFields.isEmpty,
                missingFields: missingFields
            )
        }
    }
    
    /// 篩選不完整的書目
    static func filterIncompleteEntries(
        from results: [ValidationResult]
    ) -> [ValidationResult] {
        return results.filter { !$0.isComplete }
    }
    
    // MARK: - 批次切換星號
    
    /// 批次切換星號標記
    static func batchToggleStar(
        entries: [Entry],
        setStarred: Bool,
        context: NSManagedObjectContext
    ) throws -> OperationResult {
        for entry in entries {
            entry.isStarred = setStarred
            entry.updatedAt = Date()
        }
        
        try context.save()
        
        let action = setStarred ? "標記星號" : "移除星號"
        return OperationResult(
            successCount: entries.count,
            failureCount: 0,
            errors: [],
            message: "已為 \(entries.count) 篇文獻\(action)"
        )
    }
    
    // MARK: - 批次重新提取元數據
    
    /// 批次重新提取元數據（異步）
    @available(macOS 26.0, *)
    static func batchReExtractMetadata(
        entries: [Entry],
        context: NSManagedObjectContext,
        progressHandler: @escaping (Int, Int) -> Void
    ) async throws -> OperationResult {
        var successCount = 0
        var errors: [String] = []
        let aiService = UnifiedAIService.shared
        
        for (index, entry) in entries.enumerated() {
            progressHandler(index + 1, entries.count)
            
            // 檢查是否有 PDF 附件
            guard let pdfAttachment = entry.attachments?.first(where: { $0.mimeType == "application/pdf" }) else {
                errors.append("\(entry.title): 無 PDF 附件")
                continue
            }
            
            do {
                // 提取 PDF 文字
                let pdfURL = URL(fileURLWithPath: pdfAttachment.filePath)
                let (_, extractedText) = try PDFService.extractPDFMetadata(from: pdfURL)
                
                guard let pdfText = extractedText, !pdfText.isEmpty else {
                    errors.append("\(entry.title): 無法提取文字")
                    continue
                }
                
                // 使用 AI 提取元數據
                let metadata = try await aiService.document.extractMetadata(from: pdfText)
                
                // 更新欄位（只填補空缺）
                var updatedFields = entry.fields
                
                if let title = metadata.title, !title.isEmpty,
                   (updatedFields["title"]?.isEmpty ?? true) {
                    updatedFields["title"] = title
                }
                
                if !metadata.authors.isEmpty,
                   (updatedFields["author"]?.isEmpty ?? true) {
                    updatedFields["author"] = metadata.authorsBibTeX
                }
                
                if let year = metadata.year,
                   (updatedFields["year"]?.isEmpty ?? true) {
                    updatedFields["year"] = year
                }
                
                if let journal = metadata.journal,
                   (updatedFields["journal"]?.isEmpty ?? true) {
                    updatedFields["journal"] = journal
                }
                
                if let doi = metadata.doi,
                   (updatedFields["doi"]?.isEmpty ?? true) {
                    updatedFields["doi"] = doi
                }
                
                entry.fields = updatedFields
                entry.bibtexRaw = entry.generateBibTeX()
                entry.updatedAt = Date()
                
                successCount += 1
            } catch {
                errors.append("\(entry.title): \(error.localizedDescription)")
            }
        }
        
        try context.save()
        
        return OperationResult(
            successCount: successCount,
            failureCount: entries.count - successCount,
            errors: errors,
            message: "已重新提取 \(successCount) 篇文獻的元數據"
        )
    }
}


// MARK: - 擴展：統計資訊

extension BatchOperationService {
    
    /// 批次操作統計
    struct BatchStatistics {
        let totalCount: Int
        let typeDistribution: [String: Int]
        let yearDistribution: [String: Int]
        let withPDFCount: Int
        let withDOICount: Int
        let starredCount: Int
        let incompleteCount: Int
    }
    
    /// 計算選中書目的統計資訊
    static func calculateStatistics(for entries: [Entry]) -> BatchStatistics {
        var typeDistribution: [String: Int] = [:]
        var yearDistribution: [String: Int] = [:]
        var withPDFCount = 0
        var withDOICount = 0
        var starredCount = 0
        var incompleteCount = 0
        
        for entry in entries {
            // 類型分佈
            typeDistribution[entry.entryType, default: 0] += 1
            
            // 年份分佈
            if let year = entry.fields["year"], !year.isEmpty {
                yearDistribution[year, default: 0] += 1
            }
            
            // PDF 統計
            if entry.hasPDF {
                withPDFCount += 1
            }
            
            // DOI 統計
            if let doi = entry.fields["doi"], !doi.isEmpty {
                withDOICount += 1
            }
            
            // 星號統計
            if entry.isStarred {
                starredCount += 1
            }
            
            // 完整性統計
            let requiredFields = Constants.BibTeX.requiredFields[entry.entryType] ?? []
            let isComplete = requiredFields.allSatisfy { field in
                let value = entry.fields[field] ?? ""
                return !value.isEmpty
            }
            if !isComplete {
                incompleteCount += 1
            }
        }
        
        return BatchStatistics(
            totalCount: entries.count,
            typeDistribution: typeDistribution,
            yearDistribution: yearDistribution,
            withPDFCount: withPDFCount,
            withDOICount: withDOICount,
            starredCount: starredCount,
            incompleteCount: incompleteCount
        )
    }
}
