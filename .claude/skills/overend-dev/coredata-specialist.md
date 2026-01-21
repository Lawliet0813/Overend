# Core Data Specialist - 資料模型與持久化專家

## 職責範圍

負責所有 Core Data 相關開發，包括：
- Entry、Library、Document 等實體模型管理
- 關聯關係設計與維護
- 資料遷移策略
- 資料驗證規則
- Core Data Context 管理

**不負責**：
- UI 顯示邏輯（由 ui-specialist 處理）
- API 呼叫（由 service-specialist 處理）
- 測試撰寫（由 testing-specialist 處理）

## 何時載入此 Skill

當任務包含以下關鍵字時自動載入：
- Core Data、模型、Entity
- Entry、Library、Document、Group、Attachment
- 關聯關係、Relationship
- 資料遷移、Migration
- NSManagedObject、Context

## Core Data 模型結構

```
OVEREND/Models/
├── Entry.swift         # 文獻書目實體
├── Library.swift       # 文獻庫實體
├── Group.swift         # 分類群組實體
├── Attachment.swift    # 附件實體
└── Document.swift      # 文稿實體
```

### 實體關聯圖

```
Library (一) ──< Group (多)
   │
   └──< Entry (多)
          │
          ├──< Attachment (多)
          └──< Citation (多) ──> Document (一)

Document (一) ──< Citation (多) ──> Entry (一)
```

## Entry 實體（文獻書目）

### 核心欄位

| 欄位名稱 | 型別 | 必填 | 說明 |
|---------|------|------|------|
| `entryId` | UUID | ✅ | 唯一識別碼 |
| `citationKey` | String | ✅ | BibTeX 引用鍵（唯一） |
| `bibtexRaw` | String | ✅ | 原始 BibTeX 字串 |
| `entryType` | String | ✅ | 類型（article、book...） |
| `title` | String | ✅ | 標題 |
| `authors` | String | ❌ | 作者（分號分隔） |
| `year` | String | ❌ | 出版年份 |
| `journal` | String | ❌ | 期刊名稱 |
| `doi` | String | ❌ | DOI 編號 |
| `abstract` | String | ❌ | 摘要 |
| `keywords` | String | ❌ | 關鍵字（分號分隔） |
| `url` | String | ❌ | 網址 |
| `notes` | String | ❌ | 使用者筆記 |
| `rating` | Int16 | ❌ | 評分（0-5） |
| `readStatus` | String | ❌ | 閱讀狀態 |
| `createdAt` | Date | ✅ | 建立時間 |
| `updatedAt` | Date | ✅ | 更新時間 |

### 關聯關係

```swift
// 一對一
@NSManaged public var library: Library?  // 所屬文獻庫

// 一對多
@NSManaged public var attachments: NSSet?  // 附件集合
@NSManaged public var citations: NSSet?    // 引用集合
```

### 建立 Entry 範例

```swift
// ✅ 正確方式
extension Entry {
    static func create(
        in context: NSManagedObjectContext,
        citationKey: String,
        bibtexRaw: String,
        entryType: String,
        title: String
    ) -> Entry {
        let entry = Entry(context: context)
        entry.entryId = UUID()
        entry.citationKey = citationKey
        entry.bibtexRaw = bibtexRaw
        entry.entryType = entryType
        entry.title = title
        entry.createdAt = Date()
        entry.updatedAt = Date()
        return entry
    }
}

// 使用
let entry = Entry.create(
    in: viewContext,
    citationKey: "Chen2024",
    bibtexRaw: "@article{Chen2024,...}",
    entryType: "article",
    title: "論文標題"
)
try? viewContext.save()
```

## Library 實體（文獻庫）

### 核心欄位

| 欄位名稱 | 型別 | 必填 | 說明 |
|---------|------|------|------|
| `libraryId` | UUID | ✅ | 唯一識別碼 |
| `name` | String | ✅ | 文獻庫名稱 |
| `description` | String | ❌ | 描述 |
| `createdAt` | Date | ✅ | 建立時間 |
| `updatedAt` | Date | ✅ | 更新時間 |

### 關聯關係

```swift
// 一對多
@NSManaged public var entries: NSSet?  // 文獻集合
@NSManaged public var groups: NSSet?   // 群組集合
```

## Document 實體（文稿）

### 核心欄位

