# ModernEditorToolbar 整合指南

## 概述

`ModernEditorToolbar` 是 OVEREND 的現代化編輯器工具列，靈感來自 Claude Writing Assistant，提供更清晰的視覺設計和更流暢的使用體驗。

## 主要特色

### 1. 現代化設計
- **扁平化按鈕**：使用圓角卡片樣式，視覺更清爽
- **活躍狀態指示**：當前選取的格式（粗體、斜體等）會高亮顯示
- **智能工具列**：自動隱藏不常用功能，保持界面整潔
- **響應式佈局**：支援橫向滾動，適應不同窗口大小

### 2. 字數統計
- 實時顯示字符數
- 優雅的徽章設計
- 自動從 RTF 數據中計算

### 3. 改進的選單
- **字體選單**：下拉式選擇，當前字體有打勾標記
- **顏色選擇器**：視覺化顏色面板，支援文字和螢光筆
- **行距選單**：快速切換 1.0 / 1.15 / 1.5 / 2.0

## 如何整合

### 步驟 1：在 DocumentEditorView 中替換工具列

找到原本的 `EditorToolbar`：

```swift
// 舊版
EditorToolbar(
    document: document,
    onImport: { showImportSheet = true },
    // ... 其他參數
)
```

替換為 `ModernEditorToolbar`：

```swift
// 新版
ModernEditorToolbar(
    document: document,
    onImport: { showImportSheet = true },
    onExport: { showExportMenu = true },
    onUndo: { performUndo() },
    onRedo: { performRedo() },
    onFontChange: { fontName in applyFont(fontName) },
    onBold: { applyFormat(.bold) },
    onItalic: { applyFormat(.italic) },
    onUnderline: { applyFormat(.underline) },
    onAlignLeft: { applyAlignment(.left) },
    onAlignCenter: { applyAlignment(.center) },
    onAlignRight: { applyAlignment(.right) },
    onIncreaseFontSize: { adjustFontSize(by: 2) },
    onDecreaseFontSize: { adjustFontSize(by: -2) },
    onLineSpacing: { spacing in applyLineSpacing(spacing) },
    onTextColor: { color in applyTextColor(color) },
    onHighlight: { color in applyHighlight(color) },
    onList: { type in applyList(type) },
    canUndo: $canUndo,
    canRedo: $canRedo,
    currentFont: $currentFont,
    showCitationSidebar: $showCitationSidebar,
    isBoldActive: $isBoldActive,
    isItalicActive: $isItalicActive,
    isUnderlineActive: $isUnderlineActive
)
.environmentObject(theme)
```

### 步驟 2：添加 AI 文本分析面板

在編輯器的右側添加分析面板：

```swift
HSplitView {
    // 主編輯區域
    RichTextEditorView(...)
    
    // 引用側邊欄（原有）
    if showCitationSidebar {
        CitationSidebar(...)
    }
    
    // AI 分析面板（新增）
    if showAIAnalysis {
        AITextAnalysisPanel(
            isVisible: $showAIAnalysis,
            attributedText: attributedText,
            onApplySuggestion: { suggestion in
                applySuggestion(suggestion)
            }
        )
    }
}
```

### 步驟 3：添加狀態變數

在 `DocumentEditorView` 中添加：

```swift
@State private var showAIAnalysis = false
```

### 步驟 4：實作建議套用函數

```swift
private func applySuggestion(_ suggestion: TextSuggestion) {
    guard let textView = textViewRef else { return }
    
    // 找到問題文本的範圍
    let text = textView.string
    if let range = text.range(of: suggestion.issue) {
        let nsRange = NSRange(range, in: text)
        
        // 替換文本
        textView.replaceCharacters(
            in: nsRange,
            with: suggestion.suggestion
        )
        
        // 更新文檔
        updateDocument()
    }
}
```

## AI 分析功能說明

### AITextAnalysisPanel 元件

這個面板提供智能文本分析功能：

