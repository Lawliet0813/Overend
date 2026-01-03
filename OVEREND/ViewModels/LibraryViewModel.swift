//
//  LibraryViewModel.swift
//  OVEREND
//
//  文獻庫視圖模型 - 使用 Repository 層
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

    private let repository: LibraryRepositoryProtocol

    init(repository: LibraryRepositoryProtocol? = nil) {
        self.repository = repository ?? LibraryRepository()
        Task {
            await fetchLibraries()
        }
    }

    // MARK: - 數據操作

    func fetchLibraries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            libraries = try await repository.fetchAll()

            // 如果沒有庫，創建默認庫
            if libraries.isEmpty {
                await createDefaultLibrary()
            }
        } catch {
            errorMessage = "獲取文獻庫失敗: \(error.localizedDescription)"
        }
    }

    func createLibrary(name: String, colorHex: String? = nil) async {
        do {
            let library = try await repository.create(name: name, isDefault: false)
            if let colorHex = colorHex {
                try repository.update(library, name: nil, colorHex: colorHex)
            }
            await fetchLibraries()
        } catch {
            errorMessage = "創建庫失敗: \(error.localizedDescription)"
        }
    }

    func deleteLibrary(_ library: Library) async {
        do {
            try repository.delete(library)
            await fetchLibraries()
        } catch {
            errorMessage = "刪除庫失敗: \(error.localizedDescription)"
        }
    }

    func updateLibrary(_ library: Library, name: String, colorHex: String? = nil) async {
        do {
            try repository.update(library, name: name, colorHex: colorHex)
            await fetchLibraries()
        } catch {
            errorMessage = "更新庫失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - 輔助方法

    private func createDefaultLibrary() async {
        await createLibrary(name: "我的文獻庫")
    }
    
    // MARK: - 統計屬性
    
    /// 所有文獻總數
    var totalEntryCount: Int {
        libraries.reduce(0) { $0 + $1.entryCount }
    }
}
