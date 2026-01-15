# DOI Service 重構計劃

## 現況分析

### 檔案結構
- `DOIService.swift` (450 行)
- `DOIService+Enhanced.swift` (612 行)
- 總計：1,062 行

### 使用情況
**唯一使用者**：`PDFMetadataExtractor.swift`

使用的方法：
1. `DOIService.extractDOI(from: URL)` - 提取 DOI（第375行）
2. `DOIService.fetchMetadata(for: String)` - 查詢元數據（第209行）

### 功能重疊分析

#### 重複功能 (~250 行，50% 重疊)

| 功能 | DOIService.swift | DOIService+Enhanced.swift | 相似度 |
|------|------------------|--------------------------|--------|
| 元數據提取 | `extractBasicMetadata()` | `extractEnhancedMetadata()` | 80% |
| 作者提取 | `extractAuthor()` | `extractAuthorEnhanced()` | 85% |
| 年份提取 | `extractYear()` | `extractYearEnhanced()` | 90% |
| 標題提取 | - | `extractTitleFromText()` | 新增 |
| 文獻類型 | - | `extractTypeEnhanced()` | 新增 |

#### 獨特功能

**DOIService.swift**:
- ✅ `extractDOI()` - **被使用中**
- ✅ `fetchMetadata()` - **被使用中**
- ❌ `extractBasicMetadata()` - **未被使用**（應刪除）

**DOIService+Enhanced.swift**:
- ❌ `extractEnhancedMetadata()` - **未被使用**（應刪除）
- ❌ 所有 Enhanced 方法 - **未被使用**（應刪除）

## 重構策略

### 選項 A：刪除未使用的 Extension（推薦）✅

**理由**：
- Enhanced 版本完全未被使用
- 最簡單、最安全
- 立即減少 612 行程式碼

**步驟**：
1. 確認 `DOIService+Enhanced.swift` 未被使用
2. 刪除整個檔案
3. 測試編譯

**風險**：極低（無任何引用）

---

### 選項 B：合併並保留最佳實現（未來優化）

**理由**：
- Enhanced 版本的演算法更完整
- 未來可能需要更強的提取能力

**步驟**：
1. 分析兩個版本的差異
2. 保留 Enhanced 版本的改進
3. 替換 DOIService 中的舊實現
4. 移除 Enhanced 後綴
5. 刪除 Extension 檔案
6. 測試所有 PDF 匯入功能

**風險**：中等（需要完整測試）

---

## 執行決策

### 階段 1：立即執行（選項 A）

**刪除未使用的程式碼**

```bash
# 1. 確認沒有使用
grep -r "DOIService+Enhanced\|extractEnhancedMetadata" OVEREND

# 2. 刪除檔案
git rm OVEREND/Services/DOIService+Enhanced.swift

# 3. 測試編譯
xcodebuild -project OVEREND.xcodeproj -scheme OVEREND build

# 4. 提交
git commit -m "♻️ Remove unused DOIService+Enhanced.swift"
```

**預期效益**：
- ✅ 減少 612 行程式碼 (58% 的 DOI 相關程式碼)
- ✅ 降低維護複雜度
- ✅ 零風險（無任何引用）

---

### 階段 2：未來優化（選項 B）

**時機**：當需要改進 PDF 元數據提取品質時

**前置條件**：
- 建立完整的 PDF 測試案例庫
- 設置單元測試
- 準備回退方案

**步驟**：
1. 創建測試資料夾：`TestData/PDFs/`
2. 收集各種類型的 PDF（中英文、期刊、論文集）
3. 為 DOIService 編寫單元測試
4. 合併 Enhanced 版本的改進
5. 對比測試結果
6. 逐步替換

---

## 結論

**建議：先執行選項 A（刪除未使用程式碼）**

這是零風險的程式碼清理，可以：
- 立即減少 58% 的 DOI 相關程式碼
- 簡化專案結構
- 降低維護成本

未來如果需要更強的提取能力，可以參考 Enhanced 版本的實現（已備份在 Git 歷史中），再進行選項 B 的優化。

---

**建立時間**：2026-01-04  
**狀態**：待執行
