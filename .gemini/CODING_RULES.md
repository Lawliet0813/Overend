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
| Utilities/ | `*+Extensions.swift` 或 `*Helper.swift` | `String+Extensions.swift` |
| Theme/ | `*Theme.swift` 或 `*Style.swift` | `AppTheme.swift` |

## 檔案分類規範

### 資料夾結構一覽

```
OVEREND/
├── App/                    # App 入口與生命週期
│   └── Intents/            # App Intents (Siri/Shortcuts)
├── Core/                   # 基礎設施 (Logger, EventBus, FFI)
├── Models/                 # Core Data 與資料模型
│   └── [Feature]/          # 功能專屬模型子資料夾
├── Repositories/           # 資料存取層
├── Services/               # 業務邏輯
│   ├── Core/               # 核心服務 (DI, Batch)
│   ├── AI/                 # AI 服務
│   │   ├── Core/           # AI 核心 (UnifiedAIService)
│   │   ├── Domains/        # 領域 AI (翻譯、寫作)
│   │   ├── Providers/      # AI 提供者
│   │   └── Agent/          # Agent 系統
│   ├── Academic/           # 學術服務
│   ├── Bibliography/       # 書目服務
│   ├── Document/           # 文件服務
│   └── External/           # 外部整合
├── ViewModels/             # MVVM 視圖模型
├── Views/                  # SwiftUI 視圖
│   ├── Components/         # 可重用 UI 元件
│   │   ├── Buttons/
│   │   ├── Cards/
│   │   ├── Inputs/
│   │   └── Feedback/
│   └── [Feature]/          # 功能專屬視圖
├── Theme/                  # 主題與樣式
├── Utilities/              # 通用工具
└── Platform/               # 平台適配
    ├── macOS/
    └── iPad/
```

### 檔案放置規則

#### 1. Views (視圖)

| 類型 | 放置位置 | 範例 |
|------|---------|------|
| 功能主視圖 | `Views/[Feature]/` | `Views/Emerald/EmeraldLibraryView.swift` |
| 可重用元件 | `Views/Components/[Type]/` | `Views/Components/Buttons/GlassButton.swift` |
| 視圖擴展 | 與主視圖同目錄 | `ModernEntryDetailView+Methods.swift` |
| 通用視圖 | `Views/Common/` | `Views/Common/EmptyStateView.swift` |

#### 2. Services (服務)

| 類型 | 放置位置 | 範例 |
|------|---------|------|
| AI 相關 | `Services/AI/[子類別]/` | `Services/AI/Providers/GeminiProvider.swift` |
| 學術功能 | `Services/Academic/[子類別]/` | `Services/Academic/Citation/CitationService.swift` |
| 文件處理 | `Services/Document/[子類別]/` | `Services/Document/OCR/OCRService.swift` |
| 外部 API | `Services/External/` | `Services/External/CrossRefService.swift` |
| 核心服務 | `Services/Core/` | `Services/Core/ServiceContainer.swift` |

#### 3. Models (模型)

| 類型 | 放置位置 | 範例 |
|------|---------|------|
| Core Data 實體 | `Models/` | `Models/Entry.swift` |
| 功能專屬模型 | `Models/[Feature]/` | `Models/Companion/CompanionLevel.swift` |
| DTO/Response | `Services/[對應服務]/Models/` | `Services/AI/Models/AIResponse.swift` |

### 何時建立新資料夾

| 條件 | 動作 |
|------|------|
| 功能有 3+ 個相關檔案 | 建立功能子資料夾 |
| 服務有多個子系統 | 在 `Services/` 下建立類別資料夾 |
| UI 元件可跨功能重用 | 放入 `Components/[Type]/` |
| 平台專屬程式碼 | 放入 `Platform/[OS]/` |

### 禁止事項

- ❌ **禁止根目錄散落** - 新檔案必須放入適當子資料夾
- ❌ **禁止巢狀過深** - 最多 4 層 (`Services/AI/Domains/TranslationAIDomain.swift`)
- ❌ **禁止名稱重複** - 不同資料夾不可有同名檔案
- ❌ **禁止混合層級** - View 不能放在 Services，反之亦然

### 擴展檔案規則

當主檔案超過 **300 行**，使用擴展拆分：

```swift
// 主檔案
ModernEntryDetailView.swift         // 主結構與 body

// 擴展檔案 (同目錄)
ModernEntryDetailView+Methods.swift  // 方法
ModernEntryDetailView+Subviews.swift // 子視圖

// ⚠️ 注意：擴展需要存取的屬性不可標記為 private
```

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
