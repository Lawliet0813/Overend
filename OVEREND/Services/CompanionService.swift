//
//  CompanionService.swift
//  OVEREND
//
//  AI 夥伴核心服務
//
//  管理夥伴角色、等級進度、成就追蹤與對話觸發
//

import Foundation
import SwiftUI
import Combine

// MARK: - 夥伴服務

/// AI 夥伴核心服務
@available(macOS 26.0, *)
@MainActor
public class CompanionService: ObservableObject {
    
    // MARK: - 單例
    
    public static let shared = CompanionService()
    
    // MARK: - 發布屬性
    
    /// 當前活躍的夥伴
    @Published public var activeCompanion: Companion = .yen
    
    /// 所有已創建的夥伴
    @Published public var allCompanions: [Companion] = [.yen]
    
    /// 用戶進度
    @Published public var userProgress: UserProgress = UserProgress()
    
    /// 成就進度
    @Published public var achievementProgress: [AchievementProgress] = []
    
    /// 今日挑戰
    @Published public var dailyChallenges: [DailyChallenge] = []
    
    /// 當前對話訊息（顯示在氣泡中）
    @Published public var currentDialogue: DialogueMessage?
    
    /// 當前心情狀態
    @Published public var currentMood: CompanionMood = .idle
    
    /// 是否顯示夥伴
    @Published public var isVisible: Bool = true
    
    // MARK: - 私有屬性
    
    private let dialogues = CompanionDialogues.shared
    private var cancellables = Set<AnyCancellable>()
    private let userDefaultsKey = "companionServiceData"
    private var idleTimer: Timer?
    private var lastActivityTime = Date()
    
    // MARK: - 統計追蹤
    
    private var sessionWordCount: Int = 0
    private var wordsSinceLastCitation: Int = 0
    private var importedEntriesCount: Int = 0
    private var acceptedSuggestionsCount: Int = 0
    
    // MARK: - 初始化
    
    private init() {
        loadSavedData()
        setupDailyChallenges()
        updateStreak()
        setupIdleTimer()
        showTimeBasedGreeting()
        
        AppLogger.success("🦉 CompanionService: 初始化完成")
    }
    
    // MARK: - 資料持久化
    
