//
//  EntryViewModel.swift
//  OVEREND
//
//  書目視圖模型
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

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    var library: Library? {
        didSet {
            fetchEntries()
        }
    }

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        setupSearch()
        setupContextObserver()
    }

    // MARK: - 搜尋設置

    private func setupSearch() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Core Data 監聽
    
    private func setupContextObserver() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchEntries()
            }
            .store(in: &cancellables)
    }

    // MARK: - 數據操作

    func fetchEntries() {
        guard let library = library else {
            entries = []
            filteredEntries = []
            return
        }

        isLoading = true
        entries = Entry.fetchAll(in: library, context: context)
        filteredEntries = entries
        isLoading = false
    }

    func createEntry(citationKey: String, entryType: String, fields: [String: String]) {
        guard let library = library else { return }

        _ = Entry(
            context: context,
            citationKey: citationKey,
            entryType: entryType,
            fields: fields,
            library: library
        )

        do {
            try context.save()
            fetchEntries()
        } catch {
            errorMessage = "創建書目失敗: \(error.localizedDescription)"
        }
    }

    func deleteEntry(_ entry: Entry) {
        context.delete(entry)

        do {
            try context.save()
            fetchEntries()
        } catch {
            errorMessage = "刪除書目失敗: \(error.localizedDescription)"
        }
    }

    func updateEntry(_ entry: Entry, fields: [String: String]) {
        entry.updateFields(fields)

        do {
            try context.save()
            fetchEntries()
        } catch {
            errorMessage = "更新書目失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - 搜尋

    private func performSearch(query: String) {
        guard let library = library else { return }

        if query.isEmpty {
            filteredEntries = entries
        } else {
            filteredEntries = Entry.search(query: query, in: library, context: context)
        }
    }
}

