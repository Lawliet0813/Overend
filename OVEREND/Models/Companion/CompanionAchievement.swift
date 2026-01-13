//
//  CompanionAchievement.swift
//  OVEREND
//
//  AI 夥伴成就系統
//

import Foundation

// MARK: - 成就類別

/// 成就類別
public enum AchievementCategory: String, CaseIterable, Codable {
    case library = "library"       // 文獻庫相關
    case writing = "writing"       // 寫作相關
    case ai = "ai"                 // AI 功能相關
    case streak = "streak"         // 連續使用相關
    case special = "special"       // 特殊成就
    
    public var displayName: String {
        switch self {
        case .library: return "文獻庫"
        case .writing: return "寫作"
        case .ai: return "AI 助手"
        case .streak: return "連續使用"
        case .special: return "特殊"
        }
    }
    
    public var icon: String {
        switch self {
        case .library: return "books.vertical"
        case .writing: return "pencil"
        case .ai: return "cpu"
        case .streak: return "flame"
        case .special: return "star"
        }
    }
}

// MARK: - 成就定義

/// 成就徽章
public struct Achievement: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let category: AchievementCategory
    public let icon: String
    public let requirement: Int
    public let xpReward: Int
    
    public init(
        id: String,
        title: String,
        description: String,
        category: AchievementCategory,
        icon: String,
        requirement: Int,
        xpReward: Int = 50
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.icon = icon
        self.requirement = requirement
        self.xpReward = xpReward
    }
    
    // MARK: - 預設成就列表
    
    public static let allAchievements: [Achievement] = [
        // 文獻庫成就
        Achievement(
            id: "first_import",
            title: "踏入學術殿堂",
            description: "匯入第一篇文獻",
            category: .library,
            icon: "🎉",
            requirement: 1,
            xpReward: 20
        ),
        Achievement(
            id: "import_10",
            title: "文獻收藏家",
            description: "匯入 10 篇文獻",
            category: .library,
            icon: "📚",
            requirement: 10,
            xpReward: 50
        ),
        Achievement(
            id: "import_100",
            title: "破萬引用",
            description: "匯入超過 100 篇文獻",
            category: .library,
            icon: "🏅",
            requirement: 100,
            xpReward: 200
        ),
        Achievement(
            id: "import_500",
            title: "文獻大師",
            description: "匯入超過 500 篇文獻",
            category: .library,
            icon: "🏆",
            requirement: 500,
            xpReward: 500
        ),
        
        // 寫作成就
        Achievement(
            id: "first_doc",
            title: "提筆揮毫",
            description: "創建第一份文稿",
            category: .writing,
            icon: "✍️",
            requirement: 1,
            xpReward: 20
        ),
        Achievement(
            id: "write_10000",
            title: "萬字達人",
            description: "累計寫作 10,000 字",
            category: .writing,
            icon: "📝",
            requirement: 10000,
            xpReward: 100
        ),
        Achievement(
            id: "export_paper",
            title: "論文出爐",
            description: "成功匯出第一篇論文",
            category: .writing,
            icon: "📄",
            requirement: 1,
            xpReward: 100
        ),
        
        // AI 相關成就
        Achievement(
            id: "ai_suggestion_10",
            title: "AI 好夥伴",
            description: "採納 10 次 AI 建議",
            category: .ai,
            icon: "🤖",
            requirement: 10,
            xpReward: 50
        ),
        Achievement(
            id: "ai_suggestion_50",
            title: "人機合一",
            description: "採納 50 次 AI 建議",
            category: .ai,
            icon: "🧠",
            requirement: 50,
            xpReward: 150
        ),
        Achievement(
            id: "format_fix_50",
            title: "格式潔癖",
            description: "修正 50 個引用格式問題",
            category: .ai,
            icon: "🛠️",
            requirement: 50,
            xpReward: 100
        ),
        
        // 連續使用成就
        Achievement(
            id: "streak_7",
            title: "筆耕不輟",
            description: "連續 7 天開啟應用程式",
            category: .streak,
            icon: "🔥",
            requirement: 7,
            xpReward: 100
        ),
        Achievement(
            id: "streak_30",
            title: "月之勇者",
            description: "連續 30 天開啟應用程式",
            category: .streak,
            icon: "🌟",
            requirement: 30,
            xpReward: 300
        ),
        Achievement(
            id: "streak_100",
            title: "百日維新",
            description: "連續 100 天開啟應用程式",
            category: .streak,
            icon: "💎",
            requirement: 100,
            xpReward: 1000
        ),
        
        // 特殊成就
        Achievement(
            id: "night_owl",
            title: "夜貓子",
            description: "在午夜 12 點後使用 OVEREND",
            category: .special,
            icon: "🦉",
            requirement: 1,
            xpReward: 30
        ),
        Achievement(
            id: "early_bird",
            title: "早起的鳥兒",
            description: "在早上 6 點前使用 OVEREND",
            category: .special,
            icon: "🌅",
            requirement: 1,
            xpReward: 30
        )
    ]
}

// MARK: - 用戶成就進度

/// 單項成就的解鎖狀態
public struct AchievementProgress: Identifiable, Codable {
    public let id: String  // 對應 Achievement.id
    public var currentProgress: Int
    public var isUnlocked: Bool
    public var unlockedAt: Date?
    
    public init(
        id: String,
        currentProgress: Int = 0,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.currentProgress = currentProgress
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
    
    /// 計算完成百分比
    public func progressPercentage(for achievement: Achievement) -> Double {
        guard achievement.requirement > 0 else { return 1.0 }
        return min(1.0, Double(currentProgress) / Double(achievement.requirement))
    }
}

// MARK: - 每日任務

/// 每日挑戰任務
public struct DailyChallenge: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let icon: String
    public let targetCount: Int
    public var currentCount: Int
    public let xpReward: Int
    public let date: Date
    
    public var isCompleted: Bool {
        currentCount >= targetCount
    }
    
    public var progress: Double {
        guard targetCount > 0 else { return 1.0 }
        return min(1.0, Double(currentCount) / Double(targetCount))
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        targetCount: Int,
        currentCount: Int = 0,
        xpReward: Int = 50,
        date: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.xpReward = xpReward
        self.date = date
    }
    
    // MARK: - 隨機生成每日任務
    
    public static func generateDaily() -> [DailyChallenge] {
        let challenges = [
            DailyChallenge(
                title: "閱讀摘要",
                description: "閱讀一篇文獻摘要",
                icon: "📖",
                targetCount: 1,
                xpReward: 10
            ),
            DailyChallenge(
                title: "勤勞寫手",
                description: "寫作超過 500 字",
                icon: "✍️",
                targetCount: 500,
                xpReward: 30
            ),
            DailyChallenge(
                title: "整理達人",
                description: "整理 5 篇未分類文獻",
                icon: "🗂️",
                targetCount: 5,
                xpReward: 20
            ),
            DailyChallenge(
                title: "引用高手",
                description: "完成 3 次引用插入",
                icon: "📎",
                targetCount: 3,
                xpReward: 15
            ),
            DailyChallenge(
                title: "AI 協作",
                description: "採納 2 次 AI 建議",
                icon: "🤖",
                targetCount: 2,
                xpReward: 20
            )
        ]
        
        // 隨機選取 3 個任務
        return Array(challenges.shuffled().prefix(3))
    }
}
