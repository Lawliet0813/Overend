//
//  DocumentViewModel.swift
//  OVEREND
//
//  論文文檔視圖模型 - 使用 Repository 層
//

import Foundation
import CoreData
import Combine
#if canImport(AppKit)
import AppKit
#endif

@MainActor
class DocumentViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var selectedDocument: Document?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: DocumentRepositoryProtocol

    init(repository: DocumentRepositoryProtocol? = nil) {
        self.repository = repository ?? DocumentRepository()
        Task {
            await fetchDocuments()
        }
    }

    // MARK: - 數據操作

    func fetchDocuments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            documents = try await repository.fetchAll()
        } catch {
            errorMessage = "獲取文檔失敗: \(error.localizedDescription)"
        }
    }

    func createDocument(title: String) async {
        do {
            let document = try await repository.create(title: title)
            await fetchDocuments()
            selectedDocument = document
        } catch {
            errorMessage = "創建文檔失敗: \(error.localizedDescription)"
        }
    }

    func deleteDocument(_ document: Document) async {
        do {
            try repository.delete(document)
            await fetchDocuments()
            if selectedDocument == document {
                selectedDocument = nil
            }
        } catch {
            errorMessage = "刪除文檔失敗: \(error.localizedDescription)"
        }
    }

    func updateTitle(_ document: Document, title: String) async {
        do {
            try repository.updateTitle(document, title: title)
            await fetchDocuments()
        } catch {
            errorMessage = "更新標題失敗: \(error.localizedDescription)"
        }
    }

    #if canImport(AppKit)
    func updateContent(_ document: Document, attributedString: NSAttributedString) async {
        do {
            try repository.updateContent(document, attributedString: attributedString)
        } catch {
            errorMessage = "保存內容失敗: \(error.localizedDescription)"
        }
    }
    #endif

    func updateEditorMode(_ document: Document, mode: Document.EditorMode) async {
        do {
            try repository.updateEditorMode(document, mode: mode)
        } catch {
            errorMessage = "更新編輯器模式失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - 引用管理

    func addCitation(_ document: Document, entry: Entry) async {
        do {
            try repository.addCitation(document, entry: entry)
        } catch {
            errorMessage = "添加引用失敗: \(error.localizedDescription)"
        }
    }

    func removeCitation(_ document: Document, entry: Entry) async {
        do {
            try repository.removeCitation(document, entry: entry)
        } catch {
            errorMessage = "移除引用失敗: \(error.localizedDescription)"
        }
    }
}
