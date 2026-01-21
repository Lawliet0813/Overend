//
//  PersistenceController.swift
//  OVEREND
//
//  Core Data 持久化控制器
//

import CoreData

struct PersistenceController {
    // 共享單例
    static let shared = PersistenceController()

    // 預覽用（用於 SwiftUI Preview）
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // 創建測試數據
        let library = Library(context: viewContext)
        library.id = UUID()
        library.name = "我的文獻庫"
        library.isDefault = true
        library.createdAt = Date()
        library.updatedAt = Date()

        let entry = Entry(context: viewContext)
        entry.id = UUID()
        entry.citationKey = "einstein1905"
        entry.entryType = "article"
        entry.fieldsJSON = """
        {
            "title": "On the Electrodynamics of Moving Bodies",
            "author": "Albert Einstein",
            "journal": "Annalen der Physik",
            "year": "1905",
            "volume": "17",
            "pages": "891-921"
        }
        """
        entry.bibtexRaw = """
        @article{einstein1905,
          title = {On the Electrodynamics of Moving Bodies},
          author = {Albert Einstein},
          journal = {Annalen der Physik},
          year = {1905},
          volume = {17},
          pages = {891-921}
        }
        """
        entry.library = library
        entry.createdAt = Date()
        entry.updatedAt = Date()

        do {
            try viewContext.save()
        } catch {
            #if DEBUG
            print("Preview data creation failed: \\(error)")
            #endif
        }

        return controller
    }()

    let container: NSPersistentCloudKitContainer

    /// iCloud 同步是否已啟用（從 UserDefaults 讀取）
    private static var isCloudSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: "CloudSyncEnabled")
    }

    init(inMemory: Bool = false) {
        // 創建程式化定義的模型
        let managedObjectModel = PersistenceController.createManagedObjectModel()
        container = NSPersistentCloudKitContainer(name: Constants.CoreData.containerName, managedObjectModel: managedObjectModel)

        if inMemory {
            // 預覽模式：使用記憶體儲存
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 生產模式：明確指定本地儲存位置
            if let description = container.persistentStoreDescriptions.first {
                // 設定儲存位置在 Application Support
                let storeURL = FileManager.default
                    .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                    .first!
                    .appendingPathComponent("OVEREND")
                    .appendingPathComponent("OVEREND.sqlite")

                // 確保目錄存在
                let storeDirectory = storeURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)

                description.url = storeURL

                #if DEBUG
                print("📁 Core Data Store: \(storeURL.path)")
                #endif
            }
        }

        // 設定 CloudKit 選項（只有當使用者啟用時才生效）
        if let description = container.persistentStoreDescriptions.first, !inMemory {
            // 啟用持久化歷史追蹤（本地和 CloudKit 都需要）
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            if Self.isCloudSyncEnabled {
                // 使用者啟用 iCloud 同步
                let cloudKitContainerIdentifier = "iCloud.\(Bundle.main.bundleIdentifier ?? "com.lawliet.OVEREND")"
                let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudKitContainerIdentifier)
                description.cloudKitContainerOptions = cloudKitOptions

                #if DEBUG
                print("☁️ CloudKit 同步已啟用: \(cloudKitContainerIdentifier)")
                #endif
            } else {
                // 本地儲存模式（不啟用 CloudKit）
                description.cloudKitContainerOptions = nil

                #if DEBUG
                print("💾 使用本地儲存模式（CloudKit 未啟用）")
                #endif
            }
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                /*
                 典型的錯誤原因：
                 - 父目錄不存在或無法創建
                 - 數據模型與持久化存儲不兼容
                 - 權限問題
                 - 磁盤空間不足
                 - CloudKit 權限未設定（當啟用 CloudKit 時）
                 */
                #if DEBUG
                print("❌ 無法加載持久化存儲: \(error.localizedDescription)")
                print("   Store Description: \(storeDescription)")
                print("   Error Details: \(error.userInfo)")
                #endif

                // 生產環境應該有更優雅的錯誤處理
                // 例如：顯示錯誤訊息給使用者，或嘗試重建資料庫
                fatalError("無法加載持久化存儲: \(error), \(error.userInfo)")
            } else {
                #if DEBUG
                print("✅ Core Data 持久化存儲已成功加載")
                print("   Store URL: \(storeDescription.url?.path ?? "N/A")")
                print("   CloudKit: \(Self.isCloudSyncEnabled ? "已啟用" : "未啟用")")
                #endif
            }
        }

        // 自動合併來自父上下文的更改
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Core Data 操作輔助方法

    /// 保存 viewContext
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch let nsError as NSError {
                #if DEBUG
                print("Core Data 儲存錯誤: \(nsError), \(nsError.userInfo)")
                #endif
            }
        }
    }

    /// 創建背景上下文（用於大量數據操作）
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// 刪除所有數據（用於測試或重置）
    func deleteAll() {
        let entities = container.managedObjectModel.entities
        for entity in entities {
            guard let entityName = entity.name else { continue }
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try container.viewContext.execute(deleteRequest)
                try container.viewContext.save()
            } catch {
                #if DEBUG
                print("Failed to delete \\(entityName): \\(error)")
                #endif
            }
        }
    }
}

