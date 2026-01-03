//
//  DocumentRepository.swift
//  OVEREND
//
//  Document 實體的資料存取層
//

import Foundation
import CoreData
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Document Repository Protocol

protocol DocumentRepositoryProtocol: CRUDRepository where Entity == Document {
    /// 創建新文檔
    func create(title: String) async throws -> Document

    /// 更新文檔標題
    func updateTitle(_ document: Document, title: String) throws

    /// 更新文檔內容
    #if canImport(AppKit)
    func updateContent(_ document: Document, attributedString: NSAttributedString) throws
    #endif

    /// 更新編輯器模式
    func updateEditorMode(_ document: Document, mode: Document.EditorMode) throws

    /// 新增引用
    func addCitation(_ document: Document, entry: Entry) throws

    /// 移除引用
    func removeCitation(_ document: Document, entry: Entry) throws
}

// MARK: - Document Repository Implementation

final class DocumentRepository: BaseRepository<Document>, DocumentRepositoryProtocol {

    // MARK: - Fetch Operations

    override func createFetchRequest() -> NSFetchRequest<Document> {
        let request = Document.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)]
        return request
    }

    func fetchAll() async throws -> [Document] {
        let request = createFetchRequest()
        return try await executeFetchRequest(request)
    }

    func fetch(byId id: UUID) async throws -> Document? {
        let request = createFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let results = try await executeFetchRequest(request)
        return results.first
    }

    // MARK: - Create Operations

    @discardableResult
    func create() -> Document {
        let document = Document(context: context)
        document.id = UUID()
        document.title = "未命名文檔"
        document.createdAt = Date()
        document.updatedAt = Date()
        return document
    }

    func create(title: String) async throws -> Document {
        return try await context.perform {
            let document = Document(context: self.context)
            document.id = UUID()
            document.title = title
            document.createdAt = Date()
            document.updatedAt = Date()

            try self.save()
            return document
        }
    }

    // MARK: - Update Operations

    func update(_ document: Document) throws {
        document.updatedAt = Date()
        try save()
    }

    func updateTitle(_ document: Document, title: String) throws {
        document.title = title
        document.updatedAt = Date()
        try save()
    }

    #if canImport(AppKit)
    func updateContent(_ document: Document, attributedString: NSAttributedString) throws {
        do {
            let data = try attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            document.rtfData = data
            document.updatedAt = Date()
            try save()
        } catch {
            throw RepositoryError.saveFailed("無法保存 RTF 內容: \(error.localizedDescription)")
        }
    }
    #endif

    func updateEditorMode(_ document: Document, mode: Document.EditorMode) throws {
        document.currentEditorMode = mode
        document.updatedAt = Date()
        try save()
    }

    // MARK: - Citation Management

    func addCitation(_ document: Document, entry: Entry) throws {
        if document.citations == nil {
            document.citations = []
        }
        document.citations?.insert(entry)
        document.updatedAt = Date()
        try save()
    }

    func removeCitation(_ document: Document, entry: Entry) throws {
        document.citations?.remove(entry)
        document.updatedAt = Date()
        try save()
    }

    // MARK: - Delete Operations

    func delete(_ document: Document) throws {
        context.delete(document)
        try save()
    }

    func deleteAll(_ documents: [Document]) throws {
        for document in documents {
            context.delete(document)
        }
        try save()
    }
}
