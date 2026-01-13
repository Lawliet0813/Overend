# OVEREND 開發日記

> **整合自 DOCS 資料夾所有開發文件**  
> **最後更新：** 2026-01-14 (07:50)  
> **專案進度：** 約 99%

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

### 2026-01-03：統一 AI 服務層與學術功能擴展

**統一 AI 服務架構：**

將 6 個獨立的 Apple Intelligence 服務整合為統一入口：

```
UnifiedAIService.shared
├── .writing      // 寫作建議、風格檢查、改寫
├── .citation     // 引用檢查、修正、轉換、生成
├── .translation  // 學術翻譯、雙語對照、術語建議
├── .standards    // 完整規範檢查、快速檢查
├── .document     // 摘要、關鍵詞、分類、元數據
└── .formula      // LaTeX 生成、優化、解釋
```

**新增檔案（8 個）：**

| 檔案 | 說明 |
|------|------|
| `Services/AI/UnifiedAIService.swift` | 統一 AI 服務入口 |
| `Services/AI/AIServiceError.swift` | 統一錯誤類型 |
| `Services/AI/Domains/WritingAIDomain.swift` | 寫作 AI 領域 |
| `Services/AI/Domains/CitationAIDomain.swift` | 引用 AI 領域 |
| `Services/AI/Domains/TranslationAIDomain.swift` | 翻譯 AI 領域 |
| `Services/AI/Domains/StandardsAIDomain.swift` | 規範檢查領域 |
| `Services/AI/Domains/DocumentAIDomain.swift` | 文件處理領域 |
| `Services/AI/Domains/FormulaAIDomain.swift` | 公式 AI 領域 |

**學術 AI 功能擴展：**

- ✅ 中英文學術表達翻譯（`AcademicLanguageService`）
- ✅ 雙語對照生成與術語註解
- ✅ 台灣學術規範檢查（`TaiwanAcademicStandardsService`）
- ✅ 教育部繁中用語規範檢查
- ✅ APA 第七版引用格式檢查
- ✅ 學術翻譯 UI（`AcademicTranslationView`）
- ✅ 規範檢查 UI（`AcademicStandardsCheckView`）

**AI 智慧中心更新：**

| 功能 | 說明 | 狀態 |
|------|------|------|
| 智慧推薦 | 相關文獻推薦 | ✅ 可用 |
| 學術翻譯 | 中英文學術表達轉換 | ✅ 可用 |
| 規範檢查 | 台灣學術規範檢查 | ✅ 可用 |
| 引用檢查 | 引用品質檢查 | ⏳ 開發中 |
| 結構分析 | 論文結構優化 | ⏳ 開發中 |
| 文獻問答 | AI 文獻對話 | ⏳ 即將推出 |

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

✅ **BUILD SUCCEEDED** (2026-01-11 15:00)

---

### 2026-01-11：Emerald UI 重新設計與程式碼清理

**重點工作：**

1. **Emerald UI 系統完成**
   - 新增 8 個 Emerald 視圖元件：
     - `EmeraldLibraryView.swift` (711 行) - 文獻庫視圖
     - `EmeraldDashboardView.swift` (612 行) - 儀表板視圖
     - `EmeraldAIAssistantView.swift` (525 行) - AI 助手視圖
     - `EmeraldHomeView.swift` (421 行) - 首頁視圖
     - `EmeraldSettingsView.swift` (594 行) - 設定視圖
     - `EmeraldReaderView.swift` (656 行) - 閱讀器視圖
     - `EmeraldTheme.swift` (334 行) - 主題定義
     - `EmeraldComponents.swift` (383 行) - 共用元件

2. **Legacy UI 清理**
   - 刪除 6 個重複/未使用的檔案：
     - `AcademicLibraryView.swift` (778 行)
     - `LearningDashboardView.swift` (281 行)
     - `AIAssistantView.swift` (273 行)
     - `BatchActionBar.swift` (144 行)
     - `BatchTagInputView.swift` (179 行)
     - `LaTeXRenderer.swift` (150 行)

3. **程式碼瘦身統計**

   | 指標 | 初始 | 最終 | 變化 |
   |------|------|------|------|
   | Swift 檔案 | 188 | 182 | -6 |
   | 程式碼行數 | 55,653 | 53,844 | -1,809 |

4. **Bug 修復**
   - `ModernEntryListView.swift`: 修復 `CitationService.generateCitation` 方法調用錯誤
   - `AdvancedSearchFilter.swift`: 修復 `entry.tagArray` 不存在的編譯錯誤
   - `SimpleContentView.swift`: 批次刪除崩潰修復（Core Data 物件生命週期）

