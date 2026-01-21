# 📚 OVEREND - Core ML 模型使用完整指南

## 目錄
1. [模型訓練流程](#1-模型訓練流程)
2. [模型匯入與部署](#2-模型匯入與部署)
3. [模型推理實作](#3-模型推理實作)
4. [整合到現有功能](#4-整合到現有功能)
5. [最佳實踐](#5-最佳實踐)

---

## 1. 模型訓練流程

### 1.1 匯出訓練資料

已經實作在 `TrainingDataExportView.swift`：

```swift
// 使用方法
TrainingDataExporter.exportToCSV(
    context: viewContext,
    outputURL: URL(fileURLWithPath: "/path/to/training_data.csv")
)
```

**匯出的 CSV 格式：**
```csv
text,label
"發表於《行政管理學報》第30卷第2期","Journal Article"
"收錄於2024年台灣公共行政與公共事務系所聯合會年會論文集","Conference Paper"
"國立政治大學公共行政學系碩士論文","Thesis"
```

### 1.2 在 Create ML 訓練模型

1. **開啟 Create ML**（Xcode > Open Developer Tool > Create ML）
2. **建立新的 Text Classifier 專案**
3. **匯入訓練資料**：
   - Data Source: CSV 檔案
   - Text Column: `text`
   - Label Column: `label`
4. **設定參數**：
   - Algorithm: Transfer Learning（推薦）或 Maximum Entropy
   - Max Iterations: 25（預設）
   - Validation Split: 20%
5. **開始訓練**
6. **評估模型**：
   - Training Accuracy: >85%
   - Validation Accuracy: >80%
7. **匯出模型**：
   - 儲存為 `.mlmodel` 檔案
   - 建議命名：`LiteratureClassifier.mlmodel`

---

## 2. 模型匯入與部署

### 2.1 加入 Xcode 專案

1. **拖曳 `.mlmodel` 到 Xcode**
   ```
   OVEREND/
   ├── Models/
   │   └── LiteratureClassifier.mlmodel  ← 放這裡
   ```

2. **確認 Target Membership**
   - 右側 Inspector 面板
   - 勾選 `OVEREND`

3. **編譯專案**（⌘B）
   - Xcode 會自動生成 Swift 類別

### 2.2 生成的類別

Xcode 會自動生成：

```swift
// 自動生成（不要手動編輯）
class LiteratureClassifier {
    let model: MLModel
    
    func prediction(text: String) throws -> LiteratureClassifierOutput
}

struct LiteratureClassifierOutput {
    let label: String
    let labelProbability: [String: Double]
}
```

---

## 3. 模型推理實作

### 3.1 建立 Model Service

建議建立一個專門的服務類別：

```swift
import CoreML
import NaturalLanguage

/// Core ML 文獻分類服務
class LiteratureClassifierService {
    static let shared = LiteratureClassifierService()
    
    private var nlModel: NLModel?
    private var isModelLoaded = false
    
    init() {
        loadModel()
    }
    
    // MARK: - 模型載入
    
    private func loadModel() {
        do {
            // 方法 1: 使用 NLModel（推薦給文本分類）
            let config = MLModelConfiguration()
            
            if let modelURL = Bundle.main.url(
                forResource: "LiteratureClassifier",
                withExtension: "mlmodelc"
            ) {
                let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
                self.nlModel = try NLModel(mlModel: mlModel)
                self.isModelLoaded = true
                print("✅ 模型載入成功")
            }
            
        } catch {
            print("❌ 模型載入失敗: \(error)")
            self.isModelLoaded = false
        }
    }
    
    // MARK: - 預測方法
    
    /// 預測文獻類型（單一結果）
    func predict(text: String) -> LiteraturePrediction? {
        guard let model = nlModel, isModelLoaded else {
            return nil
        }
        
        guard let label = model.predictedLabel(for: text) else {
            return nil
        }
        
        // 取得所有機率
        let hypotheses = model.predictedLabelHypotheses(
            for: text,
            maximumCount: 4
        ) ?? [:]
        
        let confidence = hypotheses[label] ?? 0.0
        
        return LiteraturePrediction(
            label: label,
            confidence: confidence,
            allProbabilities: hypotheses
        )
    }
    
    /// 預測文獻類型（Top N 結果）
    func predictTopN(text: String, n: Int = 3) -> [LiteraturePrediction] {
        guard let model = nlModel, isModelLoaded else {
            return []
        }
        
        let hypotheses = model.predictedLabelHypotheses(
            for: text,
            maximumCount: n
        ) ?? [:]
        
        return hypotheses
            .sorted { $0.value > $1.value }
            .map { (label, confidence) in
                LiteraturePrediction(
                    label: label,
                    confidence: confidence,
                    allProbabilities: hypotheses
                )
            }
    }
}

// MARK: - 數據模型

struct LiteraturePrediction {
    let label: String
    let confidence: Double
    let allProbabilities: [String: Double]
    
    var displayName: String {
        switch label {
        case "Journal Article": return "期刊論文"
        case "Conference Paper": return "會議論文"
        case "Thesis": return "學位論文"
        case "Book Chapter": return "書籍章節"
        default: return label
        }
    }
    
    var icon: String {
        switch label {
        case "Journal Article": return "doc.text"
        case "Conference Paper": return "person.3"
        case "Thesis": return "graduationcap"
        case "Book Chapter": return "book.closed"
        default: return "questionmark"
        }
    }
    
    var color: Color {
        switch label {
        case "Journal Article": return .blue
        case "Conference Paper": return .green
        case "Thesis": return .orange
        case "Book Chapter": return .purple
        default: return .gray
        }
    }
}
```

### 3.2 在 SwiftUI 中使用

```swift
struct LiteratureClassificationView: View {
    @State private var inputText = ""
    @State private var prediction: LiteraturePrediction?
    @State private var isAnalyzing = false
    
    private let classifier = LiteratureClassifierService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // 輸入區域
            TextEditor(text: $inputText)
                .frame(height: 120)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            // 分類按鈕
            Button {
                classifyText()
            } label: {
                Label("AI 分類", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || isAnalyzing)
            
            // 結果顯示
            if let result = prediction {
                PredictionResultCard(prediction: result)
            }
        }
        .padding()
    }
    
    private func classifyText() {
        isAnalyzing = true
        
        // 非同步推理（避免 UI 卡頓）
        Task.detached {
            let result = classifier.predict(text: inputText)
            
            await MainActor.run {
                self.prediction = result
                self.isAnalyzing = false
            }
        }
    }
}
```

---

## 4. 整合到現有功能

### 4.1 整合到 Entry 編輯畫面

```swift
// 在 EntryEditorView.swift 加入
Button {
    autoDetectType()
} label: {
    Label("AI 自動偵測類型", systemImage: "sparkles")
}

private func autoDetectType() {
    let description = buildDescription(from: entry)
    
    if let prediction = LiteratureClassifierService.shared.predict(text: description),
       prediction.confidence > 0.7 {
        entry.bibtexType = prediction.label
        ToastManager.shared.showSuccess("已自動設定為：\(prediction.displayName)")
    }
}

private func buildDescription(from entry: Entry) -> String {
    var parts: [String] = []
    
    if !entry.title.isEmpty {
        parts.append(entry.title)
    }
    
    if !entry.author.isEmpty {
        parts.append(entry.author)
    }
    
    if let journal = entry.fields["journal"], !journal.isEmpty {
        parts.append("發表於《\(journal)》")
    }
    
    return parts.joined(separator: "，")
}
```

### 4.2 整合到批次處理

```swift
// 批次分類未標記的文獻
func batchClassifyEntries(entries: [Entry]) async {
    let classifier = LiteratureClassifierService.shared
    
    for entry in entries {
        guard entry.bibtexType.isEmpty || entry.bibtexType == "Unknown" else {
            continue
        }
        
        let description = buildDescription(from: entry)
        
        if let prediction = classifier.predict(text: description),
           prediction.confidence > 0.75 {
            entry.bibtexType = prediction.label
        }
        
        // 避免過快執行
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
    }
    
    // 儲存變更
    try? viewContext.save()
}
```

---

## 5. 最佳實踐

### 5.1 效能優化

```swift
// ✅ 單例模式（避免重複載入）
class LiteratureClassifierService {
    static let shared = LiteratureClassifierService()
    private init() { loadModel() }
}

// ✅ 非同步推理
Task.detached {
    let result = classifier.predict(text: text)
    await MainActor.run {
        // 更新 UI
    }
}

// ✅ 快取結果（避免重複計算）
private var cache: [String: LiteraturePrediction] = [:]

func predict(text: String) -> LiteraturePrediction? {
    if let cached = cache[text] {
        return cached
    }
    
    let result = performPrediction(text)
    cache[text] = result
    return result
}
```

### 5.2 錯誤處理

```swift
enum ModelError: Error {
    case modelNotLoaded
    case predictionFailed
    case invalidInput
    
    var localizedDescription: String {
        switch self {
        case .modelNotLoaded: return "模型尚未載入"
        case .predictionFailed: return "預測失敗"
        case .invalidInput: return "輸入文字無效"
        }
    }
}

func predict(text: String) throws -> LiteraturePrediction {
    guard isModelLoaded else {
        throw ModelError.modelNotLoaded
    }
    
    guard !text.isEmpty else {
        throw ModelError.invalidInput
    }
    
    // 執行預測...
}
```

### 5.3 使用者體驗

```swift
// ✅ 顯示信心度
if prediction.confidence > 0.9 {
    Text("🎯 高度確信：\(prediction.displayName)")
} else if prediction.confidence > 0.7 {
    Text("✅ 可能為：\(prediction.displayName)")
} else {
    Text("⚠️ 不確定，建議手動確認")
}

// ✅ 提供替代選項
let topPredictions = classifier.predictTopN(text: text, n: 3)
Menu("選擇類型") {
    ForEach(topPredictions, id: \.label) { prediction in
        Button {
            selectType(prediction.label)
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

### 5.4 模型更新流程

1. **收集使用者修正的資料**
2. **匯出新的訓練資料**（包含使用者修正）
3. **重新訓練模型**
4. **評估新模型效能**
5. **替換舊模型**（保持相同檔名）
6. **發布更新**

---

## 6. 測試與除錯

### 6.1 單元測試

```swift
import XCTest
@testable import OVEREND

class LiteratureClassifierTests: XCTestCase {
    let classifier = LiteratureClassifierService.shared
    
    func testJournalArticleClassification() {
        let text = "發表於《行政管理學報》第30卷第2期"
        let prediction = classifier.predict(text: text)
        
        XCTAssertNotNil(prediction)
        XCTAssertEqual(prediction?.label, "Journal Article")
        XCTAssertGreaterThan(prediction?.confidence ?? 0, 0.7)
    }
    
    func testConferencePaperClassification() {
        let text = "收錄於2024年台灣公共行政與公共事務系所聯合會年會論文集"
        let prediction = classifier.predict(text: text)
        
        XCTAssertEqual(prediction?.label, "Conference Paper")
    }
}
```

### 6.2 除錯技巧

```swift
// 記錄詳細資訊
func predict(text: String) -> LiteraturePrediction? {
    #if DEBUG
    print("📝 輸入文字: \(text)")
    #endif
    
    guard let result = nlModel?.predictedLabel(for: text) else {
        #if DEBUG
        print("❌ 預測失敗")
        #endif
        return nil
    }
    
    #if DEBUG
    print("✅ 預測結果: \(result)")
    if let probs = nlModel?.predictedLabelHypotheses(for: text, maximumCount: 4) {
        print("📊 機率分布:")
        for (label, prob) in probs.sorted(by: { $0.value > $1.value }) {
            print("   \(label): \(Int(prob * 100))%")
        }
    }
    #endif
    
    return createPrediction(label: result, text: text)
}
```

---

## 7. 常見問題

### Q1: 模型載入失敗怎麼辦？

**檢查清單：**
- ✅ 檔案名稱正確（不含空格）
- ✅ Target Membership 已勾選
- ✅ 已重新編譯專案（⌘B）
- ✅ 檔案在 Copy Bundle Resources 中

### Q2: 預測準確率低怎麼辦？

**改善方法：**
1. 增加訓練資料量（建議 >200 筆/類別）
2. 平衡各類別資料數量
3. 清理訓練資料（移除錯誤標籤）
4. 調整 Create ML 參數（增加 Max Iterations）

### Q3: 如何支援多語言？

```swift
// 在訓練資料中混合中英文
"Published in Journal of Public Administration, 行政管理學報","Journal Article"

// 或建立兩個模型
let chineseModel = LiteratureClassifier_zh()
let englishModel = LiteratureClassifier_en()

func predict(text: String) -> LiteraturePrediction? {
    let language = NLLanguageRecognizer.dominantLanguage(for: text)
    
    switch language {
    case .traditionalChinese, .simplifiedChinese:
        return chineseModel.predict(text)
    default:
        return englishModel.predict(text)
    }
}
```

---

## 8. 進階功能

### 8.1 模型版本管理

```swift
class ModelVersionManager {
    static let shared = ModelVersionManager()
    
    private var models: [String: NLModel] = [:]
    
    func loadModel(version: String) {
        let modelName = "LiteratureClassifier_v\(version)"
        // 載入特定版本
    }
    
    func compareModels(text: String) {
        // 比較不同版本的預測結果
    }
}
```

### 8.2 A/B 測試

```swift
class ABTestManager {
    func shouldUseNewModel() -> Bool {
        // 50% 使用者使用新模型
        return Bool.random()
    }
    
    func recordModelPerformance(
        modelVersion: String,
        prediction: String,
        userCorrection: String?
    ) {
        // 記錄使用者修正，用於評估模型效能
    }
}
```

---

## 總結

1. ✅ **訓練資料準備**：使用 `TrainingDataExportView` 匯出
2. ✅ **模型訓練**：在 Create ML 訓練並匯出
3. ✅ **模型整合**：建立 `LiteratureClassifierService`
4. ✅ **UI 整合**：在編輯器和批次處理中使用
5. ✅ **最佳化**：快取、非同步、錯誤處理

**下一步建議：**
- 📊 收集更多標註資料
- 🧪 測試模型準確率
- 🔄 建立自動更新機制
- 📈 追蹤使用者修正以改善模型

---

**相關文件：**
- `MLModelTestView.swift` - 測試介面
- `TrainingDataExportView.swift` - 資料匯出
- `LearningService.swift` - 標籤學習服務
