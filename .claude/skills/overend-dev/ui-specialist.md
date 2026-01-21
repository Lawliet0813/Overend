# UI Specialist - SwiftUI & 使用者介面專家

## 職責範圍

負責所有 UI 相關開發，包括：
- SwiftUI 視圖元件開發
- AppTheme 主題系統管理
- 深色/淺色模式支援
- 佈局與動畫設計
- 使用者互動邏輯
- 三視圖導航系統

**不負責**：
- Core Data 模型定義（由 coredata-specialist 處理）
- API 呼叫邏輯（由 service-specialist 處理）
- 測試撰寫（由 testing-specialist 處理）

## 何時載入此 Skill

當任務包含以下關鍵字時自動載入：
- UI、視圖、View、SwiftUI
- 佈局、Layout、介面
- AppTheme、顏色、深色模式
- 按鈕、列表、卡片等 UI 元件
- 動畫、過渡效果

## 目錄結構

```
OVEREND/Views/
├── NewContentView.swift        # 主容器（三視圖入口）
├── Sidebar/
│   └── NewSidebarView.swift    # 側邊欄
├── Common/
│   └── DynamicToolbar.swift    # 共用工具列
├── EntryList/
│   └── ModernEntryListView.swift    # 文獻列表
├── EntryDetail/
│   └── ModernEntryDetailView.swift  # 文獻詳情
├── Editor/
│   └── EntryEditorView.swift       # 書目編輯器
└── Writer/
    ├── EditorListView.swift        # 寫作中心（卡片網格）
    ├── DocumentCardView.swift       # 文稿卡片
    ├── ProfessionalEditorView.swift # 專業編輯器
    └── CitationInspector.swift      # 引用檢查器
```

## AppTheme 主題系統

### 強制規則

**所有顏色必須來自 `AppTheme.swift`**，禁止硬編碼顏色值。

✅ **正確用法**：
```swift
import SwiftUI

struct MyView: View {
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        Text("標題")
            .foregroundColor(theme.textPrimary)
            .background(theme.card)
            .cornerRadius(theme.cornerRadiusSmall)
    }
}

#Preview {
    MyView()
        .environmentObject(AppTheme())  // 預覽時必須注入
}
```

❌ **錯誤用法**：
```swift
// 禁止直接使用 Color
Text("標題")
    .foregroundColor(.green)
    .background(Color(hex: "#00D97E"))
    
// 禁止硬編碼圓角值
.cornerRadius(8)
```

### 可用的主題屬性

#### 顏色
```swift
theme.primary           // 主色調 (#00D97E)
theme.primaryLight      // 淺色主色調
theme.primaryDark       // 深色主色調

theme.textPrimary       // 主要文字顏色
theme.textSecondary     // 次要文字顏色
theme.textTertiary      // 第三級文字顏色

theme.background        // 頁面背景
theme.surface           // 表面顏色
theme.card              // 卡片背景

theme.border            // 邊框顏色
theme.divider           // 分隔線顏色

theme.success           // 成功狀態
theme.warning           // 警告狀態
theme.error             // 錯誤狀態
theme.info              // 資訊狀態
```

#### 尺寸與間距
```swift
theme.paddingSmall      // 小間距
theme.paddingMedium     // 中間距
theme.paddingLarge      // 大間距

theme.cornerRadiusSmall // 小圓角
theme.cornerRadiusMedium // 中圓角
theme.cornerRadiusLarge  // 大圓角
```

## 命名規範

### 視圖檔案命名

| 視圖類型 | 命名規則 | 範例 |
|---------|---------|------|
| 主要視圖 | `[功能]View` | `EntryListView` |
| 現代化視圖 | `Modern[功能]View` | `ModernEntryListView` |
| 新版視圖 | `New[功能]View` | `NewContentView` |
| 子元件 | `[功能]Card/Item/Row` | `DocumentCardView` |
| 通用元件 | `[描述][類型]` | `DynamicToolbar` |

### 變數命名

```swift
// ✅ 正確
@State private var isShowingSheet = false
@State private var selectedEntry: Entry?
@Binding var searchText: String
@EnvironmentObject var theme: AppTheme

// ❌ 錯誤
@State private var show = false  // 不夠明確
@State private var entry: Entry?  // 缺少 selected 前綴
```

## 深色/淺色模式支援

### 檢查清單

每個視圖必須：
- [ ] 使用 AppTheme 顏色（不硬編碼）
- [ ] 在預覽中測試兩種模式
- [ ] 確認文字可讀性
- [ ] 檢查邊框與分隔線對比度

### 預覽範本

```swift
#Preview("淺色模式") {
    MyView()
        .environmentObject(AppTheme())
        .preferredColorScheme(.light)
}

#Preview("深色模式") {
    MyView()
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
```

## 三視圖導航系統

OVEREND 有三種主要視圖模式：

### 1. 文獻管理模式（Library Mode）
- **入口**：側邊欄「全部文獻」
- **視圖**：`ModernEntryListView` + `ModernEntryDetailView`
- **功能**：瀏覽、搜尋、查看文獻詳情

### 2. 寫作中心模式（Editor List Mode）
- **入口**：側邊欄「寫作中心」
- **視圖**：`EditorListView`（卡片網格）
- **功能**：查看所有文稿、建立新文稿

### 3. 專業編輯模式（Editor Full Mode）
- **入口**：雙擊文稿卡片
- **視圖**：`ProfessionalEditorView`
- **功能**：Word 風格的寫作編輯器

### 視圖狀態管理

```swift
// 定義於 MainViewState.swift
enum ViewMode {
    case library      // 文獻管理
    case editorList   // 寫作中心
    case editorFull   // 專業編輯
}

// 使用方式
@StateObject private var viewState = MainViewState.shared

// 切換視圖
viewState.currentMode = .library
viewState.currentMode = .editorList
viewState.currentMode = .editorFull
```

