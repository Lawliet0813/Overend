//
//  CompanionView.swift
//  OVEREND
//
//  AI 夥伴主視圖 - 浮動角色與對話氣泡
//

import SwiftUI

// MARK: - 夥伴視圖

/// AI 夥伴主視圖
@available(macOS 26.0, *)
struct CompanionView: View {
    
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var service = CompanionService.shared
    
    @State private var isHovering = false
    @State private var showingPanel = false
    @State private var bounceAnimation = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // 對話氣泡
            if let dialogue = service.currentDialogue {
                dialogueBubble(dialogue)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            // 夥伴角色
            companionAvatar
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: service.currentDialogue != nil)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceAnimation)
        .onAppear {
            startIdleAnimation()
        }
    }
    
    // MARK: - 角色頭像
    
    private var companionAvatar: some View {
        Button {
            withAnimation {
                showingPanel.toggle()
            }
        } label: {
            ZStack {
                // 背景光暈
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.accent.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .opacity(isHovering ? 1 : 0.5)
                
                // 角色圖片或預設 SF Symbol
                avatarImage
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.accent, lineWidth: 2)
                    )
                    .shadow(color: theme.accent.opacity(0.4), radius: isHovering ? 10 : 5)
                    .scaleEffect(bounceAnimation ? 1.05 : 1.0)
                    .offset(y: bounceAnimation ? -3 : 0)
                
                // 狀態指示器
                moodIndicator
                    .offset(x: 20, y: -20)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .popover(isPresented: $showingPanel) {
            CompanionPanelView()
                .environmentObject(theme)
                .frame(width: 320, height: 450)
        }
    }
    
    @ViewBuilder
    private var avatarImage: some View {
        // 檢查是否有自訂圖片
        if let imageData = service.activeCompanion.moodImages[service.currentMood],
           let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // 預設：使用表情符號
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(moodEmoji)
                    .font(.system(size: 32))
            }
        }
    }
    
    private var moodEmoji: String {
        switch service.currentMood {
        case .idle: return "🦉"
        case .excited: return "💡"
        case .reading: return "📚"
        case .celebrating: return "🎉"
        case .sleepy: return "😴"
        case .thinking: return "🤔"
        }
    }
    
    private var moodIndicator: some View {
        Circle()
            .fill(moodColor)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: moodColor.opacity(0.5), radius: 3)
    }
    
    private var moodColor: Color {
        switch service.currentMood {
        case .idle: return .gray
        case .excited: return .yellow
        case .reading: return .blue
        case .celebrating: return .green
        case .sleepy: return .purple
        case .thinking: return .orange
        }
    }
    
    // MARK: - 對話氣泡
    
    private func dialogueBubble(_ dialogue: DialogueMessage) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(dialogue.message)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let actionLabel = dialogue.actionLabel {
                        Button(actionLabel) {
                            dialogue.actionHandler?()
                            service.dismissDialogue()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.border.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // 氣泡箭頭
                Triangle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(-90))
                    .offset(x: -1)
            }
            .frame(maxWidth: 250)
            
            // 關閉按鈕
            Button {
                service.dismissDialogue()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(theme.textSecondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
    }
    
    // MARK: - 動畫
    
    private func startIdleAnimation() {
        // 隨機輕微彈跳動畫
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            if service.currentMood == .idle {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        bounceAnimation = false
                    }
                }
            }
        }
    }
}

// MARK: - 三角形形狀

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 夥伴狀態指示

@available(macOS 26.0, *)
struct CompanionStatusBadge: View {
    
    @ObservedObject var service = CompanionService.shared
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        HStack(spacing: 6) {
            // 等級
            Text("Lv.\(service.userProgress.currentLevel.rawValue)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.accent)
            
            // 經驗值進度條
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.border.opacity(0.3))
                    
                    Capsule()
                        .fill(theme.accent)
                        .frame(width: geo.size.width * service.userProgress.progressToNextLevel)
                }
            }
            .frame(width: 50, height: 4)
            
            // 連續天數
            if service.userProgress.streakDays > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("\(service.userProgress.streakDays)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Preview

@available(macOS 26.0, *)
#Preview {
    ZStack {
        Color.black.opacity(0.8)
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                CompanionView()
                    .environmentObject(AppTheme())
                    .padding()
            }
        }
    }
    .frame(width: 400, height: 300)
}
