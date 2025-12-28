//
//  Entry.swift
//  OVEREND
//
//  BibTeX 條目實體 - Core Data
//

import Foundation
import CoreData

@objc(Entry)
public class Entry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var citationKey: String
    @NSManaged public var entryType: String
    @NSManaged public var fieldsJSON: String
    @NSManaged public var bibtexRaw: String
    @NSManaged public var userNotes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    // 關聯
    @NSManaged public var library: Library?
    @NSManaged public var groups: Set<Group>?
    @NSManaged public var attachments: Set<Attachment>?

    // MARK: - 計算屬性

    /// 解析後的 BibTeX 字段
    var fields: [String: String] {
        get {
            guard let data = fieldsJSON.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: data, encoding: .utf8) {
                fieldsJSON = jsonString
                updatedAt = Date()
            }
        }
    }

    /// 標題
    var title: String {
        fields["title"] ?? "Untitled"
    }

    /// 作者
    var author: String {
        fields["author"] ?? "Unknown"
    }

    /// 年份
    var year: String {
        fields["year"] ?? ""
    }

    /// 期刊或出版社
    var publication: String {
        fields["journal"] ?? fields["booktitle"] ?? fields["publisher"] ?? ""
    }

    // MARK: - 便利初始化

    convenience init(
        context: NSManagedObjectContext,
        citationKey: String,
        entryType: String,
        fields: [String: String],
        library: Library
    ) {
        self.init(context: context)
        self.id = UUID()
        self.citationKey = citationKey
        self.entryType = entryType
        self.fields = fields
        self.library = library
        self.createdAt = Date()
        self.updatedAt = Date()

        // 生成原始 BibTeX
        self.bibtexRaw = generateBibTeX()
    }

    // MARK: - BibTeX 生成

    /// 生成 BibTeX 格式字符串
    func generateBibTeX() -> String {
        var bib = "@\(entryType){\(citationKey),\n"

        for element in fields.sorted(by: { $0.key < $1.key }) {
            let key = element.key
            let value = element.value
            bib += "  \(key) = {\(value)},\n"
        }

        bib += "}\n"
        return bib
    }

    /// 更新字段並重新生成 BibTeX
    func updateFields(_ newFields: [String: String]) {
        self.fields = newFields
        self.bibtexRaw = generateBibTeX()
        self.updatedAt = Date()
    }

    // MARK: - 附件管理

    var attachmentArray: [Attachment] {
        attachments?.sorted { $0.createdAt < $1.createdAt } ?? []
    }

    var hasPDF: Bool {
        attachmentArray.contains { $0.mimeType == "application/pdf" }
    }
}

// MARK: - Fetch Requests

extension Entry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        return NSFetchRequest<Entry>(entityName: "Entry")
    }

    /// 獲取指定庫的所有條目
    static func fetchAll(
        in library: Library,
        sortBy: SortOption = .updated,
        context: NSManagedObjectContext
    ) -> [Entry] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "library == %@", library)
        request.sortDescriptors = sortBy.sortDescriptors

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch entries: \(error)")
            return []
        }
    }

    /// 搜尋條目
    static func search(
        query: String,
        in library: Library,
        context: NSManagedObjectContext
    ) -> [Entry] {
        guard query.count >= Constants.Search.minQueryLength else { return [] }

        let request = fetchRequest()
        let libraryPredicate = NSPredicate(format: "library == %@", library)
        let searchPredicate = NSPredicate(
            format: "citationKey CONTAINS[cd] %@ OR bibtexRaw CONTAINS[cd] %@ OR userNotes CONTAINS[cd] %@",
            query, query, query
        )

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            libraryPredicate,
            searchPredicate
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)]
        request.fetchLimit = Constants.Search.maxResults

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to search entries: \(error)")
            return []
        }
    }

    /// 根據 Citation Key 查找
    static func find(byCitationKey key: String, in context: NSManagedObjectContext) -> Entry? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "citationKey == %@", key)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to find entry: \(error)")
            return nil
        }
    }

    // MARK: - 排序選項

    enum SortOption {
        case title
        case author
        case year
        case created
        case updated

        var sortDescriptors: [NSSortDescriptor] {
            switch self {
            case .title:
                return [NSSortDescriptor(keyPath: \Entry.fieldsJSON, ascending: true)]
            case .author:
                return [NSSortDescriptor(keyPath: \Entry.fieldsJSON, ascending: true)]
            case .year:
                return [NSSortDescriptor(keyPath: \Entry.fieldsJSON, ascending: false)]
            case .created:
                return [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
            case .updated:
                return [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)]
            }
        }
    }
}

// MARK: - Core Data Entity Description

extension Entry {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Entry"
        entity.managedObjectClassName = NSStringFromClass(Entry.self)

        var properties: [NSPropertyDescription] = []

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        properties.append(idAttr)

        let citationKeyAttr = NSAttributeDescription()
        citationKeyAttr.name = "citationKey"
        citationKeyAttr.attributeType = .stringAttributeType
        citationKeyAttr.isOptional = false
        properties.append(citationKeyAttr)

        let entryTypeAttr = NSAttributeDescription()
        entryTypeAttr.name = "entryType"
        entryTypeAttr.attributeType = .stringAttributeType
        entryTypeAttr.isOptional = false
        properties.append(entryTypeAttr)

        let fieldsJSONAttr = NSAttributeDescription()
        fieldsJSONAttr.name = "fieldsJSON"
        fieldsJSONAttr.attributeType = .stringAttributeType
        fieldsJSONAttr.isOptional = false
        fieldsJSONAttr.defaultValue = "{}"
        properties.append(fieldsJSONAttr)

        let bibtexRawAttr = NSAttributeDescription()
        bibtexRawAttr.name = "bibtexRaw"
        bibtexRawAttr.attributeType = .stringAttributeType
        bibtexRawAttr.isOptional = false
        properties.append(bibtexRawAttr)

        let userNotesAttr = NSAttributeDescription()
        userNotesAttr.name = "userNotes"
        userNotesAttr.attributeType = .stringAttributeType
        userNotesAttr.isOptional = true
        properties.append(userNotesAttr)

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

