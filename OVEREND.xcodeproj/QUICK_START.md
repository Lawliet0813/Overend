# 🚀 Core ML 模型使用快速指南

## 基本使用

### 1. 單一預測

```swift
let classifier = LiteratureClassifierService.shared

// 建立描述文字
let text = "發表於《行政管理學報》第30卷第2期"

// 執行預測
if let prediction = classifier.predict(text: text) {
    print("類型：\(prediction.displayName)")
    print("信心度：\(Int(prediction.confidence * 100))%")
    
    // 更新 Entry（注意：使用 entryType 而非 bibtexType）
    entry.entryType = prediction.label
}
```

### 2. 在 SwiftUI View 中使用

```swift
struct LiteratureClassifierView: View {
    @StateObject private var classifier = LiteratureClassifierService.shared
    @State private var prediction: LiteraturePrediction?
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            // 輸入區域
            TextEditor(text: $inputText)
                .frame(height: 120)
            
            // 分類按鈕
            Button("AI 分類") {
                prediction = classifier.predict(text: inputText)
            }
            .disabled(!classifier.isModelLoaded)
            
            // 結果顯示
            if let result = prediction {
                LiteraturePredictionCard(prediction: result) {
                    // 使用者接受建議
                    applyPrediction(result)
                }
            }
        }
    }
}
```

### 3. 非同步預測（推薦）

```swift
Button("AI 分類") {
    classifier.predictAsync(text: inputText) { prediction in
        guard let result = prediction else { return }
        self.prediction = result
    }
}
```

## 整合範例

### 從 Entry 建立描述文字

```swift
func buildDescription(from entry: Entry) -> String {
    var parts: [String] = []
    
    if !entry.title.isEmpty && entry.title != "Untitled" {
        parts.append(entry.title)
    }
    
    if !entry.author.isEmpty && entry.author != "Unknown" {
        parts.append(entry.author)
    }
    
    if let journal = entry.fields["journal"], !journal.isEmpty {
        parts.append("發表於《\(journal)》")
    }
    
    if let booktitle = entry.fields["booktitle"], !booktitle.isEmpty {
        parts.append("收錄於《\(booktitle)》")
    }
    
    if let year = Int(entry.year), year > 0 {
        parts.append("\(year)年")
    }
    
    return parts.joined(separator: "，")
}
```

### 自動偵測類型功能

```swift
Button {
    autoDetectType()
} label: {
    Label("AI 自動偵測類型", systemImage: "sparkles")
}

private func autoDetectType() {
    let description = buildDescription(from: entry)
    
    if let prediction = LiteratureClassifierService.shared.predict(text: description),
       prediction.confidence > 0.7 {
        // 使用 entryType 更新類型
        entry.entryType = prediction.label
        
        // 儲存變更
        try? viewContext.save()
        
        ToastManager.shared.showSuccess("已自動設定為：\(prediction.displayName)")
    } else {
        ToastManager.shared.showWarning("信心度較低，請手動確認")
    }
}
```

### 批次分類

```swift
func batchClassify(entries: [Entry]) {
    let classifier = LiteratureClassifierService.shared
    
    ToastManager.shared.startLoading("正在分類...")
    
    var successCount = 0
    
    for (index, entry) in entries.enumerated() {
        // 只處理未分類或類型為 Unknown 的條目
        guard entry.entryType.isEmpty || entry.entryType == "Unknown" else {
            continue
        }
        
        let description = buildDescription(from: entry)
        
        if let prediction = classifier.predict(text: description),
           prediction.confidence > 0.75 {
            entry.entryType = prediction.label
            successCount += 1
        }
        
        // 更新進度
        let progress = Double(index + 1) / Double(entries.count)
        ToastManager.shared.updateProgress(progress)
    }
    
    // 儲存所有變更
    try? viewContext.save()
    
    ToastManager.shared.finishWithSuccess("成功分類 \(successCount) 筆文獻")
}
```

## 信心度判斷策略

```swift
if let prediction = classifier.predict(text: text) {
    switch prediction.confidenceLevel {
    case .high:
        // 自動套用（信心度 > 90%）
        entry.entryType = prediction.label
        try? viewContext.save()
        
    case .medium:
        // 顯示建議，讓使用者確認（70% - 90%）
        showSuggestionDialog(prediction)
        
    case .low:
        // 信心度太低，顯示多個選項（< 70%）
        let topPredictions = classifier.predictTopN(text: text, n: 3)
        showMultipleOptions(topPredictions)
    }
}
```

## 提供多個選項

```swift
let topPredictions = classifier.predictTopN(text: text, n: 3)

Menu("選擇類型") {
    ForEach(topPredictions, id: \.label) { prediction in
        Button {
            entry.entryType = prediction.label
            try? viewContext.save()
        } label: {
            HStack {
                Image(systemName: prediction.icon)
                Text(prediction.displayName)
                Spacer()
                Text("\(Int(prediction.confidence * 100))%")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    Divider()
    
    Button("手動選擇...") {
        showManualPicker()
    }
}
```