#### 分析類別
- **文法**：檢查語法錯誤
- **拼寫**：找出拼寫錯誤
- **標點**：檢查標點符號使用
- **風格**：提供風格改進建議
- **清晰度**：改善表達清晰度

#### 使用流程
1. 用戶點擊「分析」按鈕
2. 系統分析文本內容
3. 顯示分類建議列表
4. 用戶可以：
   - **套用**：自動替換問題文本
   - **忽略**：移除該建議
   - **篩選**：按分類查看建議

### 目前實作狀態

**已完成**：
- ✅ UI 界面設計
- ✅ 分類篩選系統
- ✅ 建議卡片展示
- ✅ 模擬數據生成

**待整合**：
- ⏳ AI Service 整合（需要連接實際 AI API）
- ⏳ 文本高亮顯示（在編輯器中標記問題）
- ⏳ 批量套用功能

### AI Service 整合方案

目前使用模擬數據，實際部署時可以：

**方案 A：本地 AI 模型**
```swift
// 使用 Apple 的 Core ML 或 Create ML
let model = try TextAnalysisModel(configuration: config)
let prediction = try model.prediction(text: inputText)
```

**方案 B：雲端 API**
```swift
// 整合 Claude API 或其他服務
let service = AIAnalysisService()
let suggestions = try await service.analyze(text: inputText)
```

**方案 C：混合模式**
- 簡單檢查（拼寫、標點）→ 本地處理
- 複雜分析（風格、清晰度）→ 雲端 API

## 視覺效果

### 工具列對比

**舊版工具列**：
- 密集排列的按鈕
- 缺少視覺反饋
- 字體選擇不直觀

**新版工具列**：
- 圓角卡片設計
- 活躍狀態高亮
- 下拉式字體選單
- 視覺化顏色選擇器

### 字數統計徽章

```
┌─────────────┐
│ 📄 1,234 字 │
└─────────────┘
```

### AI 分析面板

```
┌──────────────────────┐
│ ✨ AI 文本分析    🔄 │
├──────────────────────┤
│ [全部] [文法] [拼寫] │
├──────────────────────┤
│ ┌──────────────────┐ │
│ │ [文法]     ●     │ │
│ │ 的的 → 的        │ │
│ │ 重複的助詞...    │ │
│ │ [套用] [忽略]    │ │
│ └──────────────────┘ │
└──────────────────────┘
```

## 下一步

1. **測試編譯**
   ```bash
   xcodebuild -scheme OVEREND build
   ```

2. **整合到主視圖**
   - 更新 `DocumentEditorView.swift`
   - 添加 AI 分析按鈕到工具列

3. **完善 AI 功能**
   - 實作真實的 AI 分析邏輯
   - 添加文本高亮顯示
   - 完善錯誤處理

4. **用戶測試**
   - 收集使用反饋
   - 優化 UI/UX
   - 調整功能優先級

## 注意事項

### AppTheme 依賴
所有元件都依賴 `AppTheme`，確保：
```swift
.environmentObject(AppTheme())
```

### Core Data 上下文
Document 操作需要：
```swift
.environment(\.managedObjectContext, viewContext)
```

### 預覽支援
記得為預覽提供測試數據：
```swift
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let doc = Document(context: context)
    // ... 設置測試數據
}
```

## 疑難排解

### 問題：工具列按鈕無反應
**解決**：檢查回調函數是否正確綁定

### 問題：字數統計不更新
**解決**：確保 `document.rtfData` 有正確更新

### 問題：AI 分析面板不顯示
**解決**：檢查 `showAIAnalysis` 狀態綁定

### 問題：顏色選擇器顯示異常
**解決**：確認 AppTheme 顏色定義完整

## 相關文件

- `ui-specialist.md` - UI 開發規範
- `AppTheme.swift` - 主題系統文檔
- `DocumentEditorView.swift` - 編輯器主視圖
- `RichTextEditor.swift` - 富文本編輯核心

---

**最後更新**：2025-01-21  
**版本**：1.0.0  
**作者**：UI Specialist
