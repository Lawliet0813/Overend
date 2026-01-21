# AI智慧中心 - 學術翻譯匯入文稿功能與多文獻庫支援

## 概述

本次更新為AI智慧中心的學術翻譯功能新增了以下特性：

### ✅ 已完成功能

1. **文獻庫匯入功能強化** - 支援從多個文獻庫匯入內容
2. **智能文獻庫選擇** - 自動識別並切換不同文獻庫
3. **內容類型篩選** - 可選擇匯入摘要、筆記或 BibTeX
4. **文獻庫標籤顯示** - 在全部文獻檢視時顯示來源文獻庫

## 功能詳情

### 1. 多文獻庫支援

**位置**: `OVEREND/Views/AICenter/ContentImportPicker.swift`

#### 新增功能：

- **文獻庫下拉選單**：當系統中有多個文獻庫時，會自動顯示文獻庫選擇器
- **全部文獻模式**：可以選擇「全部文獻庫」來檢視所有文獻
- **文獻計數顯示**：每個文獻庫旁會顯示包含的文獻數量

```swift
Picker("選擇文獻庫", selection: $selectedLibrary) {
    Text("全部文獻庫").tag(nil as Library?)
    ForEach(Array(libraries), id: \.id) { library in
        HStack {
            Text(library.name)
            Text("(\(library.entryCount))")
        }
        .tag(library as Library?)
    }
}
```

#### 使用方式：

1. 在學術翻譯頁面點擊「從文獻庫導入」
2. 如果有多個文獻庫，會看到文獻庫選擇器
3. 選擇特定文獻庫或「全部文獻庫」
4. 選擇內容類型（摘要/筆記/BibTeX）
5. 點擊文獻條目即可匯入內容

### 2. 智能篩選與搜尋

#### 篩選邏輯：

```swift
private var filteredEntries: [Entry] {
    var entries = Array(allEntries)
    
    // 按文獻庫篩選
    if let selectedLibrary = selectedLibrary {
        entries = entries.filter { $0.library?.id == selectedLibrary.id }
    }
    
    // 按搜尋文字篩選
    if !searchText.isEmpty {
        let query = searchText.lowercased()
        entries = entries.filter { entry in
            entry.title.lowercased().contains(query) ||
            entry.author.lowercased().contains(query) ||
            entry.citationKey.lowercased().contains(query)
        }
    }
    
    return entries
}
```

### 3. 文獻庫標籤顯示

當選擇「全部文獻庫」時，每個文獻條目會顯示其所屬文獻庫的標籤：

```swift
// 文獻庫標籤（當顯示全部文獻庫時）
if selectedLibrary == nil, let library = entry.library {
    Text(library.name)
        .font(.system(size: 9, weight: .medium))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(theme.accentLight)
        .foregroundColor(theme.accent)
        .cornerRadius(4)
}
```

### 4. 空狀態優化

系統會根據不同情況顯示適當的提示訊息：

- **完全沒有文獻**：「文獻庫為空，請先從主介面匯入文獻」
- **選定的文獻庫為空**：「此文獻庫中尚無文獻，請選擇其他文獻庫或匯入文獻」
- **搜尋無結果**：「找不到符合的文獻，請嘗試其他搜尋關鍵字」

## 使用者介面

### 學術翻譯頁面

```
┌─────────────────────────────────────────┐
│  AI智慧中心 > 學術翻譯                    │
├─────────────────────────────────────────┤
│  [輸入文本區域]                          │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [從文獻庫導入] ← 點擊開啟選擇器         │
│  [翻譯] [雙語對照] [清除]               │
└─────────────────────────────────────────┘
```

### 文獻庫匯入選擇器

```
┌──────────────────────────────────────────┐
│  從文獻庫導入                      [✕]   │
│  選擇文獻庫和要導入的內容                 │
├──────────────────────────────────────────┤
│  📚 文獻庫: [全部文獻庫 ▼]               │
├──────────────────────────────────────────┤
│  導入內容: [摘要] [筆記] [BibTeX]        │
├──────────────────────────────────────────┤
│  🔍 搜尋文獻...                          │
├──────────────────────────────────────────┤
│  ┌────────────────────────────────────┐ │
│  │ 📄 文獻標題 1            [研究庫]  │ │
│  │    作者名稱 • 2023      ⬇          │ │
│  │    摘要預覽...                     │ │
│  ├────────────────────────────────────┤ │
│  │ 📄 文獻標題 2            [教學庫]  │ │
│  │    作者名稱 • 2024      ⬇          │ │
│  └────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

## 技術實現

### Core Data 查詢

使用 `@FetchRequest` 來獲取所有文獻庫和文獻：

```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
    animation: .default
)
private var libraries: FetchedResults<Library>

@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)],
    animation: .default
)
private var allEntries: FetchedResults<Entry>
```

### 狀態管理

```swift
@State private var selectedLibrary: Library?      // 選擇的文獻庫
@State private var searchText: String = ""        // 搜尋文字
@State private var selectedContentType: LibraryImportContentType = .abstract
```

## 未來擴展建議

### 短期改進

1. **批次匯入** - 支援一次選擇多個文獻並合併內容
2. **內容預處理** - 自動清理和格式化匯入的內容
3. **最近使用記錄** - 記住上次選擇的文獻庫和內容類型

### 中期改進

1. **智能推薦** - 根據翻譯主題推薦相關文獻
2. **標籤篩選** - 支援按文獻標籤篩選
3. **分組檢視** - 按文獻庫、作者、年份等分組顯示

### 長期改進

1. **AI 內容摘要** - 自動總結文獻內容
2. **跨文獻比對** - 比對多篇文獻的異同
3. **引用網路視覺化** - 顯示文獻間的引用關係

## 測試建議

### 功能測試

- [x] 單一文獻庫情境（不顯示選擇器）
- [x] 多個文獻庫情境（顯示選擇器）
- [x] 空文獻庫提示
- [x] 搜尋功能
- [x] 內容類型切換
- [x] 文獻庫標籤顯示

### 邊界測試

- [ ] 大量文獻（1000+ 條目）效能測試
- [ ] 長文獻名稱顯示測試
- [ ] 特殊字元搜尋測試
- [ ] 無權限文獻庫處理

### 整合測試

- [ ] 與學術翻譯功能的整合
- [ ] 與文獻管理系統的同步
- [ ] Core Data 並發訪問測試

## 相關文件

- `ContentImportPicker.swift` - 內容匯入選擇器
- `AcademicTranslationView.swift` - 學術翻譯主視圖
- `LibraryViewModel.swift` - 文獻庫視圖模型
- `Entry.swift` - 文獻條目模型
- `Library.swift` - 文獻庫模型

## 版本資訊

- **版本**: 1.0.0
- **更新日期**: 2026-01-08
- **開發者**: AI Assistant
- **狀態**: ✅ 已完成並測試編譯
