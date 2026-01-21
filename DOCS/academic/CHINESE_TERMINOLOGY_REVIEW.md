# OVEREND 繁體中文術語全面檢查報告

> 執行日期：2025-12-28  
> 目標：確保 OVEREND 完全符合台灣學術圈用語習慣

---

## 📊 術語使用統計

### 🔴 需要修改的術語

| 目前用語 | 出現次數 | 建議改為 | 優先級 | 理由 |
|---------|---------|---------|--------|------|
| **條目** | ~30 次 | **書目** | 🔴 高 | 台灣學術圈標準用語 |
| **組群** | ~10 次 | **資料夾** | 🔴 高 | 更直觀易懂 |

### ✅ 正確的術語（保持不變）

| 用語 | 出現次數 | 說明 |
|------|---------|------|
| **文獻庫** | ~22 次 | ✅ 正確 |
| **附件** | ~10 次 | ✅ 正確 |
| **匯入** | ~32 次 | ✅ 正確 |
| **匯出** | ~8 次 | ✅ 正確 |
| **引用** | ~7 次 | ✅ 正確 |
| **論文** | ~5 次 | ✅ 正確 |

## 🎯 具體修改清單

### 優先級 1：UI 顯示文字（用戶可見）

#### 「條目」→「書目」修改清單：

**OVERENDApp.swift:**
- Line 88: "新增文獻" → "新增書目"

**ContentView.swift:**
- Line 73, 82: "未選擇文獻" → "未選擇書目"
- Line 75, 84: "從列表中選擇一篇文獻查看詳情" → "從列表中選擇一筆書目查看詳情"
- Line 147: "成功匯入 X 筆文獻" → "成功匯入 X 筆書目"

**Views/EntryList/EntryListView.swift:**
- Line 30: "搜尋文獻" → "搜尋書目"

**Views/Editor/EntryEditorView.swift:**
- Line 119: "新建文獻" → "新建書目"

#### 「組群」→「資料夾」修改清單：

**Models/Group.swift:**
- 檔案註解更新

---

## ✅ 執行計畫

**我現在將開始執行以下修改：**

1. ✅ 修改所有 UI 顯示的「條目」→「書目」
2. ✅ 修改所有 UI 顯示的「組群」→「資料夾」  
3. ✅ 統一量詞使用
4. ✅ 測試編譯

**預估時間：30 分鐘**

## ✅ 補充修改：Citation Key → 引用鍵

### 修改檔案：

| 檔案 | 位置 | 修改內容 |
|------|------|---------|
| **Views/Editor/EntryEditorView.swift** | Line 60 | `TextField("Citation Key")` → `TextField("引用鍵 (如：chen2023)")` |
| **Views/EntryDetail/EntryDetailView.swift** | Line 45 | `DetailRow(label: "Citation Key")` → `DetailRow(label: "引用鍵")` |
| **Views/EntryList/EntryListView.swift** | Line 326 | 註解 `// Citation Key 與類型` → `// 引用鍵與類型` |
| **Views/EntryList/EntryListView.swift** | Line 250 | 註解 `// 生成 citation key` → `// 生成引用鍵` |
| **Services/BibTeXGenerator.swift** | Line 145 | 註解 `// MARK: - 擴展：Citation Key 生成` → `// MARK: - 擴展：引用鍵生成` |
| **Services/BibTeXGenerator.swift** | Line 147-152 | 文檔註解全部改為「引用鍵」 |
| **Services/BibTeXGenerator.swift** | Line 179-184 | 文檔註解全部改為「引用鍵」 |
| **Services/BibTeXParser.swift** | Line 56 | 註解 `// 提取 Citation Key` → `// 提取引用鍵` |

### 術語說明

**Citation Key = 引用鍵**

**為什麼用「引用鍵」？**
1. ✅ 符合台灣學術圈用語習慣
2. ✅ 清楚表達功能（用於引用的鍵值）
3. ✅ 與「引用格式」「引用文獻」等用語一致
4. ✅ 比「索引鍵」更貼近學術情境

**範例：**
- `chen2023` - 引用鍵
- `smith2024machine` - 引用鍵  
- `wang2022railway` - 引用鍵

---

**編譯狀態：** ✅ BUILD SUCCEEDED  
**修改時間：** 2025-12-28 03:47
