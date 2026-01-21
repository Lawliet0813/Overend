#if false
import SwiftUI
import CoreML
import NaturalLanguage

/// Core ML 模型測試視圖
struct MLModelTestView: View {
    @State private var inputText = ""
    @State private var prediction = ""
    @State private var confidence: Double = 0.0
    @State private var isModelLoaded = false
    @State private var errorMessage = ""
    
    private var nlModel: NLModel?
    
    init() {
        loadModel()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題
            HStack {
                Image(systemName: isModelLoaded ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isModelLoaded ? .green : .red)
                Text("文獻分類模型測試")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            if !isModelLoaded {
                VStack(spacing: 12) {
                    Text("⚠️ 模型未載入")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text(errorMessage.isEmpty ? "請確認已將 PDF_TRAIN 1.mlmodel 加入專案" : errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("匯入步驟：")
                            .font(.headline)
                        Text("1. 在 Create ML 的 Output 分頁找到模型檔案")
                        Text("2. 拖曳 PDF_TRAIN 1.mlmodel 到 Xcode")
                        Text("3. 放入 OVEREND/Models/ 資料夾")
                        Text("4. 確認 Target Membership 勾選 OVEREND")
                        Text("5. 重新編譯專案 (Cmd+B)")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            } else {
                // 測試介面
                VStack(alignment: .leading, spacing: 12) {
                    Text("輸入文獻描述：")
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .font(.body)
                    
                    Button(action: classifyText) {
                        Label("分類", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(inputText.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(inputText.isEmpty)
                }
                
                // 預測結果
                if !prediction.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("預測結果：")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: iconForType(prediction))
                                .font(.title)
                                .foregroundColor(colorForType(prediction))
                            
                            VStack(alignment: .leading) {
                                Text(displayName(prediction))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("信心度：\(Int(confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                // 快速測試範例
                VStack(alignment: .leading, spacing: 8) {
                    Text("快速測試範例：")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            QuickTestButton(
                                text: "發表於《行政管理學報》第30卷第2期",
                                inputText: $inputText
                            )
                            
                            QuickTestButton(
                                text: "收錄於2024年台灣公共行政與公共事務系所聯合會年會論文集",
                                inputText: $inputText
                            )
                            
                            QuickTestButton(
                                text: "國立政治大學公共行政學系碩士論文",
                                inputText: $inputText
                            )
                            
                            QuickTestButton(
                                text: "載於張三主編《當代公共管理》第五章",
                                inputText: $inputText
                            )
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(30)
        .frame(minWidth: 700, minHeight: 600)
    }
    
    
    // MARK: - 方法
    
    private mutating func loadModel() {
        do {
            // ⚠️ 重要：替換成你的模型名稱
            // Xcode 會將 "PDF_TRAIN 1.mlmodel" 編譯成 "PDF_TRAIN_1" 類別
            
            let config = MLModelConfiguration()
            
            // 嘗試載入模型（名稱可能是這些其中之一）
            if let modelURL = Bundle.main.url(forResource: "PDF_TRAIN_1", withExtension: "mlmodelc") {
                let compiledModel = try MLModel(contentsOf: modelURL, configuration: config)
                self.nlModel = try NLModel(mlModel: compiledModel)
                self._isModelLoaded = State(initialValue: true)
                print("✅ 模型載入成功")
            } else {
                self._errorMessage = State(initialValue: "找不到模型檔案：PDF_TRAIN_1.mlmodelc")
                print("❌ 找不到模型檔案")
            }
            
        } catch {
            self._errorMessage = State(initialValue: "載入失敗：\(error.localizedDescription)")
            print("❌ 模型載入失敗: \(error)")
        }
    }
    
    private func classifyText() {
        guard let model = nlModel else {
            prediction = "模型未載入"
            return
        }
        
        // 使用模型進行預測
        if let predictedLabel = model.predictedLabel(for: inputText) {
            prediction = predictedLabel
            
            // 取得信心度
            if let labelHypotheses = model.predictedLabelHypotheses(for: inputText, maximumCount: 1) {
                confidence = labelHypotheses[predictedLabel] ?? 0.0
            }
        } else {
            prediction = "無法分類"
        }
    }
    
    private func displayName(_ type: String) -> String {
        switch type {
        case "Journal Article": return "期刊論文"
        case "Conference Paper": return "會議論文"
        case "Thesis": return "學位論文"
        case "Book Chapter": return "書籍章節"
        default: return type
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "Journal Article": return "doc.text"
        case "Conference Paper": return "person.3"
        case "Thesis": return "graduationcap"
        case "Book Chapter": return "book.closed"
        default: return "questionmark"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type {
        case "Journal Article": return .blue
        case "Conference Paper": return .green
        case "Thesis": return .orange
        case "Book Chapter": return .purple
        default: return .gray
        }
    }
}


// MARK: - 子元件

struct QuickTestButton: View {
    let text: String
    @Binding var inputText: String
    
    var body: some View {
        Button(action: { inputText = text }) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    MLModelTestView()
}
#endif