// MARK: - 程式化定義 Core Data 模型

extension PersistenceController {
    static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // 創建所有實體
        let libraryEntity = Library.entityDescription()
        let entryEntity = Entry.entityDescription()
        let groupEntity = Group.entityDescription()
        let attachmentEntity = Attachment.entityDescription()
        let documentEntity = Document.entityDescription()
        let tagEntity = Tag.entityDescription()
        let extractionLogEntity = ExtractionLog.entityDescription()

        // 設置關聯關係
        setupRelationships(
            library: libraryEntity,
            entry: entryEntity,
            group: groupEntity,
            attachment: attachmentEntity,
            document: documentEntity,
            tag: tagEntity,
            extractionLog: extractionLogEntity
        )

        model.entities = [
            libraryEntity,
            entryEntity,
            groupEntity,
            attachmentEntity,
            documentEntity,
            tagEntity,
            extractionLogEntity
        ]

        return model
    }

    private static func setupRelationships(
        library: NSEntityDescription,
        entry: NSEntityDescription,
        group: NSEntityDescription,
        attachment: NSEntityDescription,
        document: NSEntityDescription,
        tag: NSEntityDescription,
        extractionLog: NSEntityDescription
    ) {
        // Library <-> Entry (1對多)
        let libraryToEntries = NSRelationshipDescription()
        libraryToEntries.name = "entries"
        libraryToEntries.destinationEntity = entry
        libraryToEntries.minCount = 0
        libraryToEntries.maxCount = 0  // 0 表示無限制
        libraryToEntries.deleteRule = .cascadeDeleteRule

        let entryToLibrary = NSRelationshipDescription()
        entryToLibrary.name = "library"
        entryToLibrary.destinationEntity = library
        entryToLibrary.minCount = 0
        entryToLibrary.maxCount = 1
        entryToLibrary.deleteRule = .nullifyDeleteRule

        libraryToEntries.inverseRelationship = entryToLibrary
        entryToLibrary.inverseRelationship = libraryToEntries

        // Library <-> Group (1對多)
        let libraryToGroups = NSRelationshipDescription()
        libraryToGroups.name = "groups"
        libraryToGroups.destinationEntity = group
        libraryToGroups.minCount = 0
        libraryToGroups.maxCount = 0
        libraryToGroups.deleteRule = .cascadeDeleteRule

        let groupToLibrary = NSRelationshipDescription()
        groupToLibrary.name = "library"
        groupToLibrary.destinationEntity = library
        groupToLibrary.minCount = 0
        groupToLibrary.maxCount = 1
        groupToLibrary.deleteRule = .nullifyDeleteRule

        libraryToGroups.inverseRelationship = groupToLibrary
        groupToLibrary.inverseRelationship = libraryToGroups

        // Entry <-> Attachment (1對多)
        let entryToAttachments = NSRelationshipDescription()
        entryToAttachments.name = "attachments"
        entryToAttachments.destinationEntity = attachment
        entryToAttachments.minCount = 0
        entryToAttachments.maxCount = 0
        entryToAttachments.deleteRule = .cascadeDeleteRule

        let attachmentToEntry = NSRelationshipDescription()
        attachmentToEntry.name = "entry"
        attachmentToEntry.destinationEntity = entry
        attachmentToEntry.minCount = 0
        attachmentToEntry.maxCount = 1
        attachmentToEntry.deleteRule = .nullifyDeleteRule

        entryToAttachments.inverseRelationship = attachmentToEntry
        attachmentToEntry.inverseRelationship = entryToAttachments

        // Entry <-> Group (多對多)
        let entryToGroups = NSRelationshipDescription()
        entryToGroups.name = "groups"
        entryToGroups.destinationEntity = group
        entryToGroups.minCount = 0
        entryToGroups.maxCount = 0
        entryToGroups.deleteRule = .nullifyDeleteRule

        let groupToEntries = NSRelationshipDescription()
        groupToEntries.name = "entries"
        groupToEntries.destinationEntity = entry
        groupToEntries.minCount = 0
        groupToEntries.maxCount = 0
        groupToEntries.deleteRule = .nullifyDeleteRule

        entryToGroups.inverseRelationship = groupToEntries
        groupToEntries.inverseRelationship = entryToGroups

        // Group <-> Group (父子關係，自引用)
        let groupToParent = NSRelationshipDescription()
        groupToParent.name = "parent"
        groupToParent.destinationEntity = group
        groupToParent.minCount = 0
        groupToParent.maxCount = 1
        groupToParent.deleteRule = .nullifyDeleteRule

        let groupToChildren = NSRelationshipDescription()
        groupToChildren.name = "children"
        groupToChildren.destinationEntity = group
        groupToChildren.minCount = 0
        groupToChildren.maxCount = 0
        groupToChildren.deleteRule = .cascadeDeleteRule

        groupToParent.inverseRelationship = groupToChildren
        groupToChildren.inverseRelationship = groupToParent

        // Document <-> Entry (多對多，引用關係)
        let documentToCitations = NSRelationshipDescription()
        documentToCitations.name = "citations"
        documentToCitations.destinationEntity = entry
        documentToCitations.minCount = 0
        documentToCitations.maxCount = 0
        documentToCitations.deleteRule = .nullifyDeleteRule

        // Library <-> Tag (1對多)
        let libraryToTags = NSRelationshipDescription()
        libraryToTags.name = "tags"
        libraryToTags.destinationEntity = tag
        libraryToTags.minCount = 0
        libraryToTags.maxCount = 0
        libraryToTags.deleteRule = .cascadeDeleteRule

        let tagToLibrary = NSRelationshipDescription()
        tagToLibrary.name = "library"
        tagToLibrary.destinationEntity = library
        tagToLibrary.minCount = 0
        tagToLibrary.maxCount = 1
        tagToLibrary.deleteRule = .nullifyDeleteRule

        libraryToTags.inverseRelationship = tagToLibrary
        tagToLibrary.inverseRelationship = libraryToTags

        // Entry <-> Tag (多對多)
        let entryToTags = NSRelationshipDescription()
        entryToTags.name = "tags"
        entryToTags.destinationEntity = tag
        entryToTags.minCount = 0
        entryToTags.maxCount = 0
        entryToTags.deleteRule = .nullifyDeleteRule

        let tagToEntries = NSRelationshipDescription()
        tagToEntries.name = "entries"
        tagToEntries.destinationEntity = entry
        tagToEntries.minCount = 0
        tagToEntries.maxCount = 0
        tagToEntries.deleteRule = .nullifyDeleteRule

        entryToTags.inverseRelationship = tagToEntries
        tagToEntries.inverseRelationship = entryToTags

        // Entry <-> ExtractionLog (1對1，可選)
        let entryToExtractionLog = NSRelationshipDescription()
        entryToExtractionLog.name = "extractionLog"
        entryToExtractionLog.destinationEntity = extractionLog
        entryToExtractionLog.minCount = 0
        entryToExtractionLog.maxCount = 1
        entryToExtractionLog.deleteRule = .cascadeDeleteRule

        let extractionLogToEntry = NSRelationshipDescription()
        extractionLogToEntry.name = "entry"
        extractionLogToEntry.destinationEntity = entry
        extractionLogToEntry.minCount = 0
        extractionLogToEntry.maxCount = 1
        extractionLogToEntry.deleteRule = .nullifyDeleteRule

        entryToExtractionLog.inverseRelationship = extractionLogToEntry
        extractionLogToEntry.inverseRelationship = entryToExtractionLog

        // 添加關聯到實體
        library.properties = library.properties + [libraryToEntries, libraryToGroups, libraryToTags]
        entry.properties = entry.properties + [entryToLibrary, entryToAttachments, entryToGroups, entryToTags, entryToExtractionLog]
        group.properties = group.properties + [groupToLibrary, groupToEntries, groupToParent, groupToChildren]
        attachment.properties = attachment.properties + [attachmentToEntry]
        document.properties = document.properties + [documentToCitations]
        tag.properties = tag.properties + [tagToLibrary, tagToEntries]
        extractionLog.properties = extractionLog.properties + [extractionLogToEntry]
    }
}
