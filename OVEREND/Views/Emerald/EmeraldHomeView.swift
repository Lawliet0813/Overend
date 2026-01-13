//
//  EmeraldHomeView.swift
//  OVEREND
//
//  Emerald Home - 首頁 / 歡迎頁面
//

import SwiftUI
import CoreData

// MARK: - 主視圖

struct EmeraldHomeView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        predicate: NSPredicate(format: "isDeleted == NO"),
        animation: .default
    )
    private var recentDocuments: FetchedResults<Document>
    
    @State private var userName = "研究者"
    @State private var showNewDocument = false
    
    var body: some View {
        ZStack {
            // 背景漸層
            EmeraldTheme.gradientBackground
                .ignoresSafeArea()
            
            // 環境光效果
            AmbientGlowBackground()
            
            // 內容
            ScrollView {
                VStack(spacing: 48) {
                    // Hero 區域
                    HeroSection(userName: userName, onStartWriting: {
                        showNewDocument = true
                    })
                    
                    // 快速操作
                    QuickActionsSection()
                    
                    // 最近專案
                    RecentProjectsSection(documents: Array(recentDocuments.prefix(4)))
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 48)
            }
        }
    }
}

// MARK: - 環境光背景

struct AmbientGlowBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // 左上角光暈
            Circle()
                .fill(
                    RadialGradient(
                        colors: [EmeraldTheme.primary.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .offset(x: -200, y: -200)
                .blur(radius: 60)
                .offset(y: animate ? 10 : -10)
            
            // 右下角光暈
            Circle()
                .fill(
                    RadialGradient(
                        colors: [EmeraldTheme.primary.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: 300, y: 400)
                .blur(radius: 50)
                .offset(y: animate ? -15 : 15)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Hero 區域

struct HeroSection: View {
    let userName: String
    let onStartWriting: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 28))
                    .foregroundColor(EmeraldTheme.primary)
                
                Text("OVEREND")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(EmeraldTheme.textSecondary)
                    .tracking(4)
            }
            .floating(amplitude: 3, duration: 3)
            
            // 歡迎文字
            VStack(spacing: 12) {
                Text("Welcome back,")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(EmeraldTheme.textSecondary)
                
                Text(userName)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(-1)
            }
            
            Text("加速你的研究，精煉你的寫作。\n今天想創造什麼？")
                .font(.system(size: 16))
                .foregroundColor(EmeraldTheme.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // 開始按鈕
            Button(action: onStartWriting) {
                HStack(spacing: 8) {
                    Text("開始寫作")
                        .font(.system(size: 15, weight: .bold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(EmeraldTheme.backgroundDark)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(EmeraldTheme.primary)
                .cornerRadius(999)
            }
            .buttonStyle(.plain)
            .pulseGlow()
            .scaleOnHover(1.05)
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - 快速操作區

struct QuickActionsSection: View {
    var body: some View {
        HStack(spacing: 20) {
            HomeQuickActionCard(
                icon: "plus",
                title: "新增文件",
                description: "從頭開始或選擇模板",
                color: EmeraldTheme.primary
            )
            
            HomeQuickActionCard(
                icon: "books.vertical",
                title: "開啟文獻庫",
                description: "存取你的研究資料",
                color: .blue
            )
            
            HomeQuickActionCard(
                icon: "sparkles",
                title: "AI 助手",
                description: "取得寫作、引用和分析協助",
                color: .purple
            )
        }
    }
}

// MARK: - 快速操作卡片

struct HomeQuickActionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 16) {
                // 圖標
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(EmeraldTheme.textMuted)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .frame(height: 160)
            .emeraldCard(isHovered: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleOnHover(1.02)
    }
}

// MARK: - 最近專案區

struct RecentProjectsSection: View {
    let documents: [Document]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent Projects")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EmeraldTheme.textSecondary)
                    .tracking(1)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                            .foregroundColor(EmeraldTheme.textMuted)
                            .frame(width: 28, height: 28)
                            .background(EmeraldTheme.surfaceDark)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(EmeraldTheme.textMuted)
                            .frame(width: 28, height: 28)
                            .background(EmeraldTheme.surfaceDark)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if documents.isEmpty {
                // 空狀態
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 36))
                            .foregroundColor(EmeraldTheme.textMuted)
                        
                        Text("還沒有文件")
                            .font(.system(size: 14))
                            .foregroundColor(EmeraldTheme.textMuted)
                    }
                    .padding(.vertical, 60)
                    Spacer()
                }
            } else {
                // 專案卡片
                HStack(spacing: 16) {
                    ForEach(documents) { doc in
                        RecentProjectCard(document: doc)
                    }
                }
            }
        }
    }
}

// MARK: - 最近專案卡片

struct RecentProjectCard: View {
    let document: Document
    
    @State private var isHovered = false
    
    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: document.updatedAt ?? Date(), relativeTo: Date())
    }
    
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 0) {
                // 縮圖區域
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [EmeraldTheme.surfaceDark, EmeraldTheme.backgroundDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 模擬文字預覽
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(0..<4, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                        }
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 60, height: 6)
                    }
                    .padding(12)
                }
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                
                // 資訊
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        Text(relativeDate)
                            .font(.system(size: 11))
                            .foregroundColor(EmeraldTheme.textMuted)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("Open")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(EmeraldTheme.backgroundDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(EmeraldTheme.primary)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .opacity(isHovered ? 1 : 0)
                    }
                }
                .padding(12)
            }
            .frame(width: 200)
            .background(EmeraldTheme.surfaceDark.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? EmeraldTheme.borderAccent : Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleOnHover(1.03)
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // 建立測試文件
    for i in 0..<4 {
        let doc = Document(context: context)
        doc.title = ["量子計算神經科學", "永續城市發展", "基因組數據分析", "科技哲學"][i]
        doc.updatedAt = Date().addingTimeInterval(TimeInterval(-i * 3600 * 24))
    }
    
    return EmeraldHomeView()
        .environmentObject(AppTheme())
        .environment(\.managedObjectContext, context)
        .frame(width: 1200, height: 800)
}
