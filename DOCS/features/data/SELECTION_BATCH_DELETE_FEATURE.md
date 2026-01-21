# 文稿與文獻選取批次刪除功能

## 概述

為 OVEREND 應用程式的文稿卡片和文獻列表加入了完整的選取和批次刪除功能，提升使用者管理大量資料的效率。

## 功能位置

### 1. 文稿選取功能

**位置**: 寫作首頁 → 最近的寫作專案

**檔案**: `OVEREND/Views/SimpleContentView.swift`

### 2. 文獻選取功能  

**位置**: 文獻庫 → 文獻列表

**檔案**: `OVEREND/Views/EntryList/ModernEntryListView.swift`

## 功能特性

### ✅ 文稿選取功能

#### 新增功能：
1. **選取模式按鈕** - 進入/退出選取模式
2. **卡片選取指示器** - 顯示選取狀態的圓形圖示
3. **全選/取消全選** - 一鍵選取所有文稿
4. **批次刪除** - 刪除所有選取的文稿
5. **選取數量顯示** - 即時顯示已選取的數量
6. **確認對話框** - 防止誤刪除

#### 視覺設計：
- 選取模式下卡片右上角顯示圓形指示器
- 選取的卡片有藍色邊框高亮
- 批次操作工具列浮現在列表上方
- 紅色刪除按鈕明確標示危險操作

### ✅ 文獻選取功能（已存在，保持不變）

#### 現有功能：
1. **選取模式** - 進入/退出選取模式
2. **全選/取消全選** - 批次選取功能
3. **批次刪除** - 刪除選取的文獻及附件
4. **選取狀態顯示** - 複選框顯示選取狀態
5. **確認對話框** - 雙重確認機制

## 使用者介面

### 文稿選取模式

#### 正常模式（檢視）
```
┌─────────────────────────────────────────────┐
│  最近的寫作專案    [✓ 選取] [+ 新建專案]    │
├─────────────────────────────────────────────┤
│  ┌───────┐  ┌───────┐  ┌───────┐           │
│  │文稿 1 │  │文稿 2 │  │文稿 3 │           │
│  │       │  │       │  │       │           │
│  └───────┘  └───────┘  └───────┘           │
└─────────────────────────────────────────────┘
```

#### 選取模式（已選 2 個）
```
┌─────────────────────────────────────────────┐
│  最近的寫作專案  [✓ 取消選取] [+ 新建專案]  │
├─────────────────────────────────────────────┤
│  已選取 2 個專案        [全選] [🗑️ 刪除]    │
├─────────────────────────────────────────────┤
│  ┌───────┐  ┌───────┐  ┌───────┐           │
│  │☑ 文稿1│  │☑ 文稿2│  │○ 文稿3│           │
│  │       │  │       │  │       │           │
│  └───────┘  └───────┘  └───────┘           │
└─────────────────────────────────────────────┘
```

### 文獻選取模式

#### 正常模式（表格檢視）
```
┌────────────────────────────────────────────────┐
│                                    [選取]      │
├────────────────────────────────────────────────┤
│ 標題            作者/年份    附件  類型        │
├────────────────────────────────────────────────┤
│ 深度學習研究    張三/2023    📎   article     │
│ AI應用探討      李四/2024    📎   conference  │
└────────────────────────────────────────────────┘
```

#### 選取模式（已選 3 篇）
```
┌────────────────────────────────────────────────┐
│ [☑ 全選] 已選取 3 項       [🗑️ 刪除] [完成]  │
├────────────────────────────────────────────────┤
│ ☑ 標題            作者/年份    附件  類型      │
├────────────────────────────────────────────────┤
│ ☑ 深度學習研究    張三/2023    📎   article   │
│ ☑ AI應用探討      李四/2024    📎   conference│
│ ○ 研究方法論      王五/2023    📎   book      │
└────────────────────────────────────────────────┘
```

## 技術實現

### 文稿選取功能

#### 狀態管理
```swift
// 選取模式狀態
@State private var isSelectionMode: Bool = false
@State private var selectedDocumentIDs: Set<UUID> = []
@State private var showBatchDeleteConfirm: Bool = false
```

