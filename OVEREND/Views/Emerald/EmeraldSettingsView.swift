//
//  EmeraldSettingsView.swift
//  OVEREND
//
//  Emerald Settings - 設定頁面
//

import SwiftUI

// MARK: - 主視圖

struct EmeraldSettingsView: View {
    @EnvironmentObject var theme: AppTheme
    
    @State private var selectedTab = "appearance"
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側導航
            SettingsSidebar(selectedTab: $selectedTab)
                .frame(width: 220)
            
            // 右側內容
            SettingsContent(selectedTab: selectedTab)
        }
        .background(EmeraldTheme.backgroundDark)
    }
}

// MARK: - 側邊欄

struct SettingsSidebar: View {
    @Binding var selectedTab: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 標題
            Text("Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            
            // 分類按鈕
            VStack(spacing: 4) {
                SettingsTabButton(
                    icon: "gearshape",
                    title: "General",
                    tab: "general",
                    selectedTab: $selectedTab
                )
                
                SettingsTabButton(
                    icon: "paintpalette",
                    title: "Appearance",
                    tab: "appearance",
                    selectedTab: $selectedTab
                )
                
                SettingsTabButton(
                    icon: "sparkles",
                    title: "AI",
                    tab: "ai",
                    selectedTab: $selectedTab
                )
                
                SettingsTabButton(
                    icon: "arrow.triangle.2.circlepath.icloud",
                    title: "Sync",
                    tab: "sync",
                    selectedTab: $selectedTab
                )
                
                SettingsTabButton(
                    icon: "info.circle",
                    title: "About",
                    tab: "about",
                    selectedTab: $selectedTab
                )
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            // 版本資訊
            VStack(alignment: .leading, spacing: 8) {
                Text("Version 2.1.0 (Build 450)")
                    .font(.system(size: 11))
                    .foregroundColor(EmeraldTheme.textMuted)
                
                Button(action: {}) {
                    Text("Check for Updates")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(EmeraldTheme.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(EmeraldTheme.primary.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(EmeraldTheme.borderAccent, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .background(EmeraldTheme.surfaceDark.opacity(0.5))
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// MARK: - 設定分類按鈕

struct SettingsTabButton: View {
    let icon: String
    let title: String
    let tab: String
    @Binding var selectedTab: String
    
    @State private var isHovered = false
    
    var isSelected: Bool { selectedTab == tab }
    
    var body: some View {
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? EmeraldTheme.primary : EmeraldTheme.textSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : EmeraldTheme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? EmeraldTheme.primary.opacity(0.15) : (isHovered ? Color.white.opacity(0.05) : .clear))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? EmeraldTheme.borderAccent : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 設定內容

struct SettingsContent: View {
    let selectedTab: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                switch selectedTab {
                case "general":
                    GeneralSettings()
                case "appearance":
                    AppearanceSettings()
                case "ai":
                    AISettings()
                case "sync":
                    SyncSettings()
                case "about":
                    AboutSettings()
                default:
                    EmptyView()
                }
            }
            .padding(48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 外觀設定

struct AppearanceSettings: View {
    @State private var interfaceTheme = "system"
    @State private var accentColor = "#25f49d"
    @State private var fontSize: Double = 16
    @State private var defaultFont = "SF Pro"
    @State private var highContrastText = false
    @State private var focusMode = true
    @State private var sidebarWidth: Double = 280
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Appearance")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            // 主題設定
            SettingsCard(title: "Theme & Accent Color") {
                VStack(spacing: 20) {
                    // 介面主題
                    HStack {
                        Text("Interface Theme")
                            .font(.system(size: 14))
                            .foregroundColor(EmeraldTheme.textSecondary)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            ThemeToggle(label: "System Default", isOn: interfaceTheme == "system") {
                                interfaceTheme = "system"
                            }
                            ThemeToggle(label: "Custom Theme", isOn: interfaceTheme == "custom") {
                                interfaceTheme = "custom"
                            }
                        }
                    }
                    
                    // 強調色
                    HStack {
                        Text("Accent Color")
                            .font(.system(size: 14))
                            .foregroundColor(EmeraldTheme.textSecondary)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(EmeraldTheme.primary)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                            
                            Text(accentColor)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(EmeraldTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(EmeraldTheme.backgroundDark)
                                .cornerRadius(6)
                            
                            Button("Custom") {}
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(EmeraldTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(EmeraldTheme.surfaceDark)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // 字型設定
            SettingsCard(title: "Typography") {
                VStack(spacing: 20) {
                    // 字體大小
                    HStack {
                        Text("Font Size")
                            .font(.system(size: 14))
                            .foregroundColor(EmeraldTheme.textSecondary)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Slider(value: $fontSize, in: 12...24, step: 1)
                                .accentColor(EmeraldTheme.primary)
                                .frame(width: 150)
                            
                            Text("\(Int(fontSize)) pt")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    
                    // 預設字型
                    HStack {
                        Text("Default Font")
                            .font(.system(size: 14))
                            .foregroundColor(EmeraldTheme.textSecondary)
                        
                        Spacer()
                        
                        Menu {
                            Button("SF Pro (System Font)") { defaultFont = "SF Pro" }
                            Button("New York") { defaultFont = "New York" }
                            Button("Menlo") { defaultFont = "Menlo" }
                        } label: {
                            HStack {
                                Text("\(defaultFont) (System Font)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(EmeraldTheme.textMuted)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(EmeraldTheme.surfaceDark)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 高對比文字
                    SettingsToggleRow(title: "High Contrast Text", isOn: $highContrastText)
                }
            }
            
            // AI 寫作助手（快速預覽）
            SettingsCard(title: "AI Writing Assistant") {
                VStack(spacing: 20) {
                    HStack {
                        Text("AI Model")
                            .font(.system(size: 14))
                            .foregroundColor(EmeraldTheme.textSecondary)
                        
                        Spacer()
                        
                        Menu {
                            Button("Academic Pro (GPT-4 Turbo)") {}
                            Button("Standard (GPT-3.5)") {}
                            Button("Local (LLaMA)") {}
                        } label: {
                            HStack {
                                Text("Academic Pro (GPT-4 Turbo)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(EmeraldTheme.textMuted)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(EmeraldTheme.surfaceDark)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("Recommended for research papers")
                        .font(.system(size: 11))
                        .foregroundColor(EmeraldTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    SettingsToggleRow(
                        title: "Enable AI Suggestions",
                        subtitle: "Real-time phrasing, grammar, and citation suggestions",
                        isOn: .constant(true)
                    )
                }
            }
            
            // 版面
            SettingsCard(title: "Layout") {
                VStack(spacing: 20) {
                    SettingsToggleRow(
                        title: "Focus Mode (Distraction-Free)",
                        isOn: $focusMode
                    )
                    
                    HStack {
                        Text("Sidebar Width")
                            .font(.system(size: 14))
                            .foregroundColor(EmeraldTheme.textSecondary)
                        
                        Spacer()
                        
                        Slider(value: $sidebarWidth, in: 200...400, step: 20)
                            .accentColor(EmeraldTheme.primary)
                            .frame(width: 150)
                    }
                }
            }
        }
    }
}

// MARK: - 設定卡片

struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EmeraldTheme.surfaceDark.opacity(0.6))
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - 主題切換

struct ThemeToggle: View {
    let label: String
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isOn ? EmeraldTheme.primary : Color.white.opacity(0.1))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isOn ? EmeraldTheme.primary : Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(isOn ? .white : EmeraldTheme.textMuted)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toggle 行

struct SettingsToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(EmeraldTheme.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(EmeraldTheme.textMuted)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(EmeraldToggleStyle())
        }
    }
}

// MARK: - Toggle 樣式

struct EmeraldToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? EmeraldTheme.primary : EmeraldTheme.surfaceDark)
                .frame(width: 44, height: 24)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(configuration.isOn ? EmeraldTheme.primary : Color.white.opacity(0.1), lineWidth: 1)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

// MARK: - 其他設定頁面（簡化版）

struct GeneralSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("General")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            SettingsCard(title: "Startup") {
                SettingsToggleRow(title: "Open last document on launch", isOn: .constant(true))
                SettingsToggleRow(title: "Show welcome screen", isOn: .constant(false))
            }
        }
    }
}

struct AISettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("AI")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            SettingsCard(title: "AI Configuration") {
                Text("Configure AI models and preferences here.")
                    .font(.system(size: 14))
                    .foregroundColor(EmeraldTheme.textMuted)
            }
        }
    }
}

struct SyncSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Sync")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            SettingsCard(title: "Cloud Sync") {
                HStack {
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.system(size: 24))
                        .foregroundColor(EmeraldTheme.primary)
                    
                    Text("All changes synced")
                        .font(.system(size: 14))
                        .foregroundColor(EmeraldTheme.textSecondary)
                }
            }
        }
    }
}

struct AboutSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("About")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            SettingsCard(title: "OVEREND") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Academic Writing Assistant")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Version 2.1.0 (Build 450)")
                        .font(.system(size: 13))
                        .foregroundColor(EmeraldTheme.textMuted)
                    
                    Text("© 2026 All rights reserved.")
                        .font(.system(size: 12))
                        .foregroundColor(EmeraldTheme.textMuted)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EmeraldSettingsView()
        .environmentObject(AppTheme())
        .frame(width: 900, height: 700)
}
