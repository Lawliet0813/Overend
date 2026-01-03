//
//  GroupRepository.swift
//  OVEREND
//
//  Group 實體的資料存取層（支援樹狀結構）
//

import Foundation
import CoreData

// MARK: - Group Repository Protocol

protocol GroupRepositoryProtocol: CRUDRepository where Entity == Group {
    /// 獲取指定庫的根資料夾
    func fetchRootGroups(in library: Library) async throws -> [Group]

    /// 獲取指定父資料夾的子資料夾
    func fetchChildren(of parent: Group) async throws -> [Group]

    /// 創建新資料夾
    func create(
        name: String,
        library: Library,
        parent: Group?
    ) async throws -> Group

    /// 更新資料夾資訊
    func update(
        _ group: Group,
        name: String?,
        colorHex: String?,
        iconName: String?
    ) throws

    /// 移動資料夾
    func move(_ group: Group, to parent: Group?) throws

    /// 重新排序
    func reorder(_ groups: [Group]) throws
}

// MARK: - Group Repository Implementation

final class GroupRepository: BaseRepository<Group>, GroupRepositoryProtocol {

    // MARK: - Fetch Operations

    override func createFetchRequest() -> NSFetchRequest<Group> {
        let request = Group.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.orderIndex, ascending: true)]
        return request
    }

    func fetchAll() async throws -> [Group] {
        let request = createFetchRequest()
        return try await executeFetchRequest(request)
    }

    func fetch(byId id: UUID) async throws -> Group? {
        let request = createFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let results = try await executeFetchRequest(request)
        return results.first
    }

    func fetchRootGroups(in library: Library) async throws -> [Group] {
        let request = createFetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "library == %@", library),
            NSPredicate(format: "parent == nil")
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.orderIndex, ascending: true)]

        return try await executeFetchRequest(request)
    }

    func fetchChildren(of parent: Group) async throws -> [Group] {
        let request = createFetchRequest()
        request.predicate = NSPredicate(format: "parent == %@", parent)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.orderIndex, ascending: true)]

        return try await executeFetchRequest(request)
    }

    // MARK: - Create Operations

    @discardableResult
    func create() -> Group {
        let group = Group(context: context)
        group.id = UUID()
        group.name = "新資料夾"
        group.orderIndex = 0
        group.createdAt = Date()
        return group
    }

    func create(
        name: String,
        library: Library,
        parent: Group? = nil
    ) async throws -> Group {
        return try await context.perform {
            let group = Group(context: self.context)
            group.id = UUID()
            group.name = name
            group.library = library
            group.parent = parent
            group.orderIndex = 0
            group.createdAt = Date()

            try self.save()
            return group
        }
    }

    // MARK: - Update Operations

    func update(_ group: Group) throws {
        try save()
    }

    func update(
        _ group: Group,
        name: String? = nil,
        colorHex: String? = nil,
        iconName: String? = nil
    ) throws {
        if let name = name {
            group.name = name
        }
        if let colorHex = colorHex {
            group.colorHex = colorHex
        }
        if let iconName = iconName {
            group.iconName = iconName
        }
        try save()
    }

    func move(_ group: Group, to parent: Group?) throws {
        // 防止循環引用
        if let parent = parent {
            var currentParent: Group? = parent
            while let p = currentParent {
                if p == group {
                    throw RepositoryError.saveFailed("無法移動：會造成循環引用")
                }
                currentParent = p.parent
            }
        }

        group.parent = parent
        try save()
    }

    func reorder(_ groups: [Group]) throws {
        for (index, group) in groups.enumerated() {
            group.orderIndex = Int16(index)
        }
        try save()
    }

    // MARK: - Delete Operations

    func delete(_ group: Group) throws {
        // 遞迴刪除所有子資料夾
        if let children = group.children {
            for child in children {
                try delete(child)
            }
        }

        context.delete(group)
        try save()
    }

    func deleteAll(_ groups: [Group]) throws {
        for group in groups {
            try delete(group)
        }
    }
}
