# OVEREND macOS 開發進度

> 最後更新：2025-12-27

## ✅ 已完成功能

### 1. Core Data 架構 ✅

- [x] 程式化定義 Core Data 模型（無需 .xcdatamodeld）
- [x] PersistenceController 實現
- [x] 所有實體定義與關聯關係
  - Library（文獻庫）
  - Entry（BibTeX 條目）
  - Group（組群）
  - Attachment（附件）
  - Document（論文文檔）
- [x] 完整的 CRUD 操作
- [x] Preview 資料生成

### 2. UI 介面 ✅

- [x] 三欄 NavigationSplitView 布局
- [x] **左側邊欄（LibrarySidebarView）**
  - [x] 文獻庫列表顯示
  - [x] 顯示條目數量
  - [x] 標記預設文獻庫（星號圖示）
  - [x] 右鍵選單（重新命名、刪除）
- [x] **中間欄（EntryListView）**
  - [x] 條目列表顯示
  - [x] 即時搜尋功能
  - [x] 顯示：標題、作者、年份、類型、PDF 圖示
- [x] **右側詳情（EntryDetailView）**
  - [x] 完整條目資訊顯示
  - [x] 原始 BibTeX 代碼顯示
  - [x] PDF 附件管理 UI
- [x] macOS 13.0 fallback 實現

### 3. PDF 附件功能 ✅

- [x] **PDFService 服務**
  - [x] 檔案選擇器（NSOpenPanel）
  - [x] 檔案大小限制檢查（50MB）
  - [x] 自動複製 PDF 到應用程式存儲目錄
  - [x] PDF 元數據提取（頁數、前 3 頁文字）
  - [x] 刪除附件功能
- [x] **UI 整合**
  - [x] 「匯入 PDF」按鈕
  - [x] 「查看 PDF」按鈕
  - [x] 「刪除附件」按鈕
  - [x] 顯示檔案資訊（檔名、大小、頁數）

### 4. BibTeX 解析器 ✅

- [x] **BibTeXParser 完整實現**
  - [x] 解析 .bib 文件
  - [x] 支援嵌套大括號
  - [x] 字段驗證
  - [x] LaTeX 特殊字符清理
  - [x] 批量匯入到 Core Data
  - [x] 重複條目檢查

### 5. 工具類 ✅

- [x] Constants - 全局常量定義
- [x] Color+Brand - 品牌色彩
- [x] DialogHelper - 對話框工具（多種實現）
- [x] FocusManager - 全局焦點管理
- [x] FocusedTextField - AppKit TextField 包裝

## ⚠️ 已知問題

### 1. 創建文獻庫輸入框焦點問題 ✅ **已解決**

**問題描述：**

- 點擊 + 按鈕後，輸入框出現且有藍色焦點框
- 但打字時文字跑到右下角的搜尋框中

**解決方案：**
使用 SwiftUI 的 `.popover()` 取代內嵌輸入框，因為 Popover 是獨立的視窗層，焦點會自然地留在其中。

**修改檔案：**

- `LibrarySidebarView.swift` - 使用 Popover，新增 `NewLibraryPopoverView`
- `EntryListView.swift` - 移除不必要的 FocusManager 依賴

### 2. SPM 專案限制 ⚠️

**控制台警告：**

```
Cannot index window tabs due to missing main bundle identifier
ViewBridge to RemoteViewService Terminated
```

**原因：**

- 使用 Swift Package Manager 而非 Xcode 專案
- 缺少 Bundle Identifier
- 缺少 Info.plist

**影響：**

- 不影響核心功能
- 僅是開發階段警告
- 可能影響視窗標籤索引

**解決方案：**

- 暫時忽略（不影響功能）
- 或轉換為完整 Xcode 專案（發布前）

## 🚧 待實現功能

### 高優先級

- [x] **修復創建文獻庫輸入框焦點問題** ⭐⭐⭐ ✅ 已完成
- [ ] 條目 CRUD UI（創建、編輯、刪除）
- [ ] BibTeX 匯入/匯出 UI 整合
- [ ] 組群管理功能

### 中優先級

- [ ] BibTeXGenerator 實現
- [ ] ExportService（PDF/DOCX 匯出）
- [ ] 富文本編輯器（論文寫作）
- [ ] 完善搜尋功能

### 低優先級

- [ ] 設定頁面完善
- [ ] 鍵盤快捷鍵優化
- [ ] 錯誤處理改進
- [ ] 單元測試

## 📊 代碼統計

### 檔案結構

```
Sources/OVEREND/
├── Models/                 # Core Data 模型（5 個文件）
├── ViewModels/            # 視圖模型（2 個文件）
├── Views/                 # SwiftUI 視圖（4 個子目錄）
├── Services/              # 業務邏輯（3 個文件）
└── Utilities/             # 工具類（6 個文件）
```

### 已實現文件數量

- **模型層：** 6 個文件（PersistenceController + 5 個實體）
- **視圖層：** 5 個主要視圖
- **服務層：** 3 個服務（PDFService、BibTeXParser、BibTeXGenerator）
- **工具類：** 6 個工具

## 🎯 下一步建議

### 方案 A：解決焦點問題優先

1. 嘗試使用 Popover 取代內嵌輸入
2. 或使用完全獨立的視窗（NSWindow）
3. 或簡化為只能通過匯入 .bib 來創建庫

### 方案 B：繞過問題，實現其他功能

1. 先實現 BibTeX 匯入 UI
2. 用戶可以先匯入 .bib 文件自動創建庫
3. 創建庫功能後續再解決

### 方案 C：轉換專案結構

1. 從 SPM 轉換為 Xcode App 專案
2. 可能解決部分環境相關問題
3. 同時解決 Bundle Identifier 警告

## 💡 技術亮點

1. **程式化 Core Data 模型** - 無需 .xcdatamodeld
2. **MVVM 架構** - 清晰的關注點分離
3. **完整的 PDF 管理** - 自動提取元數據
4. **強大的 BibTeX 解析** - 支援複雜嵌套
5. **品牌色彩系統** - 統一的 UI 風格

## 🔗 相關文檔

- `README.md` - 專案說明
- `CLAUDE.md` - Claude Code 工作指南
- `Package.swift` - SPM 配置

---

**總體進度：** 約 75% 核心功能完成，焦點問題已修復。
