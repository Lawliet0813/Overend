//
//  Attachment.swift
//  OVEREND
//
//  PDF 附件實體 - Core Data
//

import Foundation
import CoreData

@objc(Attachment)
public class Attachment: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var fileName: String
    @NSManaged public var filePath: String
    @NSManaged public var fileSize: Int64
    @NSManaged public var mimeType: String
    @NSManaged public var pageCount: Int16
    @NSManaged public var extractedText: String?
    @NSManaged public var createdAt: Date

    // 關聯
    @NSManaged public var entry: Entry?

    // MARK: - 計算屬性

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    // MARK: - 便利初始化

    convenience init(
        context: NSManagedObjectContext,
        fileName: String,
        filePath: String,
        entry: Entry
    ) {
        self.init(context: context)
        self.id = UUID()
        self.fileName = fileName
        self.filePath = filePath
        self.mimeType = "application/pdf"
        self.entry = entry
        self.createdAt = Date()

        // 計算文件大小
        if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
           let size = attributes[.size] as? Int64 {
            self.fileSize = size
        }
    }
}

// MARK: - Fetch Requests

extension Attachment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment")
    }
}

// MARK: - Core Data Entity Description

extension Attachment {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Attachment"
        entity.managedObjectClassName = NSStringFromClass(Attachment.self)

        var properties: [NSPropertyDescription] = []

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        properties.append(idAttr)

        let fileNameAttr = NSAttributeDescription()
        fileNameAttr.name = "fileName"
        fileNameAttr.attributeType = .stringAttributeType
        fileNameAttr.isOptional = false
        properties.append(fileNameAttr)

        let filePathAttr = NSAttributeDescription()
        filePathAttr.name = "filePath"
        filePathAttr.attributeType = .stringAttributeType
        filePathAttr.isOptional = false
        properties.append(filePathAttr)

        let fileSizeAttr = NSAttributeDescription()
        fileSizeAttr.name = "fileSize"
        fileSizeAttr.attributeType = .integer64AttributeType
        fileSizeAttr.defaultValue = 0
        properties.append(fileSizeAttr)

        let mimeTypeAttr = NSAttributeDescription()
        mimeTypeAttr.name = "mimeType"
        mimeTypeAttr.attributeType = .stringAttributeType
        mimeTypeAttr.isOptional = false
        properties.append(mimeTypeAttr)

        let pageCountAttr = NSAttributeDescription()
        pageCountAttr.name = "pageCount"
        pageCountAttr.attributeType = .integer16AttributeType
        pageCountAttr.defaultValue = 0
        properties.append(pageCountAttr)

        let extractedTextAttr = NSAttributeDescription()
        extractedTextAttr.name = "extractedText"
        extractedTextAttr.attributeType = .stringAttributeType
        extractedTextAttr.isOptional = true
        properties.append(extractedTextAttr)

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        properties.append(createdAtAttr)

        entity.properties = properties
        return entity
    }
}
