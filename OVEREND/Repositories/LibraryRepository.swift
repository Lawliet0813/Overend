//
//  LibraryRepository.swift
//  OVEREND
//
//  Library 實體的資料存取層
//

import Foundation
import CoreData

// MARK: - Library Repository Protocol

protocol LibraryRepositoryProtocol: CRUDRepository where Entity == Library {
    /// 獲取默認庫
    func fetchDefault() async throws -> Library?

    /// 創建或獲取默認庫
    func getOrCreateDefault() async throws -> Library

    /// 創建新庫
    func create(name: String, isDefault: Bool) async throws -> Library

    /// 更新庫資訊
    func update(_ library: Library, name: String?, colorHex: String?) throws
}

// MARK: - Library Repository Implementation

final class LibraryRepository: BaseRepository<Library>, LibraryRepositoryProtocol {

    // MARK: - Fetch Operations

    override func createFetchRequest() -> NSFetchRequest<Library> {
        let request = Library.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Library.name, ascending: true)]
        return request
    }

    func fetchAll() async throws -> [Library] {
        let request = createFetchRequest()
        return try await executeFetchRequest(request)
    }

    func fetch(byId id: UUID) async throws -> Library? {
        let request = createFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let results = try await executeFetchRequest(request)
        return results.first
    }

    func fetchDefault() async throws -> Library? {
        let request = createFetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.fetchLimit = 1

        let results = try await executeFetchRequest(request)
        return results.first
    }

    // MARK: - Create Operations

    @discardableResult
    func create() -> Library {
        let library = Library(context: context)
        library.id = UUID()
        library.name = "新文獻庫"
        library.isDefault = false
        library.createdAt = Date()
        library.updatedAt = Date()
        return library
    }

    func create(name: String, isDefault: Bool = false) async throws -> Library {
        return try await context.perform {
            let library = Library(context: self.context)
            library.id = UUID()
            library.name = name
            library.isDefault = isDefault
            library.createdAt = Date()
            library.updatedAt = Date()

            try self.save()
            return library
        }
    }

    func getOrCreateDefault() async throws -> Library {
        if let existing = try await fetchDefault() {
            return existing
        }

        return try await create(name: "我的文獻庫", isDefault: true)
    }

    // MARK: - Update Operations

    func update(_ library: Library) throws {
        library.updatedAt = Date()
        try save()
    }

    func update(_ library: Library, name: String? = nil, colorHex: String? = nil) throws {
        if let name = name {
            library.name = name
        }
        if let colorHex = colorHex {
            library.colorHex = colorHex
        }
        library.updatedAt = Date()
        try save()
    }

    // MARK: - Delete Operations

    func delete(_ library: Library) throws {
        guard !library.isDefault else {
            throw RepositoryError.deleteFailed("無法刪除默認文獻庫")
        }

        context.delete(library)
        try save()
    }

    func deleteAll(_ libraries: [Library]) throws {
        for library in libraries {
            guard !library.isDefault else { continue }
            context.delete(library)
        }
        try save()
    }
}
