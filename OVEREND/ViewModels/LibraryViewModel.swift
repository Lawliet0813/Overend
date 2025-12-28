//
//  LibraryViewModel.swift
//  OVEREND
//
//  文獻庫視圖模型
//

import Foundation
import CoreData
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var libraries: [Library] = []
    @Published var selectedLibrary: Library?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetchLibraries()
    }

    // MARK: - 數據操作

    func fetchLibraries() {
        isLoading = true
        libraries = Library.fetchAll(in: context)
        isLoading = false

        // 如果沒有庫，創建默認庫
        if libraries.isEmpty {
            createDefaultLibrary()
        }
    }

    func createLibrary(name: String, colorHex: String? = nil) {
        let library = Library(context: context, name: name)
        library.colorHex = colorHex

        do {
            try context.save()
            fetchLibraries()
        } catch {
            errorMessage = "創建庫失敗: \\(error.localizedDescription)"
        }
    }

    func deleteLibrary(_ library: Library) {
        context.delete(library)

        do {
            try context.save()
            fetchLibraries()
        } catch {
            errorMessage = "刪除庫失敗: \\(error.localizedDescription)"
        }
    }

    func updateLibrary(_ library: Library, name: String, colorHex: String? = nil) {
        library.update(name: name, colorHex: colorHex)

        do {
            try context.save()
            fetchLibraries()
        } catch {
            errorMessage = "更新庫失敗: \\(error.localizedDescription)"
        }
    }

    // MARK: - 輔助方法

    private func createDefaultLibrary() {
        createLibrary(name: "我的文獻庫")
    }
}