## 測試模型

打開測試介面：

```swift
// 在 Settings 或 Debug Menu 中
NavigationLink("測試 AI 模型") {
    MLModelTestView()
        .environmentObject(AppTheme())
}
```

## 模型狀態檢查

```swift
let classifier = LiteratureClassifierService.shared

if !classifier.isModelLoaded {
    Text("⚠️ AI 模型未載入")
        .foregroundColor(.orange)
    
    if let error = classifier.lastError {
        Text(error)
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    Button("重新載入") {
        classifier.reloadModel()
    }
}
```

## 常見錯誤處理

### 模型未載入

```swift
guard classifier.isModelLoaded else {
    ToastManager.shared.showError("AI 模型尚未載入")
    return
}
```

### 輸入為空

```swift
let description = buildDescription(from: entry)
guard !description.isEmpty else {
    ToastManager.shared.showWarning("文獻資訊不足，無法進行分類")
    return
}
```

### 信心度過低

```swift
if let prediction = classifier.predict(text: text) {
    if prediction.confidence < 0.5 {
        ToastManager.shared.showWarning("AI 無法確定類型，建議手動選擇")
        return
    }
    
    // 繼續處理...
}
```

## 清除快取

```swift
// 當模型更新後，清除舊的預測快取
Button("清除預測快取") {
    LiteratureClassifierService.shared.clearCache()
    ToastManager.shared.showSuccess("已清除快取")
}
```

## Entry 屬性對照表

| 文檔中的名稱 | 實際屬性名 | 說明 |
|------------|----------|------|
| `bibtexType` | ❌ 不存在 | 舊的錯誤命名 |
| `entryType` | ✅ 正確 | BibTeX 條目類型 |
| `citationKey` | ✅ 正確 | 引用鍵 |
| `fields` | ✅ 正確 | 字段字典 |
| `title` | ✅ 正確 | 計算屬性 |
| `author` | ✅ 正確 | 計算屬性 |
| `year` | ✅ 正確 | 計算屬性 |

## 完整範例：Entry 編輯器整合

```swift
struct EntryEditorView: View {
    @ObservedObject var entry: Entry
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var classifier = LiteratureClassifierService.shared
    @State private var showingPrediction = false
    @State private var currentPrediction: LiteraturePrediction?
    
    var body: some View {
        Form {
            Section("基本資訊") {
                TextField("標題", text: Binding(
                    get: { entry.title },
                    set: { entry.fields["title"] = $0 }
                ))
                
                TextField("作者", text: Binding(
                    get: { entry.author },
                    set: { entry.fields["author"] = $0 }
                ))
                
                // 類型選擇器
                HStack {
                    Picker("類型", selection: $entry.entryType) {
                        Text("期刊論文").tag("Journal Article")
                        Text("會議論文").tag("Conference Paper")
                        Text("學位論文").tag("Thesis")
                        Text("書籍章節").tag("Book Chapter")
                    }
                    
                    // AI 自動偵測按鈕
                    Button {
                        detectType()
                    } label: {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    .help("AI 自動偵測類型")
                    .disabled(!classifier.isModelLoaded)
                }
            }
        }
        .sheet(isPresented: $showingPrediction) {
            if let prediction = currentPrediction {
                VStack {
                    LiteraturePredictionCard(prediction: prediction) {
                        entry.entryType = prediction.label
                        try? viewContext.save()
                        showingPrediction = false
                        ToastManager.shared.showSuccess("已更新類型")
                    }
                    
                    Button("取消") {
                        showingPrediction = false
                    }
                }
                .padding()
            }
        }
    }
    
    private func detectType() {
        let description = buildDescription(from: entry)
        
        classifier.predictAsync(text: description) { prediction in
            guard let result = prediction else {
                ToastManager.shared.showError("預測失敗")
                return
            }
            
            if result.confidence > 0.9 {
                // 高信心度，直接套用
                entry.entryType = result.label
                try? viewContext.save()
                ToastManager.shared.showSuccess("已自動設定為：\(result.displayName)")
            } else {
                // 顯示確認對話框
                currentPrediction = result
                showingPrediction = true
            }
        }
    }
    
    private func buildDescription(from entry: Entry) -> String {
        var parts: [String] = []
        
        if !entry.title.isEmpty && entry.title != "Untitled" {
            parts.append(entry.title)
        }
        
        if !entry.author.isEmpty && entry.author != "Unknown" {
            parts.append(entry.author)
        }
        
        if let journal = entry.fields["journal"], !journal.isEmpty {
            parts.append("發表於《\(journal)》")
        }
        
        return parts.joined(separator: "，")
    }
}
```

## 總結

✅ **使用 `entryType` 而非 `bibtexType`**  
✅ **檢查模型載入狀態**  
✅ **根據信心度決定是否自動套用**  
✅ **提供手動確認選項**  
✅ **記得儲存 Core Data 變更**  

祝開發順利！🎉
