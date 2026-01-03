//
//  EntryRepository.swift
//  OVEREND
//
//  Entry 實體的資料存取層
//

import Foundation
import CoreData

// MARK: - Entry Repository Protocol

protocol EntryRepositoryProtocol: CRUDRepository where Entity == Entry {
    /// 獲取指定庫的所有條目
    func fetchAll(in library: Library, sortBy: Entry.SortOption) async throws -> [Entry]

    /// 搜尋條目
    func search(query: String, in library: Library) async throws -> [Entry]

    /// 根據 Citation Key 查找
    func find(byCitationKey key: String) async throws -> Entry?

    /// 創建新條目
    func create(
        citationKey: String,
        entryType: String,
        fields: [String: String],
        library: Library
    ) async throws -> Entry

    /// 更新條目字段
    func updateFields(_ entry: Entry, fields: [String: String]) throws
}

// MARK: - Entry Repository Implementation

final class EntryRepository: BaseRepository<Entry>, EntryRepositoryProtocol {

    // MARK: - Fetch Operations

    override func createFetchRequest() -> NSFetchRequest<Entry> {
        return Entry.fetchRequest()
    }

    func fetchAll() async throws -> [Entry] {
        let request = createFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)]
        return try await executeFetchRequest(request)
    }

    func fetchAll(in library: Library, sortBy: Entry.SortOption = .updated) async throws -> [Entry] {
        let request = createFetchRequest()
        request.predicate = NSPredicate(format: "library == %@", library)
        request.sortDescriptors = sortBy.sortDescriptors

        return try await executeFetchRequest(request)
    }

    func fetch(byId id: UUID) async throws -> Entry? {
        let request = createFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let results = try await executeFetchRequest(request)
        return results.first
    }

    func search(query: String, in library: Library) async throws -> [Entry] {
        guard query.count >= 2 else { return [] }

        let request = createFetchRequest()
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
        request.fetchLimit = 100

        return try await executeFetchRequest(request)
    }

    func find(byCitationKey key: String) async throws -> Entry? {
        let request = createFetchRequest()
        request.predicate = NSPredicate(format: "citationKey == %@", key)
        request.fetchLimit = 1

        let results = try await executeFetchRequest(request)
        return results.first
    }

    // MARK: - Create Operations

    @discardableResult
    func create() -> Entry {
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.citationKey = "new_entry_\(UUID().uuidString.prefix(8))"
        entry.entryType = "article"
        entry.fieldsJSON = "{}"
        entry.bibtexRaw = ""
        entry.createdAt = Date()
        entry.updatedAt = Date()
        return entry
    }

    func create(
        citationKey: String,
        entryType: String,
        fields: [String: String],
        library: Library
    ) async throws -> Entry {
        return try await context.perform {
            let entry = Entry(context: self.context)
            entry.id = UUID()
            entry.citationKey = citationKey
            entry.entryType = entryType
            entry.fields = fields
            entry.library = library
            entry.createdAt = Date()
            entry.updatedAt = Date()
            entry.bibtexRaw = entry.generateBibTeX()

            try self.save()
            return entry
        }
    }

    // MARK: - Update Operations

    func update(_ entry: Entry) throws {
        entry.updatedAt = Date()
        try save()
    }

    func updateFields(_ entry: Entry, fields: [String: String]) throws {
        entry.fields = fields
        entry.bibtexRaw = entry.generateBibTeX()
        entry.updatedAt = Date()
        try save()
    }

    // MARK: - Delete Operations

    func delete(_ entry: Entry) throws {
        context.delete(entry)
        try save()
    }

    func deleteAll(_ entries: [Entry]) throws {
        for entry in entries {
            context.delete(entry)
        }
        try save()
    }
}
