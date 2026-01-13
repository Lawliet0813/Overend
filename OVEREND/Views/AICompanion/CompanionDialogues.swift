//
//  CompanionDialogues.swift
//  OVEREND
//
//  AI 夥伴對話內容管理
//

import Foundation

// MARK: - 對話類型

/// 對話觸發類型
public enum DialogueTrigger: String, CaseIterable {
    // 時間觸發
    case morningGreeting = "morning_greeting"
    case afternoonGreeting = "afternoon_greeting"
    case eveningGreeting = "evening_greeting"
    case lateNightReminder = "late_night_reminder"
    case longTimeNoSee = "long_time_no_see"
    
    // 行為觸發
    case pdfImported = "pdf_imported"
    case writingProgress = "writing_progress"
    case noRecentCitation = "no_recent_citation"
    case duplicateDetected = "duplicate_detected"
    case taskCompleted = "task_completed"
    case levelUp = "level_up"
    case achievementUnlocked = "achievement_unlocked"
    case dailyChallengeComplete = "daily_challenge_complete"
    
    // 閒置觸發
    case idle = "idle"
    case encouragement = "encouragement"
}

// MARK: - 對話內容

/// 對話訊息
public struct DialogueMessage: Identifiable {
    public let id = UUID()
    public let trigger: DialogueTrigger
    public let message: String
    public let actionLabel: String?
    public let actionHandler: (() -> Void)?
    
    public init(
        trigger: DialogueTrigger,
        message: String,
        actionLabel: String? = nil,
        actionHandler: (() -> Void)? = nil
    ) {
        self.trigger = trigger
        self.message = message
        self.actionLabel = actionLabel
        self.actionHandler = actionHandler
    }
}

// MARK: - 對話庫

/// 對話內容管理器
public class CompanionDialogues {
    
    public static let shared = CompanionDialogues()
    
    // MARK: - 時間問候語
    