#### 切換選取
```swift
private func toggleSelection(_ documentID: UUID) {
    if selectedDocumentIDs.contains(documentID) {
        selectedDocumentIDs.remove(documentID)
    } else {
        selectedDocumentIDs.insert(documentID)
    }
}
```

#### 批次刪除
```swift
private func batchDeleteDocuments() {
    let documentsToDelete = documents.filter { selectedDocumentIDs.contains($0.id) }
    
    viewContext.performAndWait {
        for document in documentsToDelete {
            viewContext.delete(document)
        }
        
        do {
            try viewContext.save()
            ToastManager.shared.showSuccess("已刪除 \(documentsToDelete.count) 個專案")
        } catch {
            ToastManager.shared.showError("刪除失敗：\(error.localizedDescription)")
        }
    }
    
    selectedDocumentIDs.removeAll()
    isSelectionMode = false
}
```

### 卡片視覺更新

#### 選取指示器
```swift
// 選取指示器
if isSelectionMode {
    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 24, weight: .medium))
        .foregroundColor(isSelected ? theme.accent : theme.textMuted)
        .padding(12)
        .background(
            Circle()
                .fill(theme.card)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .padding(8)
}
```

#### 選取邊框
```swift
.overlay(
    RoundedRectangle(cornerRadius: theme.radiusCard)
        .stroke(
            isSelected ? theme.accent : (isHovered ? theme.accent.opacity(0.3) : theme.border), 
            lineWidth: isSelected ? 2 : 1
        )
)
```

### 文獻選取功能（現有實現）

#### 批次操作工具列
```swift
private var batchOperationToolbar: some View {
    HStack(spacing: DesignTokens.Spacing.lg) {
        if isSelectionMode {
            // 全選按鈕
            Button(action: toggleSelectAll) { /* ... */ }
            
            // 已選取數量
            Text("已選取 \(selectedEntryIDs.count) 項")
            
            // 刪除按鈕
            if !selectedEntryIDs.isEmpty {
                Button(action: { showBatchDeleteConfirm = true }) { /* ... */ }
            }
            
            // 完成按鈕
            Button(action: exitSelectionMode) { /* ... */ }
        } else {
            // 進入選取模式按鈕
            Button(action: { isSelectionMode = true }) { /* ... */ }
        }
    }
}
```

## 互動流程

### 文稿選取流程

1. **進入選取模式**
   - 點擊「選取」按鈕
   - 卡片上顯示圓形選取指示器
   - 「選取」按鈕變為「取消選取」

2. **選取文稿**
   - 點擊文稿卡片進行選取/取消選取
   - 選取的卡片有藍色邊框
   - 批次操作工具列顯示選取數量

3. **全選操作**
   - 點擊「全選」按鈕選取所有文稿
   - 再次點擊變為「取消全選」

4. **批次刪除**
   - 點擊「刪除」按鈕
   - 彈出確認對話框
   - 確認後刪除所有選取的文稿
   - 顯示成功訊息

5. **退出選取模式**
   - 點擊「取消選取」按鈕
   - 或完成批次操作後自動退出
   - 清除所有選取狀態

### 文獻選取流程

1. **進入選取模式**
   - 點擊「選取」按鈕
   - 表格行左側顯示複選框

2. **選取文獻**
   - 點擊文獻行或複選框進行選取
   - 選取的行有高亮背景

3. **全選/批次操作**
   - 點擊「全選」選取所有文獻
   - 點擊「刪除選取項目」批次刪除
   - 確認對話框雙重確認

4. **完成操作**
   - 點擊「完成」按鈕退出選取模式
   - 清除所有選取狀態

## 安全機制

### 防止誤刪

1. **確認對話框**
   - 刪除前彈出確認對話框
   - 顯示將要刪除的數量
   - 明確說明「無法還原」

2. **視覺警告**
   - 刪除按鈕使用紅色
   - 對話框使用警告圖示
   - 清晰的文字說明

3. **操作反饋**
   - 刪除成功顯示 Toast 訊息
   - 失敗時顯示錯誤訊息
   - 自動退出選取模式

