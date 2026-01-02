//
//  WelcomeView.swift
//  OVEREND
//
//  應用程式起始頁面 - 問候語、快速入口
//

import SwiftUI
import CoreData

/// 起始頁面視圖
struct WelcomeView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext
    
    // 最近文稿查詢
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        predicate: nil,
        animation: .default
    )
    private var recentDocuments: FetchedResults<Document>
    
    // 番茄鐘狀態
    @State private var showPomodoro = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 頂部問候橫幅
                greetingBanner
                
                // 主要內容區
                VStack(spacing: 32) {
                    // 最近的專案
                    recentProjectsSection
                    
                    // 快速操作卡片
                    quickActionsSection
                }
                .padding(.horizontal, 40)
                .padding(.top, 32)
                .padding(.bottom, 60)
            }
        }
        .background(theme.background)
    }
    
    // MARK: - 問候橫幅
    
    private var greetingBanner: some View {
        ZStack(alignment: .bottomLeading) {
            // 漸層背景
            LinearGradient(
                colors: [
                    theme.accent,
                    theme.accent.opacity(0.8),
                    theme.accent.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 180)
            
            // 裝飾圖案
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width - 100, y: -50)
                
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 200, y: 80)
            }
            
            // 右上角番茄鐘按鈕
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: { showPomodoro.toggle() }) {
                        HStack(spacing: 6) {
                            Text("🍅")
                                .font(.system(size: 16))
                            
                            Text(pomodoroDisplayText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showPomodoro, arrowEdge: .bottom) {
                        PomodoroView()
                            .environmentObject(theme)
                    }
                }
                .padding(16)
                
                Spacer()
            }
            
            // 問候文字
            VStack(alignment: .leading, spacing: 8) {
                Text(greetingText)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text(motivationalText)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 32)
        }
    }
    
    /// 番茄鐘顯示文字
    private var pomodoroDisplayText: String {
        let timer = PomodoroTimer.shared
        if timer.state == .idle {
            return "番茄鐘"
        } else {
            return timer.formattedTime
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早安 ☀️"
        case 12..<18:
            return "午安 🌤"
        case 18..<22:
            return "晚安 🌙"
        default:
            return "夜深了 🌟"
        }
    }
    
    /// 隨機鼓勵語句庫
    private static let motivationalMessages = [
        // 正向鼓勵
        "新的一天，開始創作吧！",
        "持續專注，靈感不斷～",
        "今天的寫作進展如何？",
        "每一個段落都是進步 ✨",
        "好的開始是成功的一半",
        "靈感來了擋都擋不住！",
        "相信自己，你可以的！",
        "一步一步，穩步前進",
        "今天也要元氣滿滿唷！",
        "寫作是思想的對話",
        // 趣味金句
        "論文寫完沒？沒關係寫不完我也沒差 😏",
        "聽說 deadline 是第一生產力？",
        "又是寫論文的一天呢（微笑）",
        "咖啡☕ + 靈感💡 = 生產力🚀",
        "今天不寫，明天也不想寫...",
        "拖延症患者請點擊開始寫作",
        "不要問我寫了多少，問我喝了幾杯咖啡",
        "工作做不完，不如先寫論文？",
        "寫作時間到！（逃避可恥但有用）",
        "論文不會自己寫完的，除非...？"
    ]
    
    private var motivationalText: String {
        Self.motivationalMessages.randomElement() ?? "開始寫作吧！"
    }
    
    // MARK: - 最近的專案
    
    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 區塊標題
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.accent)
                
                Text("最近的寫作專案")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    viewState.mode = .editorList
                }) {
                    Text("查看全部")
                        .font(.system(size: 13))
                        .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            }
            
            // 專案卡片
            if recentDocuments.isEmpty {
                emptyProjectsCard
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(recentDocuments.prefix(6), id: \.id) { doc in
                        ProjectCard(document: doc) {
                        viewState.mode = .editorFull(doc)
                        }
                        .environmentObject(theme)
                    }
                }
            }
        }
    }
    
    private var emptyProjectsCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 32))
                .foregroundColor(theme.textMuted)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("尚無寫作專案")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text("開始建立您的第一個寫作專案")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
            
            Button(action: createNewProject) {
                Text("新增寫作專案")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.accent)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.card)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 快速操作
    
    private var quickActionsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            QuickActionCard(
                icon: "plus.circle.fill",
                title: "新建寫作",
                subtitle: "開始新的寫作專案",
                color: .blue
            ) {
                createNewProject()
            }
            .environmentObject(theme)
            
            QuickActionCard(
                icon: "books.vertical.fill",
                title: "文獻管理",
                subtitle: "管理您的參考文獻庫",
                color: .purple
            ) {
                viewState.mode = .library
            }
            .environmentObject(theme)
            
            QuickActionCard(
                icon: "questionmark.circle.fill",
                title: "使用教學",
                subtitle: "了解如何使用 OVEREND",
                color: .orange
            ) {
                // TODO: 顯示教學
            }
            .environmentObject(theme)
        }
    }
    
    // MARK: - 輔助方法
    
    private func createNewProject() {
        let newDoc = Document(context: viewContext)
        newDoc.id = UUID()
        newDoc.title = "未命名寫作專案"
        newDoc.createdAt = Date()
        newDoc.updatedAt = Date()
        
        do {
            try viewContext.save()
            viewState.mode = .editorFull(newDoc)
        } catch {
            print("建立專案失敗：\(error)")
        }
    }
}

// MARK: - 專案卡片

struct ProjectCard: View {
    @EnvironmentObject var theme: AppTheme
    let document: Document
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // 文件圖示
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.accentLight)
                        .frame(height: 80)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 28))
                        .foregroundColor(theme.accent)
                }
                
                // 標題
                Text(document.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                
                // 更新時間
                Text(formatDate(document.updatedAt))
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.card)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh-TW")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 快速操作卡片

struct QuickActionCard: View {
    @EnvironmentObject var theme: AppTheme
    
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // 圖示
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                // 文字
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.card)
                    .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 12 : 8, x: 0, y: isHovered ? 6 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isHovered ? color.opacity(0.5) : theme.border, lineWidth: isHovered ? 2 : 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView()
        .environmentObject(AppTheme())
        .environmentObject(MainViewState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 1000, height: 700)
}
