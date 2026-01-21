//
//  LiteratureClassifierService.swift
//  OVEREND
//
//  Core ML 文獻分類服務 - 使用已訓練好的模型進行推理
//  支援自動偵測文獻類型：期刊論文、會議論文、學位論文、書籍章節
//

import Foundation
import CoreML
import NaturalLanguage
import Combine
import SwiftUI

/// Core ML 文獻分類服務
class LiteratureClassifierService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LiteratureClassifierService()
    
    // MARK: - Published Properties
    
    @Published var isModelLoaded = false
    @Published var modelVersion = "1.0.0"
    @Published var lastError: String?
    
    // MARK: - Private Properties
    
    private var nlModel: NLModel?
    private var predictionCache: [String: LiteraturePrediction] = [:]
    private let cacheLimit = 100 // 最多快取 100 個預測結果
    
    // 模型檔名（根據實際檔案名稱調整）
    private let modelResourceName = "LiteratureClassifier" // 不含 .mlmodel 副檔名
    
    // MARK: - Initialization
    
    private init() {
        loadModel()
    }
    
    // MARK: - Model Loading
    
    /// 載入 Core ML 模型
    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            
            // 方法 1: 直接使用編譯後的模型（推薦）
            if let modelURL = Bundle.main.url(
                forResource: modelResourceName,
                withExtension: "mlmodelc"
            ) {
                let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
                self.nlModel = try NLModel(mlModel: mlModel)
                self.isModelLoaded = true
                
                print("✅ [LiteratureClassifier] 模型載入成功")
                print("📍 [LiteratureClassifier] 模型位置: \(modelURL.path)")
                
                self.lastError = nil
                
            } else {
                // 模型檔案未找到
                let errorMsg = "找不到模型檔案：\(modelResourceName).mlmodelc"
                print("❌ [LiteratureClassifier] \(errorMsg)")
                print("💡 [LiteratureClassifier] 請確認：")
                print("   1. 已將 .mlmodel 檔案加入專案")
                print("   2. Target Membership 已勾選 OVEREND")
                print("   3. 檔案名稱為 '\(modelResourceName).mlmodel'")
                print("   4. 已重新編譯專案 (⌘B)")
                
                self.lastError = errorMsg
                self.isModelLoaded = false
            }
            
        } catch {
            let errorMsg = "模型載入失敗: \(error.localizedDescription)"
            print("❌ [LiteratureClassifier] \(errorMsg)")
            self.lastError = errorMsg
            self.isModelLoaded = false
        }
    }
    
    /// 重新載入模型（用於模型更新後）
    func reloadModel() {
        predictionCache.removeAll()
        loadModel()
    }
    
    // MARK: - Prediction Methods
    
    /// 預測文獻類型（單一結果）
    /// - Parameter text: 文獻描述文字（標題、作者、出版資訊等）
    /// - Returns: 預測結果，若失敗則回傳 nil
    func predict(text: String) -> LiteraturePrediction? {
        guard isModelLoaded, let model = nlModel else {
            print("⚠️ [LiteratureClassifier] 模型未載入，無法執行預測")
            return nil
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [LiteratureClassifier] 輸入文字為空")
            return nil
        }
        
        // 檢查快取
        if let cached = predictionCache[text] {
            #if DEBUG
            print("🎯 [LiteratureClassifier] 使用快取結果")
            #endif
            return cached
        }
        
        // 執行預測
        guard let label = model.predictedLabel(for: text) else {
            print("❌ [LiteratureClassifier] 預測失敗")
            return nil
        }
        
        // 取得所有機率
        let hypotheses = model.predictedLabelHypotheses(
            for: text,
            maximumCount: 10 // 取得所有可能的結果
        ) ?? [:]
        
        let confidence = hypotheses[label] ?? 0.0
        
        let prediction = LiteraturePrediction(
            label: label,
            confidence: confidence,
            allProbabilities: hypotheses
        )
        
        // 儲存到快取
        cacheResult(text: text, prediction: prediction)
        
        #if DEBUG
        print("✅ [LiteratureClassifier] 預測完成")
        print("   輸入: \(text.prefix(50))...")
        print("   結果: \(prediction.displayName)")
        print("   信心度: \(Int(confidence * 100))%")
        #endif
        
        return prediction
    }
    
    /// 預測文獻類型（Top N 結果）
    /// - Parameters:
    ///   - text: 文獻描述文字
    ///   - n: 回傳前 N 個結果
    /// - Returns: 排序後的預測結果陣列
    func predictTopN(text: String, n: Int = 3) -> [LiteraturePrediction] {
        guard isModelLoaded, let model = nlModel else {
            return []
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let hypotheses = model.predictedLabelHypotheses(
            for: text,
            maximumCount: max(n, 10)
        ) ?? [:]
        
        return hypotheses
            .sorted { $0.value > $1.value }
            .prefix(n)
            .map { (label, confidence) in
                LiteraturePrediction(
                    label: label,
                    confidence: confidence,
                    allProbabilities: hypotheses
                )
            }
    }
    
    /// 非同步預測（避免 UI 卡頓）
    /// - Parameters:
    ///   - text: 文獻描述文字
    ///   - completion: 完成回呼
    func predictAsync(text: String, completion: @escaping (LiteraturePrediction?) -> Void) {
        Task.detached(priority: .userInitiated) {
            let result = self.predict(text: text)
            
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    // MARK: - Cache Management
    
    private func cacheResult(text: String, prediction: LiteraturePrediction) {
        // 如果快取已滿，移除最舊的項目
        if predictionCache.count >= cacheLimit {
            // 簡單策略：清空一半
            let keysToRemove = Array(predictionCache.keys.prefix(cacheLimit / 2))
            keysToRemove.forEach { predictionCache.removeValue(forKey: $0) }
        }
        
        predictionCache[text] = prediction
    }
    
    func clearCache() {
        predictionCache.removeAll()
    }
    
    // MARK: - Utility Methods
    
    /// 從 Entry 物件建立描述文字（用於預測）
    func buildDescription(from entry: Entry) -> String {
        var parts: [String] = []
        
        // 標題
        let title = entry.title
        if !title.isEmpty && title != "Untitled" {
            parts.append(title)
        }
        
        // 作者
        let author = entry.author
        if !author.isEmpty && author != "Unknown" {
            parts.append(author)
        }
        
        // 期刊
        if let journal = entry.fields["journal"], !journal.isEmpty {
            parts.append("發表於《\(journal)》")
        }
        
        // 會議
        if let booktitle = entry.fields["booktitle"], !booktitle.isEmpty {
            parts.append("收錄於《\(booktitle)》")
        }
        
        // 學校（論文）
        if let school = entry.fields["school"], !school.isEmpty {
            parts.append(school)
        }
        
        // 書名
        if let bookTitle = entry.fields["title"], !bookTitle.isEmpty {
            parts.append("載於《\(bookTitle)》")
        }
        
        // 年份
        if let year = Int(entry.year), year > 0 {
            parts.append("\(year)年")
        }
        
        return parts.joined(separator: "，")
    }
    
    /// 批次預測（適用於大量資料）
    /// - Parameters:
    ///   - entries: Entry 陣列
    ///   - progress: 進度回呼（0.0 - 1.0）
    ///   - completion: 完成回呼（成功數量）
    func batchPredict(
        entries: [Entry],
        progress: @escaping (Double) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        Task.detached(priority: .userInitiated) {
            var successCount = 0
            let total = entries.count
            
            for (index, entry) in entries.enumerated() {
                let description = self.buildDescription(from: entry)
                
                if let prediction = self.predict(text: description),
                   prediction.confidence > 0.6 {
                    
                    await MainActor.run {
                        entry.entryType = prediction.label
                        successCount += 1
                    }
                }
                
                // 更新進度
                let currentProgress = Double(index + 1) / Double(total)
                await MainActor.run {
                    progress(currentProgress)
                }
                
                // 避免過快執行
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 秒
            }
            
            await MainActor.run {
                completion(successCount)
            }
        }
    }
}

// MARK: - Data Models

/// 文獻類型預測結果
struct LiteraturePrediction: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Double
    let allProbabilities: [String: Double]
    
    /// 顯示名稱（中文）
    var displayName: String {
        switch label {
        case "Journal Article": return "期刊論文"
        case "Conference Paper": return "會議論文"
        case "Thesis": return "學位論文"
        case "Book Chapter": return "書籍章節"
        case "Book": return "書籍"
        case "Technical Report": return "技術報告"
        case "Working Paper": return "工作論文"
        default: return label
        }
    }
    
    /// SF Symbol 圖示
    var icon: String {
        switch label {
        case "Journal Article": return "doc.text"
        case "Conference Paper": return "person.3"
        case "Thesis": return "graduationcap"
        case "Book Chapter": return "book.closed"
        case "Book": return "book"
        case "Technical Report": return "doc.plaintext"
        case "Working Paper": return "doc.badge.gearshape"
        default: return "questionmark.circle"
        }
    }
    
    /// 顏色
    var color: Color {
        switch label {
        case "Journal Article": return .blue
        case "Conference Paper": return .green
        case "Thesis": return .orange
        case "Book Chapter": return .purple
        case "Book": return .red
        case "Technical Report": return .cyan
        case "Working Paper": return .yellow
        default: return .gray
        }
    }
    
    /// 信心度等級
    var confidenceLevel: ConfidenceLevel {
        if confidence > 0.9 { return .high }
        if confidence > 0.7 { return .medium }
        return .low
    }
    
    enum ConfidenceLevel {
        case high, medium, low
        
        var description: String {
            switch self {
            case .high: return "高度確信"
            case .medium: return "中等確信"
            case .low: return "低確信"
            }
        }
        
        var emoji: String {
            switch self {
            case .high: return "🎯"
            case .medium: return "✅"
            case .low: return "⚠️"
            }
        }
    }
    
    // Equatable 實作
    static func == (lhs: LiteraturePrediction, rhs: LiteraturePrediction) -> Bool {
        lhs.label == rhs.label && lhs.confidence == rhs.confidence
    }
}

// MARK: - SwiftUI Extensions

/// 預測結果卡片元件
struct LiteraturePredictionCard: View {
    @EnvironmentObject var theme: AppTheme
    let prediction: LiteraturePrediction
    var onAccept: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題列
            HStack {
                Image(systemName: prediction.icon)
                    .font(.title2)
                    .foregroundColor(prediction.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.displayName)
                        .font(theme.fontDisplaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    
                    HStack(spacing: 4) {
                        Text(prediction.confidenceLevel.emoji)
                        Text(prediction.confidenceLevel.description)
                        Text("•")
                        Text("\(Int(prediction.confidence * 100))%")
                    }
                    .font(theme.fontBodySmall)
                    .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
            }
            
            // 信心度條
            ProgressView(value: prediction.confidence)
                .tint(prediction.color)
            
            // 其他可能結果
            if prediction.allProbabilities.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("其他可能：")
                        .font(theme.fontBodySmall)
                        .foregroundColor(theme.textTertiary)
                    
                    ForEach(
                        prediction.allProbabilities
                            .filter { $0.key != prediction.label }
                            .sorted { $0.value > $1.value }
                            .prefix(2),
                        id: \.key
                    ) { label, prob in
                        HStack {
                            Text(mapLabelToDisplayName(label))
                                .font(theme.fontBodySmall)
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                            Text("\(Int(prob * 100))%")
                                .font(theme.fontBodySmall)
                                .foregroundColor(theme.textTertiary)
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            // 操作按鈕
            if let onAccept = onAccept {
                Button {
                    onAccept()
                } label: {
                    Text("接受此分類")
                        .font(theme.fontButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(theme.cornerRadiusSM)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(theme.card)
        .cornerRadius(theme.cornerRadiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                .stroke(prediction.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func mapLabelToDisplayName(_ label: String) -> String {
        LiteraturePrediction(
            label: label,
            confidence: 0,
            allProbabilities: [:]
        ).displayName
    }
}

// MARK: - Preview

#Preview("Prediction Card") {
    LiteraturePredictionCard(
        prediction: LiteraturePrediction(
            label: "Journal Article",
            confidence: 0.92,
            allProbabilities: [
                "Journal Article": 0.92,
                "Conference Paper": 0.05,
                "Book Chapter": 0.03
            ]
        )
    )
    .environmentObject(AppTheme())
    .padding()
    .frame(width: 400)
}
