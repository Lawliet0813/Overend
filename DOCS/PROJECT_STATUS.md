# OVEREND 專案狀態總覽

**更新日期：** 2026-01-16
**專案進度：** 約 99%（學術寫作整合完成）

---

## 📊 整體架構

```
OVEREND/
├── Models/              # 資料模型
│   ├── Entry.swift      # 文獻書目
│   ├── Library.swift    # 文獻庫
│   ├── Group.swift      # 分類群組
│   └── Document.swift   # 文章文件 ⭐ 待開發編輯器
│
├── Services/            # 服務層
│   ├── DOIService.swift           # DOI 查詢 ✅
│   ├── CrossRefService.swift      # CrossRef API ✅
│   ├── CitationService.swift      # 引用格式 ✅
│   ├── BibTeXGenerator.swift      # BibTeX 生成 ✅
│   └── PDFService.swift           # PDF 處理 ✅
│
├── Views/
│   ├── Sidebar/         # 側邊欄（文獻庫、分類）
│   ├── EntryList/       # 文獻列表
│   ├── EntryDetail/     # 文獻詳細資訊
│   ├── Editor/          # 書目編輯器 ✅
│   └── Writer/          # 文章編輯器 ⏳ 待開發
│
└── ViewModels/          # 視圖模型
```

---

## ✅ 已完成功能（~75%）

### 1. 文獻管理核心

- ✅ 文獻匯入（PDF、BibTeX）
- ✅ 文獻分類與群組
- ✅ 搜尋與過濾
- ✅ 多選與批次操作
- ✅ 書目編輯器（EntryEditorView）

### 2. DOI 自動查詢（100% 完成）

- ✅ DOI 自動提取（支援括號等特殊字符）
- ✅ CrossRef API 整合
- ✅ 三層回退機制（CrossRef → DOIService → 本地提取）
- ✅ 完整期刊資訊提取（標題、作者、年份、期刊、卷、期、頁碼）
- ✅ 已用真實 DOI 驗證（10.1080/10803548.2024.2404748）
- ✅ 引用格式生成（APA 7th、MLA 9th、BibTeX）

**測試結果：**

- CrossRef 200 成功
- 所有期刊資訊完整提取
- 引用格式完美生成

**相關文件：**

- `/Users/lawliet/OVEREND/DOI_DEVELOPMENT_COMPLETE.md`
- `/Users/lawliet/OVEREND/DOI_FINAL_REPORT.md`

### 3. PDF 處理

- ✅ PDF 元數據提取
- ✅ PDF 預覽
- ✅ PDF 附件管理

### 4. 引用系統

- ✅ APA 7th 格式
- ✅ MLA 9th 格式
- ✅ BibTeX 格式
- ✅ Citation Key 自動生成
- ✅ 一鍵複製引用

### 5. UI/UX 優化

- ✅ 統一字體系統
- ✅ 間距優化
- ✅ 多選操作
- ✅ 批次刪除/移動

### 6. 核心引擎 (Rust Core)

- ✅ Typst 編譯器整合
- ✅ Hayagriva 文獻引擎整合
- ✅ 高效能 PDF 生成

---

## ⏳ 待開發功能（~25%）

### 🎯 **最重要：文章寫作編輯器（Next Priority）**

**目標：** 像 Word 一樣的寫作環境，整合引用功能

**核心需求：**

1. **文字編輯**
   - 基本格式（粗體、斜體、底線）
   - 標題層級（H1, H2, H3）
   - 段落格式
   - 列表（有序、無序）

2. **引用插入** ⭐ 最重要
   - 從文獻庫快速插入引用
   - 支援多種引用格式（APA/MLA/Chicago）
   - 自動生成參考文獻列表
   - 引用與文獻連結

3. **文件管理**
   - 多文件支援
   - 自動儲存
   - 版本控制

4. **匯出功能**
   - 匯出 Word (.docx)
   - 匯出 PDF
   - 匯出 LaTeX
   - 包含參考文獻列表

**技術方案考慮：**

