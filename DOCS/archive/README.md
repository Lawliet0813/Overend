# OVEREND macOS - 智慧文獻管理與論文寫作工具

> 讓研究者專注於研究本身，而不是文獻管理

## 📱 關於此專案

OVEREND macOS 是一個原生 macOS 應用，使用 SwiftUI + AppKit 開發，專注於：

- **免登入** - 純本地應用，無需帳號
- **BibTeX 管理** - 完整的文獻庫管理
- **Word 級別編輯器** - 富文本論文寫作
- **PDF/DOCX 匯出** - 匯出完整論文
- **PDF 附件** - 管理 PDF 文件
- **強大搜尋** - 全文搜索與篩選
- **組群管理** - 樹狀結構組織

## 🚀 快速開始

### 前置需求

- **macOS 13.0 (Ventura)** 或更高版本
- **Xcode 15.0** 或更高版本
- **Swift 5.9** 或更高版本

### 方式一：使用 Xcode 開啟（推薦）

1. 打開 Xcode
2. 選擇 **File > Open**
3. 導航到 `overend-macos` 目錄
4. 選擇 **Package.swift** 文件並開啟
5. 等待 Xcode 解析依賴（首次需下載 ZIPFoundation）
6. 選擇 **Product > Run** 或按 `⌘R` 運行

### 方式二：命令行編譯

```bash
cd overend-macos
swift build
swift run OVEREND
```

### 方式三：創建 Xcode 專案

```bash
cd overend-macos
swift package generate-xcodeproj
open OVEREND.xcodeproj
```

## 📁 專案結構

```
overend-macos/
├── Package.swift                    # Swift Package 配置
├── Sources/OVEREND/
│   ├── OVERENDApp.swift             # App 入口
│   ├── ContentView.swift            # 主視圖（三欄布局）
│   │
│   ├── Models/                      # Core Data 模型
│   │   ├── PersistenceController.swift
│   │   ├── Library.swift
│   │   ├── Entry.swift
│   │   ├── Group.swift
│   │   ├── Attachment.swift
│   │   └── Document.swift
│   │
│   ├── ViewModels/                  # 視圖模型
│   │   ├── LibraryViewModel.swift
│   │   └── EntryViewModel.swift
│   │
│   ├── Views/                       # SwiftUI 視圖
│   │   ├── Sidebar/
│   │   ├── EntryList/
│   │   ├── EntryDetail/
│   │   ├── Editor/
│   │   └── Settings/
│   │
│   ├── Services/                    # 業務邏輯
│   │   ├── BibTeXParser.swift      # TODO
│   │   ├── BibTeXGenerator.swift   # TODO
│   │   ├── ExportService.swift     # TODO
│   │   └── SearchService.swift     # TODO
│   │
│   └── Utilities/                   # 工具類
│       ├── Color+Brand.swift
│       └── Constants.swift
```

## 🎨 OVEREND 品牌色彩

- **主色（鋼筆藍）：** `#1A2B3C` - 代表專業、可靠、知識深度
- **強調色（啟發綠）：** `#00F5A0` - 代表創新、啟發、生命力
- **背景色（紙張灰）：** `#F4F4F9` - 柔和的背景色，模擬紙張質感

## 🔧 技術棧

- **框架：** SwiftUI + AppKit
- **語言：** Swift 5.9+
- **數據持久化：** Core Data
- **PDF 處理：** PDFKit
- **DOCX 匯出：** ZIPFoundation + 自定義 XML
- **架構：** MVVM

## 📝 開發狀態

### ✅ 已完成（Phase 1 - Week 1）

- [x] 專案結構設置
- [x] Swift Package Manager 配置
- [x] Core Data 模型（Library, Entry, Group, Attachment, Document）
- [x] PersistenceController
- [x] 品牌色彩工具類
- [x] 基礎 ViewModel（LibraryViewModel, EntryViewModel）
- [x] 基礎 UI 布局（三欄 NavigationSplitView）
- [x] Sidebar 視圖（庫列表）
- [x] EntryList 視圖（條目列表）
- [x] EntryDetail 視圖（條目詳情）
- [x] Settings 視圖

### 🚧 進行中

- [ ] BibTeX 解析器實現
- [ ] BibTeX 生成器實現
- [ ] 匯入/導出 .bib 文件功能

### 📅 下一步（Phase 1 - Week 2-3）

- [ ] 完整的 CRUD 操作（創建/編輯/刪除庫和條目）
- [ ] BibTeX 字段編輯器 UI
- [ ] 組群管理功能

## 🤝 貢獻

目前為內部開發階段，歡迎提供建議與反饋。

## 📄 授權

專有軟件 - OVEREND Team

---

**讓研究者專注於研究本身，而不是文獻管理。**
