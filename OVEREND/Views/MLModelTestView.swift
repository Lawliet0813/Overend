import SwiftUI
import CoreML
import NaturalLanguage

/// Core ML 模型測試視圖
struct MLModelTestView: View {
    @EnvironmentObject var theme: AppTheme
    @StateObject private var classifier = LiteratureClassifierService.shared
    
    @State private var inputText = ""
    @State private var prediction: LiteraturePrediction?
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題
            HStack {
                Image(systemName: classifier.isModelLoaded ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(classifier.isModelLoaded ? .green : .red)
                Text("文獻分類模型測試")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            if !classifier.isModelLoaded {
                // 模型未載入提示
                modelNotLoadedView
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
                    
                    Button {
                        classifyText()
                    } label: {
                        Label(isAnalyzing ? "分析中..." : "AI 分類", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(inputText.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(inputText.isEmpty || isAnalyzing)
                }
                
                // 預測結果
                if let result = prediction {
                    LiteraturePredictionCard(prediction: result)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // 快速測試範例
                quickTestExamples
            }
            
            Spacer()
        }
        .padding(30)
        .frame(minWidth: 700, minHeight: 600)
    }
    
    // MARK: - 子視圖
    
    private var modelNotLoadedView: some View {
        VStack(spacing: 12) {
            Text("⚠️ 模型未載入")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text(classifier.lastError ?? "請確認已將模型檔案加入專案")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("匯入步驟：")
                    .font(.headline)
                Text("1. 在 Create ML 的 Output 分頁找到模型檔案")
                Text("2. 拖曳 LiteratureClassifier.mlmodel 到 Xcode")
                Text("3. 放入 OVEREND/Models/ 資料夾")
                Text("4. 確認 Target Membership 勾選 OVEREND")
                Text("5. 重新編譯專案 (⌘B)")
            }
            .font(.caption)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button {
                classifier.reloadModel()
            } label: {
                Label("重新載入模型", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private var quickTestExamples: some View {
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
    
    // MARK: - 方法
    
    private func classifyText() {
        isAnalyzing = true
        prediction = nil
        
        // 使用 LiteratureClassifierService 執行預測
        classifier.predictAsync(text: inputText) { result in
            withAnimation(.spring(response: 0.3)) {
                self.prediction = result
                self.isAnalyzing = false
            }
        }
    }
}

// MARK: - 子元件

struct QuickTestButton: View {
    let text: String
    @Binding var inputText: String
    
    var body: some View {
        Button {
            inputText = text
        } label: {
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
        .environmentObject(AppTheme())
}

