//
//  CoreDataTestHelper.swift
//  OVERENDTests
//
//  Core Data 測試環境輔助工具
//  使用與主程式相同的程式化模型定義
//

import CoreData
@testable import OVEREND

/// Core Data 測試輔助類別
/// 提供內存中的 Core Data Stack，與主程式使用相同的模型定義
@MainActor
class CoreDataTestHelper {
    
    /// 內存中的持久化容器
    let container: NSPersistentContainer
    
    /// 主要上下文
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    /// 初始化測試環境
    /// - Parameter inMemory: 是否使用內存存儲（預設 true）
    init(inMemory: Bool = true) {
        // 使用與主程式相同的程式化模型
        let managedObjectModel = PersistenceController.createManagedObjectModel()
        container = NSPersistentContainer(
            name: "OVERENDTest",
            managedObjectModel: managedObjectModel
        )
        
        if inMemory {
            // 使用 /dev/null 作為存儲位置，實現內存存儲
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Failed to load test store: \(error), \(error.userInfo)")
            }
        }
        
        // 配置上下文
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// 創建新的測試上下文（用於隔離測試）
    func newContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// 保存上下文
    func save() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
    
    /// 清空所有測試資料
    func reset() {
        let entities = container.managedObjectModel.entities
        for entity in entities {
            guard let entityName = entity.name else { continue }
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try container.viewContext.execute(deleteRequest)
            } catch {
                print("Failed to delete \(entityName): \(error)")
            }
        }
        
        // 重置上下文狀態
        container.viewContext.reset()
    }
    
    // MARK: - 快速創建測試資料
    
    /// 創建測試用 Library
    func createTestLibrary(
        name: String = "Test Library",
        isDefault: Bool = true
    ) -> Library {
        return Library(context: viewContext, name: name, isDefault: isDefault)
    }
    
    /// 創建測試用 Entry
    func createTestEntry(
        citationKey: String = "test2024",
        entryType: String = "article",
        fields: [String: String] = [:],
        library: Library? = nil
    ) -> Entry {
        let lib = library ?? createTestLibrary()
        return Entry(
            context: viewContext,
            citationKey: citationKey,
            entryType: entryType,
            fields: fields,
            library: lib
        )
    }
    
    /// 創建測試用 Document
    func createTestDocument(title: String = "Test Document") -> Document {
        return Document(context: viewContext, title: title)
    }
    
    /// 創建測試用 Group
    func createTestGroup(
        name: String = "Test Group",
        library: Library? = nil,
        parent: Group? = nil
    ) -> Group {
        let lib = library ?? createTestLibrary()
        return Group(context: viewContext, name: name, library: lib, parent: parent)
    }
}

// MARK: - XCTestCase 擴展

import XCTest

extension XCTestCase {
    
    /// 創建獨立的測試 Core Data 環境
    /// 每個測試方法應該創建自己的環境以確保隔離
    @MainActor
    func createTestCoreDataHelper() -> CoreDataTestHelper {
        return CoreDataTestHelper(inMemory: true)
    }
}
