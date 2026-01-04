# OVEREND 程式碼規範指南

本文檔定義 OVEREND 專案的命名規則與程式碼規範，確保團隊一致性。

---

## 📁 檔案命名規則

### Swift 檔案

| 位置 | 命名規則 | 範例 |
|------|----------|------|
| `Views/` | `*View.swift` | `ProfessionalEditorView.swift` |
| `ViewModels/` | `*ViewModel.swift` | `DocumentViewModel.swift` |
| `Models/` | `[實體名].swift` | `Entry.swift`, `Document.swift` |
| `Services/` | `*Service.swift` | `CitationService.swift` |
| `Repositories/` | `*Repository.swift` | `EntryRepository.swift` |
| `Theme/` | `[功能名].swift` | `AppTheme.swift`, `DesignTokens.swift` |
| `Utilities/` | `[Type]+Extensions.swift` | `Color+Brand.swift` |

### 目錄結構

```
OVEREND/
├── Core/              # 核心協議與基礎類別
├── Models/            # 資料模型
├── Repositories/      # 資料存取層
├── Services/          # 業務邏輯服務
│   └── AI/           # AI 相關服務
│       ├── Domains/  # 領域服務
│       └── Tools/    # AI 工具
├── ViewModels/        # 視圖模型
├── Views/             # 視圖層
│   ├── Common/       # 共用視圖
│   ├── Components/   # UI 元件
│   ├── Writer/       # 寫作中心
│   ├── AICenter/     # AI 中心
│   └── Settings/     # 設定
├── Theme/             # 主題系統
└── Utilities/         # 工具類
```

---

## 🏷️ 命名慣例

### 類別與結構 (PascalCase)

```swift
// ✅ 正確
class ProfessionalEditorView: View { }
struct DocumentViewModel: ObservableObject { }
enum EntryType: String, Codable { }
protocol EntryRepositoryProtocol { }

// ❌ 錯誤
class professionalEditorView { }     // 小寫開頭
struct document_view_model { }       // 蛇形命名
enum entrytype { }                   // 缺少分隔
```

### 函數與方法 (camelCase + 動詞開頭)

```swift
// ✅ 正確 - CRUD 操作
func fetchAllEntries() -> [Entry]
func createEntry(fields: [String: String]) -> Entry
func updateDocument(_ document: Document, title: String)
func deleteEntry(withId id: UUID)

// ✅ 正確 - 布林查詢
func isValid() -> Bool
func hasUnsavedChanges() -> Bool
func canExport() -> Bool

// ✅ 正確 - 非同步操作
func loadData() async throws
func saveDocument() async

// ❌ 錯誤
func entries() { }           // 缺少動詞
func documentUpdate() { }    // 動詞在後
func getget() { }            // 重複
```

### 變數與屬性 (camelCase)

```swift
// ✅ 正確
let selectedEntry: Entry
var isLoading: Bool
private var documentRepository: DocumentRepositoryProtocol
@Published var entries: [Entry] = []

// ❌ 錯誤
let SelectedEntry: Entry       // PascalCase
var is_loading: Bool           // 蛇形命名
private var documentrepo { }   // 縮寫不清
```

### 常數 (camelCase 或 UPPER_SNAKE)

```swift
// ✅ 全域常數
enum Constants {
    static let maxRetryCount = 3
    static let defaultTimeout: TimeInterval = 30.0
    static let apiVersion = "v1"
}

// ✅ 環境常數 (全大寫)
#if DEBUG
let API_BASE_URL = "https://dev.api.example.com"
#else
let API_BASE_URL = "https://api.example.com"
#endif
```

---

## 🏛️ 架構規範

### 分層依賴規則

```
Views → ViewModels → Repositories → Core Data
          ↓              ↓
       Services ←────────┘
```

**禁止反向依賴**：

- ❌ Model 不能依賴 View
- ❌ Repository 不能依賴 ViewModel
- ❌ Service 不能直接依賴 View

### 依賴注入

```swift
// ✅ 正確 - 建構函數注入
class EntryViewModel: ObservableObject {
    private let repository: EntryRepositoryProtocol
    
    init(repository: EntryRepositoryProtocol = EntryRepository()) {
        self.repository = repository
    }
}

// ❌ 錯誤 - 直接存取單例
class EntryViewModel: ObservableObject {
    func loadEntries() {
        let context = PersistenceController.shared.container.viewContext
        // 直接使用 Core Data
    }
}
```

### Protocol 優先

```swift
// ✅ 定義協議
protocol EntryRepositoryProtocol {
    func fetchAll(in library: Library?) async throws -> [Entry]
    func find(byCitationKey: String) async -> Entry?
}

// ✅ 實現協議
class EntryRepository: EntryRepositoryProtocol {
    // 實現...
}
```

---

## 📝 程式碼風格

### 縮排與空白

- 使用 **4 個空格** 縮排 (Xcode 預設)
- 大括號 `{` 與宣告同行
- 逗號後加一個空格

```swift
// ✅ 正確
func process(items: [Item], completion: @escaping (Result<Void, Error>) -> Void) {
    for item in items {
        // 處理
    }
}

// ❌ 錯誤
func process(items:[Item],completion:@escaping(Result<Void,Error>)->Void)
{
    for item in items{
        //處理
    }
}
```

### 註解規範

```swift
/// 單行文檔註解
var count: Int

/**
 多行文檔註解
 
 - Parameter text: 輸入文字
 - Returns: 處理後的結果
 - Throws: `ValidationError` 當輸入無效時
 */
func process(text: String) throws -> String {
    // 實作註解 (行內)
    return text.trimmingCharacters(in: .whitespaces)
}

// MARK: - Section Header
// TODO: 待實作
// FIXME: 需修復
```

### 存取控制

```swift
// 預設使用最小權限
class DocumentService {
    // 公開 API
    public func exportDocument() { }
    
    // 模組內可見
    internal func prepareExport() { }
    
    // 私有實作
    private func formatContent() { }
    
    // 檔案內可見
    fileprivate func helper() { }
}
```

---

## 🧪 測試命名

```swift
// 格式: test_[測試對象]_[場景]_[預期結果]
func test_fetchEntries_withValidLibrary_returnsEntries() { }
func test_createEntry_withEmptyFields_throwsError() { }
func test_deleteEntry_whenNotFound_returnsNil() { }
```

---

## ⚠️ 禁止事項

1. **禁止 Force Unwrap** (除非 100% 確定)

   ```swift
   // ❌ 危險
   let value = optionalValue!
   
   // ✅ 安全
   guard let value = optionalValue else { return }
   ```

2. **禁止硬編碼字串**

   ```swift
   // ❌ 硬編碼
   let url = "https://api.example.com/v1"
   
   // ✅ 使用常數
   let url = Constants.API.baseURL
   ```

3. **禁止巨大函數** (超過 50 行需拆分)

4. **禁止 Massive View** (超過 300 行需拆分元件)

---

*最後更新：2026-01-04*
