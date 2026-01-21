---
description: 從 GitHub 同步最新代碼 (Sync from GitHub)
---

這個工作流程將協助您從 GitHub 遠端儲存庫拉取最新的變更並合併到當前分支。

1. **檢查 Git 狀態**
   確保您的工作目錄是乾淨的，沒有未提交的變更。

   ```bash
   git status
   ```

2. **拉取遠端變更**
   // turbo
   從 `origin` 儲存庫拉取當前分支的最新版本。

   ```bash
   git pull origin main
   ```

   *(如果您使用不同分支，请將 `main` 替換為您的分支名稱)*

3. **處理衝突 (如果有)**
   如果 `git pull` 報告衝突，請手動解決衝突文件，然後執行：

   ```bash
   git add .
   git commit -m "Merge remote changes"
   ```
