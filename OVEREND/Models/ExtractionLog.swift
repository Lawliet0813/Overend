//
//  ExtractionLog.swift
//  OVEREND
//
//  AI 提取日誌實體 - Core Data
//

import Foundation
import CoreData

@objc(ExtractionLog)
public class ExtractionLog: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    
    // 原始資料
    @NSManaged public var pdfText: String?          // PDF完整文字
    @NSManaged public var pdfFileName: String?      // 檔案名稱
    @NSManaged public var pdfFilePath: String?      // PDF 檔案路徑
    
    // AI提取結果
    @NSManaged public var aiPrompt: String?         // 使用的prompt
    @NSManaged public var aiRawResponse: String?    // AI原始回應
    @NSManaged public var extractionMethod: String? // "doi" / "apple_ai" / "regex"
    
    // 解析後的欄位
    @NSManaged public var aiTitle: String?
    @NSManaged public var aiAuthors: String?
    @NSManaged public var aiYear: String?
    @NSManaged public var aiJournal: String?
    @NSManaged public var aiDOI: String?
    @NSManaged public var aiAbstract: String?
    @NSManaged public var aiVolume: String?
    @NSManaged public var aiPages: String?
    @NSManaged public var aiEntryType: String?
    @NSManaged public var aiConfidence: String?     // "high" / "medium" / "low"
    
    // 使用者修正
    @NSManaged public var userCorrectedTitle: String?
    @NSManaged public var userCorrectedAuthors: String?
    @NSManaged public var userCorrectedYear: String?
    @NSManaged public var userCorrectedJournal: String?
    @NSManaged public var userCorrectedDOI: String?
    
    // 評估指標
    @NSManaged public var userRating: Int16         // 1-5星評分
    @NSManaged public var needsCorrection: Bool     // 是否需要修正
    @NSManaged public var correctionNote: String?   // 修正備註
    
    // 關聯
    @NSManaged public var entry: Entry?             // 關聯到最終Entry
    
    // MARK: - 便利屬性
    
    /// 最終使用的標題（優先使用修正值）
    var finalTitle: String {
        userCorrectedTitle ?? aiTitle ?? "Untitled"
    }
    
    /// 最終使用的作者
    var finalAuthors: String {
        userCorrectedAuthors ?? aiAuthors ?? ""
    }
    
    /// 最終使用的年份
    var finalYear: String? {
        userCorrectedYear ?? aiYear
    }
    
    /// 最終使用的期刊
    var finalJournal: String? {
        userCorrectedJournal ?? aiJournal
    }
    
    /// 最終使用的 DOI
    var finalDOI: String? {
        userCorrectedDOI ?? aiDOI
    }
    
    /// 是否有任何修正
    var hasCorrections: Bool {
        userCorrectedTitle != nil ||
        userCorrectedAuthors != nil ||
        userCorrectedYear != nil ||
        userCorrectedJournal != nil ||
        userCorrectedDOI != nil
    }
    
    /// 信心度枚舉
    var confidence: PDFMetadata.MetadataConfidence {
        switch aiConfidence {
        case "high": return .high
        case "medium": return .medium
        default: return .low
        }
    }
    
    /// 提取方法顯示名稱
    var extractionMethodDisplay: String {
        switch extractionMethod {
        case "apple_ai": return "Apple Intelligence"
        case "doi": return "DOI Lookup"
        case "regex": return "Regex Fallback"
        case "pdf_attributes": return "PDF Attributes"
        case "filename": return "Filename Fallback"
        default: return extractionMethod ?? "Unknown"
        }
    }
}

// MARK: - Fetch Requests

