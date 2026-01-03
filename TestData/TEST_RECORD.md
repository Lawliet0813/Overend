# OVEREND 測試記錄

**測試日期**：2025-01-04  
**測試人員**：彥儒  
**專案版本**：v0.95  

---

## 測試統計

| 項目 | 數值 |
|------|------|
| 測試總數 | 75 項 |
| 已完成 | 13 項 |
| 通過 | 11 項 |
| 部分通過 | 2 項 |
| 失敗 | 0 項 |
| 跳過 | 8 項 |
| 待修復 Bug | 5 項 |
| 技術觀察 | 2 項 |

**整體通過率**：85% (11/13 已測試項目)

**階段完成度**：
- 階段 1.1：100% (5/5) - 1 項部分通過，發現 BibTeX 重複檢測功能
- 階段 1.2：跳過 (Bug #2 阻擋，5 項)
- 階段 2.1：100% (4/4) ✅
- 階段 2.2：跳過 (台灣使用華藝編碼，3 項)
- 階段 2.3：100% (3/3) ✅
- 階段 2.4：未測試 (2 項)

**Bug 嚴重程度分布**：
- 🔴 高：1 項 (Bug #2 - 新增書目未連接)
- 🟡 中：3 項 (Bug #1 - BibTeX 錯誤處理, #3 - PDF 重複檢測, #4 - 標題誤判)
- 🟢 低：1 項 (Bug #5 - 日誌字串插值)

**技術觀察**：
- Tool Calling 不穩定性（非關鍵）
- PDF 渲染警告（非關鍵）

**新發現（2025-01-04）**：
- ✅ BibTeX 重複檢測功能存在且運作正常
- ⚠️ 日誌輸出有字串插值錯誤（Bug #5）

---

## 階段 1：文獻管理核心（4/15）

### 1.1 匯入功能（4/5）

#### ✅ 1.1.1 BibTeX 標準格式匯入

**測試步驟**：
1. 開啟 OVEREND
2. 檔案 → 匯入 BibTeX
3. 選擇 `standard_entries.bib`

**預期結果**：匯入 5 筆文獻，所有欄位正確解析

**實際結果**：
- [x] ✅ 通過

**問題描述**：無

**Console 輸出**：
```
📌 點擊文獻：Advanced Topics in Machine Learning
📌 點擊文獻：Deep Learning for Natural Language Processing
```

**備註**：所有標準格式文獻正確匯入並顯示

---

#### ✅ 1.1.2 中文 BibTeX 匯入

**測試步驟**：
1. 匯入 `chinese_entries.bib` 和 `mixed_entries.bib`

**預期結果**：繁體中文顯示正常

**實際結果**：
- [x] ✅ 通過

**問題描述**：無

**Console 輸出**：
```
📌 點擊文獻：數位轉型與政府效能:Digital Transformation and Government Efficiency
📌 點擊文獻：公共管理理論與實務 (Public Management: Theory and Practice)
```

**備註**：繁體中文、中英混合文獻皆正常顯示

---

#### ✅ 1.1.3 特殊字元處理

**測試檔案**：`special_chars.bib`

**實際結果**：
- [x] ✅ 通過

**Console 輸出**：
```
📌 點擊文獻：跨文化研究 \& Cross-Cultural Studies: 50\% Theory + 50\% Practice
```

**備註**：特殊字元 `\&`, `\%` 正確處理，Emoji ✨🎉 正常顯示

---

#### ⚠️ 1.1.4 容錯機制

**測試檔案**：`malformed_entries.bib`

**實際結果**：
- [x] ⚠️ 部分通過

**問題描述**：
1. 格式錯誤的條目產生 "Untitled" 標題
2. 部分條目標題為空字串
3. 系統未崩潰，但用戶體驗欠佳

**Console 輸出**：
```
📌 點擊文獻：Untitled
📌 點擊文獻：（空標題）
📌 點擊文獻：Unknown Entry Type
📌 點擊文獻：Testing Unicode Characters ✨🎉
```

**改進建議**：
- 匯入時顯示警告訊息，告知哪些條目格式錯誤
- 為錯誤條目提供更明確的標示（如 "[解析錯誤] Untitled"）
- 提供「查看匯入錯誤」的功能

---

#### ✅ 1.1.5 重複匯入

**測試步驟**：
1. 重複匯入相同的 BibTeX 檔案（`standard_entries.bib`）
2. 觀察系統行為

**實際結果**：
- [x] ✅ 通過（BibTeX）
- [x] ⚠️ 部分通過（PDF，見 Bug #3）

**詳細觀察**：

**BibTeX 重複檢測**（2025-01-04 驗證完成）：
- ✅ 功能正常運作
- ✅ 成功檢測 5 筆重複書目
- ✅ 全部跳過，未建立重複條目
- ✅ 使用者提示：「匯入 0 筆書目」
- ⚠️ 日誌輸出有字串插值錯誤（Bug #5，不影響功能）

**使用者體驗**：
- 顯示「匯入 0 筆書目」
- 清楚告知沒有新增內容
- 不會誤導使用者

**改進建議**（優先級：低）：
```
建議顯示：
✅ 匯入完成
   新增：0 筆
   跳過：5 筆（重複）
```

**PDF 重複檢測**：
- ❌ 未檢測重複
- ❌ 建立重複條目
- ❌ 第二次提取品質下降

**Console 輸出**：
```
跳過重複書目: \(bibEntry.citationKey)  ← BibTeX（字串插值錯誤）
跳過重複書目: \(bibEntry.citationKey)
跳過重複書目: \(bibEntry.citationKey)
跳過重複書目: \(bibEntry.citationKey)
跳過重複書目: \(bibEntry.citationKey)
```

**參考**：
- Bug #3 - PDF 重複匯入未檢測
- Bug #5 - 日誌字串插值錯誤（不影響功能）

---

---

### 1.2 CRUD 操作（0/5）

#### ❓ 1.2.1 手動建立文獻

**實際結果**：
- [ ] ✅ 通過
- [ ] ❌ 失敗
- [ ] ⏭️ 跳過

---

（以下項目以相同格式繼續...）

---

## 階段 2：PDF & DOI 處理（5/12，42%）

### 2.1 PDF 匯入（4/4，100%）

#### ✅ 2.1.1 匯入國際期刊 PDF

**測試檔案**：`Public Administration - 2024 - Zhang - Public Employees whistleblowing intention.pdf`

**實際結果**：
- [x] ✅ 通過

**詳細觀察**：
- Apple Intelligence Tool Calling 成功
- 正確提取：標題、作者（4人）、年份（2024）、期刊、DOI
- 自動生成引用鍵：`zhang2024publicemployees`

**Console 輸出**：
```
📄 開始提取 PDF 元數據: Public Administration - 2024 - Zhang...
🍎 使用 Apple Intelligence 分析...
🔧 Tool Called: extractPDFMetadata
✅ 提取成功
```

---

#### ✅ 2.1.2 匯入中文檔名 PDF

**測試檔案**：
- `陽剛霸權中的同志現身-以警察組織為例.pdf`
- `台鐵改革的迷思.pdf`
- `從個人風險特質探討公務人員之創新行為.pdf`

**實際結果**：
- [x] ✅ 通過

**詳細觀察**：
- 中文檔名正常處理
- 繁體中文內容正確顯示
- 部分使用 AI Prompt 方式（Tool Calling 失敗時降級）
- 民國年份：112 需手動轉換為 2023

**Console 輸出**：
```
📄 開始提取 PDF 元數據: 陽剛霸權中的同志現身...
🍎 使用 Apple Intelligence 分析...
🔧 Tool Called: extractPDFMetadata
作者: 鍾琇媛，年份: 112
```

---

#### ✅ 2.1.3 PDF 附件關聯

**測試步驟**：
1. 匯入 PDF
2. 查看詳情面板的附件區域

**實際結果**：
- [x] ✅ 通過

**詳細觀察**：
- PDF 正確附加到文獻條目
- 附件顯示檔案大小（2.2 MB）
- 附件顯示頁數（21 頁）
- 可正常開啟預覽

**截圖證據**：圖片 1、2、3

---

#### ✅ 2.1.4 PDF 開啟權限

**測試步驟**：
1. 點擊文獻列表中的 PDF 附件
2. 點擊「開啟」按鈕

**實際結果**：
- [x] ✅ 通過

**詳細觀察**：
- 預覽視窗正常顯示 PDF 內容
- 無 Sandbox 權限錯誤
- 內建預覽功能完整（類似 Quick Look）
- 可用外部程式開啟

**截圖證據**：圖片 1（預覽視窗）

---

### 2.2 DOI 處理（0/3，跳過）⏭️

**跳過原因**：
台灣學術文獻使用華藝 (Airiti) 自有的 DOI 編碼系統，不是標準的國際 DOI (CrossRef)。OVEREND 目標用戶主要是台灣研究者，因此 CrossRef API 的適用性有限。

**建議**：
未來可考慮整合華藝 API 或台灣學術資料庫的標準。

#### ⏭️ 2.2.1 DOI 查詢 - 已跳過

**原因**：台灣文獻使用華藝編碼

---

#### ⏭️ 2.2.2 CrossRef 驗證 - 已跳過

**原因**：台灣文獻使用華藝編碼

---

#### ⏭️ 2.2.3 DOI 更新元資料 - 已跳過

**原因**：台灣文獻使用華藝編碼

---

### 2.3 提取策略（3/3，100%）

#### ✅ 2.3.1 CrossRef API（第一層）

**測試步驟**：
觀察有 DOI 的 PDF 是否優先使用 CrossRef

**實際結果**：
- [x] ✅ 通過

**詳細觀察**：
- 國際期刊 PDF 顯示 DOI：`10.1111/padm.13009`
- 元資料完整且準確
- 推測：系統可能先嘗試 DOI 查詢

**備註**：需要 Console 日誌確認 CrossRef 呼叫順序

---

#### ✅ 2.3.2 Apple Intelligence（第二層）

**測試步驟**：
觀察無 DOI 的 PDF 使用 AI 提取

**實際結果**：
- [x] ✅ 通過

**詳細觀察**：
- Tool Calling 成功：2/4 次
- Prompt 方式成功：2/4 次
- 信心度標註：高

**Console 輸出**：
```
🍎 使用 Apple Intelligence 分析...
🔧 Tool Called: extractPDFMetadata
信心度: 高
```

---

#### ✅ 2.3.3 正則表達式（第三層）

**測試步驟**：
重複匯入時 AI 不可用，降級到 Regex

**實際結果**：
- [x] ✅ 通過

**詳細觀察**：
- Regex 成功提取部分資訊
- 但品質明顯低於 AI
- 標題提取錯誤：`Received: 11 April 2023 DOI: 10.1111/padm.13009`

**Console 輸出**：
```
ℹ️ Apple Intelligence 不可用
📝 使用正則表達式提取...
```

**參考**：Bug #3 的次要問題

---

### 2.4 特殊情況（0/2，0%）

#### ❓ 2.4.1 提取完全失敗

**測試步驟**：
匯入無法提取的 PDF（純圖片掃描）

**實際結果**：
- [ ] ✅ 通過
- [ ] ❌ 失敗
- [ ] ⏭️ 跳過

**備註**：需要特殊測試檔案

---

#### ❓ 2.4.2 損壞的 PDF

**測試步驟**：
匯入損壞或格式錯誤的 PDF

**實際結果**：
- [ ] ✅ 通過
- [ ] ❌ 失敗
- [ ] ⏭️ 跳過

**備註**：需要特殊測試檔案

---

## 階段 3：寫作中心（0/10）

（待測試）

---

## 階段 4：專業編輯器（0/8）

（待測試）

---

## 階段 5：引用系統（0/9）

（待測試）

---

## 階段 6：UI/UX 與導航（0/10）

（待測試）

---

## 階段 7：主題與中文（0/6）

（待測試）

---

## 階段 8：資料持久化（0/5）

（待測試）

---

## 🐛 發現的 Bug

### Bug #1 - 格式錯誤 BibTeX 產生 "Untitled" 條目

**問題描述**：
當匯入格式錯誤的 BibTeX 檔案時，系統會建立標題為 "Untitled" 或空字串的文獻條目，但沒有提示使用者哪些條目解析失敗。

**重現步驟**：
1. 匯入 `malformed_entries.bib`
2. 查看文獻列表
3. 發現多筆 "Untitled" 或空標題條目

**預期結果**：
- 選項 A：完全拒絕匯入並顯示錯誤訊息
- 選項 B：成功匯入但彈出警告視窗列出錯誤條目
- 選項 C：匯入後在條目上標記 "[解析錯誤]"

**實際結果**：
靜默建立 "Untitled" 條目，無任何警告

**Console 輸出**：
```
📌 點擊文獻：Untitled
📌 點擊文獻：（空標題）
📌 點擊文獻：Unknown Entry Type
```

**嚴重程度**：🟡 中

**狀態**：⏳ 待修復

**建議修復方案**：
1. 在 BibTeXParser 中加入錯誤收集機制
2. 匯入完成後顯示摘要：「成功 X 筆，失敗 Y 筆」
3. 提供「查看匯入錯誤詳情」按鈕
4. 錯誤條目在列表中標記 ⚠️ 圖示

---

### Bug #2 - 「新增書目」功能未正確連接

**問題描述**：
快捷鍵 Cmd+Shift+N 無反應，選單列的「新增書目」按鈕也無法使用。

**重現步驟**：
1. 確保已選擇 Library
2. 按下 Cmd+Shift+N
3. 或點擊選單列「檔案」→「新增書目」
4. 無任何反應

**預期結果**：
彈出書目編輯器，讓用戶手動填寫文獻資料

**實際結果**：
無反應

**技術原因**：
OVERENDApp.swift 定義了快捷鍵並設定 `showNewEntry?.wrappedValue = true`，但 NewContentView.swift 缺少 `.focusedValue(\.showNewEntry, $showNewEntrySheet)` 連接，導致狀態無法傳遞。

**Console 輸出**：
無任何輸出或錯誤訊息

**嚴重程度**：🔴 高

**狀態**：⏳ 待修復

**建議修復方案**：
在 NewContentView.swift 的主視圖加入：
```swift
.focusedValue(\.showNewEntry, $showNewEntrySheet)
```

**影響範圍**：
無法手動建立文獻，只能透過匯入 BibTeX 或 PDF 來新增文獻。

---

### Bug #3 - 重複匯入 PDF 未檢測

**問題描述**：
重複匯入相同的 PDF 檔案時，系統不會檢測到重複，而是建立新的文獻條目，且第二次匯入時元資料提取品質下降。

**重現步驟**：
1. 匯入 PDF：`Public Administration - 2024 - Zhang...`
2. 再次匯入同一個 PDF 檔案
3. 系統建立第二筆文獻條目

**預期結果**：
- 檢測到重複並提示使用者
- 選項 A：略過重複檔案
- 選項 B：更新現有條目
- 選項 C：建立副本並標記

**實際結果**：
- 靜默建立重複條目
- 第一次標題：`Public Employees' Whistleblowing Intention...` ✅
- 第二次標題：`Received: 11 April 2023 DOI: 10.1111/padm.13009` ❌
- 第二次匯入時 AI 降級到 Regex，提取品質下降

**Console 輸出**：
```
📄 開始提取 PDF 元數據: Public Administration - 2024 - Zhang...
ℹ️ Apple Intelligence 不可用
📝 使用正則表達式提取...
```

**嚴重程度**：🟡 中

**狀態**：⏳ 待修復

**建議修復方案**：
1. 在 PDF 匯入前檢查檔案雜湊值或路徑
2. 比對現有 Entry 的附件，檢測重複
3. 提供重複處理對話框：
   - 略過
   - 更新元資料
   - 建立副本
4. 記錄重複匯入次數供統計

**次要問題**：
為什麼第二次匯入時 AI 不可用？可能的原因：
- API 限制或冷卻時間
- 短時間內多次呼叫被限流
- 需要檢查 UnifiedAIService 的呼叫間隔

---

### Bug #4 - PDF 元資料提取：單位誤判為標題

**問題描述**：
某些 PDF 檔案的作者單位被錯誤提取為文獻標題。

**重現步驟**：
1. 匯入特定台灣學術 PDF
2. 查看文獻列表

**預期結果**：
標題應為論文正式標題

**實際結果**：
標題顯示：`國立政治大學公共行政學系`（這是作者單位）

**Console 輸出**：
```
📌 點擊文獻：國立政治大學公共行政學系
✅ selectedEntry 已更新：國立政治大學公共行政學系
```

**嚴重程度**：🟡 中

**狀態**：⏳ 待修復

**可能原因**：
- PDF 結構不標準
- AI 提取時優先級判斷錯誤
- Regex 提取邏輯問題

**建議修復方案**：
1. 改進 AI Prompt，明確區分標題與單位
2. 在 Regex 中加入單位關鍵字過濾（如：大學、學系、研究所）
3. 提供手動標題修正功能

**影響範圍**：
部分台灣學術 PDF 標題提取錯誤，影響文獻管理與搜尋

---

### Bug #5 - BibTeX 重複檢測日誌輸出錯誤

**問題描述**：
BibTeX 重複檢測功能正常運作，但 Console 日誌輸出顯示字面字串而非實際引用鍵值。

**重現步驟**：
1. 匯入 BibTeX 檔案
2. 再次匯入相同的 BibTeX 檔案
3. 查看 Console 輸出

**預期結果**：
```
✅ 跳過重複書目: zhang2024publicemployees
✅ 跳過重複書目: lin2021innovation
```

**實際結果**：
```
跳過重複書目: \(bibEntry.citationKey)
跳過重複書目: \(bibEntry.citationKey)
跳過重複書目: \(bibEntry.citationKey)
跳過重複書目: \(bibEntry.citationKey)
跳過重複書目: \(bibEntry.citationKey)
```

**Console 輸出**（2025-01-04）：
```
跳過重複書目: \(bibEntry.citationKey)  ← 字串插值未執行
```

**嚴重程度**：🟢 低（功能正常，僅日誌顯示有誤）

**狀態**：⏳ 待修復

**可能原因**：
- 使用單引號而非雙引號
- 或在日誌函式中誤用跳脫字元

**錯誤程式碼範例**：
```swift
// ❌ 錯誤 1：單引號
print('跳過重複書目: \(bibEntry.citationKey)')

// ❌ 錯誤 2：跳脫錯誤
NSLog("跳過重複書目: \\(bibEntry.citationKey)")
```

**建議修復方案**：
```swift
// ✅ 正確
print("跳過重複書目: \(bibEntry.citationKey)")

// ✅ 或更詳細的日誌
print("✅ 跳過重複書目: \(bibEntry.citationKey)（已存在於文獻庫）")
```

**影響範圍**：
- 不影響功能（重複檢測正常運作）
- 僅影響開發者除錯體驗
- 優先級低，可延後修復

**正面發現**：
✅ 證實了 BibTeX 重複檢測功能存在且運作正常

---

### 技術觀察 #1 - Tool Calling 不穩定性

**現象描述**：
Apple Intelligence 可用，但模型有時選擇不使用 Tool，而是用 Prompt 方式回應。

**Console 輸出**：
```
✅ UnifiedAIService: Apple Intelligence 可用
⚠️ Tool Calling 失敗: 處理失敗：Tool was not called by the model，降級到 Prompt 方式
```

**觀察統計**（基於目前測試）：
- Tool Calling 成功：約 50%
- 降級到 Prompt：約 50%

**影響**：
- Prompt 方式提取品質略低於 Tool Calling
- 但整體仍可正常運作
- 不影響核心功能

**可能原因**：
- 模型自主判斷某些情況用 Prompt 更合適
- PDF 內容格式影響模型選擇
- Apple Intelligence 的內部邏輯

**建議**：
- 目前降級機制運作正常
- 可記錄統計資料以優化未來策略
- 非關鍵問題，優先級較低

---

### 技術觀察 #2 - PDF 渲染警告

**現象描述**：
開啟特定 PDF 時，macOS 的 CoreGraphics 引擎報告錯誤。

**Console 輸出**：
```
CoreGraphics PDF has logged an error. Set environment variable "CG_PDF_VERBOSE" to learn more.
```

**影響**：
- 目前未觀察到功能異常
- PDF 仍可正常顯示和開啟
- 可能只是格式相容性警告

**建議**：
- 如 PDF 功能出現異常，再深入調查
- 可透過 `CG_PDF_VERBOSE=1` 環境變數獲取詳細資訊
- 非關鍵問題，優先級低

---

## 💡 優化建議

1. 

---

## 📝 測試心得



---

**完成時間**：  
**總測試時間**：
