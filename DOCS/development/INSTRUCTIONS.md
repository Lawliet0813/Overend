# OVEREND 專案開發指南

## 快速開始

### 開發環境需求

- macOS 13.0 (Ventura) 或以上
- Xcode 15.0 或以上
- Swift 5.9+

### 開啟專案

```bash
cd /Users/lawliet/OVEREND
open OVEREND.xcodeproj
```

### 執行專案

1. 在 Xcode 中選擇 **OVEREND** scheme
2. 選擇目標裝置為 **My Mac**
3. 按下 `Cmd + R` 執行

---

## 專案結構

```
OVEREND/
├── OVEREND.xcodeproj          # Xcode 專案檔案
├── OVEREND/
│   ├── Models/                # Core Data 模型
│   │   ├── Entry.swift        # 文獻書目
│   │   ├── Library.swift      # 文獻庫
│   │   ├── Group.swift        # 分類群組
│   │   ├── Attachment.swift   # 附件
│   │   └── Document.swift     # 文稿
│   │
│   ├── Theme/                 # 主題系統
│   │   └── AppTheme.swift     # 深色/淺色模式管理
│   │
│   ├── Services/              # 服務層
│   │   ├── DOIService.swift       # DOI 查詢
│   │   ├── CrossRefService.swift  # CrossRef API
│   │   ├── CitationService.swift  # 引用格式生成
│   │   ├── BibTeXParser.swift     # BibTeX 解析
│   │   ├── BibTeXGenerator.swift  # BibTeX 生成
│   │   └── PDFService.swift       # PDF 處理
│   │
│   ├── ViewModels/            # 視圖模型
│   │   ├── LibraryViewModel.swift
│   │   ├── EntryViewModel.swift
│   │   └── MainViewState.swift
│   │
│   └── Views/                 # UI 視圖
│       ├── NewContentView.swift       # 主容器（新 UI 入口）
│       ├── Sidebar/                   # 側邊欄
│       │   └── NewSidebarView.swift
│       ├── Common/                    # 共用元件
│       │   └── DynamicToolbar.swift
│       ├── EntryList/                 # 文獻列表
│       │   └── ModernEntryListView.swift
│       ├── EntryDetail/               # 詳情面板
│       │   └── ModernEntryDetailView.swift
│       ├── Editor/                    # 書目編輯
│       │   └── EntryEditorView.swift
│       └── Writer/                    # 寫作編輯器
│           ├── EditorListView.swift
│           ├── DocumentCardView.swift
│           ├── ProfessionalEditorView.swift
│           └── CitationInspector.swift
│
├── PROJECT_STATUS.md          # 專案進度總覽
└── OVEREND_Brand_Product_Design_Manual.md  # 品牌設計手冊
```

---

## 核心技術

### 框架

- **SwiftUI** - UI 框架
- **Core Data** - 資料持久化
- **PDFKit** - PDF 處理

### 主題系統

所有顏色定義集中在 `AppTheme.swift`：

```swift
// 使用方式
@EnvironmentObject var theme: AppTheme

Text("標題")
    .foregroundColor(theme.textPrimary)
    .background(theme.card)
```

**主色調**：`#00D97E`

---

## 常用開發指令

### 建置專案

```bash
xcodebuild -scheme OVEREND -destination 'platform=macOS' build
```

### 檢查編譯錯誤

```bash
xcodebuild -scheme OVEREND build 2>&1 | grep -E "error:"
```

### 清除建置快取

```bash
xcodebuild clean -scheme OVEREND
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

## 開發規範

### 命名慣例

| 類型 | 規則 | 範例 |
|------|------|------|
| 視圖 | PascalCase + View | `ModernEntryListView` |
| 視圖模型 | PascalCase + ViewModel | `LibraryViewModel` |
| 服務 | PascalCase + Service | `CitationService` |
| 檔案 | 與類別同名 | `EntryDetailView.swift` |

### UI 元件命名

新版 UI 使用 `Modern` 或 `New` 前綴以區分舊版：

- `NewContentView` - 新版主容器
- `NewSidebarView` - 新版側邊欄
- `ModernEntryListView` - 現代化列表
- `ModernEntryDetailView` - 現代化詳情

### 中文化

- 所有 UI 文字使用繁體中文
- 使用台灣學術用語（如「書目」而非「文獻」）
- 標點符號使用全形（，。「」）

---

## 三視圖導航

應用程式有三種主要模式：

| 模式 | 說明 | 入口 |
|------|------|------|
| **文獻管理** | 文獻列表 + 詳情面板 | 側邊欄「全部文獻」 |
| **寫作中心** | 文稿卡片網格 | 側邊欄「寫作中心」 |
| **專業編輯** | Word 風格編輯器 | 雙擊文稿卡片 |

視圖狀態由 `MainViewState` 管理：

```swift
enum ViewMode {
    case library      // 文獻管理
    case editorList   // 寫作中心
    case editorFull   // 專業編輯
}
```

---

## 文獻管理

### 匯入 BibTeX

```swift
// 在 NewContentView.swift
private func importBibTeX() {
    // 使用 NSOpenPanel 選擇 .bib 檔案
    // 透過 BibTeXParser 解析
}
```

### 匯入 PDF

```swift
// PDF 匯入會自動：
// 1. 建立 Entry
// 2. 從檔名提取標題
// 3. 生成 citation key
// 4. 附加 PDF 檔案
```

### 引用格式

支援格式定義於 `CitationService.swift`：

- APA 7th Edition
- MLA 9th Edition
- BibTeX

---

## 相關文件

| 文件 | 說明 |
|------|------|
| `PROJECT_STATUS.md` | 專案進度總覽 |
| `OVEREND_Brand_Product_Design_Manual.md` | 品牌設計手冊 |

---

## 常見問題

### Q: 編譯錯誤 "CitationCard redeclared"

**A:** 不同檔案有同名 struct，使用前綴區分（如 `DetailCitationCard`）

### Q: PDF 無法開啟

**A:** 檢查 App Sandbox 權限，確保 `startAccessingSecurityScopedResource()` 正確使用

### Q: Core Data 驗證錯誤

**A:** 確保必填欄位（如 `bibtexRaw`）不為 nil

---

**最後更新：2025-12-29**
