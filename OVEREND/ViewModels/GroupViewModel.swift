//
//  GroupViewModel.swift
//  OVEREND
//
//  資料夾視圖模型 - 管理樹狀結構資料夾（使用 Repository 層）
//

import Foundation
import CoreData
import Combine

@MainActor
class GroupViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var errorMessage: String?

    private let repository: GroupRepositoryProtocol

    var library: Library? {
        didSet {
            Task {
                await fetchRootGroups()
            }
        }
    }

    init(repository: GroupRepositoryProtocol? = nil) {
        self.repository = repository ?? GroupRepository()
    }

    // MARK: - Fetch

    func fetchRootGroups() async {
        guard let library = library else {
            groups = []
            return
        }

        do {
            groups = try await repository.fetchRootGroups(in: library)
        } catch {
            errorMessage = "獲取資料夾失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - CRUD

    func createGroup(name: String, parent: Group? = nil) async {
        guard let library = library else { return }

        do {
            _ = try await repository.create(name: name, library: library, parent: parent)
            await fetchRootGroups()
        } catch {
            errorMessage = "創建資料夾失敗: \(error.localizedDescription)"
        }
    }

    func updateGroup(_ group: Group, name: String) async {
        do {
            try repository.update(group, name: name, colorHex: nil, iconName: nil)
            await fetchRootGroups()
        } catch {
            errorMessage = "更新資料夾失敗: \(error.localizedDescription)"
        }
    }

    func deleteGroup(_ group: Group) async {
        do {
            try repository.delete(group)
            await fetchRootGroups()
        } catch {
            errorMessage = "刪除資料夾失敗: \(error.localizedDescription)"
        }
    }

    func moveGroup(_ group: Group, to parent: Group?) async {
        do {
            try repository.move(group, to: parent)
            await fetchRootGroups()
        } catch {
            errorMessage = "移動資料夾失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - Entry Assignment

    func addEntry(_ entry: Entry, to group: Group) async {
        do {
            if group.entries == nil {
                group.entries = []
            }
            group.entries?.insert(entry)
            try repository.update(group)
        } catch {
            errorMessage = "添加條目失敗: \(error.localizedDescription)"
        }
    }

    func removeEntry(_ entry: Entry, from group: Group) async {
        do {
            group.entries?.remove(entry)
            try repository.update(group)
        } catch {
            errorMessage = "移除條目失敗: \(error.localizedDescription)"
        }
    }
}
