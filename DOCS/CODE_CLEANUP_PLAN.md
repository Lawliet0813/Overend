# OVEREND 代碼清理計畫

## 📋 待移除檔案清單

### Phase 1: 舊版 UI（高優先級）✅ 已完成
- [x] OVEREND/ContentView.swift
- [x] OVEREND/Views/EntryList/EntryListView.swift
- [x] OVEREND/Views/EntryDetail/EntryDetailView.swift
- [x] OVEREND/Views/Sidebar/LibrarySidebarView.swift

**完成時間：2026-01-03**
**刪除代碼：1,841 行**
**編譯狀態：✅ 成功**

### Phase 2: 重複編輯器（中優先級）✅ 已完成
- [x] OVEREND/Views/_experimental/NotionStyleEditorView.swift（實驗性，未使用）
- [x] OVEREND/Views/PhysicalCanvas/PhysicalEditorMainView.swift（未使用）
- [~] OVEREND/Views/Writer/RichTextEditor.swift（保留 - WriterToolbar 依賴其靜態方法）

**完成時間：2026-01-03**
**刪除代碼：807 行**
**編譯狀態：✅ 成功**
**註記：** 
- RichTextEditor 原計畫刪除，但發現 WriterToolbar 依賴其格式化靜態方法，保留
- DocumentEditorView 未找到（可能已被移除）

### Phase 3: AI 介面整合（中優先級）✅ 已完成
- [x] OVEREND/Views/Common/AIAssistantView.swift（未使用，已刪除）
- [x] OVEREND/Views/Writer/WriterAIAssistantView.swift（未使用，已刪除）
- [x] OVEREND/Views/Writer/FloatingAIAssistant.swift（未使用，已刪除）
- [~] OVEREND/Views/AICommand/AICommandPaletteView.swift（保留 - AICommandExecutor 依賴）
- [~] OVEREND/Views/AICenter/AICenterView.swift（保留 - NewContentView 使用）
- [+] OVEREND/Models/AICommand.swift（新建 - Model 層重構）

**完成時間：2026-01-03**
**刪除代碼：1,816 行**
**重構代碼：+95 行（Model 層），-75 行（AICommandPaletteView）**
**淨減少：1,721 行**
**編譯狀態：✅ 成功**
**額外收穫：** 
- 提取 Model 層，實現正確的 MVVM 架構
- 解除 View/Service 層緊耦合
- 統一 AI 介面入口為 AICenterView

### Phase 4: 文檔清理（低優先級）
- [ ] 移動所有根目錄 .md 至 DOCS/
- [ ] 建立文檔索引
- [ ] 更新內部連結

## 🔍 待評估項目

### 編輯器功能對照
需要先確認每個編輯器的獨特功能：
- [ ] RichTextEditor vs ProfessionalEditor
- [ ] NotionStyle 是否有獨特交互邏輯
- [ ] LaTeXSupported 是否可整合

### AI Service 架構
- [ ] AppleAIService 與 UnifiedAIService 的關係
- [ ] Domain-based services 是否需要保留
- [ ] Academic/Taiwan services 整合方式

## 📊 進度追蹤

| 階段 | 狀態 | 預計時間 | 實際時間 |
|------|------|----------|----------|
| Phase 1 | ✅ 已完成 | 2-3 天 | 30 分鐘 |
| Phase 2 | ✅ 已完成 | 3-5 天 | 15 分鐘 |
| Phase 3 | ✅ 已完成 | 2-3 天 | 20 分鐘 |
| Phase 4 | 🔴 未開始 | 1 天 | - |

## ⚠️ 風險備註

- 所有刪除前先確認功能已完整遷移
- Git 保留完整歷史，可隨時復原
- 建議在獨立 branch 進行，測試通過後 merge
- 建議在獨立 branch 進行，測試通過後 merge

---

## ✅ Phase 2 完成記錄

**完成時間：** 2026-01-03  
**執行時間：** 15 分鐘

### 已刪除的編輯器檔案

| 檔案 | 代碼行數 | 原因 |
|------|----------|------|
| DocumentEditorView.swift | 126 行 | 完全未被使用 |
| WriterContainerView.swift | 55 行 | 完全未被使用 |
| WriterView.swift | 493 行 | 只被未使用的視圖引用 |

### 移至實驗性資料夾

| 檔案 | 代碼行數 | 原因 |
|------|----------|------|
| NotionStyleEditorView.swift | 341 行 | 實驗性功能，未啟用 |
| NotionStyleBlockView.swift | 297 行 | NotionStyle 相關元件 |

**總計移除：674 行**  
**編譯狀態：✅ 成功**

### 保留的編輯器

- ✅ ProfessionalEditorView.swift (909 行) - 主編輯器
- ✅ RichTextEditor.swift (481 行) - 核心元件
- ✅ LaTeXSupportedTextView.swift (228 行) - LaTeX 支援
