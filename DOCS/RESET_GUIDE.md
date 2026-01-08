# OVEREND 資料重置指南

## 資料儲存位置

OVEREND 使用 macOS 沙盒機制，資料儲存在：

```
~/Library/Containers/com.overend.OVEREND/Data/Library/Application Support/OVEREND/
├── OVEREND.sqlite       # Core Data 資料庫（文獻、文稿）
├── OVEREND.sqlite-shm   # SQLite 共享記憶體
├── OVEREND.sqlite-wal   # SQLite 寫入日誌
├── Attachments/         # PDF 附件檔案
└── Templates/           # 文稿範本
```

---

## 完全重置（恢復出廠設定）

> ⚠️ **警告**：此操作將刪除所有資料，無法復原！

### 步驟

1. **關閉 OVEREND App**

2. **在終端機執行：**

```bash
rm -rf ~/Library/Containers/com.overend.OVEREND/Data/Library/Application\ Support/OVEREND/*
```

1. **重新啟動 OVEREND**
   - App 會自動建立空白資料庫
   - 如同全新安裝

---

## 僅清除資料庫（保留附件）

```bash
rm ~/Library/Containers/com.overend.OVEREND/Data/Library/Application\ Support/OVEREND/OVEREND.sqlite*
```

---

## 備份資料

在重置前備份：

```bash
cp -R ~/Library/Containers/com.overend.OVEREND/Data/Library/Application\ Support/OVEREND ~/Desktop/OVEREND_Backup
```

還原備份：

```bash
cp -R ~/Desktop/OVEREND_Backup/* ~/Library/Containers/com.overend.OVEREND/Data/Library/Application\ Support/OVEREND/
```