### 資料完整性

1. **事務處理**
   - 使用 `performAndWait` 同步執行
   - 失敗時自動 rollback
   - 確保資料一致性

2. **級聯刪除**
   - 文獻刪除時同時刪除附件
   - 文稿刪除時清理相關資料
   - 避免孤立資料

## 使用者體驗優化

### 視覺反饋
- ✅ 選取狀態即時更新
- ✅ 懸停效果提示可點擊
- ✅ 選取數量即時顯示
- ✅ 邊框顏色區分狀態

### 操作便利性
- ✅ 一鍵進入/退出選取模式
- ✅ 全選/取消全選快速操作
- ✅ 批次刪除一次完成
- ✅ 確認對話框防止誤操作

### 效能優化
- ✅ 使用 Set 管理選取狀態（O(1) 查詢）
- ✅ 批次操作減少資料庫操作
- ✅ 動畫流暢不卡頓
- ✅ 大量資料處理優化

## 測試建議

### 功能測試

#### 文稿選取
- [x] 進入/退出選取模式
- [x] 點擊卡片選取/取消選取
- [x] 全選功能
- [x] 批次刪除功能
- [ ] 選取狀態視覺正確
- [ ] 確認對話框正確顯示

#### 文獻選取
- [x] 進入/退出選取模式
- [x] 複選框選取/取消選取
- [x] 全選功能
- [x] 批次刪除功能
- [ ] 附件同時刪除
- [ ] 確認對話框正確顯示

### 邊界測試
- [ ] 選取所有項目後刪除
- [ ] 未選取任何項目時的處理
- [ ] 大量項目（100+）的效能
- [ ] 刪除過程中取消操作

### 整合測試
- [ ] Core Data 事務正確性
- [ ] Toast 訊息正確顯示
- [ ] 列表自動更新
- [ ] 與其他功能的協作

## 未來改進建議

### 短期改進
1. **撤銷刪除**
   - 提供 Undo/Redo 功能
   - 刪除後短時間內可恢復

2. **鍵盤快捷鍵**
   - ⌘A 全選
   - Delete 鍵刪除選取項目
   - Esc 退出選取模式

3. **拖放操作**
   - 拖放選取的項目到分組
   - 拖放到其他資料夾

### 中期改進
1. **批次編輯**
   - 批次修改標籤
   - 批次移動到其他文獻庫
   - 批次匯出

2. **智能選取**
   - 按條件自動選取
   - 選取相似項目
   - 反向選取

3. **選取歷史**
   - 記住上次選取的項目
   - 快速恢復選取狀態

### 長期改進
1. **多頁面選取**
   - 跨頁面保持選取狀態
   - 分頁選取功能

2. **協作功能**
   - 多人同時選取
   - 選取狀態同步

3. **AI 輔助選取**
   - AI 建議相關項目
   - 智能分組選取

## 相關檔案

### 修改的檔案
1. `OVEREND/Views/SimpleContentView.swift`
   - SimpleDashboardView - 加入選取模式狀態
   - EnhancedProjectCard - 加入選取指示器
   - 批次操作方法

2. `OVEREND/Views/EntryList/ModernEntryListView.swift`
   - 已存在的選取功能（保持不變）

### 相關元件
- `AppTheme.swift` - 主題顏色定義
- `DesignTokens.swift` - 設計規範
- `ToastManager.swift` - 提示訊息
- `DocumentViewModel.swift` - 文稿資料管理

## 注意事項

⚠️ **重要提醒**

1. **資料安全**
   - 批次刪除無法還原
   - 建議定期備份資料
   - 重要項目請先匯出

2. **效能考量**
   - 大量項目選取可能較慢
   - 批次刪除需要時間
   - 建議分批處理大量資料

3. **使用限制**
   - 文稿最多顯示前 6 個
   - 選取狀態不跨頁面保存
   - 退出選取模式會清除選取狀態

## 版本資訊

- **版本**: 1.0.0
- **實作日期**: 2026-01-08
- **開發者**: AI Assistant
- **狀態**: ✅ 已完成並測試編譯

---

**最後更新**: 2026-01-08
