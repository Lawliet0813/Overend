//
//  EditorThemeSection.swift
//  OVEREND
//
//  編輯器主題選擇區塊
//

import SwiftUI

struct EditorThemeSection: View {
    @EnvironmentObject var theme: AppTheme
    @State private var selectedTheme = "deepForest"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "paintpalette", title: "編輯器主題")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ThemeCard(
                    name: "深林",
                    isSelected: selectedTheme == "deepForest",
                    backgroundColor: Color(hex: "#0a120e"),
                    lineColor: Color.white.opacity(0.1),
                    footerColor: Color(hex: "#15231c")
                ) {
                    selectedTheme = "deepForest"
                }
                
                ThemeCard(
                    name: "薄荷",
                    isSelected: selectedTheme == "mint",
                    backgroundColor: Color(hex: "#e0f2eb"),
                    lineColor: Color(hex: "#065F46").opacity(0.1),
                    footerColor: Color(hex: "#cce8dd"),
                    isLight: true
                ) {
                    selectedTheme = "mint"
                }
                
                ThemeCard(
                    name: "淺灰",
                    isSelected: selectedTheme == "lightSage",
                    backgroundColor: Color(hex: "#f0f4f2"),
                    lineColor: Color(hex: "#1e293b").opacity(0.1),
                    footerColor: Color(hex: "#e2e8e5"),
                    isLight: true
                ) {
                    selectedTheme = "lightSage"
                }
            }
            
            // Typography Section
            TypographySection()
        }
    }
}

// MARK: - 主題卡片

struct ThemeCard: View {
    @EnvironmentObject var theme: AppTheme
    let name: String
    let isSelected: Bool
    let backgroundColor: Color
    let lineColor: Color
    let footerColor: Color
    var isLight: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // 主題預覽
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(lineColor)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(lineColor)
                        .frame(width: 100, height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(lineColor)
                        .frame(width: 60, height: 8)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 100)
                .background(backgroundColor)
                
                // 底部欄
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red.opacity(isLight ? 0.5 : 0.5))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.yellow.opacity(isLight ? 0.5 : 0.5))
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    Text("文件.md")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(isLight ? .gray : .white.opacity(0.3))
                }
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(footerColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? theme.emerald : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isSelected ? 1.0 : (isHovered ? 1.0 : 0.8))
            .shadow(color: isSelected ? theme.emerald.opacity(0.3) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        
        // 名稱和勾選
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.emerald)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    EditorThemeSection()
        .padding(32)
        .background(Color(hex: "#10221a"))
        .environmentObject(AppTheme())
}
