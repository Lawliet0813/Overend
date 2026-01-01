---
description: 更新專案進度至 PROJECT_STATUS.md
---

# 更新專案進度工作流程

當用戶說「更新專案進度」或 `/update-project-status` 時，執行以下步驟：

## 1. 檢視目前 PROJECT_STATUS.md

// turbo

```bash
cat /Users/lawliet/OVEREND/PROJECT_STATUS.md
```

## 2. 收集最新進度資訊

檢查以下來源的變更：

- 最近編輯的 Swift 檔案
- 新增或刪除的功能
- UI 改進項目
- 已修復的 Bug

## 3. 更新 PROJECT_STATUS.md

更新以下區塊：

- **最後更新日期**：更新為當前日期
- **專案完成度**：根據實際進度調整百分比
- **已完成功能**：新增最新完成的功能
- **進行中功能**：更新當前正在開發的項目
- **待開發功能**：移除已完成的項目

## 4. 同步更新相關文件

如有需要，同時更新：

- `UI_IMPROVEMENTS_COMPLETE.md` - UI 改進記錄
- `WRITER_REQUIREMENTS.md` - 編輯器需求狀態
- `INSTRUCTIONS.md` - 開發指南

## 5. 確認更新內容

向用戶確認已更新的內容摘要。

---

## 進度格式範例

```markdown
## 📊 專案進度

| 模組 | 狀態 | 完成度 |
|------|------|--------|
| 文獻管理 | ✅ 完成 | 95% |
| UI 系統 | ✅ 完成 | 90% |
| 寫作編輯器 | 🔄 進行中 | 60% |
| AI 輔助 | ⏳ 待開發 | 0% |
```

## 狀態標記說明

- ✅ 已完成
- 🔄 進行中
- ⏳ 待開發
- 🐛 有 Bug
- ⚠️ 需要注意
