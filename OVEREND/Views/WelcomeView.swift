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

    // 金句輪播
    @State private var currentQuoteIndex = 0
    @State private var quoteTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 頂部問候橫幅
                greetingBanner
                
                // 主要內容區
                VStack(spacing: 32) {
                    // 金句卡片
                    inspirationalQuoteSection

                    // 快速操作卡片（主要功能第一排）
                    quickActionsSection

                    // 最近的專案（第二排）
                    recentProjectsSection
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
    
    /// 統計資訊文字
    private var motivationalText: String {
        let docCount = recentDocuments.count
        let libraryCount = fetchLibraryCount()
        
        return "文獻：\(libraryCount) 筆  •  文稿：\(docCount) 篇"
    }
    
    /// 取得文獻庫數量
    private func fetchLibraryCount() -> Int {
        let request = NSFetchRequest<Entry>(entityName: "Entry")
        return (try? viewContext.count(for: request)) ?? 0
    }

    // MARK: - 金句庫存

    private let inspirationalQuotes: [(text: String, author: String)] = [
        ("研究的目的不在於證明自己是對的，而在於發現真理。", "卡爾·波普爾"),
        ("在科學研究中，問對問題比找到答案更重要。", "愛因斯坦"),
        ("學術寫作是思想的建築，每一句話都是支撐論點的磚石。", "溫貝托·艾可"),
        ("優秀的論文不是一次完成的，而是反覆打磨的結果。", "海明威"),
        ("研究者的使命是站在前人的肩膀上，看得更遠。", "牛頓"),
        ("批判性思考是學術研究的靈魂。", "約翰·杜威"),
        ("文獻回顧不是堆砌資料，而是建構對話。", "韋恩·布斯"),
        ("寫作是思考的過程，而非思考的記錄。", "E.M.佛斯特"),
        ("每一個偉大的研究都始於一個小小的好奇。", "瑪麗·居里"),
        ("論文的價值在於其對知識體系的貢獻，而非篇幅。", "威廉·斯特倫克"),
        ("學術誠信是研究者最寶貴的資產。", "羅伯特·默頓"),
        ("數據不會說話，但研究者必須讓數據說出有意義的故事。", "愛德華·塔夫特"),
        ("研究方法是通往真理的地圖，選對方法才能到達目的地。", "查爾斯·達爾文"),
        ("引用不僅是致敬，更是將個人研究置於學術傳統之中。", "米歇爾·傅柯"),
        ("寫論文如同登山，每一步都要踏實，最終才能登頂。", "艾德蒙·希拉里"),
        ("好的研究問題值得用一生去探索。", "漢娜·鄂蘭"),
        ("學術寫作需要清晰、精確、優雅三者兼具。", "史蒂芬·平克"),
        ("研究的過程比結果更能塑造一個學者。", "托馬斯·庫恩"),
        ("每一份文獻都是前人智慧的結晶，值得尊重與學習。", "本傑明·富蘭克林"),
        ("論文的邏輯如同音樂的旋律，必須和諧流暢。", "路德維希·維根斯坦"),
        ("學術研究是一場馬拉松，而非短跑。", "村上春樹"),
        ("資料分析如同偵探辦案，細節中藏著真相。", "夏洛克·福爾摩斯"),
        ("寫作的第一步是克服空白頁的恐懼。", "安妮·拉莫特"),
        ("創新來自於對既有知識的質疑與重組。", "史蒂夫·賈伯斯"),
        ("研究倫理不是限制，而是保護研究價值的盾牌。", "艾莉絲·沃克")
    ]

    // MARK: - 金句區塊

    private var inspirationalQuoteSection: some View {
        let quote = inspirationalQuotes[currentQuoteIndex]

        return HStack(spacing: 0) {
            // 左側裝飾線
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [theme.accent, theme.accent.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)

            // 金句內容
            VStack(alignment: .leading, spacing: 16) {
                // 引號圖示
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 24))
                        .foregroundColor(theme.accent.opacity(0.6))

                    Spacer()

                    // 切換按鈕
                    HStack(spacing: 8) {
                        Button(action: previousQuote) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(theme.accent.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .help("上一句")

                        Button(action: nextQuote) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(theme.accent.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .help("下一句")
                    }
                }

                // 金句文字
                Text(quote.text)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineSpacing(6)
                    .transition(.opacity)
                    .id("quote-\(currentQuoteIndex)")

                // 作者
                HStack {
                    Spacer()
                    Text("— \(quote.author)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                        .italic()
                }

                // 進度指示器
                HStack(spacing: 4) {
                    ForEach(0..<min(inspirationalQuotes.count, 10), id: \.self) { index in
                        Circle()
                            .fill(index == currentQuoteIndex % 10 ? theme.accent : theme.textMuted.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.card)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.accent.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            startQuoteRotation()
        }
        .onDisappear {
            stopQuoteRotation()
        }
    }

    // MARK: - 金句控制方法

    private func startQuoteRotation() {
        // 每30秒自動切換金句
        quoteTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                nextQuote()
            }
        }
    }

    private func stopQuoteRotation() {
        quoteTimer?.invalidate()
        quoteTimer = nil
    }

    private func nextQuote() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentQuoteIndex = (currentQuoteIndex + 1) % inspirationalQuotes.count
        }
    }

    private func previousQuote() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentQuoteIndex = (currentQuoteIndex - 1 + inspirationalQuotes.count) % inspirationalQuotes.count
        }
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
                subtitle: "\(fetchLibraryCount()) 筆文獻",
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
        newDoc.title = "新建文稿"
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
