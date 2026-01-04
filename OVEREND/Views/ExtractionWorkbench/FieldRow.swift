//
//  FieldRow.swift
//  OVEREND
//
//  欄位對照顯示/編輯元件
//

import SwiftUI

/// 欄位對照元件：顯示 AI 提取值和可編輯的修正值
struct FieldRow: View {
    let label: String
    let aiValue: String?
    @Binding var correctedValue: String
    let isEditing: Bool
    
    @EnvironmentObject var theme: AppTheme
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 標籤
            Text(label)
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundColor(theme.textMuted)
            
            if isEditing {
                // 編輯模式：顯示 AI 值 + 可編輯欄位
                VStack(alignment: .leading, spacing: 8) {
                    // AI 提取值（參考）
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))
                        Text("AI: \(aiValue ?? "未提取")")
                            .font(.system(size: DesignTokens.Typography.caption))
                    }
                    .foregroundColor(Color(hex: "#FF9800"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#FF9800").opacity(0.1))
                    )
                    
                    // 修正輸入欄位
                    TextField("輸入修正值...", text: $correctedValue)
                        .textFieldStyle(.plain)
                        .font(.system(size: DesignTokens.Typography.body))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(theme.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                        .stroke(theme.accent.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            } else {
                // 檢視模式：只顯示 AI 值或修正值
                HStack {
                    Text(displayValue)
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(hasCorrection ? theme.success : theme.textPrimary)
                    
                    if hasCorrection {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.success)
                    }
                    
                    Spacer()
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .stroke(theme.border, lineWidth: 1)
                        )
                )
            }
        }
    }
    
    /// 顯示的值：優先使用修正值
    private var displayValue: String {
        if hasCorrection {
            return correctedValue
        }
        return aiValue ?? "未提取"
    }
    
    /// 是否有修正值
    private var hasCorrection: Bool {
        !correctedValue.isEmpty
    }
}

/// 只讀版本的欄位顯示
struct FieldRowDisplay: View {
    let label: String
    let aiValue: String?
    let correctedValue: String?
    
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundColor(theme.textMuted)
            
            HStack {
                if let corrected = correctedValue, !corrected.isEmpty {
                    // 有修正
                    VStack(alignment: .leading, spacing: 2) {
                        Text(corrected)
                            .font(.system(size: DesignTokens.Typography.body))
                            .foregroundColor(theme.textPrimary)
                        
                        if let ai = aiValue, !ai.isEmpty, ai != corrected {
                            Text("原始: \(ai)")
                                .font(.system(size: 11))
                                .foregroundColor(theme.textMuted)
                                .strikethrough()
                        }
                    }
                } else {
                    // 無修正，顯示 AI 值
                    Text(aiValue ?? "—")
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(aiValue != nil ? theme.textPrimary : theme.textMuted)
                }
                
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.card)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FieldRow(
            label: "標題",
            aiValue: "On the Electrodynamics of Moving Bodies",
            correctedValue: .constant(""),
            isEditing: false
        )
        
        FieldRow(
            label: "作者",
            aiValue: "Albert Einstein",
            correctedValue: .constant("A. Einstein"),
            isEditing: false
        )
        
        FieldRow(
            label: "年份",
            aiValue: "1905",
            correctedValue: .constant(""),
            isEditing: true
        )
        
        Divider()
        
        FieldRowDisplay(
            label: "期刊",
            aiValue: "Annalen der Physik",
            correctedValue: nil
        )
    }
    .padding()
    .frame(width: 400)
    .environmentObject(AppTheme())
}
