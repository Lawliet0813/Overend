//
//  GroupViewModel.swift
//  OVEREND
//
//  資料夾視圖模型 - 管理樹狀結構資料夾
//

import Foundation
import CoreData
import Combine

@MainActor
class GroupViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    
    var library: Library? {
        didSet {
            fetchRootGroups()
        }
    }
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    // MARK: - Fetch
    
    func fetchRootGroups() {
        guard let library = library else {
            groups = []
            return
        }
        
        groups = Group.fetchRootGroups(in: library, context: context)
    }
    
    // MARK: - CRUD
    
    func createGroup(name: String, parent: Group? = nil) {
        guard let library = library else { return }
        
        let group = Group(context: context, name: name, library: library, parent: parent)
        
        // 設置排序順序
        if let parent = parent {
            group.orderIndex = Int16((parent.children?.count ?? 0))
        } else {
            group.orderIndex = Int16(groups.count)
        }
        
        do {
            try context.save()
            fetchRootGroups()
        } catch {
            errorMessage = "創建資料夾失敗: \(error.localizedDescription)"
        }
    }
    
    func updateGroup(_ group: Group, name: String) {
        group.name = name
        
        do {
            try context.save()
            fetchRootGroups()
        } catch {
            errorMessage = "更新資料夾失敗: \(error.localizedDescription)"
        }
    }
    
    func deleteGroup(_ group: Group) {
        context.delete(group)
        
        do {
            try context.save()
            fetchRootGroups()
        } catch {
            errorMessage = "刪除資料夾失敗: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Entry Assignment
    
    func addEntry(_ entry: Entry, to group: Group) {
        guard var entries = group.entries else {
            group.entries = [entry]
            saveContext()
            return
        }
        
        entries.insert(entry)
        group.entries = entries
        saveContext()
    }
    
    func removeEntry(_ entry: Entry, from group: Group) {
        guard var entries = group.entries else { return }
        
        entries.remove(entry)
        group.entries = entries
        saveContext()
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            errorMessage = "保存失敗: \(error.localizedDescription)"
        }
    }
}
