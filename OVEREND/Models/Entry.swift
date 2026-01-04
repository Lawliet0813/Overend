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
    @NSManaged public var tags: Set<Tag>?
    @NSManaged public var extractionLog: ExtractionLog?  // AI 提取日誌

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
    
    /// 星號標記狀態（儲存在 fields 中）
    var isStarred: Bool {
        get {
            fields["_starred"] == "true"
        }
        set {
            var newFields = fields
            newFields["_starred"] = newValue ? "true" : "false"
            self.fields = newFields
        }
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
            // 排除內部使用的欄位
            if !key.hasPrefix("_") {
                bib += "  \(key) = {\(value)},\n"
            }
        }

        bib += "}\n"
        return bib
    }
    
    // MARK: - 引用格式生成
    
    /// 生成 APA 7th Edition 引用格式
    func generateAPACitation() -> String {
        let authorList = formatAuthorsAPA(author)
        let yearStr = year.isEmpty ? "n.d." : "(\(year))"
        let titleStr = title
        let journalStr = fields["journal"] ?? ""
        let volumeStr = fields["volume"] ?? ""
        let issueStr = fields["number"] ?? ""
        let pagesStr = fields["pages"] ?? ""
        let doiStr = fields["doi"] ?? ""
        
        var citation = "\(authorList) \(yearStr). \(titleStr)."
        
        if !journalStr.isEmpty {
            citation += " *\(journalStr)*"
            if !volumeStr.isEmpty {
                citation += ", *\(volumeStr)*"
                if !issueStr.isEmpty {
                    citation += "(\(issueStr))"
                }
            }
            if !pagesStr.isEmpty {
                citation += ", \(pagesStr)"
            }
            citation += "."
        }
        
        if !doiStr.isEmpty {
            let doiURL = doiStr.hasPrefix("http") ? doiStr : "https://doi.org/\(doiStr)"
            citation += " \(doiURL)"
        }
        
        return citation
    }
    
    /// 生成 MLA 9th Edition 引用格式
    func generateMLACitation() -> String {
        let authorList = formatAuthorsMLA(author)
        let titleStr = "\"\(title).\""
        let journalStr = fields["journal"] ?? ""
        let volumeStr = fields["volume"] ?? ""
        let issueStr = fields["number"] ?? ""
        let yearStr = year
        let pagesStr = fields["pages"] ?? ""
        let doiStr = fields["doi"] ?? ""
        
        var citation = "\(authorList) \(titleStr)"
        
        if !journalStr.isEmpty {
            citation += " *\(journalStr)*"
            if !volumeStr.isEmpty {
                citation += ", vol. \(volumeStr)"
            }
            if !issueStr.isEmpty {
                citation += ", no. \(issueStr)"
            }
            if !yearStr.isEmpty {
                citation += ", \(yearStr)"
            }
            if !pagesStr.isEmpty {
                citation += ", pp. \(pagesStr)"
            }
            citation += "."
        }
        
        if !doiStr.isEmpty {
            let doiURL = doiStr.hasPrefix("http") ? doiStr : "https://doi.org/\(doiStr)"
            citation += " \(doiURL)."
        }
        
        return citation
    }
    
    /// 格式化作者列表（APA 格式）
    private func formatAuthorsAPA(_ authorString: String) -> String {
        let authors = authorString.components(separatedBy: " and ")
        if authors.isEmpty { return "Unknown" }
        
        let formatted = authors.enumerated().map { index, author -> String in
            let parts = author.trimmingCharacters(in: .whitespaces).components(separatedBy: ", ")
            if parts.count >= 2 {
                // 格式：姓, 名首字母.
                let lastName = parts[0]
                let firstName = parts[1]
                let initials = firstName.components(separatedBy: " ").map { String($0.prefix(1)) + "." }.joined(separator: " ")
                return "\(lastName), \(initials)"
            }
            return author
        }
        
        if formatted.count == 1 {
            return formatted[0]
        } else if formatted.count == 2 {
            return "\(formatted[0]), & \(formatted[1])"
        } else {
            let allButLast = formatted.dropLast().joined(separator: ", ")
            return "\(allButLast), & \(formatted.last!)"
        }
    }
    
    /// 格式化作者列表（MLA 格式）
    private func formatAuthorsMLA(_ authorString: String) -> String {
        let authors = authorString.components(separatedBy: " and ")
        if authors.isEmpty { return "Unknown." }
        
        if authors.count == 1 {
            return "\(authors[0].trimmingCharacters(in: .whitespaces))."
        } else if authors.count == 2 {
            return "\(authors[0].trimmingCharacters(in: .whitespaces)), and \(authors[1].trimmingCharacters(in: .whitespaces))."
        } else {
            return "\(authors[0].trimmingCharacters(in: .whitespaces)), et al."
        }
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