**Git 合併：**

```bash
feature/emerald-ui-redesign → main (Fast-forward)
64 files changed, +11,369 / -1,986
```

**專案狀態：**

- Emerald UI 系統完成並整合到主分支。
- 移除舊的標準視圖，統一使用 Emerald 設計語言。
- 編譯通過 (Build Succeeded)。

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

### 2026-01-03：P2 進階功能實作完成

**重點工作：**

1. **專注模式與寫作統計**
   - 實作 `FocusWritingView`，提供全螢幕無干擾寫作體驗。
   - 實作 `WritingStatsView`，提供即時字數、段落、引用統計。
   - 支援多種閱讀主題（白色、米色、深色）。

2. **版本控制系統**
   - 建立 `VersionHistoryService`，實作自動快照與版本管理。
   - 支援版本差異比較與一鍵還原。
   - 採用增量儲存策略，優化效能。

3. **智慧推薦與範本**
   - 實作 `RelatedLiteratureService`，基於多維度（作者、關鍵詞、期刊）計算文獻相似度。
   - 建立 `WritingTemplate` 系統，提供 APA、期刊、研討會等標準範本。

4. **動畫系統增強**
   - 擴充 `AnimationSystem`，新增 Panel, Button, Card, Content, Modal, Toast, Loading 等多種動畫預設。
   - 優化 UI 互動體驗，增加微互動回饋。

**技術決策：**

- **版本儲存**：使用獨立的 `.version` 檔案儲存快照，避免 CoreData 資料庫過度膨脹。
- **相似度算法**：採用加權計分機制（作者 > 關鍵詞 > 期刊 > 標題），確保推薦結果的相關性。
- **動畫架構**：將動畫參數集中管理於 `AnimationSystem`，確保全 App 動畫風格一致。

**解決問題：**

- 解決了 `DesignTokens.swift` 與 `AnimationSystem.swift` 的重複定義問題。
- 修正了 `VersionHistoryService` 缺少 `Combine` 與 `AppKit` 引入的編譯錯誤。

**專案狀態：**

- P2 功能全數完成。
- 編譯通過 (Build Succeeded)。

### 2026-01-03：Phase 3 代碼清理與優化

**重點工作：**

1. **移除未使用的 AI 介面**
   - 清理了 5 個實驗性 AI 視圖（`AIAssistantView`, `WriterAIAssistantView`, `FloatingAIAssistant`, `AICommandPaletteView`）。
   - 保留 `AICenterView` 作為統一的 AI 功能入口。
   - 總計移除 2,232 行冗餘代碼，顯著減少維護負擔。

2. **代碼庫瘦身**
   - 累計 Phase 1-3 共移除 4,880 行代碼 (-32.6%)。
   - 編譯時間縮短約 5%。

**技術決策：**

- **統一入口策略**：確認 AI 功能應集中管理，避免多個分散且功能重疊的 UI 元件。
- **實驗性代碼清理**：建立定期清理機制，防止原型代碼殘留影響專案品質。

**專案狀態：**

- 專案架構更為精簡，無冗餘 AI 視圖。
- 編譯通過，無相關錯誤。

### 2026-01-03 (晚間)：AI 智慧中心內容導入與批次選取功能

**重點工作：**

1. **AI 智慧中心內容導入功能**
   - 新增 `ContentImportPicker.swift` 共用元件
   - `LibraryEntryPicker`：從文獻庫導入摘要、筆記或 BibTeX
   - `DocumentPicker`：從寫作中心導入文稿內容（RTF 轉純文字）
   - 修改 `AcademicTranslationView.swift` 新增「從文獻庫導入」按鈕
   - 修改 `AcademicStandardsCheckView.swift` 新增「從寫作中心導入」按鈕

2. **文獻庫與文稿批次選取刪除功能**
   - `ModernEntryListView.swift`：新增選擇模式、批次操作工具列
   - `EntryTableRow`：新增複選框支援
   - `EditorListView.swift`：新增批次操作工具列
   - `DocumentCardView.swift`：新增複選框覆蓋層與選中邊框

**新增/修改檔案：**

| 檔案 | 說明 |
|------|------|
| `Views/AICenter/ContentImportPicker.swift` | 內容導入選擇器 🆕 |
| `Views/AICenter/AcademicTranslationView.swift` | 新增文獻庫導入 |
| `Views/AICenter/AcademicStandardsCheckView.swift` | 新增寫作中心導入 |
| `Views/EntryList/ModernEntryListView.swift` | 批次選取與刪除 |
| `Views/Writer/EditorListView.swift` | 批次選取與刪除 |
| `Views/Writer/DocumentCardView.swift` | 選擇模式 UI |

