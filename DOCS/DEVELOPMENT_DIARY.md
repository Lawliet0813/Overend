# OVEREND 開發日記

> **整合自 DOCS 資料夾所有開發文件**  
> **最後更新：** 2026-01-02 (09:00)  
> **專案進度：** 約 98%

---

## 📖 目錄

1. [專案概述](#專案概述)
2. [開發時間線](#開發時間線)
3. [核心功能開發](#核心功能開發)
4. [技術決策與架構](#技術決策與架構)
5. [問題解決紀錄](#問題解決紀錄)
6. [待開發功能](#待開發功能)

---

## 專案概述

### 品牌使命

**讓每位研究者都能專注於研究本質，而非工具操作。**

OVEREND 是整合型學術寫作軟體，將文字編輯器與文獻管理系統完美融合，專為華語研究者設計。

### 產品公式

```
OVEREND = 文字編輯器 + 文獻管理 + AI 輔助
       = Word + EndNote（無插件、原生繁中）
```

### 開發環境

| 項目 | 說明 |
|------|------|
| 系統 | Mac mini M4 (RAM 16G) |
| 開發工具 | Xcode |
| 語言 | Swift + SwiftUI |
| 資料庫 | CoreData |

---

## 開發時間線

### 2025-12-27 ～ 2025-12-28：繁體中文優化

**重點工作：**

- ✅ 術語全面中文化（條目 → 書目、組群 → 資料夾、Citation Key → 引用鍵）
- ✅ 量詞統一（筆/個）
- ✅ APA 7th 引用格式台灣習慣適配
- ✅ PDF 匯入元數據增強（支援民國年轉西元）
- ✅ 作者識別率提升至 80%+

**修改範圍：** 9 個檔案、33+ 處修改

---

### 2025-12-28 ～ 2025-12-29：UI 全面重新設計

**主題系統（AppTheme.swift）**

- 深色/淺色模式切換
- 主色調 `#00D97E`（Spring Green）
- 集中管理所有顏色定義

**新建檔案清單：**

| 檔案 | 說明 |
|------|------|
| `Theme/AppTheme.swift` | 主題管理 |
| `Views/NewContentView.swift` | 主容器視圖 |
| `Views/Sidebar/NewSidebarView.swift` | 現代化側邊欄 |
| `Views/Common/DynamicToolbar.swift` | 動態工具列 |
| `Views/EntryList/ModernEntryListView.swift` | 現代化文獻列表 |
| `Views/EntryDetail/ModernEntryDetailView.swift` | 現代化詳情面板 |
| `Views/Writer/EditorListView.swift` | 文稿列表 |
| `Views/Writer/DocumentCardView.swift` | 文稿卡片元件 |
| `Views/Writer/ProfessionalEditorView.swift` | 專業編輯器 |
| `Views/Writer/CitationInspector.swift` | 引用檢視器 |

**佈局修正：**

- 改用 HStack 作為根佈局容器
- 移除 macOS 預設視窗標題列
- 側邊欄頂部加入 "OVEREND" 品牌 Header

---

### 2025-12-29：格式系統實作

**核心目標：**

- ✅ 格式不跑版（HTML + CSS 內部格式）
- ✅ 一鍵套用範本（政大論文格式）
- ✅ Word 匯入支援
- ✅ 精確 PDF 匯出（WebKit 渲染）

**新增檔案：**

- `FormatTemplate.swift`（452 行）- 範本資料結構
- `TemplateManager.swift`（146 行）- 範本管理器
- `DocumentFormatter.swift`（357 行）- HTML 轉換層
- `PDFExporter.swift`（94 行）- PDF 匯出器
- `WordImporter.swift`（143 行）- Word 匯入器

**技術決策：** 使用 HTML + CSS 作為內部格式，因為：

1. CSS 規則精確到 0.1pt
2. 易於範本化（切換 CSS = 切換格式）
3. WKWebView 渲染保證編輯器 = PDF 輸出一致

---

### 2025-12-30 ～ 2025-12-31：UX 改進實作

**P0 高優先完成項目：**

- ✅ 批次操作功能（多選、批次刪除/匯出）
- ✅ @ 快速引用插入（即時搜尋與插入）
- ✅ Toast 提示系統
- ✅ 空狀態設計
- ✅ 右鍵選單（完整上下文選單支援）
- ✅ 快捷鍵支援
- ✅ 拖曳操作（PDF 拖曳匯入）

**P1 中優先完成項目：**

- ✅ 數量統計顯示
- ✅ 載入狀態指示
- ✅ 詳情面板優化

---

### 2025-12-31 ～ 2026-01-01：AI 智慧功能整合

**Apple Intelligence 整合：**

- ✅ `AppleAIService.swift` - 核心 AI 服務
- ✅ 文章摘要生成
- ✅ 關鍵詞提取
- ✅ 智慧分類建議
- ✅ 寫作優化建議

**LaTeX 混合模式：**

- ✅ `LaTeXRenderer.swift` - LaTeX → 圖片渲染
- ✅ `AILatexGenerator.swift` - 自然語言 → LaTeX
- ✅ `LaTeXSupportedTextView.swift` - 支援 LaTeX 的文字視圖
- ✅ `LaTeXFormulaSheet.swift` - 公式插入面板

**AI 智慧排版：**

- ✅ `AILayoutFormatter.swift` - APA 格式智慧排版
- ✅ 引用格式自動修正
- ✅ 目錄自動生成
- ✅ 段落間距調整

**番茄鐘專注工具：**

- ✅ `PomodoroTimer.swift` 整合
- ✅ `PomodoroView.swift` 狀態列倒數顯示

---

### 2026-01-01：Word 風格編輯器優化

**新功能：**

- ✅ A4 分頁檢視模擬
- ✅ 尺規工具列（模擬 Word 尺規樣式）
- ✅ Undo/Redo 功能整合
- ✅ 自適應寬度佈局

**PDF 匯出修復：**

- 問題：匯出的 PDF 顯示亂碼（雙重轉換導致）
- 解決：直接使用已儲存的 HTML 匯出，避免 htmlData → NSAttributedString → HTML 的雙重轉換

---

### 2026-01-02：UI 立體感增強與批次匯入

**UI 立體感全面升級：**

- ✅ 陰影系統升級（強度提升 50%，新增 Level 5）
- ✅ 卡片和按鈕添加漸變光澤（LinearGradient）
- ✅ 懸停浮起效果（動態陰影 + 1.02x 縮放）
- ✅ 漸變邊框增加深度感

**批次 PDF 匯入功能：**

- ✅ 啟用多文件選擇（`allowsMultipleSelection = true`）
- ✅ 單選：AI 預覽流程（現有體驗）
- ✅ 多選：批次自動匯入（每 5 個更新進度）
- ✅ `savePDFEntry()` 方法實現

**AI 智慧中心：**

- ✅ 新增 AI 智慧中心側邊欄按鈕
- ✅ `AICenterView` 視圖整合

**修改檔案：**

| 檔案 | 修改內容 |
|------|----------|
| `DesignTokens.swift` | 陰影系統升級（5 級 + 發光效果） |
| `NewSidebarView.swift` | AI 中心按鈕、按鈕漸變、陰影、縮放 |
| `DocumentCardView.swift` | 卡片漸變光澤、動態陰影 |
| `ModernEntryListView.swift` | 表格漸變背景、邊框、陰影 |
| `NewContentView.swift` | 批次 PDF 匯入、savePDFEntry 方法 |
| `AILatexGenerator.swift` | 添加 @available(macOS 26.0, *) |

---

## 核心功能開發

### 一、文獻管理系統（100%）

```
功能模組：
├── PDF 匯入（增強版元數據提取）
├── BibTeX 匯入/匯出
├── DOI 自動查詢（CrossRef API、三層回退機制）
├── 文獻分類與資料夾
├── 多選與批次操作
└── 書目編輯器
```

**DOI 識別增強：**

- 擴大掃描範圍：3 → 5 頁
- 支援多種格式：`doi:`, `https://doi.org/`, `http://dx.doi.org/`
- 識別率：70% → 95%+

**作者識別增強：**

- 擴大掃描範圍：800 → 2000 字元
- 多重識別策略
- 支援中英文姓名格式
- 識別率：30% → 80%+

---

### 二、引用系統（100%）

**支援格式：**

- APA 7th Edition
- MLA 9th Edition
- BibTeX 格式

**功能：**

- Citation Key 自動生成
- 一鍵複製引用
- @ 快速引用插入（即時搜尋）
- RTF 富文本格式複製（保留斜體等樣式）

---

### 三、寫作中心（90%）

```
Views/Writer/
├── EditorListView.swift         ✅ 文稿卡片網格
├── DocumentCardView.swift       ✅ 刪除功能、懸停效果
├── ProfessionalEditorView.swift ✅ A4 分頁、尺規、Undo/Redo
├── RichTextEditor.swift         ✅ LaTeX 支援、@ 引用
├── CitationInspector.swift      ✅ 格式選擇、搜尋
└── FloatingAIAssistant.swift    ✅ AI 排版整合
```

---

### 四、AI 智慧功能（100%）

| 功能 | 說明 | 狀態 |
|------|------|------|
| LaTeX 混合模式 | 自然語言生成數學公式 | ✅ |
| 智慧排版 | 自動調整為 APA 格式 | ✅ |
| 引用格式修正 | 自動修正為 APA 7th | ✅ |
| 目錄生成 | 自動產生階層式目錄 | ✅ |
| 段落間距調整 | 學術論文格式排版 | ✅ |
| 文字潤飾 | AI 改寫與優化 | ✅ |

**系統需求：**

- macOS 15.1+ (Apple Intelligence)
- Apple M1+ 晶片
- MacTeX 或 BasicTeX（LaTeX 渲染）

---

## 技術決策與架構

### 專案結構

```
OVEREND/
├── Models/                    # 資料模型
│   ├── Entry.swift            # 文獻書目
│   ├── Library.swift          # 文獻庫
│   ├── Group.swift            # 資料夾
│   ├── Document.swift         # 文章文件
│   └── FormatTemplate.swift   # 格式範本
│
├── Theme/                     # 主題系統
│   └── AppTheme.swift         # 深色/淺色模式
│
├── Services/                  # 服務層
│   ├── DOIService.swift       # DOI 查詢
│   ├── CrossRefService.swift  # CrossRef API
│   ├── CitationService.swift  # 引用格式
│   ├── PDFService.swift       # PDF 處理
│   ├── AppleAIService.swift   # Apple AI 整合
│   ├── LaTeXRenderer.swift    # LaTeX 渲染
│   ├── AILayoutFormatter.swift # AI 排版
│   └── PomodoroTimer.swift    # 番茄鐘
│
├── ViewModels/                # 視圖模型
│   ├── LibraryViewModel.swift
│   └── MainViewState.swift
│
└── Views/                     # 視圖層
    ├── NewContentView.swift
    ├── Sidebar/
    ├── Common/
    ├── EntryList/
    ├── EntryDetail/
    ├── Editor/
    └── Writer/
```

### 資料流程

```
使用者編輯
    ↓
NSTextView (NSAttributedString)
    ↓
儲存時轉換
    ├─→ HTML + CSS (主要格式)
    └─→ RTF (向下相容)
    ↓
Core Data (Document 實體)
    ↓
匯出時
    ├─→ PDF (透過 WKWebView)
    └─→ HTML (預覽)
```

---

## 問題解決紀錄

### 問題 1：PDF 匯出亂碼

**症狀：** 匯出的 PDF 顯示 PK、FK、driver 等片段

**根本原因：** 雙重轉換 — htmlData → NSAttributedString → HTML → PDF

**解決方案：**

```swift
// 直接使用已儲存的 HTML，避免雙重轉換
if let htmlData = htmlData,
   let existingHTML = String(data: htmlData, encoding: .utf8) {
    PDFExporter.exportFromHTML(existingHTML, ...)
}
```

---

### 問題 2：側邊欄與主視窗間隙

**症狀：** NavigationSplitView 造成無法消除的間隙

**解決方案：**

- 改用 HStack 作為根佈局容器
- 精確控制 NewSidebarView (200px) 與主內容區域

---

### 問題 3：深色模式主題初始化

**症狀：** 工具列文字顯示不清

**解決方案：** 正確初始化 AppTheme 的 isDarkMode 設定以匹配系統外觀

---

## 待開發功能

### 進階寫作功能（~2%）

- ⏳ 參考文獻列表自動生成
- ⏳ Word (.docx) 匯出
- ⏳ LaTeX (.tex) 匯出

### 雲端同步（未來規劃）

- ⏳ iCloud 整合
- ⏳ 跨裝置同步

### P2 低優先功能

- ⏳ 專注模式（全螢幕編輯）
- ⏳ 版本歷史
- ⏳ 相關文獻推薦
- ⏳ 範本系統
- ⏳ 多視窗支援

---

## 編譯狀態

✅ **BUILD SUCCEEDED** (2026-01-02 09:00)

---

## 相關文件索引

| 文件 | 說明 |
|------|------|
| [PROJECT_STATUS.md](PROJECT_STATUS.md) | 專案進度總覽 |
| [AI_FEATURES_SUMMARY.md](AI_FEATURES_SUMMARY.md) | AI 功能總覽 |
| [AI_INTEGRATION_PLAN.md](AI_INTEGRATION_PLAN.md) | Apple AI 整合開發計畫 |
| [UX_IMPROVEMENTS.md](UX_IMPROVEMENTS.md) | UX 改善計畫 |
| [FORMAT_SYSTEM_GUIDE.md](FORMAT_SYSTEM_GUIDE.md) | 格式系統使用說明 |
| [LATEX_HYBRID_MODE.md](LATEX_HYBRID_MODE.md) | LaTeX 混合模式指南 |
| [CHINESE_TERMINOLOGY_COMPLETE_REPORT.md](CHINESE_TERMINOLOGY_COMPLETE_REPORT.md) | 中文術語優化報告 |
| [PDF_EXPORT_FIX.md](PDF_EXPORT_FIX.md) | PDF 匯出修復報告 |
| [PDF_IMPORT_OPTIMIZATION.md](PDF_IMPORT_OPTIMIZATION.md) | PDF 匯入優化說明 |
| [WRITER_REQUIREMENTS.md](WRITER_REQUIREMENTS.md) | 寫作編輯器功能需求 |
| [OVEREND_Brand_Product_Design_Manual.md](OVEREND_Brand_Product_Design_Manual.md) | 品牌及產品設計手冊 |

---

**開發日記整合完成**  
**整合檔案數：** 22 個 Markdown 文件  
**整合日期：** 2026-01-02