- 方案 A：Markdown 編輯器 + 引用（快速 MVP）
- 方案 B：Rich Text 編輯器（完整功能）
- 方案 C：混合方案（Markdown → Rich Text）

**預估開發時間：**

- MVP（Markdown）：2-3 天
- 完整版：1-2 週

### 其他待開發功能

1. **AI 輔助功能**
   - 摘要生成
   - 智慧分類
   - 關鍵詞提取

2. **協作功能**
   - 共享文獻庫
   - 多人協作

3. **雲端同步**
   - iCloud 整合
   - 跨裝置同步

---

## 📁 專案結構

### 核心檔案位置

**Models:**

- `/Users/lawliet/OVEREND/OVEREND/Models/Entry.swift` - 文獻書目
- `/Users/lawliet/OVEREND/OVEREND/Models/Document.swift` - 文章文件（已有基礎，待擴展）

**Services:**

- `/Users/lawliet/OVEREND/OVEREND/Services/DOIService.swift` - DOI 查詢 ✅
- `/Users/lawliet/OVEREND/OVEREND/Services/CrossRefService.swift` - CrossRef API ✅
- `/Users/lawliet/OVEREND/OVEREND/Services/CitationService.swift` - 引用格式 ✅
- `/Users/lawliet/OVEREND/OVEREND/Services/BibTeXGenerator.swift` - BibTeX 生成 ✅

**Views:**

- `/Users/lawliet/OVEREND/OVEREND/Views/Editor/EntryEditorView.swift` - 書目編輯器 ✅
- `/Users/lawliet/OVEREND/OVEREND/Views/Writer/` - 文章編輯器 ⏳ 待建立

---

## 🎯 下一步行動

### 立即優先項目：文章寫作編輯器

**規劃重點：**

1. 確定功能範圍（MVP vs 完整版）
2. 選擇技術方案（Markdown vs Rich Text）
3. 設計 UI/UX
4. 規劃引用插入工作流程
5. 設計匯出功能

**關鍵問題：**

- 編輯器類型選擇？
- 引用插入的操作方式？
- 參考文獻列表的生成邏輯？
- 匯出格式的優先順序？

---

## 💻 開發環境

- **系統：** Mac mini M4 (RAM 16G, 256G 儲存)
- **開發工具：** Xcode
- **語言：** Swift + SwiftUI
- **資料庫：** CoreData
- **專案路徑：** `/Users/lawliet/OVEREND/`
- **使用者：** lawliet

---

## 📚 相關文件

**DOI 功能：**

- `DOI_DEVELOPMENT_COMPLETE.md` - 完整開發記錄
- `DOI_FINAL_REPORT.md` - 最終測試報告
- `DOI_IMPLEMENTATION_STATUS.md` - 實作狀態
- `DOI_TEST_PLAN.md` - 測試計畫
- `DOI_BRACKET_FIX.md` - 括號修復記錄
- `DOI_TESTING_SUMMARY.md` - 測試總結

---

## 🎓 背景資訊

**開發者：** 彥儒 (lawliet)

- 前台鐵員工（2014-2025）：司機員、機車長、助理工程師、教育訓練講師
- 現為政大行政管理碩士一年級學生
- 專長：系統開發、教育訓練、技術整合

**專案目標：**
打造一個**專為台灣研究生設計**的 AI 驅動文獻管理系統，提供：

- 優秀的繁體中文支援
- 直覺的操作介面
- 強大的引用管理
- 整合的寫作環境
- AI 輔助功能

**競爭對手：** EndNote, Zotero, Mendeley

---

## 🚀 專案願景

**短期目標（3 個月）：**

- ✅ 完成核心文獻管理功能
- ✅ DOI 自動查詢整合
- ⏳ 完成文章寫作編輯器
- ⏳ 基礎 AI 輔助功能

**中期目標（6 個月）：**

- Beta 版本發布
- 使用者測試
- 功能優化

**長期目標（1 年）：**

- 正式版發布
- 推廣至台灣研究生社群
- 建立使用者生態

---

**下一個對話主題：文章寫作編輯器功能規劃** 📝✨