**技術決策：**

- **選擇模式切換**：使用 `isSelectionMode` 狀態控制 UI 切換，避免常駐複選框影響一般操作體驗。
- **批次刪除確認**：所有批次刪除操作都有確認對話框，防止誤刪。

**專案狀態：**

- 編譯通過 (Build Succeeded)。
- 功能測試待手動驗證。

### 2026-01-03 (深夜)：AI 工具整合與日誌同步

**重點工作：**

1. **AI 工具全面整合**
   - 將 P1/P2 開發的 AI 工具正式整合至各個領域服務中 (`Domains`)。
   - `WritingAIDomain`: 整合 `AnalyzeWritingTool`, `RewriteTextTool`。
   - `TranslationAIDomain`: 整合 `TranslateAcademicTool`, `SuggestTermTranslationTool`。
   - `CitationAIDomain`: 整合 `CheckCitationFormatTool`, `GenerateCitationTool`, `ConvertCitationStyleTool`。
   - `FormulaAIDomain`: 整合 `ExplainFormulaTool`, `GenerateFormulaTool`。
   - `StandardsAIDomain`: 整合 `CheckAcademicStandardsTool`, `CheckAcademicStyleTool`。
   - 實作 Tool Calling 失敗時的回退機制 (Fallback Mechanism)，確保功能穩定性。

2. **Notion 日誌同步系統**
   - 實作 `ExtractionLogger` 類別，詳實記錄 PDF 元數據提取過程。
   - 更新 `NotionService`，支援將提取日誌同步至 Notion 資料庫。
   - 在 `PDFMetadataExtractor` 中整合日誌記錄功能。

3. **UI/UX 細節優化**
   - **批次操作 UI**：優化 `EditorListView` 與 `ModernEntryListView` 的批次操作工具列，增大按鈕尺寸以符合 macOS HIG 規範。
   - **列表體驗**：實作可排序的表格欄位、側邊欄數量統計、文獻懸停預覽。

**修改檔案：**

| 檔案 | 說明 |
|------|------|
| `Services/AI/Domains/*.swift` | 各領域 AI 服務整合工具 |
| `Services/NotionService.swift` | 支援日誌同步 |
| `Services/PDFMetadataExtractor.swift` | 整合 ExtractionLogger |
| `Views/EntryList/ModernEntryListView.swift` | UI 優化 |
| `Views/Writer/EditorListView.swift` | UI 優化 |

**專案狀態：**

- AI 功能整合度大幅提升，從單純 Prompt 轉向結構化 Tool Calling。
- 系統可觀測性增強 (Notion Log Sync)。
- 編譯通過 (Build Succeeded)。

### 2026-01-04：UI/UX 視覺優化與互動增強

**重點工作：**

1. **深色模式專用化**
   - 移除淺色模式，應用程式全面採用深色配色 (Dark Slate Blue)。
   - 修改 `AppTheme.swift`，簡化所有 `isDarkMode` 條件運算式。
   - `isDarkMode` 改為唯讀屬性，始終返回 `true`。
   - 移除 `DynamicToolbar.swift` 中的主題切換按鈕。

2. **Liquid Glass 按鈕設計（WWDC25 風格）**
   - `CustomButton.swift` 全面重構：
     - `.ultraThinMaterial` 毛玻璃背景
     - 漸層玻璃邊框（白色 → 透明）
     - 發光陰影效果 (`glowShadowColor`)
     - SF Symbols `.hierarchical` 渲染模式
   - 新增 `glowShadowColor` 計算屬性，根據按鈕樣式產生相應光暈。

3. **右鍵選單功能增強**
   - `ModernEntryListView.swift` 文獻列表右鍵選單新增：
     - 開啟 PDF / 開啟 DOI 連結
     - 複製引用（APA 7th / MLA 9th / BibTeX / 引用鍵）
     - 星號標記切換
     - 編輯書目
   - `Entry.swift` 新增屬性與方法：
     - `isStarred` 星號標記屬性
     - `generateAPACitation()` APA 7th 引用生成
     - `generateMLACitation()` MLA 9th 引用生成

**修改檔案：**

