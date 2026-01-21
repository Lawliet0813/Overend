---
name: overend-dev
description: OVEREND 專案開發總則。整合 UI、Core Data、Service、Testing 四大專業領域，提供跨模組協作規範與品質檢查清單。使用此 Skill 作為開發任務的入口，系統會自動載入對應的專業 Skill。
---

# OVEREND Development Assistant - 總指揮中心

## Overview

OVEREND 是針對台灣學術社群設計的「EndNote 殺手」，提供文獻管理與寫作整合的原生 macOS 應用。

本 Skill 系統採用**分工協作架構**，將開發任務分配給專責 Skill：
- **ui-specialist.md** - UI/SwiftUI 專家
- **coredata-specialist.md** - 資料模型專家  
- **service-specialist.md** - 服務層專家
- **testing-specialist.md** - 測試專家

## When to Use This Skill

✅ **使用此 skill 的情境**：
- 規劃跨模組的新功能
- 檢查整體架構設計
- 執行跨領域的品質檢查
- 更新專案文件與開發日記
- 作為所有開發任務的**入口點**

❌ **不使用此 skill 的情境**：
- 一般性 Swift/SwiftUI 問題（與 OVEREND 無關）
- 非開發類問題（市場分析、商業策略）

## Skill 分工與自動載入機制

當接收到開發任務時，系統會：
1. 分析任務類型
2. 自動載入對應的專責 Skill
3. 依照該 Skill 的規範執行
4. 回到本 Skill 進行整合檢查

### 自動載入規則

| 任務關鍵字 | 載入 Skill | 範例 |
|-----------|-----------|------|
| UI、視圖、SwiftUI、佈局、AppTheme | ui-specialist.md | 「修改文獻列表樣式」 |
| Core Data、模型、Entry、Library | coredata-specialist.md | 「新增欄位到 Entry」 |
| API、Service、BibTeX、PDF、DOI | service-specialist.md | 「改善 PDF 擷取邏輯」 |
| 測試、Test、單元測試、UI 測試 | testing-specialist.md | 「為新功能寫測試」 |
| 整合、架構、跨模組 | 本 Skill（SKILL.md） | 「規劃標籤功能」 |

## Project Context

### 基本資訊
- **專案路徑**: `/Users/lawliet/OVEREND`
- **專案檔**: `OVEREND.xcodeproj`
- **主要程式碼**: `OVEREND/`
- **框架**: SwiftUI + Core Data + PDFKit
- **目標平台**: macOS 13.0+
- **主色調**: `#00D97E` (Emerald)

### 專案結構與 Skill 對應
```
OVEREND/
├── OVEREND.xcodeproj
├── OVEREND/
│   ├── Models/              ← coredata-specialist.md
│   │   ├── Entry.swift
│   │   ├── Library.swift
│   │   ├── Group.swift
│   │   ├── Attachment.swift
│   │   └── Document.swift
│   │
│   ├── Theme/               ← ui-specialist.md
│   │   └── AppTheme.swift
│   │
│   ├── Services/            ← service-specialist.md
│   │   ├── DOIService.swift
│   │   ├── CrossRefService.swift
│   │   ├── CitationService.swift
│   │   ├── BibTeXParser.swift
│   │   └── PDFService.swift
│   │
│   ├── ViewModels/          ← ui-specialist.md + coredata-specialist.md
│   │   ├── LibraryViewModel.swift
│   │   └── EntryViewModel.swift
│   │
│   └── Views/               ← ui-specialist.md
│       ├── NewContentView.swift
│       ├── Sidebar/
│       ├── EntryList/
│       ├── EntryDetail/
│       └── Writer/
│
├── OVERENDTests/            ← testing-specialist.md
└── OVERENDUITests/          ← testing-specialist.md
```

## 模組協作規範（跨 Skill 整合）

### 架構層級規則

```
UI 層 (Views)
    ↓ 只能透過 ViewModel
ViewModel 層
    ↓ 呼叫 Service 或直接操作 Core Data
Service 層 (Services)
    ↓ 可操作 Core Data Context
Core Data 層 (Models)
```

**強制規則**：
1. ✅ UI 只能透過 ViewModel 存取資料
2. ❌ UI 不可直接操作 Core Data
3. ✅ Service 可以直接操作 Core Data Context
4. ❌ Service 之間不可循環依賴

### 資料流向範例

#### ✅ 正確：匯入 BibTeX
```
User Action (UI)
  → ImportViewModel.importBibTeX()
    → BibTeXParser.parse() (Service)
      → Entry.create() (Core Data)
```

#### ❌ 錯誤：UI 直接寫入 Core Data
```
Button("匯入") {
    let entry = Entry(context: viewContext)  // 錯誤！
    entry.title = "..."
}
```

## 跨領域檢查清單

當任務涉及多個模組時，必須執行以下檢查：

### 修改 Core Data 模型時
```
□ 更新對應的 ViewModel 綁定
□ 檢查所有 UI 顯示是否正常
□ 執行 Core Data 單元測試
□ 確認資料遷移策略（如有新增欄位）
□ 驗證與 Service 層的互動
```

### 修改 Service 層時
```
□ 檢查 ViewModel 的呼叫是否需要調整
□ 更新相關單元測試
□ 驗證錯誤處理機制
□ 確認是否影響 UI 顯示
□ 檢查與 Core Data 的互動
```

