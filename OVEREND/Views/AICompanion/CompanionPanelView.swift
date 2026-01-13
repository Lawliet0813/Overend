//
//  CompanionPanelView.swift
//  OVEREND
//
//  AI 夥伴詳細面板 - 等級、成就、每日任務
//

import SwiftUI

// MARK: - 夥伴面板

@available(macOS 26.0, *)
struct CompanionPanelView: View {
    
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var service = CompanionService.shared
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部：角色資訊
            headerSection
            
            Divider()
            
            // 標籤選擇
            tabPicker
            
            // 內容區域
            TabView(selection: $selectedTab) {
                progressView
                    .tag(0)
                
                dailyChallengesView
                    .tag(1)
                
                achievementsView
                    .tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .background(theme.background)
    }
    
    // MARK: - 頂部區域
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            // 角色頭像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text("🦉")
                    .font(.system(size: 28))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 名字與等級
                HStack {
                    Text(service.activeCompanion.name)
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)
                    
                    Text(service.userProgress.currentLevel.icon)
                        .font(.system(size: 14))
                }
                
                // 等級標題
                Text(service.userProgress.currentLevel.title)
                    .font(.caption)
                    .foregroundStyle(theme.accent)
                
                // 經驗值進度
                HStack(spacing: 4) {
                    ProgressView(value: service.userProgress.progressToNextLevel)
                        .progressViewStyle(.linear)
                        .tint(theme.accent)
                        .frame(width: 100)
                    
                    Text("\(service.userProgress.xpToNextLevel) XP")
                        .font(.system(size: 9))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            
            Spacer()
            
            // 連續天數
            VStack(alignment: .center, spacing: 2) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(service.userProgress.streakDays)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("連續")
                    .font(.system(size: 9))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding()
    }
    
    // MARK: - 標籤選擇器
    
    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton(title: "進度", icon: "chart.line.uptrend.xyaxis", index: 0)
            tabButton(title: "任務", icon: "star.fill", index: 1)
            tabButton(title: "成就", icon: "trophy.fill", index: 2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(selectedTab == index ? theme.accent : theme.textSecondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                selectedTab == index ?
                    theme.accent.opacity(0.15) : Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 進度視圖
    
    private var progressView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 總經驗值
                HStack {
                    VStack(alignment: .leading) {
                        Text("總經驗值")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                        Text("\(service.userProgress.totalXP) XP")
                            .font(.title2.bold())
                            .foregroundStyle(theme.accent)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("下一等級")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                        if let nextLevel = nextLevel {
                            Text(nextLevel.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.textPrimary)
                        } else {
                            Text("已達最高")
                                .font(.subheadline)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.elevated)
                )
                
                // 解鎖功能
                VStack(alignment: .leading, spacing: 8) {
                    Text("已解鎖功能")
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.textPrimary)
                    
                    ForEach(unlockedFeatures, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.elevated)
                )
                
                // 最近經驗值記錄
                if !service.userProgress.xpHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近獲得")
                            .font(.subheadline.bold())
                            .foregroundStyle(theme.textPrimary)
                        
                        ForEach(service.userProgress.xpHistory.prefix(5)) { gain in
                            HStack {
                                Image(systemName: gain.source.icon)
                                    .foregroundStyle(theme.accent)
                                    .font(.caption)
                                Text(gain.source.displayName)
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                                Spacer()
                                Text("+\(gain.amount) XP")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.elevated)
                    )
                }
            }
            .padding()
        }
    }
    
    private var nextLevel: CompanionLevel? {
        let levels = CompanionLevel.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let currentIndex = levels.firstIndex(of: service.userProgress.currentLevel),
              currentIndex + 1 < levels.count else {
            return nil
        }
        return levels[currentIndex + 1]
    }
    
    private var unlockedFeatures: [String] {
        let levels = CompanionLevel.allCases.filter { $0.rawValue <= service.userProgress.currentLevel.rawValue }
        return levels.flatMap { $0.unlockedFeatures }
    }
    
    // MARK: - 每日任務視圖
    
    private var dailyChallengesView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(service.dailyChallenges) { challenge in
                    DailyChallengeCard(challenge: challenge)
                }
                
                if service.dailyChallenges.allSatisfy({ $0.isCompleted }) {
                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 40))
                        Text("今日任務全部完成！")
                            .font(.subheadline.bold())
                            .foregroundStyle(theme.textPrimary)
                        Text("明天再來挑戰吧～")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - 成就視圖
    
    private var achievementsView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Achievement.allAchievements, id: \.id) { achievement in
                    AchievementBadge(
                        achievement: achievement,
                        progress: service.achievementProgress.first { $0.id == achievement.id }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 每日任務卡片

@available(macOS 26.0, *)
struct DailyChallengeCard: View {
    
    let challenge: DailyChallenge
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        HStack(spacing: 12) {
            // 圖標
            Text(challenge.icon)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(challenge.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.textPrimary)
                    
                    if challenge.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                
                Text(challenge.description)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                
                // 進度條
                ProgressView(value: challenge.progress)
                    .progressViewStyle(.linear)
                    .tint(challenge.isCompleted ? .green : theme.accent)
            }
            
            Spacer()
            
            // 獎勵
            VStack(alignment: .trailing) {
                Text("+\(challenge.xpReward)")
                    .font(.caption.bold())
                    .foregroundStyle(challenge.isCompleted ? .green : theme.accent)
                Text("XP")
                    .font(.system(size: 9))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.elevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(challenge.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .opacity(challenge.isCompleted ? 0.7 : 1)
    }
}

// MARK: - 成就徽章

@available(macOS 26.0, *)
struct AchievementBadge: View {
    
    let achievement: Achievement
    let progress: AchievementProgress?
    @EnvironmentObject var theme: AppTheme
    
    var isUnlocked: Bool {
        progress?.isUnlocked ?? false
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? theme.accent.opacity(0.2) : theme.elevated)
                    .frame(width: 50, height: 50)
                
                Text(achievement.icon)
                    .font(.system(size: 24))
                    .grayscale(isUnlocked ? 0 : 1)
                    .opacity(isUnlocked ? 1 : 0.4)
            }
            
            Text(achievement.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isUnlocked ? theme.textPrimary : theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.elevated.opacity(0.5))
        )
        .help(achievement.description)
    }
}

// MARK: - Preview

@available(macOS 26.0, *)
#Preview {
    CompanionPanelView()
        .environmentObject(AppTheme())
        .frame(width: 320, height: 450)
}
