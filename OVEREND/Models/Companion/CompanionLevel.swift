//
//  CompanionLevel.swift
//  OVEREND
//
//  AI 夥伴等級與經驗值系統
//

import Foundation

// MARK: - 等級里程碑

/// 等級定義與解鎖功能
public enum CompanionLevel: Int, CaseIterable, Comparable, Codable {
    case newbie = 1         // 研究新手
    case reader = 5         // 認真讀者
    case librarian = 10     // 文獻管理師
    case writer = 20        // 學術寫手
    case expert = 30        // 論文達人
    case master = 50        // 學術大師
    
    public var title: String {
        switch self {
        case .newbie: return "研究新手"
        case .reader: return "認真讀者"
        case .librarian: return "文獻管理師"
        case .writer: return "學術寫手"
        case .expert: return "論文達人"
        case .master: return "學術大師"
        }
    }
    
    public var unlockedFeatures: [String] {
        switch self {
        case .newbie: return ["基礎 AI 建議"]
        case .reader: return ["智慧分類功能", "每日任務"]
        case .librarian: return ["批次工作流", "研究統計"]
        case .writer: return ["進階寫作潤飾", "風格分析"]
        case .expert: return ["研究洞察引擎", "知識圖譜"]
        case .master: return ["小研的全部表情包", "專屬成就"]
        }
    }
    
    public var requiredXP: Int {
        switch self {
        case .newbie: return 0
        case .reader: return 500
        case .librarian: return 1500
        case .writer: return 4000
        case .expert: return 8000
        case .master: return 20000
        }
    }
    
    public var icon: String {
        switch self {
        case .newbie: return "🌱"
        case .reader: return "📖"
        case .librarian: return "🗂️"
        case .writer: return "✍️"
        case .expert: return "🎓"
        case .master: return "👑"
        }
    }
    
    public static func < (lhs: CompanionLevel, rhs: CompanionLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    /// 根據經驗值計算當前等級
    public static func level(for xp: Int) -> CompanionLevel {
        let levels = CompanionLevel.allCases.sorted { $0.rawValue > $1.rawValue }
        for level in levels {
            if xp >= level.requiredXP {
                return level
            }
        }
        return .newbie
    }
}

// MARK: - 經驗值來源

/// 獲得經驗值的行為類型
public enum XPSource: String, CaseIterable, Codable {
    case importEntry = "import_entry"       // 匯入文獻 +10
    case completeCitation = "complete_citation"  // 完成引用 +5
    case write1000Words = "write_1000_words"    // 寫作 1000 字 +20
    case acceptSuggestion = "accept_suggestion"  // 採納 AI 建議 +15
    case dailyChallenge = "daily_challenge"      // 完成每日任務 +50
    case exportPaper = "export_paper"           // 論文匯出成功 +100
    case streak = "streak"                      // 連續使用獎勵
    
    public var xpAmount: Int {
        switch self {
        case .importEntry: return 10
        case .completeCitation: return 5
        case .write1000Words: return 20
        case .acceptSuggestion: return 15
        case .dailyChallenge: return 50
        case .exportPaper: return 100
        case .streak: return 25
        }
    }
    
    public var displayName: String {
        switch self {
        case .importEntry: return "匯入文獻"
        case .completeCitation: return "完成引用"
        case .write1000Words: return "寫作 1000 字"
        case .acceptSuggestion: return "採納 AI 建議"
        case .dailyChallenge: return "每日任務"
        case .exportPaper: return "論文匯出"
        case .streak: return "連續使用"
        }
    }
    
    public var icon: String {
        switch self {
        case .importEntry: return "doc.badge.plus"
        case .completeCitation: return "quote.bubble"
        case .write1000Words: return "pencil.line"
        case .acceptSuggestion: return "checkmark.circle"
        case .dailyChallenge: return "star.fill"
        case .exportPaper: return "doc.richtext"
        case .streak: return "flame.fill"
        }
    }
}

// MARK: - 經驗值記錄

/// 單筆經驗值獲得記錄
public struct XPGain: Identifiable, Codable {
    public let id: UUID
    public let source: XPSource
    public let amount: Int
    public let timestamp: Date
    public let description: String?
    
    public init(
        id: UUID = UUID(),
        source: XPSource,
        amount: Int? = nil,
        timestamp: Date = Date(),
        description: String? = nil
    ) {
        self.id = id
        self.source = source
        self.amount = amount ?? source.xpAmount
        self.timestamp = timestamp
        self.description = description
    }
}

// MARK: - 用戶進度

/// 用戶的等級進度資料
public struct UserProgress: Codable {
    public var totalXP: Int
    public var currentLevel: CompanionLevel
    public var xpHistory: [XPGain]
    public var streakDays: Int
    public var lastActiveDate: Date?
    
    public init(
        totalXP: Int = 0,
        currentLevel: CompanionLevel = .newbie,
        xpHistory: [XPGain] = [],
        streakDays: Int = 0,
        lastActiveDate: Date? = nil
    ) {
        self.totalXP = totalXP
        self.currentLevel = currentLevel
        self.xpHistory = xpHistory
        self.streakDays = streakDays
        self.lastActiveDate = lastActiveDate
    }
    
    /// 計算距離下一等級的進度（0.0 - 1.0）
    public var progressToNextLevel: Double {
        let levels = CompanionLevel.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let currentIndex = levels.firstIndex(of: currentLevel),
              currentIndex + 1 < levels.count else {
            return 1.0 // 已達最高等級
        }
        
        let nextLevel = levels[currentIndex + 1]
        let currentRequired = currentLevel.requiredXP
        let nextRequired = nextLevel.requiredXP
        let range = nextRequired - currentRequired
        let progress = totalXP - currentRequired
        
        return min(1.0, max(0.0, Double(progress) / Double(range)))
    }
    
    /// 距離下一等級所需經驗值
    public var xpToNextLevel: Int {
        let levels = CompanionLevel.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let currentIndex = levels.firstIndex(of: currentLevel),
              currentIndex + 1 < levels.count else {
            return 0
        }
        return levels[currentIndex + 1].requiredXP - totalXP
    }
    
    /// 新增經驗值
    public mutating func addXP(from source: XPSource, withDescription description: String? = nil) -> (gain: XPGain, levelUp: Bool) {
        let gain = XPGain(source: source, description: description)
        totalXP += gain.amount
        xpHistory.append(gain)
        
        // 檢查是否升級
        let newLevel = CompanionLevel.level(for: totalXP)
        let levelUp = newLevel.rawValue > currentLevel.rawValue
        currentLevel = newLevel
        
        return (gain, levelUp)
    }
    
    /// 更新連續使用天數
    public mutating func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                streakDays += 1
            } else if daysDiff > 1 {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }
        
        lastActiveDate = Date()
    }
}
