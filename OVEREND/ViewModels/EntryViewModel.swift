//
//  EntryViewModel.swift
//  OVEREND
//
//  書目視圖模型 - 使用 Repository 層
//

import Foundation
import CoreData
import Combine

@MainActor
class EntryViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var filteredEntries: [Entry] = []
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: EntryRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    var library: Library? {
        didSet {
            Task {
                await fetchEntries()
            }
        }
    }

    init(repository: EntryRepositoryProtocol? = nil) {
        self.repository = repository ?? EntryRepository()
        setupSearch()
    }

    // MARK: - 搜尋設置

    private func setupSearch() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 數據操作

    func fetchEntries() async {
        guard let library = library else {
            entries = []
            filteredEntries = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            entries = try await repository.fetchAll(in: library, sortBy: .updated)
            filteredEntries = entries
        } catch {
            errorMessage = "獲取書目失敗: \(error.localizedDescription)"
        }
    }

    func createEntry(citationKey: String, entryType: String, fields: [String: String]) async {
        guard let library = library else { return }

        do {
            _ = try await repository.create(
                citationKey: citationKey,
                entryType: entryType,
                fields: fields,
                library: library
            )
            await fetchEntries()
        } catch {
            errorMessage = "創建書目失敗: \(error.localizedDescription)"
        }
    }

    func deleteEntry(_ entry: Entry) async {
        do {
            try repository.delete(entry)
            await fetchEntries()
        } catch {
            errorMessage = "刪除書目失敗: \(error.localizedDescription)"
        }
    }

    func updateEntry(_ entry: Entry, fields: [String: String]) async {
        do {
            try repository.updateFields(entry, fields: fields)
            await fetchEntries()
        } catch {
            errorMessage = "更新書目失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - 搜尋

    private func performSearch(query: String) async {
        guard let library = library else { return }

        do {
            if query.isEmpty {
                filteredEntries = entries
            } else {
                filteredEntries = try await repository.search(query: query, in: library)
            }
        } catch {
            errorMessage = "搜尋失敗: \(error.localizedDescription)"
        }
    }
}

