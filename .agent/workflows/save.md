---
description: 儲存目前的開發進度到 Git
---

# 儲存開發進度

執行以下步驟來儲存您的工作進度：

// turbo-all

## 1. 查看目前的修改狀態

```bash
git status
```

## 2. 加入所有修改的檔案

```bash
git add .
```

## 3. 提交修改（請替換訊息內容）

```bash
git commit -m "進度儲存：[描述您的修改]"
```

## 快速一行指令（適合快速儲存）

```bash
git add . && git commit -m "進度儲存：$(date '+%Y-%m-%d %H:%M')"
```

---

**提示**：建議每完成一個功能或每隔 1-2 小時就執行一次儲存。
