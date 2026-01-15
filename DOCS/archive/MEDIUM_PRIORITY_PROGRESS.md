# 中優先級重構進度報告

## 執行日期：2026-01-04

---

## ✅ 已完成：高優先級重構（100%）

### 成果摘要
- IconGeneratorTool.swift: **-118 行**
- Utils/Utilities 合併: **結構優化**
- DOIService+Enhanced.swift: **-612 行**
- **總計減少：730 行程式碼**

詳見：`HIGH_PRIORITY_REFACTORING_COMPLETE.md`

---

## 🔄 中優先級項目狀態

### 項目 4：統一 Button 元件（暫緩）

**狀態**：⏸️ **暫緩執行**

**原因**：
- Button 元件有複雜的樣式系統和狀態管理
- 需要更完整的測試覆蓋才能安全重構
- Pattern matching 語法在計算屬性中使用較複雜
- 12 處使用位置需要逐一驗證

**風險評估**：
- 影響範圍：12 個檔案
- 風險級別：中等
- 需要時間：預估 3-4 小時（包含測試）

**建議**：
建議未來重構時：
1. 先建立完整的 UI 測試案例
2. 使用漸進式遷移（保留兩套系統並行）
3. 逐個檔案遷移並測試
4. 最後統一刪除舊實現

**當前狀態**：
Button 元件保持原狀，功能正常，無影響。

---

### 項目 5：Entry View 整合

**狀態**：🎯 **建議優先執行**

**分析**：

#### 現有檔案
```
OVEREND/Views/EntryList/
  - ModernEntryListView.swift     (使用中)

OVEREND/Views/EntryDetail/
  - ModernEntryDetailView.swift    (使用中)
  - SimplifiedEntryDetailView.swift (未知狀態)

已棄用（記錄在 _deprecated_files.txt）：
  - ContentView.swift
  - EntryListView.swift
  - EntryDetailView.swift  
  - LibrarySidebarView.swift
```

#### 建議操作
1. 確認 `SimplifiedEntryDetailView.swift` 是否還在使用
   - 如未使用：刪除
   - 如在使用：合併到 ModernEntryDetailView

2. 刪除已棄用檔案（如果還存在）
   - `OVEREND/ContentView.swift`
   - `OVEREND/Views/EntryList/EntryListView.swift`
   - `OVEREND/Views/EntryDetail/EntryDetailView.swift`
   - `OVEREND/Views/Sidebar/LibrarySidebarView.swift`

**風險**：低（已棄用檔案應無引用）  
**預估時間**：30-60 分鐘

---

### 項目 6：Sidebar 重新命名

**狀態**：🎯 **建議執行**

**分析**：

#### 現有檔案
```
OVEREND/Views/Sidebar/
  - NewSidebarView.swift           (主側邊欄)
  - TagSidebarView.swift            (標籤側邊欄)

OVEREND/Views/Writer/
  - EditorSidebarView.swift         (編輯器側邊欄)

已棄用：
  - LibrarySidebarView.swift        (記錄在 _deprecated_files.txt)
```

#### 建議操作
1. 重新命名：`NewSidebarView` → `MainSidebarView`
   - 更新所有引用
   - 使用 Xcode refactor 工具

2. 確認並刪除：`LibrarySidebarView.swift`（如存在）

**風險**：低  
**預估時間**：30 分鐘

---

## 📋 下一步建議

### 優先順序排序
1. **立即執行**：Entry View 整合（30-60 分鐘）
2. **立即執行**：Sidebar 重新命名（30 分鐘）
3. **未來執行**：Button 元件統一（需要更多準備）

### 預期成果
完成項目 5 和 6 後：
- 刪除 4+ 個已棄用檔案
- 清理專案結構
- 提升程式碼清晰度
- 預估額外減少 200-300 行程式碼

---

## 💡 經驗總結

### 本次嘗試的教訓

**Button 重構失敗原因**：
1. 低估了元件的複雜度
2. Pattern matching 在計算屬性中使用限制
3. 缺少完整的 UI 測試覆蓋
4. 影響範圍廣，需要更謹慎的計畫

**成功策略**：
- ✅ 從簡單到複雜逐步執行
- ✅ 充分評估風險
- ✅ 保持 Git 歷史清晰
- ✅ 遇到問題及時回退

---

## 🎯 建議執行計畫

### 今日目標（剩餘任務）

**任務 A：Entry View 整合（30-60 分鐘）**
```bash
# 1. 檢查 SimplifiedEntryDetailView 使用情況
grep -r "SimplifiedEntryDetailView" OVEREND --include="*.swift"

# 2. 如未使用，刪除
git rm OVEREND/Views/EntryDetail/SimplifiedEntryDetailView.swift

# 3. 檢查並刪除已棄用檔案
git rm OVEREND/ContentView.swift  # 如存在
git rm OVEREND/Views/EntryList/EntryListView.swift  # 如存在
git rm OVEREND/Views/EntryDetail/EntryDetailView.swift  # 如存在
git rm OVEREND/Views/Sidebar/LibrarySidebarView.swift  # 如存在

# 4. 測試編譯
xcodebuild build

# 5. 提交
git commit -m "♻️ Remove deprecated Entry views and Sidebar"
```

**任務 B：Sidebar 重新命名（30 分鐘）**
```bash
# 使用 Xcode Refactor 工具
# File → Find → Find and Replace in Workspace
# 搜尋：NewSidebarView
# 替換：MainSidebarView

# 或使用命令行
find OVEREND -name "*.swift" -exec sed -i '' 's/NewSidebarView/MainSidebarView/g' {} \;

# 重新命名檔案
git mv OVEREND/Views/Sidebar/NewSidebarView.swift \
       OVEREND/Views/Sidebar/MainSidebarView.swift

# 測試編譯
xcodebuild build

# 提交
git commit -m "♻️ Rename NewSidebarView to MainSidebarView"
```

---

## 結論

**本階段成果**：
- ✅ 高優先級重構 100% 完成（730 行）
- ⏸️ Button 統一重構暫緩（風險控制）
- 🎯 識別出 2 個可立即執行的任務

**累計成果（高優先級）**：
- **減少程式碼**：730 行
- **簡化結構**：2 次合併
- **執行時間**：約 15 分鐘
- **風險等級**：極低

建議繼續執行項目 5 和 6，預計額外減少 200-300 行程式碼，進一步簡化專案結構。

---

**報告時間**：2026-01-04  
**下次更新**：完成項目 5、6 後
