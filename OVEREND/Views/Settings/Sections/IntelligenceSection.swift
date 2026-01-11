//
//  IntelligenceSection.swift
//  OVEREND
//
//  AI 設定區塊
//

import SwiftUI

struct IntelligenceSection: View {
    @EnvironmentObject var theme: AppTheme
    @State private var selectedModel = "Apple Intelligence"
    @State private var autoCitationEnabled = true
    
    private let aiModels = ["Apple Intelligence", "Gemini Pro", "Claude 3.5 Sonnet"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "brain.head.profile", title: "AI 智慧助理")
            
            VStack(spacing: 12) {
                // AI 模型選擇
                SettingsRow(
                    title: "AI 模型",
                    description: "選擇用於文字生成的基礎模型。"
                ) {
                    Picker("", selection: $selectedModel) {
                        ForEach(aiModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(theme.emerald.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(20)
                }
                
                // Auto-Citation
                SettingsRow(
                    title: "自動引用",
                    description: "輸入時自動建議相關文獻引用。"
                ) {
                    Toggle("", isOn: $autoCitationEnabled)
                        .toggleStyle(.switch)
                        .tint(theme.emerald)
                }
                
                // Apple Intelligence 狀態
                SettingsRow(
                    title: "Apple Intelligence",
                    description: "裝置端 AI 處理短文本（< 1000 字元）。"
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("已啟用")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - 設定行

struct SettingsRow<Trailing: View>: View {
    let title: String
    let description: String
    @ViewBuilder let trailing: () -> Trailing
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            trailing()
        }
        .padding(16)
        .background(Color.white.opacity(isHovered ? 0.08 : 0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(isHovered ? 0.1 : 0.05), lineWidth: 1)
        )
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    IntelligenceSection()
        .padding(32)
        .background(Color(hex: "#10221a"))
        .environmentObject(AppTheme())
}