    /// 根據當前時間取得問候語
    public func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<9:
            return morningGreetings.randomElement() ?? "早安！"
        case 9..<12:
            return midMorningGreetings.randomElement() ?? "上午好！"
        case 12..<14:
            return noonGreetings.randomElement() ?? "午安！"
        case 14..<18:
            return afternoonGreetings.randomElement() ?? "下午好！"
        case 18..<22:
            return eveningGreetings.randomElement() ?? "晚上好！"
        case 22..<24, 0..<5:
            return lateNightReminders.randomElement() ?? "夜深了，注意休息喔！"
        default:
            return "嗨！"
        }
    }
    
    private let morningGreetings = [
        "早安！今天要繼續昨天的論文嗎？☀️",
        "早！新的一天，新的靈感~",
        "早安！我已經準備好幫你整理文獻了！",
        "Good morning! 今天想從哪裡開始？",
        "早安～咖啡準備好了嗎？我們開始吧！"
    ]
    
    private let midMorningGreetings = [
        "上午好！現在是寫作的黃金時間喔～",
        "嗨！需要我幫你找些參考文獻嗎？",
        "上午好！今天的進度如何？"
    ]
    
    private let noonGreetings = [
        "午安！記得吃飯休息一下喔～",
        "中午好！要不要先存個檔？",
        "午安～休息一下，等等繼續！"
    ]
    
    private let afternoonGreetings = [
        "下午好！下午茶時間到！🍵",
        "嗨！下午的精神還好嗎？",
        "下午好～需要我幫你什麼嗎？"
    ]
    
    private let eveningGreetings = [
        "晚上好！今天辛苦了～",
        "嗨！晚餐吃了嗎？",
        "晚上好～今天寫了不少喔！"
    ]
    
    private let lateNightReminders = [
        "已經很晚了...要不要先存檔休息？🌙",
        "夜深了，注意眼睛喔！",
        "熬夜傷身，記得休息～",
        "深夜的靈感特別好，但也要顧好身體喔！",
        "Zzz...我有點想睡了，你呢？"
    ]
    
    // MARK: - 行為觸發對話
    
    /// PDF 匯入後的對話
    public func getImportDialogue(topic: String?) -> String {
        if let topic = topic {
            let dialogues = [
                "這是一篇關於「\(topic)」的文獻，要我幫你分類嗎？",
                "新文獻到！看起來和「\(topic)」相關，要加標籤嗎？",
                "收到！這篇「\(topic)」的文獻，要放進哪個資料夾？"
            ]
            return dialogues.randomElement() ?? dialogues[0]
        } else {
            let dialogues = [
                "新文獻已匯入！要我幫你分析嗎？",
                "收到新 PDF！需要我提取關鍵資訊嗎？",
                "文獻入庫成功！要我幫你分類嗎？"
            ]
            return dialogues.randomElement() ?? dialogues[0]
        }
    }
    
    /// 寫作進度提醒
    public func getWritingProgressDialogue(wordCount: Int) -> String {
        let dialogues = [
            "太棒了！你已經寫了 \(wordCount) 字了！繼續加油～ 💪",
            "哇！\(wordCount) 字的進度，你真厲害！",
            "\(wordCount) 字達成！距離完成又近了一步！"
        ]
        return dialogues.randomElement() ?? dialogues[0]
    }
    
    /// 長時間未引用提醒
    public func getNoCitationDialogue(wordsSinceLastCitation: Int) -> String {
        let dialogues = [
            "你已經寫了 \(wordsSinceLastCitation) 字但還沒引用，需要找參考文獻嗎？",
            "這段落需要一些引用來支持論點嗎？我可以幫你找！",
            "要不要加個引用？這樣論述會更有說服力喔～"
        ]
        return dialogues.randomElement() ?? dialogues[0]
    }
    
    /// 偵測重複文獻
    public func getDuplicateDialogue(title: String) -> String {
        return "咦？「\(title)」好像已經匯入過了喔！要查看現有的嗎？"
    }
    
    /// 任務完成
    public func getTaskCompletedDialogue(taskName: String) -> String {
        let dialogues = [
            "「\(taskName)」完成！做得好！✨",
            "任務達成！\(taskName) 搞定！",
            "太厲害了！\(taskName) 完成！"
        ]
        return dialogues.randomElement() ?? dialogues[0]
    }
    
    /// 升級祝賀
    public func getLevelUpDialogue(newLevel: CompanionLevel) -> String {
        return "🎉 恭喜升級！你現在是「\(newLevel.title)」了！\(newLevel.icon)"
    }
    
    /// 成就解鎖
    public func getAchievementDialogue(achievement: Achievement) -> String {
        return "🏆 成就解鎖！「\(achievement.title)」— \(achievement.description)"
    }
    
    /// 每日任務完成
    public func getDailyChallengeDialogue() -> String {
        let dialogues = [
            "每日任務完成！經驗值 +50！⭐",
            "今天的挑戰達成了！你真棒！",
            "Daily Challenge 完成！明天繼續加油！"
        ]
        return dialogues.randomElement() ?? dialogues[0]
    }
    
    // MARK: - 閒置對話
    
    /// 久未使用後的問候
    public func getLongTimeNoSeeDialogue(daysSince: Int) -> String {
        if daysSince >= 7 {
            return "好久不見！\(daysSince) 天沒見到你了，論文進度還好嗎？"
        } else {
            return "嗨！好幾天沒見了，要回顧一下你的文獻庫嗎？"
        }
    }
    
    /// 閒置時的隨機鼓勵
    public func getIdleEncouragement() -> String {
        let encouragements = [
            "寫作是一場馬拉松，不是短跑，慢慢來～",
            "休息一下也沒關係，靈感需要時間醞釀！",
            "你今天的進度很棒喔！",
            "研究的路上，我一直都在！",
            "需要我幫忙什麼嗎？隨時叫我～",
            "專注的時候我會安靜陪著你 📚",
            "有任何問題都可以問我喔！",
            "今天天氣不錯，但寫論文更重要...吧？😅"
        ]
        return encouragements.randomElement() ?? encouragements[0]
    }
}
