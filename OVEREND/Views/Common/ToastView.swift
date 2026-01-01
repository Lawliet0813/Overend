//
//  ToastView.swift
//  OVEREND
//
//  Toast 視圖元件 - 右上角淡入淡出提示
//

import SwiftUI

/// 單個 Toast 視圖
struct ToastView: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var manager: ToastManager
    let toast: ToastItem
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 圖示
            Image(systemName: toast.type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(toast.type.color)
            
            // 訊息
            Text(toast.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
            
            Spacer(minLength: 8)
            
            // 關閉按鈕
            Button(action: { manager.dismiss(toast) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.card)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(toast.type.color)
                .frame(width: 4)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

/// 載入指示器視圖
struct LoadingIndicator: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var manager: ToastManager
    
    var body: some View {
        if manager.isLoading {
            HStack(spacing: 12) {
                // 進度指示
                if let progress = manager.loadingProgress {
                    // 確定進度
                    ProgressView(value: progress)
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.textMuted)
                        .monospacedDigit()
                } else {
                    // 不確定進度
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                }
                
                // 訊息
                Text(manager.loadingMessage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.card)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.accent.opacity(0.3), lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.accent)
                    .frame(width: 4)
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.9))
            ))
        }
    }
}

/// Toast 容器（放在視窗右上角）
struct ToastContainer: View {
    @EnvironmentObject var theme: AppTheme
    @StateObject private var manager = ToastManager.shared
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // 載入指示器（最上方）
            LoadingIndicator(manager: manager)
                .environmentObject(theme)
                .frame(maxWidth: 360)
            
            // Toast 列表
            ForEach(manager.toasts) { toast in
                ToastView(manager: manager, toast: toast)
                    .environmentObject(theme)
                    .frame(maxWidth: 360)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.9))
                    ))
            }
        }
        .padding(.top, 16)
        .padding(.trailing, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.toasts)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.isLoading)
    }
}


/// Toast 修飾器 - 方便在任意視圖上添加 Toast
struct ToastModifier: ViewModifier {
    @StateObject private var theme = AppTheme()
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                ToastContainer()
                    .environmentObject(theme)
            }
    }
}

extension View {
    /// 在視圖上添加 Toast 容器
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}

#Preview {
    VStack {
        Button("顯示成功") {
            ToastManager.shared.showSuccess("已匯入 5 篇文獻")
        }
        Button("顯示錯誤") {
            ToastManager.shared.showError("網路連線失敗，請稍後再試")
        }
        Button("顯示資訊") {
            ToastManager.shared.showInfo("正在同步中...")
        }
        Button("顯示警告") {
            ToastManager.shared.showWarning("部分 PDF 匯入失敗")
        }
    }
    .padding()
    .frame(width: 400, height: 300)
    .withToast()
    .environmentObject(AppTheme())
}
