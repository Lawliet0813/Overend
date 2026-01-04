---
description: 完整開發收尾流程 - Git 存檔、更新日記、同步 Notion
---

# 開發收尾工作流程

執行以下步驟完成今日開發的收尾工作：

// turbo-all

---

## 步驟 1：Git 存檔

查看修改狀態並提交到 Git：

```bash
cd /Users/lawliet/OVEREND && git status
```

```bash
cd /Users/lawliet/OVEREND && git add . && git commit -m "進度儲存：$(date '+%Y-%m-%d %H:%M')"
```

---

## 步驟 2：更新開發日記

1. 讀取 `/Users/lawliet/OVEREND/DOCS/DEVELOPMENT_DIARY.md`

2. 從最近的對話記錄和文件變更中提取重要開發資訊：
   - 新增或修改的功能
   - 解決的問題
   - 技術決策
   - 已完成的任務

3. 在 `DEVELOPMENT_DIARY.md` 中新增今日開發紀錄：
   - 更新開發時間線區段
   - 更新最後更新時間戳
   - 更新編譯狀態

---

## 步驟 3：更新專案狀態

同步更新 `/Users/lawliet/OVEREND/DOCS/PROJECT_STATUS.md`：

- 更新日期
- 專案進度百分比
- 已完成/進行中功能清單

---

## 步驟 4：同步到 Notion

使用 NotionService 將最新日記同步到 Notion 頁面：

- Diary Page ID: `2db55714413f80d0bd52ee67dafdb6cb`
- 同步最後一個 `###` 區段的內容

**注意**：此步驟需要在 App 內執行，或確認 Notion API Key 已設定。

---

## 步驟 5：確認並通知用戶

向用戶確認已完成的工作：

- Git 提交狀態
- 開發日記更新內容
- PROJECT_STATUS.md 更新內容
- Notion 同步狀態

---

## 快速指令

一行 Git 存檔：

```bash
cd /Users/lawliet/OVEREND && git add . && git commit -m "$(date '+%Y-%m-%d') 開發進度"
```

---

**建議**：每天結束開發前執行此工作流程，確保所有進度都有記錄。
