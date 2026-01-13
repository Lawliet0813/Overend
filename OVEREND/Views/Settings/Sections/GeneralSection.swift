//
//  GeneralSection.swift
//  OVEREND
//
//  一般設定區塊
//

import SwiftUI

struct GeneralSection: View {
    @EnvironmentObject var theme: AppTheme
    @AppStorage("autoSaveEnabled") private var autoSaveEnabled = true
    @AppStorage("spellCheckEnabled") private var spellCheckEnabled = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "gearshape", title: "一般設定")
            
            VStack(spacing: 12) {
                // 應用資訊
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OVEREND")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("版本 1.0.0 (macOS 26.0)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button("檢查更新") {
                        // Check updates
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.emerald)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.emerald.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(8)
                
                // 自動儲存
                SettingsRow(
                    title: "自動儲存",
                    description: "每 30 秒自動儲存你的工作。"
                ) {
                    Toggle("", isOn: $autoSaveEnabled)
                        .toggleStyle(.switch)
                        .tint(theme.emerald)
                }
                
                // 拼字檢查
                SettingsRow(
                    title: "拼字檢查",
                    description: "輸入時標示拼寫錯誤。"
                ) {
                    Toggle("", isOn: $spellCheckEnabled)
                        .toggleStyle(.switch)
                        .tint(theme.emerald)
                }
            }
        }
    }
}

#Preview {
    GeneralSection()
        .padding(32)
        .background(Color(hex: "#10221a"))
        .environmentObject(AppTheme())
}