| 欄位名稱 | 型別 | 必填 | 說明 |
|---------|------|------|------|
| `documentId` | UUID | ✅ | 唯一識別碼 |
| `title` | String | ✅ | 文稿標題 |
| `content` | String | ❌ | HTML 內容 |
| `wordCount` | Int32 | ❌ | 字數統計 |
| `citationFormat` | String | ❌ | 引用格式（APA/MLA） |
| `createdAt` | Date | ✅ | 建立時間 |
| `updatedAt` | Date | ✅ | 更新時間 |
| `lastOpenedAt` | Date | ❌ | 最後開啟時間 |

### 關聯關係

```swift
// 一對多
@NSManaged public var citations: NSSet?  // 引用集合
```

## Attachment 實體（附件）

### 核心欄位

| 欄位名稱 | 型別 | 必填 | 說明 |
|---------|------|------|------|
| `attachmentId` | UUID | ✅ | 唯一識別碼 |
| `fileName` | String | ✅ | 檔案名稱 |
| `fileURL` | URL | ✅ | 檔案路徑 |
| `fileType` | String | ✅ | 檔案類型（PDF/DOCX） |
| `fileSize` | Int64 | ❌ | 檔案大小（bytes） |
| `pageCount` | Int16 | ❌ | 頁數（PDF） |
| `createdAt` | Date | ✅ | 建立時間 |

### 關聯關係

```swift
// 多對一
@NSManaged public var entry: Entry?  // 所屬文獻
```

## 資料驗證規則

### 必填欄位檢查

```swift
extension Entry {
    func validate() throws {
        guard citationKey != nil && !citationKey!.isEmpty else {
            throw ValidationError.missingCitationKey
        }
        guard bibtexRaw != nil && !bibtexRaw!.isEmpty else {
            throw ValidationError.missingBibTeX
        }
        guard title != nil && !title!.isEmpty else {
            throw ValidationError.missingTitle
        }
    }
}

enum ValidationError: Error {
    case missingCitationKey
    case missingBibTeX
    case missingTitle
}
```

### Citation Key 唯一性

```swift
extension Entry {
    static func citationKeyExists(
        _ key: String,
        in context: NSManagedObjectContext
    ) -> Bool {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "citationKey == %@", key)
        return (try? context.count(for: request)) ?? 0 > 0
    }
    
    static func generateUniqueCitationKey(
        basedOn base: String,
        in context: NSManagedObjectContext
    ) -> String {
        var key = base
        var counter = 1
        while citationKeyExists(key, in: context) {
            key = "\(base)_\(counter)"
            counter += 1
        }
        return key
    }
}
```

## 資料查詢模式

### 使用 NSFetchRequest

```swift
// ✅ 正確：在 Repository 或 Service 層執行
class EntryRepository {
    func fetchAllEntries(in context: NSManagedObjectContext) -> [Entry] {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)
        ]
        return (try? context.fetch(request)) ?? []
    }
    
    func fetchEntriesByAuthor(
        _ author: String,
        in context: NSManagedObjectContext
    ) -> [Entry] {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(
            format: "authors CONTAINS[cd] %@",
            author
        )
        return (try? context.fetch(request)) ?? []
    }
}
```

### 使用 @FetchRequest（SwiftUI）

```swift
// ✅ 在 ViewModel 中使用
class LibraryViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadEntries()
    }
    
    func loadEntries() {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)
        ]
        entries = (try? context.fetch(request)) ?? []
    }
}
```

## 資料遷移策略

### 輕量級遷移（Lightweight Migration）

適用於：
- 新增欄位
- 刪除欄位
- 欄位改名（使用 renaming identifier）
- 修改可選性（optional ↔ non-optional）

```swift
// 在 PersistenceController 中啟用
let container = NSPersistentContainer(name: "OVEREND")
let description = container.persistentStoreDescriptions.first
description?.shouldMigrateStoreAutomatically = true
description?.shouldInferMappingModelAutomatically = true
```

### 重量級遷移（Heavyweight Migration）

適用於：
- 關聯關係變更
- 實體分割或合併
- 複雜的資料轉換

需要建立 Mapping Model（.xcmappingmodel）

### 遷移檢查清單

新增/修改模型時：
- [ ] 確認是否需要新版本
- [ ] 測試輕量級遷移是否可行
- [ ] 如需重量級遷移，建立 Mapping Model
- [ ] 撰寫遷移測試
- [ ] 備份既有資料
- [ ] 記錄遷移日誌

## Context 管理

### ViewContext（主執行緒）

```swift
// ✅ 用於 UI 相關操作
@Environment(\.managedObjectContext) private var viewContext

// 儲存變更
do {
    try viewContext.save()
} catch {
    print("儲存失敗：\(error)")
}
```

### BackgroundContext（背景執行緒）