| 檔案 | 說明 |
|------|------|
| `Theme/AppTheme.swift` | 深色模式專用化 |
| `Views/Common/DynamicToolbar.swift` | 移除主題切換按鈕 |
| `Views/Components/Buttons/CustomButton.swift` | Liquid Glass 設計 |
| `Views/EntryList/ModernEntryListView.swift` | 右鍵選單增強 |
| `Models/Entry.swift` | 新增 isStarred、引用生成方法 |
| `Views/Components/Cards/CardView.swift` | Preview 修復 |
| `Views/Components/Feedback/LoadingIndicator.swift` | Preview 修復 |
| `Views/Components/Inputs/StandardTextField.swift` | Preview 修復 |

**技術決策：**

- **深色模式專用**：考量開發者長時間使用體驗，統一採用深色配色減少視覺疲勞。
- **Liquid Glass 風格**：遵循 WWDC25 macOS 設計語言，增加 UI 的現代感與層次感。
- **星號標記儲存**：使用 `fields["_starred"]` 儲存於現有 JSON 結構，避免 CoreData 模型變更。

**專案狀態：**

- UI/UX 全面現代化，符合 macOS 26 設計規範。
- 編譯通過 (Build Succeeded)。

### 2026-01-05：完整測試計畫實作與發布準備

**重點工作：**

1. **測試計畫實作（72/78 測試通過，92%）**
   - 建立 `CoreDataTestHelper.swift`，解決程式化 CoreData 模型的測試環境問題。
   - 實作 P0 優先單元測試：
     - `PDFMetadataExtractorTests.swift` (7 cases)
     - `CitationServiceTests.swift` (10 cases)
     - `BibTeXParserTests.swift` (16 cases)
     - `RepositoryTests.swift` (16 cases)
   - 實作 AI 服務測試：
     - `AIServiceTests.swift` (24 cases) - 涵蓋 AI 錯誤類型、工具、領域
   - 實作 P0 UI 自動化測試：
     - `LibraryUITests.swift` (8 cases)
     - `EditorUITests.swift` (12 cases)

2. **Core Data 測試環境修復**
   - 問題：專案使用程式化 CoreData 模型，無法用傳統方式載入。
   - 解決：使用 `PersistenceController.createManagedObjectModel()` 建立測試專用 in-memory stack。
   - 加入 `@MainActor` 與 async `setUp()/tearDown()` 確保線程安全。

3. **Notion 同步功能發布準備**
   - 使用 `#if DEBUG` 編譯旗標包裝 Notion 相關程式碼。
   - Release 版本自動移除 Notion 功能：
     - `SettingsView.swift` - Notion 設定頁籤
     - `SimpleContentView.swift` - PDF 匯入後的自動同步

**新增檔案（7 個）：**

| 檔案 | 說明 |
|------|------|
| `OVERENDTests/CoreDataTestHelper.swift` | CoreData 測試輔助 🆕 |
| `OVERENDTests/PDFMetadataExtractorTests.swift` | PDF 提取測試 🆕 |
| `OVERENDTests/CitationServiceTests.swift` | 引用格式測試 🆕 |
| `OVERENDTests/BibTeXParserTests.swift` | BibTeX 解析測試 🆕 |
| `OVERENDTests/AIServiceTests.swift` | AI 服務測試 🆕 |
| `OVERENDUITests/LibraryUITests.swift` | 文獻庫 UI 測試 🆕 |
| `OVERENDUITests/EditorUITests.swift` | 編輯器 UI 測試 🆕 |

**技術決策：**

- **測試隔離**：每個測試方法使用獨立的 in-memory CoreData stack，避免測試間干擾。
- **編譯旗標策略**：使用 `#if DEBUG` 而非運行時旗標，確保 Release 版本完全不包含開發功能。

**專案狀態：**

- 測試覆蓋率大幅提升（新增 78 個測試案例）。
- Notion 功能已設定為僅開發版本可用。
- 編譯通過 (Build Succeeded)。

### 2026-01-13：AI 夥伴角色系統 (Companion System)

**重點工作：**

1. **AI 夥伴角色系統完整實作**
   - 新增 8 個核心檔案，打造類似「迴紋針小助手」的 AI 夥伴體驗
   - 預設角色「小研 (Yen)」：翡翠綠貓頭鷹，戴眼鏡和學士帽
   - 支援用戶用自然語言生成專屬 AI 角色

2. **等級與成長系統**
   - Lv.1 研究新手 → Lv.50 學術大師
   - 匯入文獻 (+10 XP)、寫作 1000 字 (+20 XP)、採納 AI 建議 (+15 XP) 等
   - 等級解鎖對應功能（智慧分類、批次工作流、研究洞察引擎等）

3. **成就與每日任務**
   - 15+ 個成就徽章（破萬引用、筆耕不輟、格式潔癖等）
   - 每日隨機 3 個挑戰任務
   - 連續使用獎勵機制

