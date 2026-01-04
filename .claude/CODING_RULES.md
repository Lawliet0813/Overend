# OVEREND 專案程式碼規範

> 此文件定義 OVEREND 專案的命名規則與架構規範，所有程式碼修改必須遵守這些規則。

## 檔案命名規則

| 位置 | 規則 | 範例 |
|------|------|------|
| Views/ | `*View.swift` | `ProfessionalEditorView.swift` |
| ViewModels/ | `*ViewModel.swift` | `DocumentViewModel.swift` |
| Models/ | `[實體名].swift` | `Entry.swift` |
| Services/ | `*Service.swift` | `CitationService.swift` |
| Repositories/ | `*Repository.swift` | `EntryRepository.swift` |

## 命名慣例

### 類別/結構：PascalCase

```swift
class ProfessionalEditorView: View { }
struct DocumentViewModel: ObservableObject { }
protocol EntryRepositoryProtocol { }
```

### 函數：camelCase + 動詞開頭

```swift
func fetchAllEntries() -> [Entry]
func createEntry(fields:) -> Entry
func updateDocument(_:title:)
func deleteEntry(withId:)
```

### 變數：camelCase

```swift
let selectedEntry: Entry
var isLoading: Bool
@Published var entries: [Entry] = []
```

## 架構規則

### 分層依賴

```
Views → ViewModels → Repositories → Core Data
          ↓              ↓
       Services ←────────┘
```

### 禁止事項

- ❌ Model 不能依賴 View
- ❌ Repository 不能依賴 ViewModel
- ❌ Service 不能直接依賴 View

### 依賴注入

```swift
// ✅ 正確：建構函數注入
init(repository: EntryRepositoryProtocol = EntryRepository()) {
    self.repository = repository
}

// ❌ 錯誤：直接存取單例
let context = PersistenceController.shared.container.viewContext
```

## 程式碼風格

- 使用 4 個空格縮排
- 大括號 `{` 與宣告同行
- 逗號後加一個空格
- 使用 `/// 文檔註解` 說明 public API
- 使用 `// MARK: -` 分隔邏輯區塊

## 測試命名

```swift
// 格式: test_[對象]_[場景]_[預期結果]
func test_fetchEntries_withValidLibrary_returnsEntries() { }
```

## 禁止事項

1. **禁止 Force Unwrap** - 使用 `guard let` 或 `if let`
2. **禁止硬編碼字串** - 使用 `Constants` enum
3. **禁止巨大函數** - 超過 50 行需拆分
4. **禁止 Massive View** - 超過 300 行需拆分元件
