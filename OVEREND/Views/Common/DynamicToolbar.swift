//
//  DynamicToolbar.swift
//  OVEREND
//
//  動態工具列 - 根據視圖模式變化
//

import SwiftUI

/// 動態工具列
struct DynamicToolbar: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    
    @Binding var searchText: String
    var onNewItem: () -> Void
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 左側：返回按鈕 + 標題
            HStack(spacing: DesignTokens.Spacing.sm) {
                // 返回按鈕（僅在編輯器模式顯示）
                if case .editorFull = viewState.mode {
                    IconButton(
                        icon: "arrow.left",
                        action: {
                            viewState.backToEditorList()
                        },
                        style: .standard,
                        tooltip: "返回"
                    )
                    .environmentObject(theme)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // 標題
                Text(toolbarTitle)
                    .font(.system(size: DesignTokens.Typography.body, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .animation(AnimationSystem.Easing.quick, value: toolbarTitle)
            }

            Spacer()

            // 右側：番茄鐘 + 搜尋 + 主題切換 + 新建按鈕
            HStack(spacing: DesignTokens.Spacing.sm) {
                // 🍅 番茄鐘按鈕
                PomodoroToolbarButton()
                    .environmentObject(theme)
                
                // 主題切換
                IconButton(
                    icon: theme.isDarkMode ? "sun.max" : "moon",
                    action: {
                        withAnimation(AnimationSystem.Easing.spring) {
                            theme.isDarkMode.toggle()
                        }
                    },
                    style: .subtle,
                    tooltip: theme.isDarkMode ? "切換到淺色模式" : "切換到深色模式"
                )
                .environmentObject(theme)

                // 搜尋欄
                SearchField(placeholder: "搜尋...", text: $searchText)
                    .environmentObject(theme)
                    .frame(width: searchText.isEmpty ? 140 : 200)
                    .animation(AnimationSystem.Easing.quick, value: searchText.isEmpty)

                // 新建按鈕
                PrimaryButton(newButtonTitle, icon: "plus", size: .medium) {
                    onNewItem()
                }
                .environmentObject(theme)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .frame(height: 52)
        // Apple HIG: Liquid Glass 統一工具列樣式
        .background(.ultraThinMaterial)
        .background(
            // 微妙漸層提供層次感
            LinearGradient(
                colors: [
                    theme.accent.opacity(0.02),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(alignment: .bottom) {
            // 底部分隔線
            Rectangle()
                .fill(theme.glassBorder.opacity(0.5))
                .frame(height: 0.5)
        }
        .animation(AnimationSystem.Easing.spring, value: viewState.mode)
    }
    
    // MARK: - 計算屬性
    
    private var toolbarTitle: String {
        switch viewState.mode {
        case .welcome:
            return "歡迎"
        case .library:
            return "全部文獻庫"
        case .editorList:
            return "寫作中心"
        case .editorFull(let doc):
            return "正在編輯：\(doc.title)"
        case .aiCenter:
            return "AI 智慧中心"
        }
    }
    
    private var newButtonTitle: String {
        switch viewState.mode {
        case .welcome:
            return "開始寫作"
        case .library:
            return "匯入文獻"
        case .editorList, .editorFull:
            return "新增寫作專案"
        case .aiCenter:
            return "新功能"
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    
    return VStack {
        DynamicToolbar(searchText: .constant(""), onNewItem: {})
            .environmentObject(theme)
            .environmentObject(viewState)
        
        Spacer()
    }
    .frame(width: 800, height: 400)
}
