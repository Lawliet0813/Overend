# 🚀 快速開始：使用 Core ML 模型

## 📝 簡短版指南

### 1️⃣ 準備訓練資料

```swift
// 在你的 SwiftUI View 中
Button("匯出訓練資料") {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.commaSeparatedText]
    panel.nameFieldStringValue = "training_data.csv"
    
    panel.begin { response in
        guard response == .OK, let url = panel.url else { return }
        
        do {
            try TrainingDataExporter.exportToCSV(
                context: viewContext,
                outputURL: url
            )
            print("✅ 匯出成功")
        } catch {
            print("❌ 匯出失敗: \(error)")
        }
    }
}
```

### 2️⃣ 在 Create ML 訓練模型

1. 開啟 **Create ML**（Xcode > Open Developer Tool > Create ML）
2. 選擇 **Text Classifier**
3. 匯入 CSV 檔案（Text: `text`, Label: `label`）
4. 訓練模型（約 5-15 分鐘）
5. 匯出為 `LiteratureClassifier.mlmodel`

### 3️⃣ 加入 Xcode 專案

```
OVEREND/
├── Models/
│   └── LiteratureClassifier.mlmodel  ← 拖曳到這裡
```

✅ 勾選 Target Membership: `OVEREND`  
✅ 重新編譯專案（⌘B）

### 4️⃣ 使用模型進行預測

#### 方法 A：單一預測

```swift
let classifier = LiteratureClassifierService.shared

// 建立描述文字
let text = "發表於《行政管理學報》第30卷第2期"

// 執行預測
if let prediction = classifier.predict(text: text) {
    print("類型：\(prediction.displayName)")
    print("信心度：\(Int(prediction.confidence * 100))%")
    
    // 使用結果
    entry.bibtexType = prediction.label
}
```

#### 方法 B：非同步預測（推薦）

```swift
classifier.predictAsync(text: text) { prediction in
    guard let result = prediction else { return }
    
    // 更新 UI
    self.entryType = result.label
    self.confidence = result.confidence
}
```

#### 方法 C：批次預測

```swift
classifier.batchPredict(
    entries: entries,
    progress: { progress in
        print("進度：\(Int(progress * 100))%")
    },
    completion: { successCount in
        print("成功分類 \(successCount) 筆")
    }
)
```

### 5️⃣ 在 UI 中顯示結果

```swift
struct ContentView: View {
    @State private var prediction: LiteraturePrediction?
    
    var body: some View {
        VStack {
            Button("AI 分類") {
                let text = buildDescription(from: entry)
                prediction = LiteratureClassifierService.shared.predict(text: text)
            }
            
            if let result = prediction {
                LiteraturePredictionCard(prediction: result) {
                    // 使用者點擊「接受」
                    entry.bibtexType = result.label
                }
            }
        }
    }
}
```

### 6️⃣ 測試模型

打開 `MLModelTestView` 進行測試：

```swift
// 在 ContentView 或 Settings 中
NavigationLink("測試 AI 模型") {
    MLModelTestView()
}
```

---

## 📊 信心度判斷

```swift
if prediction.confidence > 0.9 {
    // 自動套用
    entry.bibtexType = prediction.label
} else if prediction.confidence > 0.7 {
    // 顯示建議，讓使用者確認
    showSuggestion(prediction)
} else {
    // 信心度太低，顯示多個選項
    showTopN(predictions)
}
```

---

## 🔧 故障排除

### 模型未載入？

1. ✅ 檢查檔案名稱：`LiteratureClassifier.mlmodel`
2. ✅ 確認 Target Membership
3. ✅ 重新編譯專案（⌘B）
4. ✅ 查看 Console 錯誤訊息

### 預測準確率低？

1. 📈 增加訓練資料（建議 >200 筆/類別）
2. ⚖️ 平衡各類別數量
3. 🧹 清理錯誤標籤
4. 🎯 使用更多特徵（作者、年份、關鍵字）

---

## 📚 完整文件

詳細說明請參考：`CoreMLModelGuide.md`

---

## 💡 實用範例

### 從 Entry 建立描述

```swift
extension LiteratureClassifierService {
    func predictForEntry(_ entry: Entry) -> LiteraturePrediction? {
        let text = buildDescription(from: entry)
        return predict(text: text)
    }
}
```

### 自動分類未標記的文獻

```swift
Button("批次自動分類") {
    let unclassified = entries.filter { 
        $0.bibtexType.isEmpty || $0.bibtexType == "Unknown" 
    }
    
    LiteratureClassifierService.shared.batchPredict(
        entries: unclassified,
        progress: { progress in
            self.progress = progress
        },
        completion: { count in
            ToastManager.shared.showSuccess("已分類 \(count) 筆文獻")
        }
    )
}
```

### 提供替代選項

```swift
let topPredictions = classifier.predictTopN(text: text, n: 3)

Menu("選擇類型") {
    ForEach(topPredictions, id: \.label) { prediction in
        Button {
            entry.bibtexType = prediction.label
        } label: {
            HStack {
                Text(prediction.displayName)
                Spacer()
                Text("\(Int(prediction.confidence * 100))%")
            }
        }
    }
}
```

---

## ✅ 完成！

現在您可以：
- ✅ 使用已訓練好的 Core ML 模型
- ✅ 自動分類文獻類型
- ✅ 批次處理大量資料
- ✅ 提供 AI 輔助建議

**下一步：**
1. 收集使用者反饋
2. 持續改善訓練資料
3. 定期更新模型