    private func loadSavedData() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let saved = try JSONDecoder().decode(SavedCompanionData.self, from: data)
                self.allCompanions = saved.companions.isEmpty ? [.yen] : saved.companions
                self.activeCompanion = saved.companions.first { $0.isActive } ?? .yen
                self.userProgress = saved.progress
                self.achievementProgress = saved.achievements
            } catch {
                AppLogger.error("🦉 CompanionService: 載入資料失敗 - \(error)")
            }
        }
        
        // 初始化成就進度
        if achievementProgress.isEmpty {
            achievementProgress = Achievement.allAchievements.map { 
                AchievementProgress(id: $0.id) 
            }
        }
    }
    
    private func saveData() {
        let saved = SavedCompanionData(
            companions: allCompanions,
            progress: userProgress,
            achievements: achievementProgress
        )
        
        do {
            let data = try JSONEncoder().encode(saved)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            AppLogger.error("🦉 CompanionService: 儲存資料失敗 - \(error)")
        }
    }
    
    // MARK: - 每日任務
    
    private func setupDailyChallenges() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 檢查是否需要重新生成每日任務
        if let lastDate = UserDefaults.standard.object(forKey: "dailyChallengeDate") as? Date {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay == today {
                // 載入已儲存的任務
                if let data = UserDefaults.standard.data(forKey: "dailyChallenges"),
                   let challenges = try? JSONDecoder().decode([DailyChallenge].self, from: data) {
                    dailyChallenges = challenges
                    return
                }
            }
        }
        
        // 生成新的每日任務
        dailyChallenges = DailyChallenge.generateDaily()
        UserDefaults.standard.set(today, forKey: "dailyChallengeDate")
        saveDailyChallenges()
    }
    
    private func saveDailyChallenges() {
        if let data = try? JSONEncoder().encode(dailyChallenges) {
            UserDefaults.standard.set(data, forKey: "dailyChallenges")
        }
    }
    
    // MARK: - 連續使用
    
    private func updateStreak() {
        userProgress.updateStreak()
        
        // 檢查連續使用成就
        let streakDays = userProgress.streakDays
        checkAchievement(id: "streak_7", currentValue: streakDays)
        checkAchievement(id: "streak_30", currentValue: streakDays)
        checkAchievement(id: "streak_100", currentValue: streakDays)
        
        // 連續使用獎勵
        if streakDays > 1 && streakDays % 7 == 0 {
            addXP(from: .streak, description: "連續 \(streakDays) 天使用")
        }
        
        saveData()
    }
    
    // MARK: - 閒置計時
    
    private func setupIdleTimer() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.handleIdleState()
            }
        }
    }
    
    private func handleIdleState() {
        let idleSeconds = Date().timeIntervalSince(lastActivityTime)
        
        if idleSeconds > 600 { // 10 分鐘無操作
            currentMood = .sleepy
            if idleSeconds > 1800 { // 30 分鐘
                showDialogue(message: dialogues.getIdleEncouragement(), trigger: .idle)
            }
        }
    }
    
    public func recordActivity() {
        lastActivityTime = Date()
        if currentMood == .sleepy {
            currentMood = .idle
        }
    }
    
    // MARK: - 時間問候
    
    private func showTimeBasedGreeting() {
        let greeting = dialogues.getTimeBasedGreeting()
        
        // 檢查久未使用
        if let lastActive = userProgress.lastActiveDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day ?? 0
            if daysSince >= 3 {
                showDialogue(
                    message: dialogues.getLongTimeNoSeeDialogue(daysSince: daysSince),
                    trigger: .longTimeNoSee
                )
                return
            }
        }
        
        showDialogue(message: greeting, trigger: .morningGreeting)
    }
    
    // MARK: - 對話控制
    
    public func showDialogue(message: String, trigger: DialogueTrigger, actionLabel: String? = nil, actionHandler: (() -> Void)? = nil) {
        currentDialogue = DialogueMessage(
            trigger: trigger,
            message: message,
            actionLabel: actionLabel,
            actionHandler: actionHandler
        )
        
        // 5 秒後自動隱藏（除非有動作按鈕）
        if actionLabel == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.currentDialogue?.trigger == trigger {
                    self?.currentDialogue = nil
                }
            }
        }
    }
    
    public func dismissDialogue() {
        currentDialogue = nil
    }
    
    // MARK: - 情緒控制
    
    public func setMood(_ mood: CompanionMood, duration: TimeInterval? = nil) {
        currentMood = mood
        
        if let duration = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.currentMood = .idle
            }
        }
    }
    
    // MARK: - 經驗值與等級
    
    @discardableResult
    public func addXP(from source: XPSource, description: String? = nil) -> (gain: XPGain, levelUp: Bool) {
        let result = userProgress.addXP(from: source, withDescription: description)
        
        if result.levelUp {
            // 升級動畫與對話
            setMood(.celebrating, duration: 3)
            showDialogue(
                message: dialogues.getLevelUpDialogue(newLevel: userProgress.currentLevel),
                trigger: .levelUp
            )
        }
        
        saveData()
        return result
    }
    
    // MARK: - 成就系統
    
    public func checkAchievement(id: String, currentValue: Int) {
        guard let index = achievementProgress.firstIndex(where: { $0.id == id }),
              !achievementProgress[index].isUnlocked,
              let achievement = Achievement.allAchievements.first(where: { $0.id == id }) else {
            return
        }
        
        achievementProgress[index].currentProgress = currentValue
        
        if currentValue >= achievement.requirement {
            // 解鎖成就
            achievementProgress[index].isUnlocked = true
            achievementProgress[index].unlockedAt = Date()
            
            // 獎勵 XP
            let _ = userProgress.addXP(from: .dailyChallenge, withDescription: "成就解鎖：\(achievement.title)")
            userProgress.totalXP += achievement.xpReward - XPSource.dailyChallenge.xpAmount // 調整多給的 XP
            
            // 慶祝動畫
            setMood(.celebrating, duration: 3)
            showDialogue(
                message: dialogues.getAchievementDialogue(achievement: achievement),
                trigger: .achievementUnlocked
            )
            
            saveData()
        }
    }
    
    // MARK: - 事件處理
    
    /// PDF 匯入事件
    public func onPDFImported(topic: String? = nil) {
        recordActivity()
        importedEntriesCount += 1
        
        // 經驗值
        addXP(from: .importEntry, description: topic)
        
        // 成就檢查
        checkAchievement(id: "first_import", currentValue: importedEntriesCount)
        checkAchievement(id: "import_10", currentValue: importedEntriesCount)
        checkAchievement(id: "import_100", currentValue: importedEntriesCount)
        checkAchievement(id: "import_500", currentValue: importedEntriesCount)
        
        // 對話
        setMood(.excited, duration: 2)
        showDialogue(
            message: dialogues.getImportDialogue(topic: topic),
            trigger: .pdfImported,
            actionLabel: "幫我分類",
            actionHandler: { /* 觸發分類功能 */ }
        )
        
        // 每日任務進度
        updateDailyChallenge(targetTitle: "整理達人")
    }
    
    /// 寫作進度事件
    public func onWritingProgress(wordCount: Int) {
        recordActivity()
        sessionWordCount = wordCount
        wordsSinceLastCitation += wordCount
        
        // 每 1000 字給經驗
        if wordCount > 0 && wordCount % 1000 == 0 {
            addXP(from: .write1000Words, description: "\(wordCount) 字達成")
            showDialogue(
                message: dialogues.getWritingProgressDialogue(wordCount: wordCount),
                trigger: .writingProgress
            )
        }
        
        // 長時間未引用提醒
        if wordsSinceLastCitation >= 500 {
            showDialogue(
                message: dialogues.getNoCitationDialogue(wordsSinceLastCitation: wordsSinceLastCitation),
                trigger: .noRecentCitation,
                actionLabel: "尋找文獻",
                actionHandler: { /* 開啟文獻搜尋 */ }
            )
        }
        
        // 每日任務
        updateDailyChallenge(targetTitle: "勤勞寫手", incrementBy: wordCount)
        
        // 成就
        checkAchievement(id: "write_10000", currentValue: sessionWordCount)
    }
    
    /// 引用完成事件
    public func onCitationCompleted() {
        recordActivity()
        wordsSinceLastCitation = 0
        addXP(from: .completeCitation)
        
        // 每日任務
        updateDailyChallenge(targetTitle: "引用高手")
    }
    
    /// 採納 AI 建議
    public func onSuggestionAccepted() {
        recordActivity()
        acceptedSuggestionsCount += 1
        addXP(from: .acceptSuggestion)
        
        // 成就
        checkAchievement(id: "ai_suggestion_10", currentValue: acceptedSuggestionsCount)
        checkAchievement(id: "ai_suggestion_50", currentValue: acceptedSuggestionsCount)
        
        // 每日任務
        updateDailyChallenge(targetTitle: "AI 協作")
    }
    
    /// 論文匯出
    public func onPaperExported() {
        recordActivity()
        addXP(from: .exportPaper)
        
        // 成就
        checkAchievement(id: "export_paper", currentValue: 1)
        
        // 慶祝
        setMood(.celebrating, duration: 5)
        showDialogue(
            message: "🎉 論文匯出成功！辛苦了！",
            trigger: .taskCompleted
        )
    }
    
    // MARK: - 每日任務更新
    
    private func updateDailyChallenge(targetTitle: String, incrementBy: Int = 1) {
        guard let index = dailyChallenges.firstIndex(where: { $0.title == targetTitle && !$0.isCompleted }) else {
            return
        }
        
        dailyChallenges[index].currentCount += incrementBy
        
        if dailyChallenges[index].isCompleted {
            // 完成任務
            addXP(from: .dailyChallenge, description: targetTitle)
            showDialogue(
                message: dialogues.getDailyChallengeDialogue(),
                trigger: .dailyChallengeComplete
            )
        }
        
        saveDailyChallenges()
    }
    
    // MARK: - 角色管理
    
    /// 切換活躍夥伴
    public func setActiveCompanion(_ companion: Companion) {
        for i in allCompanions.indices {
            allCompanions[i].isActive = (allCompanions[i].id == companion.id)
        }
        activeCompanion = companion
        saveData()
    }
    
    /// 新增自訂夥伴
    public func addCompanion(_ companion: Companion) {
        var newCompanion = companion
        newCompanion.isActive = false
        allCompanions.append(newCompanion)
        saveData()
    }
    
    /// 刪除夥伴
    public func removeCompanion(_ companion: Companion) {
        guard !companion.isDefault else { return } // 不能刪除預設角色
        allCompanions.removeAll { $0.id == companion.id }
        
        // 如果刪除的是當前活躍角色，切換到預設
        if companion.id == activeCompanion.id {
            activeCompanion = .yen
            if let index = allCompanions.firstIndex(where: { $0.isDefault }) {
                allCompanions[index].isActive = true
            }
        }
        
        saveData()
    }
}

// MARK: - 儲存資料結構

private struct SavedCompanionData: Codable {
    let companions: [Companion]
    let progress: UserProgress
    let achievements: [AchievementProgress]
}
