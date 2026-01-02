//
//  Library.swift
//  OVEREND
//
//  文獻庫實體 - Core Data
//

import Foundation
import CoreData

@objc(Library)
public class Library: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var colorHex: String?
    @NSManaged public var isDefault: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    // 關聯
    @NSManaged public var entries: Set<Entry>?
    @NSManaged public var groups: Set<Group>?
    @NSManaged public var tags: Set<Tag>?

    // MARK: - 便利初始化

    convenience init(context: NSManagedObjectContext, name: String, isDefault: Bool = false) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 屬性更新

    func update(name: String? = nil, colorHex: String? = nil) {
        if let name = name {
            self.name = name
        }
        if let colorHex = colorHex {
            self.colorHex = colorHex
        }
        self.updatedAt = Date()
    }

    // MARK: - 統計資訊

    var entryCount: Int {
        entries?.count ?? 0
    }

    var groupCount: Int {
        groups?.count ?? 0
    }
}

// MARK: - Fetch Requests

extension Library {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Library> {
        return NSFetchRequest<Library>(entityName: "Library")
    }

    /// 獲取所有庫，按名稱排序
    static func fetchAll(in context: NSManagedObjectContext) -> [Library] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Library.name, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch libraries: \\(error)")
            return []
        }
    }

    /// 獲取默認庫
    static func fetchDefault(in context: NSManagedObjectContext) -> Library? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch default library: \\(error)")
            return nil
        }
    }

    /// 創建或獲取默認庫
    static func getOrCreateDefault(in context: NSManagedObjectContext) -> Library {
        if let existing = fetchDefault(in: context) {
            return existing
        }

        let library = Library(context: context, name: "我的文獻庫", isDefault: true)
        try? context.save()
        return library
    }
}

// MARK: - Core Data Entity Description

extension Library {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Library"
        entity.managedObjectClassName = NSStringFromClass(Library.self)

        // 屬性
        var properties: [NSPropertyDescription] = []

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        properties.append(idAttr)

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        properties.append(nameAttr)

        let colorHexAttr = NSAttributeDescription()
        colorHexAttr.name = "colorHex"
        colorHexAttr.attributeType = .stringAttributeType
        colorHexAttr.isOptional = true
        properties.append(colorHexAttr)

        let isDefaultAttr = NSAttributeDescription()
        isDefaultAttr.name = "isDefault"
        isDefaultAttr.attributeType = .booleanAttributeType
        isDefaultAttr.defaultValue = false
        properties.append(isDefaultAttr)

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

        // 關聯將在設置模型時配置
        entity.properties = properties

        return entity
    }
}