extension ExtractionLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExtractionLog> {
        return NSFetchRequest<ExtractionLog>(entityName: "ExtractionLog")
    }
    
    /// 獲取所有已評分的日誌
    static func fetchAllRated(context: NSManagedObjectContext) -> [ExtractionLog] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "userRating > 0")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractionLog.timestamp, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Failed to fetch rated extraction logs: \(error)")
            #endif
            return []
        }
    }
    
    /// 獲取所有有修正的日誌
    static func fetchAllWithCorrections(context: NSManagedObjectContext) -> [ExtractionLog] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "needsCorrection == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractionLog.timestamp, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Failed to fetch corrected extraction logs: \(error)")
            #endif
            return []
        }
    }
    
    /// 獲取所有日誌
    static func fetchAll(context: NSManagedObjectContext, limit: Int? = nil) -> [ExtractionLog] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractionLog.timestamp, ascending: false)]
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Failed to fetch extraction logs: \(error)")
            #endif
            return []
        }
    }
    
    /// 根據提取方法獲取日誌
    static func fetchByMethod(_ method: String, context: NSManagedObjectContext) -> [ExtractionLog] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "extractionMethod == %@", method)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractionLog.timestamp, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Failed to fetch extraction logs by method: \(error)")
            #endif
            return []
        }
    }
}

// MARK: - Core Data Entity Description

extension ExtractionLog {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ExtractionLog"
        entity.managedObjectClassName = NSStringFromClass(ExtractionLog.self)
        
        var properties: [NSPropertyDescription] = []
        
        // ID
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        properties.append(idAttr)
        
        // Timestamp
        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType
        timestampAttr.isOptional = false
        properties.append(timestampAttr)
        
        // 原始資料
        let pdfTextAttr = NSAttributeDescription()
        pdfTextAttr.name = "pdfText"
        pdfTextAttr.attributeType = .stringAttributeType
        pdfTextAttr.isOptional = true
        properties.append(pdfTextAttr)
        
        let pdfFileNameAttr = NSAttributeDescription()
        pdfFileNameAttr.name = "pdfFileName"
        pdfFileNameAttr.attributeType = .stringAttributeType
        pdfFileNameAttr.isOptional = true
        properties.append(pdfFileNameAttr)
        
        let pdfFilePathAttr = NSAttributeDescription()
        pdfFilePathAttr.name = "pdfFilePath"
        pdfFilePathAttr.attributeType = .stringAttributeType
        pdfFilePathAttr.isOptional = true
        properties.append(pdfFilePathAttr)
        
        // AI 提取結果
        let aiPromptAttr = NSAttributeDescription()
        aiPromptAttr.name = "aiPrompt"
        aiPromptAttr.attributeType = .stringAttributeType
        aiPromptAttr.isOptional = true
        properties.append(aiPromptAttr)
        
        let aiRawResponseAttr = NSAttributeDescription()
        aiRawResponseAttr.name = "aiRawResponse"
        aiRawResponseAttr.attributeType = .stringAttributeType
        aiRawResponseAttr.isOptional = true
        properties.append(aiRawResponseAttr)
        
        let extractionMethodAttr = NSAttributeDescription()
        extractionMethodAttr.name = "extractionMethod"
        extractionMethodAttr.attributeType = .stringAttributeType
        extractionMethodAttr.isOptional = true
        properties.append(extractionMethodAttr)
        
        // 解析後的欄位
        let aiTitleAttr = NSAttributeDescription()
        aiTitleAttr.name = "aiTitle"
        aiTitleAttr.attributeType = .stringAttributeType
        aiTitleAttr.isOptional = true
        properties.append(aiTitleAttr)
        
        let aiAuthorsAttr = NSAttributeDescription()
        aiAuthorsAttr.name = "aiAuthors"
        aiAuthorsAttr.attributeType = .stringAttributeType
        aiAuthorsAttr.isOptional = true
        properties.append(aiAuthorsAttr)
        
        let aiYearAttr = NSAttributeDescription()
        aiYearAttr.name = "aiYear"
        aiYearAttr.attributeType = .stringAttributeType
        aiYearAttr.isOptional = true
        properties.append(aiYearAttr)
        
        let aiJournalAttr = NSAttributeDescription()
        aiJournalAttr.name = "aiJournal"
        aiJournalAttr.attributeType = .stringAttributeType
        aiJournalAttr.isOptional = true
        properties.append(aiJournalAttr)
        
