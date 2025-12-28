//
//  Document.swift
//  OVEREND
//
//  論文文檔實體 - Core Data
//

import Foundation
import CoreData
#if canImport(AppKit)
import AppKit
#endif

@objc(Document)
public class Document: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var rtfData: Data?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    // 關聯的引用（用於生成參考文獻）
    @NSManaged public var citations: Set<Entry>?

    // MARK: - 計算屬性

#if canImport(AppKit)
    /// NSAttributedString 表示
    var attributedString: NSAttributedString {
        get {
            guard let data = rtfData else {
                return NSAttributedString(string: "")
            }

            do {
                return try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
            } catch {
                print("Failed to load RTF: \\(error)")
                return NSAttributedString(string: "")
            }
        }
        set {
            do {
                let data = try newValue.data(
                    from: NSRange(location: 0, length: newValue.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
                rtfData = data
                updatedAt = Date()
            } catch {
                print("Failed to save RTF: \\(error)")
            }
        }
    }
#endif

    var citationArray: [Entry] {
        citations?.sorted { $0.citationKey < $1.citationKey } ?? []
    }

    // MARK: - 便利初始化

    convenience init(context: NSManagedObjectContext, title: String) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Fetch Requests

extension Document {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }

    /// 獲取所有文檔，按更新時間排序
    static func fetchAll(in context: NSManagedObjectContext) -> [Document] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch documents: \\(error)")
            return []
        }
    }
}

// MARK: - Core Data Entity Description

extension Document {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Document"
        entity.managedObjectClassName = NSStringFromClass(Document.self)

        var properties: [NSPropertyDescription] = []

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        properties.append(idAttr)

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = false
        properties.append(titleAttr)

        let rtfDataAttr = NSAttributeDescription()
        rtfDataAttr.name = "rtfData"
        rtfDataAttr.attributeType = .binaryDataAttributeType
        rtfDataAttr.isOptional = true
        rtfDataAttr.allowsExternalBinaryDataStorage = true
        properties.append(rtfDataAttr)

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        properties.append(createdAtAttr)

        let updatedAtAttr = NSAttributeDescription()
        updatedAtAttr.name = "updatedAt"
        updatedAtAttr.attributeType = .dateAttributeType
        updatedAtAttr.isOptional = false
        properties.append(updatedAtAttr)

        entity.properties = properties
        return entity
    }
}
