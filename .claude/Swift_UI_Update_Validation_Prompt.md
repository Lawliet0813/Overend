# Swift UI 更新完整檢查清單

## 🎯 使用方法
每次要求 AI 更新 UI 時，在提示詞中加入：
「請按照 Swift UI 更新檢查清單完成更新並驗證」

---

## 📋 AI 必須執行的檢查步驟

### 階段 1：編譯檢查 ✅
```bash
# 執行編譯
xcodebuild -scheme OVEREND -destination 'platform=macOS' build

# 確認：沒有編譯錯誤
```

---

### 階段 2：UI-功能綁定完整性檢查 🔗

#### 2.1 按鈕與 Action 對應
掃描所有新增/修改的按鈕：

```swift
// ❌ 錯誤：按鈕沒有 action
Button("確認") { }

// ✅ 正確：按鈕有明確的 action
Button("確認") { 
    viewModel.confirmAction() 
}
```

**檢查項目：**
- [ ] 所有 `Button` 都有非空的 action closure
- [ ] 所有 `Button` 的 action 函數都存在
- [ ] 函數名稱拼寫正確（注意大小寫）

---

#### 2.2 事件處理器綁定
檢查所有事件綁定：

```swift
// ✅ 檢查 @State 和 @Binding 是否正確綁定
TextField("標題", text: $title)  // $ 不能省略

// ✅ 檢查 onChange 綁定
.onChange(of: selection) { newValue in
    handleSelectionChange(newValue)  // 函數必須存在
}

// ✅ 檢查 onTapGesture 綁定
.onTapGesture {
    performAction()  // 函數必須存在
}
```

**檢查項目：**
- [ ] 所有 `$` 綁定變數都已宣告為 `@State` 或 `@Binding`
- [ ] 所有 `onChange` 的處理函數都存在
- [ ] 所有 `onTapGesture` / `onLongPressGesture` 都有對應函數

---

#### 2.3 導航與路由檢查
檢查導航相關綁定：

```swift
// ✅ NavigationLink 目標檢查
NavigationLink(destination: DetailView(item: item)) { ... }
// DetailView 必須存在且參數正確

// ✅ Sheet/Alert 綁定檢查
.sheet(isPresented: $showingSheet) { SheetView() }
// $showingSheet 必須是 @State，SheetView() 必須存在
```

**檢查項目：**
- [ ] 所有 `NavigationLink` 的 destination 視圖都存在
- [ ] 所有 `.sheet` / `.alert` 的綁定變數已宣告
- [ ] 傳遞的參數類型正確

---

### 階段 3：資料流檢查 💾

#### 3.1 ViewModel 連接
```swift
// ✅ 確認 @StateObject / @ObservedObject 正確使用
@StateObject private var viewModel = LibraryViewModel()

// ✅ 確認 ViewModel 函數都存在
viewModel.loadData()  // 函數必須存在於 ViewModel
```

**檢查項目：**
- [ ] 所有 ViewModel 函數調用都在 ViewModel 中有定義
- [ ] `@Published` 屬性正確宣告
- [ ] 沒有循環參照問題

---

#### 3.2 Core Data 連接（如果適用）
```swift
// ✅ @FetchRequest 正確設置
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Entry.title, ascending: true)]
) var entries: FetchedResults<Entry>

// ✅ 確認 Entity 屬性存在
entry.title  // Entry.title 必須在 Core Data 模型中存在
```

**檢查項目：**
- [ ] 所有使用的 Entity 屬性都在 `.xcdatamodeld` 中存在
- [ ] `@FetchRequest` 的 sort 和 predicate 語法正確

---

### 階段 4：常見問題掃描 🔍

自動檢查以下已知問題：

```swift
// ❌ 遺失 @State
var showingAlert = false  
// ✅ 正確
@State private var showingAlert = false

// ❌ 遺失 $ 符號
TextField("", text: title)
// ✅ 正確
TextField("", text: $title)

// ❌ 按鈕 action 是空的
Button("送出") { }
// ✅ 正確
Button("送出") { submitForm() }

// ❌ 呼叫不存在的函數
Button("刪除") { deleteItem() }  // deleteItem() 未定義
// ✅ 正確：先確認函數存在
func deleteItem() { ... }
Button("刪除") { deleteItem() }
```

---

### 階段 5：測試建議 🧪

**AI 必須提醒使用者手動測試：**

```markdown
⚠️ 需要手動測試的部分：

1. **按鈕點擊測試**
   - [ ] 點擊「確認」按鈕是否觸發正確動作
   - [ ] 點擊「取消」按鈕是否關閉視圖

2. **輸入框測試**
   - [ ] 輸入文字是否正確綁定到變數
   - [ ] 清空輸入框是否正常

3. **導航測試**
   - [ ] 頁面跳轉是否正常
   - [ ] 返回按鈕是否正常

4. **資料更新測試**
   - [ ] 新增資料是否正確儲存
   - [ ] 刪除資料是否正確移除
   - [ ] 編輯資料是否正確更新
```

---

## 📊 完整檢查報告格式

AI 完成所有檢查後，必須提供以下報告：

```markdown
# Swift UI 更新檢查報告

## ✅ 編譯狀態
- [✓] 編譯成功，無錯誤

## ✅ UI-功能綁定檢查
- [✓] 3 個按鈕，全部有 action
- [✓] 2 個 TextField，全部正確綁定
- [✓] 1 個 NavigationLink，目標視圖存在

## ✅ 資料流檢查
- [✓] ViewModel 函數全部存在
- [✓] @Published 屬性正確宣告

## ✅ 常見問題掃描
- [✓] 無遺失 @State 問題
- [✓] 無遺失 $ 綁定問題
- [✓] 無空 action 問題

## ⚠️ 需要手動測試
請測試以下功能：
1. 點擊「新增」按鈕
2. 輸入標題後儲存
3. 檢查資料是否正確顯示

## 📝 修改摘要
- 新增了 `addEntry()` 函數
- 更新了 `EntryListView` 的按鈕綁定
- 修正了 `EntryDetailView` 的導航問題
```

---

## 🚫 禁止事項

AI **絕對不可以**只說：
- ❌「編譯成功了」
- ❌「我已經更新好了」
- ❌「應該沒問題」

必須提供**完整的檢查報告**。

---

## 💡 使用範例

### 範例 1：要求 AI 更新按鈕
```
請在 EntryListView 中新增一個「匯出」按鈕，
並按照 Swift UI 更新檢查清單完成更新並驗證。
```

### 範例 2：要求 AI 修改導航
```
請將 DetailView 的導航方式改為 sheet，
並按照 Swift UI 更新檢查清單完成更新並驗證。
```

---

**最後更新：2026-01-15**
**版本：v1.0**
