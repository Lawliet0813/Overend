import Foundation

/// 學習系統的數據模型
/// 用於儲存標籤學習的權重與統計數據
struct LearningData: Codable {
    /// 標籤模型： [標籤名: [關鍵字: 出現次數]]
    /// 記錄每個標籤與特定關鍵字的關聯強度
    var tagModels: [String: [String: Int]] = [:]
    
    /// 標籤總使用次數： [標籤名: 次數]
    /// 用於正規化或計算標籤的熱門程度
    var tagUsageCounts: [String: Int] = [:]
    
    /// 總互動次數（用於計算成熟度）
    /// 每次使用者手動添加標籤或接受建議時增加
    var totalInteractions: Int = 0
    
    /// 總預測次數
    var totalPredictions: Int = 0
    
    /// 使用者接受預測的次數
    var acceptedPredictions: Int = 0
    
    /// 最近的學習活動記錄
    var recentActivities: [LearningActivity] = []
    
    /// 模型版本
    var version: Int = 1
    
    /// 最後更新時間
    var lastUpdated: Date = Date()
}

/// 學習活動記錄
struct LearningActivity: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date
    var type: ActivityType
    var description: String
    var relatedItemTitle: String
    
    enum ActivityType: String, Codable {
        case learnTag
        case predictTag
        case acceptSuggestion
        case rejectSuggestion
    }
}

/// 標籤預測結果
struct TagPrediction: Identifiable, Hashable {
    var id: String { tag }
    let tag: String
    let confidence: Double // 0.0 - 1.0
    let reason: String // e.g., "Based on keywords: 'learning', 'system'"
}
