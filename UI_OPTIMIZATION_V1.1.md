# OVEREND UI 優化 v1.1 - 功能增強

**日期**: 2025-01-11  
**版本**: v1.1 - 功能鍵優化 + 右鍵選單  

---

## 🎯 本次更新重點

### 問題
1. ❌ 文獻庫的書目功能鍵不夠顯眼
2. ❌ 書目不能按右鍵編輯

### 解決方案
1. ✅ **批次操作工具列全面增強**
2. ✅ **右鍵選單完整功能**

---

## ✅ 已完成優化

### 1. **批次操作工具列增強** (`ModernEntryListView.swift`)

#### 選取模式按鈕
**原始設計**：
- 圖示：18pt
- 文字：「選取」
- 背景：簡單填充

**優化後**：
```swift
- 圖示：20pt Semibold + checkmark.circle.fill
- 文字：「批次選取」（更明確）
- 背景：漸層 + 邊框 + 陰影
- 視覺：科技感十足
```

#### 已選取標籤
**原始設計**：
- 純文字標籤
- 灰色背景

**優化後**：
```swift
- 加入圖示：checkmark.seal.fill
- 文字加粗：fontWeight(.semibold)
- 背景：主色半透明 + 邊框
- 更顯眼的視覺層級
```

#### 刪除按鈕
**原始設計**：
- 純色背景
- 簡單陰影

**優化後**：
```swift
- 圖示：trash.fill（實心）
- 背景：漸層效果
- 陰影：更強的深度感（radius: 8）
- 視覺：警示性更強
```

#### 完成按鈕
**優化**：
- 邊框加粗：2px
- 文字加粗：fontWeight(.bold)
- 更清晰的對比

---

### 2. **右鍵選單功能** (`.contextMenu`)

#### 功能清單

1. **編輯書目** 📝
   ```
   Label("編輯書目", systemImage: "pencil")
   - 快速進入編輯模式
   ```

2. **複製引用** 📋
   ```
   - 複製 APA 引用 (doc.on.doc)
   - 複製 MLA 引用 (doc.on.doc)
   - 複製 Citation Key (key)
   - 自動複製到剪貼簿
   ```

3. **開啟 PDF** 📄
   ```
   Label("開啟 PDF", systemImage: "doc.fill")
   - 只在有附件時顯示
   - 使用 NSWorkspace 開啟
   ```

4. **刪除** 🗑️
   ```
   Button(role: .destructive)
   - 紅色警示
   - 確認對話框
   ```

#### 使用方式
- **滑鼠右鍵** → 選單彈出
- **雙指點按** → 選單彈出（觸控板）
- **Control + 點擊** → 選單彈出

---

## 📊 視覺對比

### 按鈕尺寸對比

| 元件 | 原始 | 優化後 | 改善 |
|------|------|--------|------|
| 圖示大小 | 18pt | 20pt | +11% |
| 按鈕內距 | 16x10px | 20x12px | +25% |
| 邊框粗細 | 1.5px | 2px | +33% |

### 視覺增強

| 項目 | 原始 | 優化後 |
|------|------|--------|
| 背景 | 純色 | 漸層 + 陰影 |
| 邊框 | 無 | 有（主色半透明）|
| 圖示 | 線條 | 實心（更醒目）|
| 文字 | Medium | Semibold/Bold |

---

## 🎨 設計細節

### 1. **漸層效果**
```swift
LinearGradient(
    colors: [theme.accentLight, theme.accentLight.opacity(0.5)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### 2. **陰影層次**
```swift
// 選取按鈕：輕微陰影
.shadow(color: theme.accent.opacity(0.15), radius: 4, y: 2)

// 刪除按鈕：強烈陰影
.shadow(color: theme.destructive.opacity(0.4), radius: 8, y: 4)
```

### 3. **邊框設計**
```swift
RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
    .stroke(theme.accent.opacity(0.3), lineWidth: 1.5)
```

---

## 🚀 使用指南

### 批次選取模式
1. 點擊右上角 **「批次選取」** 按鈕
2. 勾選要操作的文獻
3. 點擊 **「刪除選取項目」** 或其他操作
4. 點擊 **「完成」** 退出選取模式

### 右鍵選單
1. **編輯書目**：在文獻上按右鍵 → 選擇「編輯書目」
2. **複製引用**：右鍵 → 選擇所需格式 → 自動複製
3. **開啟 PDF**：右鍵 → 「開啟 PDF」（有附件時）
4. **刪除**：右鍵 → 「刪除」→ 確認

---

## 💡 貼心細節

### 1. **智能顯示**
- 只有在有附件時才顯示「開啟 PDF」
- 選取數量即時更新
- 圖示根據狀態變化

### 2. **快捷操作**
- 右鍵選單快速存取常用功能
- 一鍵複製引用到剪貼簿
- 直接開啟 PDF 文件

### 3. **視覺回饋**
- 按鈕有懸停效果
- 選取狀態清楚顯示
- 操作結果即時反映

---

## 🔧 技術實作

### 右鍵選單實作
```swift
.contextMenu {
    Button(action: { /* 操作 */ }) {
        Label("功能名稱", systemImage: "圖示")
    }
    
    Divider()  // 分隔線
    
    Button(role: .destructive, action: { /* 刪除 */ }) {
        Label("刪除", systemImage: "trash")
    }
}
```

### 剪貼簿操作
```swift
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(text, forType: .string)
```

---

## 📝 待辦事項

### 階段 1（已完成）✅
- [x] 批次操作工具列增強
- [x] 右鍵選單基礎功能
- [x] 複製引用功能
- [x] 開啟 PDF 功能

### 階段 2（可選）
- [ ] 編輯書目實際功能串接
- [ ] 右鍵選單增加「標籤管理」
- [ ] 右鍵選單增加「移動到群組」
- [ ] 右鍵選單增加「匯出」選項

---

## 🎯 效果預期

執行後你會看到：

1. **批次選取按鈕**
   - 更大更醒目
   - 漸層背景 + 陰影
   - 一眼就能看到

2. **右鍵選單**
   - 在任何書目上按右鍵
   - 彈出完整功能選單
   - 快速存取編輯/複製/刪除

3. **選取狀態**
   - 已選取標籤有圖示
   - 數量即時更新
   - 視覺更明確

---

**立即測試**：
```bash
cd /Users/lawliet/OVEREND
open OVEREND.xcodeproj
# 按 ⌘R 執行
```

**測試重點**：
- [ ] 批次選取按鈕是否夠醒目？
- [ ] 右鍵選單能否正常彈出？
- [ ] 複製引用功能是否正常？
- [ ] 開啟 PDF 是否正常？

---

**協作**: Claude + Lawliet Chen  
**版本**: v1.1  
**最後更新**: 2025-01-11 13:15
