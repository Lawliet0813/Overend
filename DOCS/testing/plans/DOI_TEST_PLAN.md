# DOI 自動查詢功能測試計畫

**測試日期：** 2025-12-28  
**測試版本：** 1.4.0 (DOI Auto-Query)

---

## ✅ 整合完成狀態

### 已完成項目
1. ✅ CrossRefService 建立並測試
2. ✅ 整合到 EntryListView.swift
3. ✅ 三層回退機制實作
4. ✅ 編譯成功（無錯誤）

### 程式碼變更
- **檔案：** `/Users/lawliet/OVEREND/OVEREND/Views/EntryList/EntryListView.swift`
- **修改內容：**
  - `importSinglePDF()` - 新增 CrossRefService 查詢
  - `createEntryFromCrossRef()` - 新增從 CrossRef 元數據創建 Entry 的函數

---

## 🧪 測試案例

### 測試案例 1：期刊論文（CrossRef 應該成功）

**測試 PDF：** 任何包含 DOI 的期刊論文  
**建議 DOI：** 10.6712/JCPA.202306_(32).0008 或其他

**測試步驟：**
1. 啟動 OVEREND 應用程式
2. 選擇或創建一個 Library
3. 點擊「匯入」→「匯入 PDF」
4. 選擇包含 DOI 的 PDF 檔案
5. 觀察 Console 輸出

**預期結果：**
```
找到 DOI: 10.6712/JCPA.202306_(32).0008
✅ CrossRef 查詢成功: [文章標題]
✅ 成功從 CrossRef 匯入:
  標題: [完整標題]
  作者: [作者名稱，以「、」分隔]
  年份: 2023
  期刊: 中華行政學報
  卷: 32
  期: 2
  頁碼: 129-143
  DOI: 10.6712/JCPA.202306_(32).0008
```

**驗證項目：**
- [ ] 標題正確提取
- [ ] 作者名稱正確（中文格式）
- [ ] 年份正確
- [ ] 期刊名稱正確
- [ ] 卷期號正確
- [ ] 頁碼正確
- [ ] DOI 保存
- [ ] PDF 附件成功連結

---

### 測試案例 2：CrossRef 失敗，DOIService 成功

**測試目的：** 驗證回退機制

**測試步驟：**
1. 使用一個 CrossRef 可能查不到但 DOI.org 可以查到的 DOI
2. 觀察 Console 輸出

**預期結果：**
```
找到 DOI: [DOI]
⚠️ CrossRef 查詢失敗: [錯誤訊息], 嘗試 DOIService
✅ DOIService 查詢成功: [標題]
成功匯入: [標題]
```

---

### 測試案例 3：兩者都失敗，使用本地提取

**測試目的：** 驗證最後回退機制

**測試步驟：**
1. 使用一個 DOI 格式錯誤或無效的 PDF
2. 觀察 Console 輸出

**預期結果：**
```
找到 DOI: [錯誤 DOI]
⚠️ CrossRef 查詢失敗: [錯誤]
⚠️ DOIService 也失敗: [錯誤]
回退到基本匯入模式，但保留 DOI
成功匯入 PDF: [標題] (作者: [作者], 年份: [年份], DOI: [DOI])
```

---

### 測試案例 4：無 DOI 的 PDF

**測試目的：** 確保無 DOI 的 PDF 仍能正常匯入

**測試步驟：**
1. 使用一個不包含 DOI 的 PDF（如碩士論文）
2. 觀察 Console 輸出

**預期結果：**
```
成功匯入 PDF: [標題] (作者: [作者], 年份: [年份])
```

**驗證項目：**
- [ ] 使用本地元數據提取
- [ ] 標題、作者、年份盡可能提取
- [ ] 沒有 DOI 欄位

---

## 🔍 Console 日誌關鍵字

查看 Xcode Console 時，注意以下關鍵輸出：

### 成功標記
- `找到 DOI:` - DOI 提取成功
- `✅ CrossRef 查詢成功:` - CrossRef 查詢成功
- `✅ 成功從 CrossRef 匯入:` - 完整匯入成功

### 警告標記
- `⚠️ CrossRef 查詢失敗:` - CrossRef 失敗，進入回退
- `⚠️ DOIService 也失敗:` - 兩個服務都失敗

### 錯誤標記
- `❌ PDF 附加失敗:` - PDF 檔案處理錯誤

---

## 📊 測試結果記錄

### 測試結果表格

| 案例 | PDF 名稱 | DOI | CrossRef | DOIService | 本地提取 | 結果 |
|------|----------|-----|----------|------------|----------|------|
| 1 | | | ⬜ | ⬜ | ⬜ | ⬜ |
| 2 | | | ⬜ | ⬜ | ⬜ | ⬜ |
| 3 | | | ⬜ | ⬜ | ⬜ | ⬜ |
| 4 | | | ⬜ | ⬜ | ⬜ | ⬜ |

**圖例：**
- ✅ 成功
- ❌ 失敗
- ⚠️ 警告
- ⬜ 未測試
- N/A 不適用

---

## 🚀 如何開始測試

### 方法 1：使用 Xcode
```bash
# 在 Xcode 中
1. 打開 OVEREND.xcodeproj
2. 按 Cmd+R 運行
3. 查看 Console 輸出（Cmd+Shift+Y）
```

### 方法 2：使用命令列
```bash
cd /Users/lawliet/OVEREND
open /Users/lawliet/Library/Developer/Xcode/DerivedData/OVEREND-cndwckokhthjmcbkmovocplyeztc/Build/Products/Debug/OVEREND.app
```

---

## 📝 測試後檢查清單

完成測試後，請確認：

- [ ] 所有測試案例都已執行
- [ ] Console 輸出已記錄
- [ ] 匯入的 Entry 資料正確
- [ ] PDF 附件能正常開啟
- [ ] 期刊資訊（journal, volume, issue, pages）正確顯示
- [ ] 更新 DOI_IMPLEMENTATION_STATUS.md

---

## ⏭️ 下一步計畫

完成測試後：

1. **如果測試成功：**
   - 標記功能為「已完成」
   - 考慮是否需要 UI 改進（顯示期刊資訊）
   - 準備用戶文檔

2. **如果發現問題：**
   - 記錄錯誤日誌
   - 分析失敗原因
   - 修復並重新測試

3. **未來改進方向：**
   - Entry 資料模型擴展（新增期刊欄位）
   - UI 顯示期刊完整資訊
   - 批量 DOI 查詢功能

---

**祝測試順利！** 🎉
