//
//  LoadingIndicator.swift
//  OVEREND
//
//  載入指示器和進度條組件
//

import SwiftUI

/// 標準載入指示器
/// 特點：旋轉動畫 + 可自訂大小和顏色
struct SpinnerLoadingIndicator: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    var size: CGFloat = 32
    var lineWidth: CGFloat = 3
    var color: Color? = nil

    // MARK: - 狀態

    @State private var isAnimating = false

    // MARK: - Body

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                color ?? theme.accent,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

/// 進度條組件
/// 特點：平滑填充動畫 + 百分比顯示
struct StandardProgressBar: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let progress: Double // 0.0 - 1.0
    var height: CGFloat = 8
    var showPercentage: Bool = false
    var color: Color? = nil

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景軌道
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(theme.border.opacity(0.3))
                        .frame(height: height)

                    // 進度填充
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color ?? theme.accent)
                        .frame(width: geometry.size.width * CGFloat(min(max(progress, 0), 1)), height: height)
                        .animation(AnimationSystem.Easing.spring, value: progress)
                }
            }
            .frame(height: height)

            // 百分比文字
            if showPercentage {
                HStack {
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
}

/// 不確定進度條（動畫條）
/// 特點：來回移動的動畫條，用於不確定時長的操作
struct IndeterminateProgressBar: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    var height: CGFloat = 4
    var color: Color? = nil

    // MARK: - 狀態

    @State private var offset: CGFloat = -1

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景軌道
                Rectangle()
                    .fill(theme.border.opacity(0.3))
                    .frame(height: height)

                // 移動的進度條
                Rectangle()
                    .fill(color ?? theme.accent)
                    .frame(width: geometry.size.width * 0.3, height: height)
                    .offset(x: geometry.size.width * offset)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: offset
                    )
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: height / 2))
        .onAppear {
            offset = 1.3
        }
    }
}

/// 骨架屏載入效果
/// 特點：漸層掃過動畫，用於內容載入佔位
struct SkeletonView: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    var height: CGFloat = 20
    var cornerRadius: CGFloat = DesignTokens.CornerRadius.small

    // MARK: - 狀態

    @State private var animating = false

    // MARK: - Body

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        theme.border.opacity(0.3),
                        theme.border.opacity(0.5),
                        theme.border.opacity(0.3)
                    ],
                    startPoint: animating ? .leading : .trailing,
                    endPoint: animating ? .trailing : .leading
                )
            )
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .animation(
                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                value: animating
            )
            .onAppear {
                animating = true
            }
    }
}

/// 點狀載入指示器
/// 特點：三個點依序彈跳動畫
struct DotLoadingIndicator: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    var size: CGFloat = 8
    var spacing: CGFloat = 6
    var color: Color? = nil

    // MARK: - 狀態

    @State private var animating = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color ?? theme.accent)
                    .frame(width: size, height: size)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - 預覽

#Preview("Loading Indicators") {
    VStack(spacing: 40) {
        let theme = AppTheme()

        // 標準載入指示器
        VStack(spacing: 8) {
            SpinnerLoadingIndicator()
                .environmentObject(theme)
            Text("標準載入指示器")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }

        // 不同大小
        HStack(spacing: 24) {
            SpinnerLoadingIndicator(size: 24, lineWidth: 2)
                .environmentObject(theme)
            SpinnerLoadingIndicator(size: 32, lineWidth: 3)
                .environmentObject(theme)
            SpinnerLoadingIndicator(size: 48, lineWidth: 4)
                .environmentObject(theme)
        }

        // 自訂顏色
        HStack(spacing: 24) {
            SpinnerLoadingIndicator(color: .blue)
                .environmentObject(theme)
            SpinnerLoadingIndicator(color: .red)
                .environmentObject(theme)
            SpinnerLoadingIndicator(color: .purple)
                .environmentObject(theme)
        }

        // 點狀載入
        VStack(spacing: 8) {
            DotLoadingIndicator()
                .environmentObject(theme)
            Text("點狀載入")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Progress Bars") {
    VStack(spacing: 32) {
        let theme = AppTheme()
        @State var progress1: Double = 0.3
        @State var progress2: Double = 0.7

        // 進度條（不顯示百分比）
        VStack(alignment: .leading, spacing: 8) {
            Text("下載中...")
                .font(.system(size: 14, weight: .medium))
            StandardProgressBar(progress: progress1)
                .environmentObject(theme)
        }

        // 進度條（顯示百分比）
        VStack(alignment: .leading, spacing: 8) {
            Text("處理進度")
                .font(.system(size: 14, weight: .medium))
            StandardProgressBar(progress: progress2, showPercentage: true)
                .environmentObject(theme)
        }

        // 不確定進度條
        VStack(alignment: .leading, spacing: 8) {
            Text("載入中...")
                .font(.system(size: 14, weight: .medium))
            IndeterminateProgressBar()
                .environmentObject(theme)
        }

        // 互動控制
        VStack(spacing: 16) {
            HStack {
                Text("調整進度：")
                Slider(value: $progress1, in: 0...1)
            }

            HStack(spacing: 12) {
                PrimaryButton("開始", size: .small) {
                    withAnimation {
                        progress2 = 1.0
                    }
                }
                .environmentObject(theme)

                SecondaryButton("重置", size: .small) {
                    withAnimation {
                        progress1 = 0.3
                        progress2 = 0.7
                    }
                }
                .environmentObject(theme)
            }
        }
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Skeleton Views") {
    VStack(spacing: 16) {
        let theme = AppTheme()

        // 文字骨架
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView(height: 24, cornerRadius: 8)
                .environmentObject(theme)
            SkeletonView(height: 16)
                .environmentObject(theme)
                .frame(width: 200)
            SkeletonView(height: 16)
                .environmentObject(theme)
                .frame(width: 150)
        }

        Divider()
            .padding(.vertical, 8)

        // 卡片骨架
        HStack(spacing: 12) {
            SkeletonView(height: 80, cornerRadius: 12)
                .environmentObject(theme)
                .frame(width: 80)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(height: 16)
                    .environmentObject(theme)
                SkeletonView(height: 12)
                    .environmentObject(theme)
                    .frame(width: 120)
                SkeletonView(height: 12)
                    .environmentObject(theme)
                    .frame(width: 80)
            }

            Spacer()
        }
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Dark Mode") {
    let theme = AppTheme()
    theme.isDarkMode = true

    @State var progress: Double = 0.6

    return VStack(spacing: 32) {
        SpinnerLoadingIndicator()
            .environmentObject(theme)

        DotLoadingIndicator()
            .environmentObject(theme)

        StandardProgressBar(progress: progress, showPercentage: true)
            .environmentObject(theme)

        IndeterminateProgressBar()
            .environmentObject(theme)

        SkeletonView()
            .environmentObject(theme)
    }
    .padding(40)
    .frame(width: 400)
    .background(Color(hex: "#1e1e1e"))
}
