//
//  ImportOptionsSheet.swift
//  OVEREND
//
//  匯入選項對話框
//

import SwiftUI

// MARK: - 匯入選項 Sheet

struct ImportOptionsSheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    let onImportBibTeX: () -> Void
    let onImportPDF: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("匯入文獻")
                .font(.system(size: 18, weight: .bold))
            
            HStack(spacing: 20) {
                // BibTeX 匯入
                ImportOptionCard(
                    icon: "doc.text",
                    title: "BibTeX",
                    description: "匯入 .bib 書目檔案"
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onImportBibTeX()
                    }
                }
                
                // PDF 匯入
                ImportOptionCard(
                    icon: "doc.richtext",
                    title: "PDF",
                    description: "匯入 PDF 並建立書目"
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onImportPDF()
                    }
                }
            }
            
            SecondaryButton("取消") {
                dismiss()
            }
            .environmentObject(theme)
            .keyboardShortcut(.escape)
        }
        .padding(32)
    }
}

// MARK: - 匯入選項卡片

struct ImportOptionCard: View {
    @EnvironmentObject var theme: AppTheme
    
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isHovered ? theme.accent : theme.accentLight)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isHovered ? .white : theme.accent)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(width: 160)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.elevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isHovered ? theme.accent : theme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AnimationSystem.Easing.quick) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    ImportOptionsSheet(
        onImportBibTeX: {},
        onImportPDF: {}
    )
    .environmentObject(AppTheme())
}
