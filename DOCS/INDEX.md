# OVEREND 文檔索引

本索引整理專案所有技術文檔，按功能模塊分類。

---

## 📖 快速導航

- [旗艦開發手冊](manuals/DEVELOPMENT_BOOK.md) - **新！排版優化版**
- [全文百科](manuals/OVEREND_ENCYCLOPEDIA.md) - **新！全文件匯整版**
- [開發全手冊總匯](manuals/DEVELOPMENT_OMNIBUS.md) - 核心彙整
- [使用者指南](#-使用者指南) - 安裝、使用、重置
- [旗艦手冊](#-旗艦手冊) - 專業 PDF 導覽
- [技術文檔](#-技術文檔) - 架構、服務、格式
- [功能文檔](#-功能文檔) - AI、PDF/DOI、編輯器等
- [學術格式](#-學術格式) - APA、中文術語、書目
- [UI/UX 設計](#-uiux-設計) - 介面優化與改進
- [測試文檔](#-測試文檔) - 測試計劃、指南、結果
- [開發文檔](#-開發文檔) - 進度、日誌、狀態
- [報告](#-報告) - 階段性完成報告
- [發布文檔](#-發布文檔) - 版本發布記錄
- [規劃與設計](#-規劃與設計) - 產品設計、架構規劃

---

## 📘 使用者指南

**目錄**: [guides/](guides/)

| 文檔 | 說明 |
|------|------|
| [使用者指南](guides/USER_GUIDE.md) | 完整使用手冊 |
| [安裝指南](guides/INSTALL_GUIDE.md) | 安裝步驟與依賴 |
| [重置指南](guides/RESET_GUIDE.md) | 資料重置與清理 |
| [程式碼規範](guides/CODING_GUIDELINES.md) | 開發規範指南 |
| [Rust核心功能說明](manuals/Rust核心功能說明.md) | Rust 模組詳解 |

---

## 📚 旗艦手冊 (Manuals)

**目錄**: [manuals/](manuals/)

| 文檔 | 說明 |
|------|------|
| [旗艦開發手冊](manuals/DEVELOPMENT_BOOK.md) | 排版美化版 PDF 來源 |
| [全文百科](manuals/OVEREND_ENCYCLOPEDIA.md) | 全專案文件百科全書 |
| [開發全手冊總匯](manuals/DEVELOPMENT_OMNIBUS.md) | 核心開發聚合文檔 |

---

## 🔧 技術文檔

**目錄**: [technical/](technical/)

### 架構設計

| 文檔 | 說明 |
|------|------|
| [架構優化](technical/architecture/ARCHITECTURE_OPTIMIZATION.md) | 系統架構優化 |
| [專案結構](technical/architecture/PROJECT_STRUCTURE.md) | 專案目錄結構 |
| [代碼清理計畫](technical/architecture/CODE_CLEANUP_PLAN.md) | 代碼重構計畫 |

### 服務層

| 文檔 | 說明 |
|------|------|
| [DOI 服務重構](technical/services/DOI_SERVICE_REFACTORING_PLAN.md) | DOI 服務架構 |

### 格式處理

| 文檔 | 說明 |
|------|------|
| [DOCX 格式保留](technical/formats/DOCX_PRESERVE_FORMAT_GUIDE.md) | Word 格式處理 |
| [LaTeX 混合模式](technical/formats/LATEX_HYBRID_MODE.md) | LaTeX 支援 |

---

## ⚙️ 功能文檔

**目錄**: [features/](features/)

**總覽文檔**:

- [功能總結](features/FEATURE_SUMMARY.md)
- [實作總結](features/IMPLEMENTATION_SUMMARY.md)

### AI 整合

**子目錄**: [features/ai/](features/ai/)

| 文檔 | 說明 |
|------|------|
| [AI 整合計畫](features/ai/AI_INTEGRATION_PLAN.md) | AI 功能規劃 |
| [AI 功能摘要](features/ai/AI_FEATURES_SUMMARY.md) | AI 功能總覽 |
| [Apple AI 整合](features/ai/APPLE_AI_INTEGRATION.md) | 原生 AI 整合 |
| [學習系統](features/ai/LEARNING_SYSTEM.md) | 智慧學習功能 |
| [Apple 範例專案](features/ai/AddingIntelligentAppFeaturesWithGenerativeModels/) | 官方範例 |

### PDF 與 DOI

**子目錄**: [features/pdf-doi/](features/pdf-doi/)

| 文檔 | 說明 |
|------|------|
| [DOI 最終報告](features/pdf-doi/DOI_FINAL_REPORT.md) | DOI 功能總結 |
| [DOI 開發完成](features/pdf-doi/DOI_DEVELOPMENT_COMPLETE.md) | DOI 里程碑 |
| [DOI 實作狀態](features/pdf-doi/DOI_IMPLEMENTATION_STATUS.md) | DOI 進度 |
| [DOI 括號修復](features/pdf-doi/DOI_BRACKET_FIX.md) | 格式修復 |
| [PDF 匯入優化](features/pdf-doi/PDF_IMPORT_OPTIMIZATION.md) | 匯入增強 |
| [PDF 匯出修復](features/pdf-doi/PDF_EXPORT_FIX.md) | 匯出問題 |
| [PDF 期刊問題](features/pdf-doi/PDF_JOURNAL_ISSUES.md) | 期刊處理 |

### 編輯器功能

**子目錄**: [features/editor/](features/editor/)

| 文檔 | 說明 |
|------|------|
| [寫作功能需求](features/editor/WRITER_REQUIREMENTS.md) | 編輯器規劃 |
| [Physical Canvas 說明](features/editor/PHYSICAL_CANVAS_README.md) | 畫布功能 |
| [Physical Canvas 架構](features/editor/PHYSICAL_CANVAS_ARCHITECTURE.md) | 技術架構 |
| [Physical Canvas 快速開始](features/editor/PHYSICAL_CANVAS_QUICK_START.md) | 使用指南 |

### 資料管理

**子目錄**: [features/data/](features/data/)

| 文檔 | 說明 |
|------|------|
| [清除資料功能](features/data/CLEAR_DATA_FEATURE.md) | 資料清理 |
| [清除資料摘要](features/data/CLEAR_DATA_SUMMARY.md) | 功能總結 |
| [批次刪除功能](features/data/SELECTION_BATCH_DELETE_FEATURE.md) | 批次操作 |
| [選擇功能摘要](features/data/SELECTION_FEATURE_SUMMARY.md) | 選擇機制 |

### 匯入功能

**子目錄**: [features/import/](features/import/)

| 文檔 | 說明 |
|------|------|
| [學術翻譯匯入](features/import/ACADEMIC_TRANSLATION_IMPORT_FEATURE.md) | 翻譯匯入 |

---

## 📚 學術格式

**目錄**: [academic/](academic/)

| 文檔 | 說明 |
|------|------|
| [APA 第七版指南](academic/APA_7th_Edition_Guide_for_OVEREND.md) | APA 格式規範 |
| [格式系統指南](academic/FORMAT_SYSTEM_GUIDE.md) | 格式處理架構 |
| [書目欄位對照](academic/BIBLIOGRAPHY_FIELD_COMPARISON.md) | 欄位映射 |
| [中文術語完整報告](academic/CHINESE_TERMINOLOGY_COMPLETE_REPORT.md) | 術語標準化 |
| [中文術語審查](academic/CHINESE_TERMINOLOGY_REVIEW.md) | 術語檢視 |
| [華藝 DOI 手冊](academic/airiti_DOI_numbering_handbook.pdf) | DOI 參考 |
| [論文格式參考](academic/行政管理碩士學程碩士論文撰寫格式參考建議_11207-2最新.pdf) | 格式範例 |

---

## 🎨 UI/UX 設計

**目錄**: [ui-ux/](ui-ux/)

| 文檔 | 說明 |
|------|------|
| [UX 改進計畫](ui-ux/UX_IMPROVEMENTS.md) | 使用者體驗優化 |
| [UI 改進完成](ui-ux/UI_IMPROVEMENTS_COMPLETE.md) | 已完成項目 |
| [UI 改進進度](ui-ux/UI_IMPROVEMENTS_PROGRESS.md) | 進行中項目 |
| [UI 工作流程](ui-ux/UI_WORKFLOW.md) | 設計流程 |
| [UI 優化總結](ui-ux/UI_OPTIMIZATION_SUMMARY.md) | v1.0 優化 |
| [UI 優化 v1.1](ui-ux/UI_OPTIMIZATION_V1.1.md) | v1.1 更新 |

---

## 🧪 測試文檔

**目錄**: [testing/](testing/)

### 測試計劃

**子目錄**: [testing/plans/](testing/plans/)

| 文檔 | 說明 |
|------|------|
| [DOI 測試計畫](testing/plans/DOI_TEST_PLAN.md) | DOI 測試規劃 |
| [PDF 匯入測試計畫](testing/plans/PDF_IMPORT_TEST_PLAN.md) | PDF 測試方案 |
| [PDF 擷取測試模板](testing/plans/PDF_EXTRACTION_TEST_RECORD_TEMPLATE.md) | 測試記錄模板 |

### 測試指南

**子目錄**: [testing/guides/](testing/guides/)

| 文檔 | 說明 |
|------|------|
| [PDF 匯入測試指南](testing/guides/PDF_IMPORT_TESTING_GUIDE.md) | PDF 測試步驟 |
| [使用者測試指南](testing/guides/03_使用者測試指南.md) | 使用者測試 |
| [快速參考](testing/guides/快速參考.md) | 測試速查表 |

### 測試結果

**子目錄**: [testing/results/](testing/results/)

| 文檔 | 說明 |
|------|------|
| [測試結果](testing/results/TEST_RESULTS.md) | 綜合測試結果 |
| [DOI 測試摘要](testing/results/DOI_TESTING_SUMMARY.md) | DOI 測試報告 |
| [測試記錄 2025-01-10](testing/results/測試記錄_2025-01-10.md) | 日期測試記錄 |
| [測試進度追蹤](testing/results/測試進度追蹤.md) | 進度監控 |

### 測試檢查清單

**子目錄**: [testing/checklists/](testing/checklists/)

| 文檔 | 說明 |
|------|------|
| [功能測試清單](testing/checklists/01_功能測試清單.md) | 功能測試項目 |
| [Bug 追蹤表](testing/checklists/02_Bug追蹤表.md) | 問題追蹤 |
| [展示情境腳本](testing/checklists/05_展示情境腳本.md) | Demo 流程 |

### 效能測試

**子目錄**: [testing/performance/](testing/performance/)

| 文檔 | 說明 |
|------|------|
| [效能測試記錄](testing/performance/04_效能測試記錄.md) | 效能基準 |

### 其他

| 文檔 | 說明 |
|------|------|
| [跨領域測試檔案](testing/CROSSDOMAIN_TEST_FILES.md) | 測試素材 |
| [測試素材](testing/測試素材/) | 測試用檔案 |

---

## 👨‍💻 開發文檔

**目錄**: [development/](development/)

| 文檔 | 說明 |
|------|------|
| [開發日誌](development/DEVELOPMENT_DIARY.md) | 開發記錄 |
| [專案狀態](development/PROJECT_STATUS.md) | 當前狀態 |
| [開發進度](development/PROGRESS.md) | 進度追蹤 |
| [開發指令](development/INSTRUCTIONS.md) | 開發說明 |
| [iPad 目標設定](development/IPAD_TARGET_SETUP.md) | 跨平台配置 |
| [編譯修復總結](development/BUILD_FIX_SUMMARY.md) | 編譯問題 |
| [修復編譯錯誤](development/FIX_BUILD_ERRORS.md) | 錯誤處理 |
| [編輯器說明](development/EDITOR_README.md) | 編輯器文檔 |
| [編碼規範](development/CODING_RULES.md) | 命名規則 |
| [建置狀態](development/BUILD_STATUS.md) | 最新編譯狀態 |
| [編譯修復記錄](development/COMPILATION_FIX.md) | 歷史修復 |

---

## 📊 報告

**目錄**: [reports/](reports/)

| 文檔 | 說明 |
|------|------|
| [AI 建議報告](reports/AI_Agent_優化建議報告.md) | AI 優化建議 |
| [AI 成果報告](reports/AI_Agent_優化成果報告.md) | AI 優化結果 |
| [AI 修復報告](reports/AI_TEST_FIXES_REPORT.md) | 測試修復 |
| [AI 框架修復](reports/AI_TEST_FRAMEWORK_FIX_REPORT.md) | 框架修復 |
| [AI 框架總結](reports/AI_TEST_FRAMEWORK_SUMMARY.md) | 框架總覽 |
| [UX 審查報告](reports/BUTTON_UX_AUDIT_REPORT.md) | UI/UX 審核 |
| [UI 修復報告](reports/UI_FIX_REPORT.md) | 介面修復 |
| [持久化問題報告](reports/文獻庫持久化問題修復報告.md) | 資料庫修復 |
| [排版引擎診斷](reports/編輯器排版引擎診斷報告.md) | 排版引擎分析 |
| [Phase 1 完成報告](reports/PHASE1_COMPLETION_REPORT.md) | 第一階段 |
| [Phase 2 完成報告](reports/PHASE2_COMPLETION_REPORT.md) | 第二階段 |
| [Phase 2 編輯器分析](reports/PHASE2_EDITOR_ANALYSIS.md) | 編輯器研究 |
| [Phase 3 完成報告](reports/PHASE3_COMPLETION_REPORT.md) | 第三階段 |
| [專案重構報告](reports/PROJECT_REFACTORING_REPORT.md) | 重構總結 |
| [會話完成報告](reports/SESSION_COMPLETION_REPORT.md) | 會話總結 |
| [清理進度報告](reports/CLEANUP_PROGRESS_REPORT.md) | 清理工作 |
| [重組總結](reports/REORGANIZATION_SUMMARY.md) | 架構重組 |

---

## 📦 發布文檔

**目錄**: [releases/](releases/)

### v1.0.1

| 文檔 | 說明 |
|------|------|
| [打包總結](releases/v1.0.1/BUILD_SUMMARY_v1.0.1.md) | 打包流程 |
| [發布說明](releases/v1.0.1/RELEASE_NOTES_v1.0.1.md) | 版本說明 |
| [發布檢查清單](releases/v1.0.1/RELEASE_CHECKLIST.md) | 發布流程 |

---

## 📋 規劃與設計

**目錄**: [planning/](planning/)

| 文檔 | 說明 |
|------|------|
| [品牌設計手冊](planning/OVEREND_Brand_Product_Design_Manual.md) | 品牌規範 |
| [產品設計與規劃書](planning/OVEREND_產品設計與規劃書.pdf) | 產品文檔 |
| [架構深度研究報告](planning/繁體中文優先之學術寫作與書目管理系統架構深度研究報告.md) | 技術研究 |

---

## 🎬 媒體資產

**目錄**: [assets/](assets/)

| 檔案 | 說明 |
|------|------|
| [AI Agent 展示簡報](assets/OVEREND_AI_Agent_展示簡報.pptx) | 功能演示 |
| [App 設計樣機 (v3)](assets/app_mockup_v3.png) | UI 設計稿 |
| [PDF 美編樣式](assets/manual_style.css) | 手冊 CSS |
| [Landing Page](assets/landing-page.html) | 下載頁面 |

---

## 🌐 網站文檔

**目錄**: [web/](web/)

| 文檔 | 說明 |
|------|------|
| [Beta 網站檢查清單](web/BETA_WEBSITE_CHECKLIST.md) | 網站上線檢查 |
| [Google 表單模板](web/GOOGLE_FORM_TEMPLATE.md) | 申請表單 |

---

## 🚀 v2.0 規劃

**目錄**: [v2.0_Specs/](v2.0_Specs/)

| 文檔 | 說明 |
|------|------|
| [UX 規劃](v2.0_Specs/UX 規劃.md) | 下一代 UX |
| [技術架構白皮書](v2.0_Specs/原生學術代理人編輯系統技術架構與產品設計白皮書.md) | 架構設計 |
| [架構藍圖](v2.0_Specs/原生學術代理人編輯系統架構藍圖.md) | 系統規劃 |

---

## 🇹🇼 中文特定文檔

**目錄**: [zh/](zh/)

| 文檔 | 說明 |
|------|------|
| [技術報告比對](zh/技術報告與程式碼實作比對.md) | 實作對照 |

---

## 🗄️ 歷史歸檔

歷史版本文檔已移至 [archive/](archive/) 目錄，僅保留參考價值的歷史記錄。

---

## 📜 開發日誌 (Logs)

**目錄**: [logs/](logs/)

| 文檔 | 說明 |
|------|------|
| [日誌總覽](logs/README.md) | 所有建置與測試日誌之說明 |

---

*文檔結構最後更新：2026-01-21*
*總文檔數：150+ 個 Markdown 文件 + 20+ 個日誌文件*