4. **智慧對話系統**
   - 時間感知問候（早/中/晚/深夜不同對話）
   - 行為觸發對話（PDF 匯入後、寫作進度、久未引用提醒）
   - 閒置鼓勵訊息

**新增檔案（8 個）：**

| 檔案 | 說明 |
|------|------|
| `Models/Companion/Companion.swift` | 角色數據模型 🆕 |
| `Models/Companion/CompanionLevel.swift` | 等級與經驗值系統 🆕 |
| `Models/Companion/CompanionAchievement.swift` | 成就與每日任務 🆕 |
| `Views/AICompanion/CompanionDialogues.swift` | 對話內容庫 🆕 |
| `Services/CompanionService.swift` | 核心服務（事件處理） 🆕 |
| `Views/AICompanion/CompanionView.swift` | 浮動角色 + 對話氣泡 🆕 |
| `Views/AICompanion/CompanionPanelView.swift` | 等級/任務/成就面板 🆕 |
| `Views/AICompanion/CompanionGeneratorView.swift` | AI 角色生成器 🆕 |

**技術決策：**

- **資料持久化**：使用 UserDefaults + Codable 儲存用戶進度與角色資料
- **表情狀態**：6 種狀態（idle/excited/reading/celebrating/sleepy/thinking）
- **動畫技術**：預留 Lottie 整合接口，目前使用 SwiftUI 動畫 + Emoji

**專案狀態：**

- AI 夥伴核心系統完成。
- 待整合至主視圖與事件觸發。
- 編譯通過 (Build Succeeded)。

### 2026-01-14：學術寫作功能整合（研究報告實作）

**重點工作：**

根據「繁體中文優先之學術寫作與書目管理系統架構深度研究報告」，整合多項學術寫作功能：

1. **Zotero 橋接 UI 整合**
   - 新增 `ZoteroBridgeView.swift` (~660 行)，提供完整的 Zotero 連接管理介面
   - 連線狀態指示器、即時搜尋、批次匯入功能
   - Better BibTeX 插件安裝指南

2. **PDF 版面分析視覺化**
   - 新增 `PDFLayoutAnalysisView.swift` (~575 行)
   - XY-Cut 演算法視覺化，顯示區塊邊界與閱讀順序
   - 依閱讀順序提取多欄文字

3. **RIS 匯入介面強化**
   - 新增 `RISImportView.swift` (~530 行)
   - 自動編碼偵測（UTF-8、Big5）並顯示信心度
   - 解析預覽與批次匯入功能
   - 更新 `ImportOptionsSheet.swift` 新增 RIS 匯入選項

4. **App Intents 整合**
   - 新增 `AcademicPhrasebankIntents.swift` (~235 行)
   - 4 個學術語料庫快捷指令：搜尋句型、複製句型、取得建議、瀏覽分類
   - 整合至 `OVERENDShortcuts` provider

5. **AI 中心功能擴展**
   - 更新 `AICenterView.swift`，新增 Zotero 連接與 PDF 智慧分析功能卡片

6. **編譯錯誤修復**
   - 修復 `ZoteroBridge.swift` 泛型類型推斷問題
   - 修復 `ImportSource` 重複定義
   - 新增缺少的 Combine imports
   - 修復 Preview 中的 AppTheme 引用

**新增檔案（6 個）：**

| 檔案 | 說明 |
|------|------|
| `Views/AICenter/ZoteroBridgeView.swift` | Zotero 連接 UI 🆕 |
| `Views/AICenter/RISImportView.swift` | RIS 匯入 UI 🆕 |
| `Views/Components/PDFLayoutAnalysisView.swift` | PDF 版面分析 🆕 |
| `App/Intents/AcademicPhrasebankIntents.swift` | 學術句型快捷指令 🆕 |
| `Services/AcademicPhrasebank.swift` | 學術語料庫服務 🆕 |
| `Services/TerminologyFirewall.swift` | 術語防火牆 🆕 |

**新增 Siri 語音指令：**

| 指令 | 功能 |
|------|------|
| "用 OVEREND 搜尋學術句型" | 搜尋語料庫 |
| "用 OVEREND 複製學術句型" | 複製句型到剪貼簿 |
| "用 OVEREND 取得句型建議" | 智慧推薦 |
| "用 OVEREND 瀏覽句型分類" | 分類瀏覽 |

**程式碼統計：**

- 新增約 2,200 行程式碼
- 修改 10+ 個檔案

**專案狀態：**

- 編譯通過 (Build Succeeded)
- Git 提交：29 檔案變更，+8,535 / -155 行
