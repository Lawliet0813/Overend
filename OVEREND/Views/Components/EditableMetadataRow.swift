//
//  EditableMetadataRow.swift
//  OVEREND
//
//  可編輯的書目欄位元件
//

import SwiftUI

/// 可編輯的書目欄位行
struct EditableMetadataRow: View {
    @EnvironmentObject var theme: AppTheme
    
    let label: String
    @Binding var value: String
    var isRequired: Bool = false
    var isMultiline: Bool = false
    var placeholder: String = ""
    var hint: String? = nil
    var validator: ((String) -> (Bool, String?))? = nil
    
    @State private var validationError: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 標籤
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textMuted)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            
            // 輸入欄位
            if isMultiline {
                TextEditor(text: $value)
                    .font(.system(size: 14))
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(validationError != nil ? Color.red : theme.border, lineWidth: 1)
                            )
                    )
                    .onChange(of: value) { oldValue, newValue in
                        validateField(newValue)
                    }
            } else {
                TextField(placeholder, text: $value)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(validationError != nil ? Color.red : theme.border, lineWidth: 1)
                            )
                    )
                    .onChange(of: value) { oldValue, newValue in
                        validateField(newValue)
                    }
            }
            
            // 提示或錯誤訊息
            if let error = validationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 12))
                }
                .foregroundColor(.red)
            } else if let hint = hint {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                    Text(hint)
                        .font(.system(size: 12))
                }
                .foregroundColor(theme.accent)
            }
        }
    }
    
    // MARK: - 驗證
    
    private func validateField(_ value: String) {
        // 必填檢查
        if isRequired && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "此欄位為必填"
            return
        }
        
        // 自訂驗證
        if let validator = validator {
            let (isValid, errorMessage) = validator(value)
            validationError = isValid ? nil : errorMessage
        } else {
            validationError = nil
        }
    }
}

// MARK: - 預覽

#Preview {
    let theme = AppTheme()
    
    return VStack(spacing: 20) {
        EditableMetadataRow(
            label: "標題",
            value: .constant("機器學習的應用"),
            isRequired: true,
            placeholder: "請輸入標題"
        )
        .environmentObject(theme)
        
        EditableMetadataRow(
            label: "作者",
            value: .constant("Zhang, L. & Chen, M."),
            placeholder: "請輸入作者",
            hint: "建議格式：Last, F. & Last, F."
        )
        .environmentObject(theme)
        
        EditableMetadataRow(
            label: "摘要",
            value: .constant("這是一篇關於機器學習的論文..."),
            isMultiline: true,
            placeholder: "請輸入摘要"
        )
        .environmentObject(theme)
        
        EditableMetadataRow(
            label: "年份",
            value: .constant("abc"),
            isRequired: true,
            placeholder: "YYYY",
            validator: { value in
                if let year = Int(value), year >= 1900 && year <= 2100 {
                    return (true, nil)
                } else {
                    return (false, "請輸入有效的年份（1900-2100）")
                }
            }
        )
        .environmentObject(theme)
    }
    .padding(20)
    .frame(width: 400)
}