## 佈局指南

### 標準佈局模式

#### 1. 主從佈局（Master-Detail）
```swift
NavigationSplitView {
    // 側邊欄（Master）
    Sidebar()
} content: {
    // 列表（Content）
    EntryList()
} detail: {
    // 詳情（Detail）
    EntryDetail()
}
```

#### 2. 網格佈局（Grid）
```swift
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 300), spacing: theme.paddingMedium)
], spacing: theme.paddingMedium) {
    ForEach(items) { item in
        CardView(item: item)
    }
}
.padding(theme.paddingLarge)
```

#### 3. 卡片佈局（Card）
```swift
VStack(alignment: .leading, spacing: theme.paddingSmall) {
    // 標題
    Text(title)
        .font(.headline)
        .foregroundColor(theme.textPrimary)
    
    // 內容
    Text(content)
        .font(.body)
        .foregroundColor(theme.textSecondary)
}
.padding(theme.paddingMedium)
.background(theme.card)
.cornerRadius(theme.cornerRadiusMedium)
```

### 間距規範

```swift
// 使用主題定義的間距
.padding(theme.paddingSmall)    // 8pt
.padding(theme.paddingMedium)   // 16pt
.padding(theme.paddingLarge)    // 24pt

// 避免硬編碼
.padding(8)  // ❌ 錯誤
```

## 中文化規範（UI 專屬）

### UI 文字規則

✅ **正確**：
```swift
Text("全部文獻")
Button("新增書目") { }
Label("匯入 BibTeX", systemImage: "square.and.arrow.down")
.contextMenu {
    Button("刪除", role: .destructive) { }
}
```

❌ **錯誤**：
```swift
Text("全部文献")  // 簡體中文
Button("Add Entry") { }  // 英文
Text("导入成功")  // 簡體
```

### 標點符號

- 逗號：，（全形）
- 句號：。（全形）
- 引號：「」（全形）
- 括號：（）（全形）

### SF Symbols 使用

```swift
// ✅ 系統圖示可直接使用
Image(systemName: "plus")
Image(systemName: "trash")
Image(systemName: "doc.text")

// 配合中文標籤
Label("新增", systemImage: "plus")
```

## 常見 UI 模式

### 1. 空狀態視圖

```swift
struct EmptyStateView: View {
    @EnvironmentObject var theme: AppTheme
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: theme.paddingMedium) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(theme.textTertiary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            Text(message)
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(theme.paddingLarge)
    }
}
```

### 2. 載入指示器

```swift
struct LoadingView: View {
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: theme.paddingMedium) {
            ProgressView()
            Text("載入中...")
                .foregroundColor(theme.textSecondary)
        }
    }
}
```

### 3. 錯誤提示

```swift
struct ErrorBanner: View {
    @EnvironmentObject var theme: AppTheme
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(theme.error)
            Text(message)
                .foregroundColor(theme.textPrimary)
            Spacer()
            Button("關閉", action: onDismiss)
        }
        .padding(theme.paddingMedium)
        .background(theme.error.opacity(0.1))
        .cornerRadius(theme.cornerRadiusMedium)
    }
}
```

## 動畫規範

### 標準動畫

```swift
// 使用標準過渡動畫
.animation(.easeInOut(duration: 0.2), value: isExpanded)

// 彈簧動畫
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: offset)

// 避免過度複雜的動畫
// ❌ 不使用超過 0.5 秒的動畫（除非特殊需求）
```

### 過渡效果

```swift
// 淡入淡出
.transition(.opacity)

// 滑動
.transition(.move(edge: .trailing))

// 組合過渡
.transition(.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .opacity
))
```

## 整合檢查清單

### 新增/修改視圖時必須檢查

- [ ] 使用 AppTheme 顏色（無硬編碼）
- [ ] 測試深色/淺色模式
- [ ] UI 文字使用繁體中文
- [ ] 標點符號使用全形
- [ ] 命名符合規範（PascalCase + View）
- [ ] 檔案位置正確（`Views/[子目錄]/`）
- [ ] 與 ViewModel 正確綁定
- [ ] 編譯無錯誤
- [ ] 預覽正常顯示

### 與其他 Skill 的協作

**與 Core Data Specialist 協作**：
- UI 透過 ViewModel 存取 Core Data
- 不直接操作 NSManagedObjectContext
- 使用 `@FetchRequest` 或 ViewModel 提供的資料

**與 Service Specialist 協作**：
- UI 透過 ViewModel 呼叫 Service
- 不直接呼叫 Service 方法
- 錯誤處理由 ViewModel 統一管理

**與 Testing Specialist 協作**：
- 提供可測試的 UI 結構
- 使用 `accessibilityIdentifier` 標記元件
- 確保 UI 邏輯可獨立測試

## 常見問題

### Q: 如何新增一個視圖？

```
1. 確認視圖名稱（例如：ExportBibliographyView）
2. 確認目錄位置（例如：OVEREND/Views/Export/）
3. 使用 create_file 建立檔案
4. 包含基本結構：
   - import SwiftUI
   - @EnvironmentObject var theme: AppTheme
   - 預覽程式碼
5. 編譯檢查
```

### Q: 顏色顯示不正確？

```
檢查項目：
1. 是否正確注入 AppTheme？
2. 是否有硬編碼顏色值？
3. 深色/淺色模式是否都測試過？
```

### Q: 如何實作三視圖切換？

```swift
// 在需要切換視圖的地方
@StateObject private var viewState = MainViewState.shared

Button("進入寫作中心") {
    viewState.currentMode = .editorList
}
```

---

**版本**: 1.0
**建立日期**: 2025-01-21
**維護者**: OVEREND 開發團隊