### 修改 UI 時
```
□ 確認 AppTheme 顏色使用
□ 測試深色/淺色模式
□ 驗證繁體中文顯示
□ 檢查 ViewModel 綁定
□ 執行相關 UI 測試
□ 確認 VoiceOver 可訪問性
```

### 新增功能時
```
□ 規劃 Core Data 模型變更
□ 設計 Service 層 API
□ 建立 ViewModel 層
□ 實作 UI 視圖
□ 撰寫單元測試與 UI 測試
□ 更新文件與開發日記
```

## 通用開發規範

### 命名慣例（所有 Skill 共用）

| 類型 | 規則 | 正確範例 | 錯誤範例 |
|------|------|----------|----------|
| 視圖 | PascalCase + View | `ModernEntryListView` | `entryList` |
| 視圖模型 | PascalCase + ViewModel | `LibraryViewModel` | `LibraryVM` |
| 服務 | PascalCase + Service | `CitationService` | `cite_service` |
| Core Data 實體 | PascalCase | `Entry`, `Library` | `entry`, `Lib` |
| 檔案名 | 與類別同名 | `EntryDetailView.swift` | `entryDetail.swift` |

### 中文化規範（所有 Skill 共用）

✅ **必須遵守**：
- 所有 UI 文字使用**繁體中文**
- 使用**台灣學術用語**（書目、匯入、引用）
- 標點符號使用**全形**（，。「」）

❌ **禁止**：
- 簡體中文
- 英文 UI 文字（除專有名詞：BibTeX、DOI）
- 半形標點

**台灣學術用語對照表**：
| 使用 | 不使用 |
|------|--------|
| 書目 | 文獻 |
| 匯入 | 導入 |
| 引用 | 引述 |

## 標準開發流程

## 標準開發流程

### 通用工作流程（所有任務）

```
1. 理解需求 → 識別涉及的模組
2. 自動載入對應 Skill
3. 執行專業 Skill 的規範
4. 跨模組整合檢查
5. 編譯驗證
6. 執行測試
7. 更新文件
```

### 編譯檢查指令

```bash
cd /Users/lawliet/OVEREND
xcodebuild -scheme OVEREND build 2>&1 | grep -E "error:"
```

### 品質檢查（每次任務完成前）

- [ ] 程式碼符合命名規範
- [ ] 所有顏色使用 AppTheme.swift
- [ ] UI 文字使用繁體中文與台灣學術用語
- [ ] 標點符號使用全形
- [ ] 檔案位置正確
- [ ] 編譯無錯誤
- [ ] 相關測試已執行並通過
- [ ] PROJECT_STATUS.md 已更新
- [ ] 開發日記格式已輸出

## 文件更新規範

### PROJECT_STATUS.md 更新格式

```markdown
## [YYYY-MM-DD] 更新

### 完成項目
- [具體功能或修復描述]

### 技術細節
- 修改檔案：`路徑/檔案名.swift`
- 變更內容：[簡要說明變更]
- 涉及模組：[UI / Core Data / Service / Testing]

### 測試狀態
- [x] 編譯通過
- [x] 功能驗證
- [x] 單元測試通過（如有）
- [ ] 待測試項目（如有）
```

### Notion 開發日記格式

**務必以此格式輸出**：

```markdown
---
📅 **日期**: YYYY-MM-DD HH:MM
🎯 **任務類型**: [修復Bug / 新增功能 / 程式碼優化 / 文件更新]
📝 **任務標題**: [簡短描述]
🔧 **涉及模組**: [UI / Core Data / Service / Testing]

---

## 變更內容

**修改檔案**:
- `OVEREND/[模組]/xxx.swift`

**具體變更**:
1. [變更項目 1]
2. [變更項目 2]

---

## 技術要點

- [關鍵決策或技術發現]
- [遇到的問題與解決方案]

---

## 品質檢查

- [x] 命名規範 ✅
- [x] 主題系統 ✅
- [x] 中文化 ✅
- [x] 編譯通過 ✅
- [x] 測試通過 ✅
- [x] 跨模組整合檢查 ✅

---

## 下一步

- [ ] [待辦事項 1]
- [ ] [待辦事項 2]

---
```

## 常用指令

### 專案導航
```bash
cd /Users/lawliet/OVEREND
```

### 編譯與檢查
```bash
# 建置專案
xcodebuild -scheme OVEREND -destination 'platform=macOS' build

# 檢查編譯錯誤
xcodebuild -scheme OVEREND build 2>&1 | grep -E "error:"

# 清除建置快取
xcodebuild clean -scheme OVEREND
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 測試執行
```bash
# 執行所有測試
xcodebuild test -scheme OVEREND -destination 'platform=macOS'

# 只執行單元測試
xcodebuild test -scheme OVEREND -destination 'platform=macOS' -only-testing:OVERENDTests
```

## 參考文件

- **專案開發指南**: `/Users/lawliet/OVEREND/開發指南.md`
- **專案狀態**: `/Users/lawliet/OVEREND/PROJECT_STATUS.md`
- **品牌手冊**: `/Users/lawliet/OVEREND/OVEREND_Brand_Product_Design_Manual.md`

## 專責 Skill 檔案

- `ui-specialist.md` - UI/SwiftUI 開發規範
- `coredata-specialist.md` - Core Data 模型管理
- `service-specialist.md` - 服務層開發規範
- `testing-specialist.md` - 測試撰寫與執行

---

**建立日期**: 2025-01-21
**最後更新**: 2025-01-21
**版本**: 2.0 (模組化架構)
**維護者**: 彥儒 (Lawliet)