        let aiDOIAttr = NSAttributeDescription()
        aiDOIAttr.name = "aiDOI"
        aiDOIAttr.attributeType = .stringAttributeType
        aiDOIAttr.isOptional = true
        properties.append(aiDOIAttr)
        
        let aiAbstractAttr = NSAttributeDescription()
        aiAbstractAttr.name = "aiAbstract"
        aiAbstractAttr.attributeType = .stringAttributeType
        aiAbstractAttr.isOptional = true
        properties.append(aiAbstractAttr)
        
        let aiVolumeAttr = NSAttributeDescription()
        aiVolumeAttr.name = "aiVolume"
        aiVolumeAttr.attributeType = .stringAttributeType
        aiVolumeAttr.isOptional = true
        properties.append(aiVolumeAttr)
        
        let aiPagesAttr = NSAttributeDescription()
        aiPagesAttr.name = "aiPages"
        aiPagesAttr.attributeType = .stringAttributeType
        aiPagesAttr.isOptional = true
        properties.append(aiPagesAttr)
        
        let aiEntryTypeAttr = NSAttributeDescription()
        aiEntryTypeAttr.name = "aiEntryType"
        aiEntryTypeAttr.attributeType = .stringAttributeType
        aiEntryTypeAttr.isOptional = true
        properties.append(aiEntryTypeAttr)
        
        let aiConfidenceAttr = NSAttributeDescription()
        aiConfidenceAttr.name = "aiConfidence"
        aiConfidenceAttr.attributeType = .stringAttributeType
        aiConfidenceAttr.isOptional = true
        properties.append(aiConfidenceAttr)
        
        // 使用者修正
        let userCorrectedTitleAttr = NSAttributeDescription()
        userCorrectedTitleAttr.name = "userCorrectedTitle"
        userCorrectedTitleAttr.attributeType = .stringAttributeType
        userCorrectedTitleAttr.isOptional = true
        properties.append(userCorrectedTitleAttr)
        
        let userCorrectedAuthorsAttr = NSAttributeDescription()
        userCorrectedAuthorsAttr.name = "userCorrectedAuthors"
        userCorrectedAuthorsAttr.attributeType = .stringAttributeType
        userCorrectedAuthorsAttr.isOptional = true
        properties.append(userCorrectedAuthorsAttr)
        
        let userCorrectedYearAttr = NSAttributeDescription()
        userCorrectedYearAttr.name = "userCorrectedYear"
        userCorrectedYearAttr.attributeType = .stringAttributeType
        userCorrectedYearAttr.isOptional = true
        properties.append(userCorrectedYearAttr)
        
        let userCorrectedJournalAttr = NSAttributeDescription()
        userCorrectedJournalAttr.name = "userCorrectedJournal"
        userCorrectedJournalAttr.attributeType = .stringAttributeType
        userCorrectedJournalAttr.isOptional = true
        properties.append(userCorrectedJournalAttr)
        
        let userCorrectedDOIAttr = NSAttributeDescription()
        userCorrectedDOIAttr.name = "userCorrectedDOI"
        userCorrectedDOIAttr.attributeType = .stringAttributeType
        userCorrectedDOIAttr.isOptional = true
        properties.append(userCorrectedDOIAttr)
        
        // 評估指標
        let userRatingAttr = NSAttributeDescription()
        userRatingAttr.name = "userRating"
        userRatingAttr.attributeType = .integer16AttributeType
        userRatingAttr.isOptional = false
        userRatingAttr.defaultValue = 0
        properties.append(userRatingAttr)
        
        let needsCorrectionAttr = NSAttributeDescription()
        needsCorrectionAttr.name = "needsCorrection"
        needsCorrectionAttr.attributeType = .booleanAttributeType
        needsCorrectionAttr.isOptional = false
        needsCorrectionAttr.defaultValue = false
        properties.append(needsCorrectionAttr)
        
        let correctionNoteAttr = NSAttributeDescription()
        correctionNoteAttr.name = "correctionNote"
        correctionNoteAttr.attributeType = .stringAttributeType
        correctionNoteAttr.isOptional = true
        properties.append(correctionNoteAttr)
        
        entity.properties = properties
        return entity
    }
}
