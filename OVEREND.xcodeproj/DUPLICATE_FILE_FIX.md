# 🔧 重複檔案錯誤修復

## 問題描述

編譯器報告以下錯誤：
```
error: Cannot find 'LiteraturePredictionCard' in scope
error: Cannot find 'LiteratureClassifierService' in scope
error: Cannot find type 'LiteraturePrediction' in scope
```

## 根本原因

專案中存在兩個相同的檔案，造成**重複定義**錯誤：

1. ✅ `LiteratureClassifierService.swift` (503 行) - **保留此檔案**
2. ❌ `LiteratureClassifierService 2.swift` (380 行) - **需要刪除**

兩個檔案都定義了：
- `class LiteratureClassifierService`
- `struct LiteraturePrediction`
- `struct LiteraturePredictionCard`

這導致編譯器無法確定要使用哪個定義，從而報告「找不到」錯誤。

## 已完成的修復

### 1. 修復 LiteratureClassifierService.swift 的 import 位置

**問題**：`import SwiftUI` 語句在檔案中間（第 385 行），而不是在開頭。

**修復**：
```swift
// ✅ 現在所有 import 都在檔案開頭
import Foundation
import CoreML
import NaturalLanguage
import Combine
import SwiftUI  // 已移到開頭
```

## 需要手動完成的步驟

### ⚠️ 刪除重複檔案

請在 Xcode 中執行以下步驟：

1. **在 Xcode Project Navigator 中找到檔案**
   - 展開專案目錄
   - 找到 `LiteratureClassifierService 2.swift`
   
2. **刪除檔案**
   - 右鍵點擊 `LiteratureClassifierService 2.swift`
   - 選擇「Delete」
   - 在彈出的對話框中選擇「Move to Trash」（移到垃圾桶）
   
3. **清理專案**
   - 按 `⇧⌘K` (Shift+Command+K) 清理建置目錄
   - 或選單：Product → Clean Build Folder
   
4. **重新編譯**
   - 按 `⌘B` (Command+B) 編譯專案
   - 應該看到「Build Succeeded」

### 驗證修復

編譯成功後，確認以下內容可以正常使用：

```swift
// ✅ 這些應該都能正常編譯
import SwiftUI

struct TestView: View {
    @StateObject private var classifier = LiteratureClassifierService.shared
    @State private var prediction: LiteraturePrediction?
    
    var body: some View {
        VStack {
            if let pred = prediction {
                LiteraturePredictionCard(prediction: pred)
            }
        }
    }
}
```

## 檔案對比

### LiteratureClassifierService.swift (保留)
- ✅ 503 行
- ✅ 包含完整的實作
- ✅ 包含所有必要的類型定義
- ✅ 包含 SwiftUI 元件
- ✅ 包含 Preview

### LiteratureClassifierService 2.swift (刪除)
- ❌ 380 行
- ❌ 內容與第一個檔案重複
- ❌ 造成重複定義錯誤

## 為什麼會有重複檔案？

可能的原因：
1. 版本控制合併衝突
2. 檔案複製操作
3. Xcode 自動建立備份
4. Git 合併時產生的衝突檔案

## 預防未來問題

1. **定期檢查重複檔案**
   ```bash
   # 在專案目錄執行
   find . -name "* 2.*" -o -name "*copy*"
   ```

2. **使用 Git 忽略備份檔案**
   在 `.gitignore` 中加入：
   ```
   *\ 2.*
   *copy*
   ```

3. **Xcode 設定**
   - 確保「File Inspector」中每個檔案只屬於一個 Target
   - 檢查「Target Membership」是否正確

## 相關錯誤訊息

如果看到以下錯誤，通常都是重複定義造成的：

```
error: Cannot find 'XXX' in scope
error: Ambiguous use of 'XXX'
error: 'XXX' is ambiguous for type lookup in this context
error: Redeclaration of 'XXX'
```

## 總結

1. ✅ 已修復：`LiteratureClassifierService.swift` 的 import 位置
2. ⚠️ 待完成：刪除 `LiteratureClassifierService 2.swift`
3. ⚠️ 待完成：清理並重新編譯專案

完成這些步驟後，所有編譯錯誤應該都會解決。

---

**修復日期**：2026-01-21  
**相關檔案**：
- `LiteratureClassifierService.swift` (保留)
- `LiteratureClassifierService 2.swift` (刪除)
- `MLModelTestView.swift` (使用這些類型)

