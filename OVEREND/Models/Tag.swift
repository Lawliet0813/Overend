//
//  Tag.swift
//  OVEREND
//
//  標籤實體 - Core Data
//

import Foundation
import CoreData
import SwiftUI

@objc(Tag)
public class Tag: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var colorHex: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    // 關聯
    @NSManaged public var library: Library?
    @NSManaged public var entries: Set<Entry>?

    // MARK: - 計算屬性

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var entryCount: Int {
        entries?.count ?? 0
    }

    // MARK: - 便利初始化

    convenience init(
        context: NSManagedObjectContext,
        name: String,
        colorHex: String = "#007AFF",
        library: Library
    ) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.library = library
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Fetch Requests

extension Tag {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    /// 獲取指定庫的所有標籤
    static func fetchAll(in library: Library, context: NSManagedObjectContext) -> [Tag] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "library == %@", library)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Failed to fetch tags: \(error)")
            #endif
            return []
        }
    }
}

// MARK: - Core Data Entity Description

extension Tag {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Tag"
        entity.managedObjectClassName = NSStringFromClass(Tag.self)

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
        colorHexAttr.isOptional = false
        colorHexAttr.defaultValue = "#007AFF"
        properties.append(colorHexAttr)

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


