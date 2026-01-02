//
//  ThemeSettingsView.swift
//  OVEREND
//
//  主題色設定頁面 - 讓用戶自訂主題顏色
//

import SwiftUI

/// 主題色設定視圖
struct ThemeSettingsView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // 標題
            HStack {
                Text("🎨 主題色設定")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            // 當前主題色預覽
            currentColorPreview
            
            Divider()
            
            // 顏色選擇網格
            colorGrid
            
            Spacer()
        }
        .padding(24)
        .frame(width: 400, height: 480)
        .background(theme.card)
    }
    
    // MARK: - 當前顏色預覽
    
    private var currentColorPreview: some View {
        VStack(spacing: 12) {
            Text("當前主題色")
                .font(.system(size: 14))
                .foregroundColor(theme.textMuted)
            
            if theme.isPrideMode {
                // 彩虹漸層預覽
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.prideGradient)
                    .frame(height: 60)
                    .overlay(
                        Text("🏳️‍🌈 彩虹驕傲")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    )
            } else {
                // 單色預覽
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.accent)
                    .frame(height: 60)
                    .overlay(
                        Text(currentColorName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    private var currentColorName: String {
        AppTheme.presetColors.first { $0.hex == theme.accentHex }?.name ?? "自訂顏色"
    }
    
    // MARK: - 顏色選擇網格
    
    private var colorGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇主題色")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AppTheme.presetColors, id: \.hex) { colorOption in
                    ColorOptionButton(
                        name: colorOption.name,
                        hex: colorOption.hex,
                        isGradient: colorOption.isGradient,
                        isSelected: theme.accentHex == colorOption.hex
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            theme.accentHex = colorOption.hex
                        }
                    }
                }
            }
        }
    }
}

/// 顏色選項按鈕
struct ColorOptionButton: View {
    @EnvironmentObject var theme: AppTheme
    
    let name: String
    let hex: String
    let isGradient: Bool
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 顏色圓形
                ZStack {
                    if isGradient {
                        // 彩虹漸層
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: AppTheme.prideGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                    } else {
                        // 單色
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 44, height: 44)
                    }
                    
                    // 選中勾選
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 2)
                    }
                    
                    // 邊框
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                        .frame(width: 44, height: 44)
                }
                .shadow(
                    color: isSelected ? Color(hex: hex).opacity(0.5) : .clear,
                    radius: 8
                )
                
                // 名稱
                Text(name)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? theme.itemHover : Color.clear)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    ThemeSettingsView()
        .environmentObject(AppTheme())
}
