import Foundation
import Combine

class LearningService: ObservableObject {
    static let shared = LearningService()
    
    @Published var learningData: LearningData
    @Published var maturityLevel: Double = 0.0 // 0.0 - 1.0
    
    private let storageKey = "OverendLearningData"
    private let minInteractionsForPrediction = 5 // 降低門檻以便測試，正式版可設為 10
    
    // 停用詞列表 (英文 + 常見學術用語)
    private let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
        "is", "are", "was", "were", "be", "been", "being",
        "this", "that", "these", "those",
        "from", "as", "about", "into", "through", "during", "including",
        "study", "analysis", "using", "based", "approach", "method", "system"
    ]
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // 嘗試從 UserDefaults 載入數據
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(LearningData.self, from: data) {
            self.learningData = decoded
        } else {
            self.learningData = LearningData()
        }
        
        updateMaturityLevel()
    }
    
    // MARK: - Public API
    
    /// 學習標籤行為
    /// 當使用者為文獻添加標籤時呼叫
    func learnTagging(title: String, tags: [String]) {
        guard !tags.isEmpty else { return }
        
        let keywords = extractKeywords(from: title)
        guard !keywords.isEmpty else { return }
        
        // 背景執行學習過程
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                var updated = false
                
                for tag in tags {
                    // 更新標籤使用計數
                    self.learningData.tagUsageCounts[tag, default: 0] += 1
                    
                    // 更新關鍵字權重
                    var tagModel = self.learningData.tagModels[tag] ?? [:]
                    for keyword in keywords {
                        tagModel[keyword, default: 0] += 1
                    }
                    self.learningData.tagModels[tag] = tagModel
                    updated = true
                }
                
                if updated {
                    self.learningData.totalInteractions += 1
                    self.learningData.lastUpdated = Date()
                    self.addActivity(type: .learnTag, description: "Learned tags: \(tags.joined(separator: ", "))", relatedTitle: title)
                    self.saveData()
                    self.updateMaturityLevel()
                }
            }
        }
    }
    
    /// 預測標籤
    /// 輸入文獻標題，回傳建議標籤
    func predictTags(for title: String) -> [TagPrediction] {
        // 檢查是否達到學習門檻
        guard learningData.totalInteractions >= minInteractionsForPrediction else {
            return []
        }
        
        let keywords = extractKeywords(from: title)
        guard !keywords.isEmpty else { return [] }
        
        var scores: [String: Double] = [:]
        var matchReasons: [String: [String]] = [:] // Tag -> Matched Keywords
        
        // 計算每個標籤的得分
        for (tag, model) in learningData.tagModels {
            var score = 0.0
            var matched: [String] = []
            
            for keyword in keywords {
                if let count = model[keyword] {
                    // 簡單加權：關鍵字出現次數
                    score += Double(count)
                    matched.append(keyword)
                }
            }
            
            // 如果有匹配到關鍵字
            if score > 0 {
                // 根據標籤總使用次數進行微調 (Penalize very rare tags slightly, or boost popular ones?)
                // 這裡暫時只用關鍵字匹配分數
                scores[tag] = score
                matchReasons[tag] = matched
            }
        }
        
        // 排序並取前 3 名
        let sortedTags = scores.sorted { $0.value > $1.value }.prefix(3)
        
        // 轉換為 TagPrediction
        let predictions = sortedTags.map { (tag, score) -> TagPrediction in
            // 正規化信心度 (這只是一個粗略的估計)
            // 假設最高分通常在 10 左右，超過 10 就算很高
            let confidence = min(score / 10.0, 0.95)
            let keywordsStr = matchReasons[tag]?.joined(separator: ", ") ?? ""
            
            return TagPrediction(
                tag: tag,
                confidence: confidence,
                reason: "Matches: \(keywordsStr)"
            )
        }
        
        // 記錄預測活動
        if !predictions.isEmpty {
            learningData.totalPredictions += 1
            // 這裡不存檔，避免頻繁寫入，僅在學習或接受時存檔
        }
        
        return predictions
    }
    
    /// 記錄使用者反饋
    func recordFeedback(accepted: Bool, tags: [String], for title: String) {
        if accepted {
            learningData.acceptedPredictions += 1
            // 接受建議視為一次強化學習
            learnTagging(title: title, tags: tags)
            addActivity(type: .acceptSuggestion, description: "Accepted: \(tags.joined(separator: ", "))", relatedTitle: title)
        } else {
            addActivity(type: .rejectSuggestion, description: "Ignored suggestions", relatedTitle: title)
        }
        saveData()
    }
    
    /// 清除所有數據
    func clearData() {
        learningData = LearningData()
        saveData()
        updateMaturityLevel()
    }
    
    /// 匯出數據為 JSON 字串
    func exportDataJSON() -> String? {
        guard let data = try? JSONEncoder().encode(learningData) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Private Helpers
    
    private func extractKeywords(from text: String) -> [String] {
        let range = text.startIndex..<text.endIndex
        var keywords: [String] = []
        
        text.enumerateSubstrings(in: range, options: [.byWords, .localized]) { substring, _, _, _ in
            if let word = substring?.lowercased() {
                // 過濾條件：長度 > 2 且不在停用詞表中
                if word.count > 2 && !self.stopWords.contains(word) {
                    keywords.append(word)
                }
            }
        }
        
        return keywords
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(learningData) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
    
    private func updateMaturityLevel() {
        // 簡單的成熟度計算：基於互動次數
        // 0-10: 初學
        // 10-50: 成長
        // 50+: 成熟
        let interactions = Double(learningData.totalInteractions)
        let level = min(interactions / 50.0, 1.0)
        self.maturityLevel = level
    }
    
    private func addActivity(type: LearningActivity.ActivityType, description: String, relatedTitle: String) {
        let activity = LearningActivity(timestamp: Date(), type: type, description: description, relatedItemTitle: relatedTitle)
        // 只保留最近 20 筆
        learningData.recentActivities.insert(activity, at: 0)
        if learningData.recentActivities.count > 20 {
            learningData.recentActivities.removeLast()
        }
    }
}
