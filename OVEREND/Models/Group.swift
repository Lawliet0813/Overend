//
//  Group.swift
//  OVEREND
//
//  資料夾實體（樹狀結構）- Core Data
//

import Foundation
import CoreData

@objc(Group)
public class Group: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var colorHex: String?
    @NSManaged public var iconName: String?
    @NSManaged public var orderIndex: Int16
    @NSManaged public var createdAt: Date

    // 關聯（樹狀結構）
    @NSManaged public var parent: Group?
    @NSManaged public var children: Set<Group>?

    // 關聯
    @NSManaged public var library: Library?
    @NSManaged public var entries: Set<Entry>?

    // MARK: - 計算屬性

    var childrenArray: [Group] {
        children?.sorted { $0.orderIndex < $1.orderIndex } ?? []
    }

    var entryCount: Int {
        entries?.count ?? 0
    }

    var isRootGroup: Bool {
        parent == nil
    }

    // MARK: - 便利初始化

    convenience init(
        context: NSManagedObjectContext,
        name: String,
        library: Library,
        parent: Group? = nil
    ) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.library = library
        self.parent = parent
        self.orderIndex = 0
        self.createdAt = Date()
    }
}

// MARK: - Fetch Requests

extension Group {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Group> {
        return NSFetchRequest<Group>(entityName: "Group")
    }

    /// 獲取指定庫的根資料夾
    static func fetchRootGroups(in library: Library, context: NSManagedObjectContext) -> [Group] {
        let request = fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "library == %@", library),
            NSPredicate(format: "parent == nil")
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.orderIndex, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch root groups: \\(error)")
            return []
        }
    }
}

// MARK: - Core Data Entity Description

extension Group {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Group"
        entity.managedObjectClassName = NSStringFromClass(Group.self)

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

        let iconNameAttr = NSAttributeDescription()
        iconNameAttr.name = "iconName"
        iconNameAttr.attributeType = .stringAttributeType
        iconNameAttr.isOptional = true
        properties.append(iconNameAttr)

        let orderIndexAttr = NSAttributeDescription()
        orderIndexAttr.name = "orderIndex"
        orderIndexAttr.attributeType = .integer16AttributeType
        orderIndexAttr.defaultValue = 0
        properties.append(orderIndexAttr)

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        properties.append(createdAtAttr)

        entity.properties = properties
        return entity
    }
}