```swift
// ✅ 用於大量資料操作
let backgroundContext = container.newBackgroundContext()
backgroundContext.perform {
    // 在背景執行
    for data in largeDataSet {
        let entry = Entry(context: backgroundContext)
        // ... 設定屬性
    }
    
    do {
        try backgroundContext.save()
    } catch {
        print("背景儲存失敗：\(error)")
    }
}
```

## 常見操作模式

### 1. 建立 Entry

```swift
func createEntry(
    citationKey: String,
    bibtexRaw: String,
    title: String,
    in context: NSManagedObjectContext
) -> Entry {
    let entry = Entry(context: context)
    entry.entryId = UUID()
    entry.citationKey = citationKey
    entry.bibtexRaw = bibtexRaw
    entry.title = title
    entry.createdAt = Date()
    entry.updatedAt = Date()
    
    do {
        try context.save()
        return entry
    } catch {
        print("建立 Entry 失敗：\(error)")
        context.rollback()
        fatalError("無法建立 Entry")
    }
}
```

### 2. 更新 Entry

```swift
func updateEntry(
    _ entry: Entry,
    title: String?,
    authors: String?,
    in context: NSManagedObjectContext
) {
    if let title = title {
        entry.title = title
    }
    if let authors = authors {
        entry.authors = authors
    }
    entry.updatedAt = Date()
    
    do {
        try context.save()
    } catch {
        print("更新 Entry 失敗：\(error)")
        context.rollback()
    }
}
```

### 3. 刪除 Entry

```swift
func deleteEntry(
    _ entry: Entry,
    in context: NSManagedObjectContext
) {
    context.delete(entry)
    
    do {
        try context.save()
    } catch {
        print("刪除 Entry 失敗：\(error)")
        context.rollback()
    }
}
```

### 4. 批次操作

```swift
func batchDeleteEntries(
    matching predicate: NSPredicate,
    in context: NSManagedObjectContext
) {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Entry")
    request.predicate = predicate
    
    let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
    batchDelete.resultType = .resultTypeObjectIDs
    
    do {
        let result = try context.execute(batchDelete) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        
        // 更新 context
        let changes: [AnyHashable: Any] = [
            NSDeletedObjectsKey: objectIDArray ?? []
        ]
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: changes,
            into: [context]
        )
    } catch {
        print("批次刪除失敗：\(error)")
    }
}
```

## 整合檢查清單

### 新增/修改模型時

- [ ] 欄位定義完整（名稱、型別、可選性）
- [ ] 設定預設值（如需要）
- [ ] 定義關聯關係
- [ ] 檢查是否需要資料遷移
- [ ] 撰寫驗證邏輯
- [ ] 建立便利方法（create、update、delete）
- [ ] 撰寫單元測試
- [ ] 更新相關 ViewModel
- [ ] 確認 UI 顯示正常

### 與其他 Skill 協作

**與 UI Specialist 協作**：
- UI 透過 ViewModel 或 Repository 存取資料
- 提供 @FetchRequest 查詢結果
- 不直接在 View 中操作 Context

**與 Service Specialist 協作**：
- Service 可直接操作 Context
- Service 負責複雜的 CRUD 邏輯
- 確保交易一致性

**與 Testing Specialist 協作**：
- 使用 CoreDataTestHelper
- 建立 in-memory store 測試
- 驗證資料完整性與關聯關係

## 常見問題

### Q: Citation Key 重複怎麼辦？

```swift
// 使用自動遞增編號
let baseKey = "Chen2024"
let uniqueKey = Entry.generateUniqueCitationKey(
    basedOn: baseKey,
    in: context
)
// 結果：Chen2024_1, Chen2024_2...
```

### Q: 如何處理大量資料匯入？

```swift
// 使用背景 Context
let backgroundContext = container.newBackgroundContext()
backgroundContext.performAndWait {
    for data in largeDataSet {
        let entry = Entry(context: backgroundContext)
        // 設定屬性
    }
    try? backgroundContext.save()
}
```

### Q: 資料遷移失敗怎麼辦？

```
1. 檢查模型版本是否正確設定
2. 確認 shouldMigrateStoreAutomatically = true
3. 檢查是否需要 Mapping Model
4. 查看 Console 錯誤訊息
5. 必要時重新建立資料庫（開發階段）
```

### Q: 如何測試 Core Data？

```swift
// 使用 in-memory store
let testHelper = CoreDataTestHelper(inMemory: true)
let testContext = testHelper.viewContext

// 執行測試
let entry = Entry.create(in: testContext, ...)
XCTAssertNotNil(entry.entryId)
```

---

**版本**: 1.0
**建立日期**: 2025-01-21
**維護者**: OVEREND 開發團隊
