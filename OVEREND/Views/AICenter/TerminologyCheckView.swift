//
//  TerminologyCheckView.swift
//  OVEREND
//
//  術語檢查介面 - 繁簡學術詞彙校正
//
//  功能：
//  - 即時偵測簡體中文術語
//  - 自動校正為繁體中文學術用語
//  - 顯示校正前後對比
//

import SwiftUI

/// 術語檢查視圖
@available(macOS 26.0, *)
struct TerminologyCheckView: View {
    @EnvironmentObject var theme: AppTheme
    
    // 服務
    private let firewall = TerminologyFirewall.shared
    
    // 狀態
    @State private var inputText: String = ""
    @State private var result: TerminologyResult?
    @State private var selectedField: AcademicField?
    @State private var showCopiedToast: Bool = false
    
    var body: some View {
        HSplitView {
            // 左側：輸入區
            inputPanel
                .frame(minWidth: 400)
            
            // 右側：結果區
            resultPanel
                .frame(minWidth: 400)
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showCopiedToast)
    }
    
    // MARK: - 輸入面板
    
    private var inputPanel: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(theme.accent)
                Text("輸入文字")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                
                Spacer()
                
                Text("\(inputText.count) 字")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            .padding()
            
            Divider()
            
            // 文字輸入區
            TextEditor(text: $inputText)
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding()
                .background(theme.background)
            
            Divider()
            
            // 選項區
            VStack(spacing: DesignTokens.Spacing.md) {
                // 學科領域選擇
                HStack {
                    Text("學科領域")
                        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    
                    Picker("", selection: $selectedField) {
                        Text("通用").tag(nil as AcademicField?)
                        ForEach(AcademicField.allCases) { field in
                            Text(field.displayName).tag(field as AcademicField?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                    
                    Spacer()
                    
                    // 檢查按鈕
                    Button {
                        checkTerminology()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("檢查術語")
                        }
                        .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
                    .disabled(inputText.isEmpty)
                }
                
                // 統計資訊
                HStack(spacing: DesignTokens.Spacing.lg) {
                    statisticBadge(
                        title: "規則數",
                        value: "\(firewall.statistics.total)",
                        icon: "list.bullet"
                    )
                    statisticBadge(
                        title: "強制替換",
                        value: "\(firewall.statistics.forceReplace)",
                        icon: "arrow.left.arrow.right"
                    )
                    statisticBadge(
                        title: "上下文判斷",
                        value: "\(firewall.statistics.contextual)",
                        icon: "brain"
                    )
                }
            }
            .padding()
            .background(theme.card)
        }
        .background(theme.background)
    }
    
    private func statisticBadge(title: String, value: String, icon: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(theme.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: DesignTokens.Typography.body, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                Text(title)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(theme.background)
        )
    }
    
    // MARK: - 結果面板
    
    private var resultPanel: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(theme.accent)
                Text("校正結果")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                
                Spacer()
                
                if let result = result {
                    // 統計
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        if result.correctionCount > 0 {
                            Label("\(result.correctionCount) 項校正", systemImage: "arrow.left.arrow.right")
                                .font(.system(size: DesignTokens.Typography.caption))
                                .foregroundColor(.orange)
                        }
                        if result.suggestionCount > 0 {
                            Label("\(result.suggestionCount) 項建議", systemImage: "lightbulb")
                                .font(.system(size: DesignTokens.Typography.caption))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding()
            
            Divider()
            
            if let result = result {
                // 結果內容
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // 校正後文字
                        correctedTextSection(result)
                        
                        // 校正項目列表
                        if !result.corrections.isEmpty {
                            correctionsListSection(result)
                        }
                    }
                    .padding()
                }
            } else {
                // 空狀態
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "character.textbox")
                        .font(.system(size: 48))
                        .foregroundColor(theme.textMuted)
                    
                    Text("輸入文字後點擊「檢查術語」")
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(theme.textSecondary)
                    
                    Text("系統將自動偵測並校正簡體中文術語")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(theme.background)
    }
    
    private func correctedTextSection(_ result: TerminologyResult) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("校正後文字")
                    .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    copyToClipboard(result.correctedText)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("複製")
                    }
                    .font(.system(size: DesignTokens.Typography.caption))
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.accent)
            }
            
            Text(result.correctedText)
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textPrimary)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.card)
                .cornerRadius(DesignTokens.CornerRadius.medium)
        }
    }
    
    private func correctionsListSection(_ result: TerminologyResult) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("校正項目")
                .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            ForEach(result.corrections) { correction in
                correctionRow(correction)
            }
        }
    }
    
    private func correctionRow(_ correction: TerminologyCorrection) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 狀態圖標
            Image(systemName: correction.wasApplied ? "checkmark.circle.fill" : "lightbulb.fill")
                .foregroundColor(correction.wasApplied ? .green : .orange)
            
            // 原始詞彙
            VStack(alignment: .leading, spacing: 2) {
                Text(correction.original)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textPrimary)
                    .strikethrough(correction.wasApplied, color: .red)
                
                Text("簡體/大陸用語")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            
            // 箭頭
            Image(systemName: "arrow.right")
                .foregroundColor(theme.textMuted)
            
            // 校正後詞彙
            VStack(alignment: .leading, spacing: 2) {
                Text(correction.corrected)
                    .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                    .foregroundColor(theme.accent)
                
                Text("繁體/台灣用語")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
            
            // 狀態標籤
            Text(correction.wasApplied ? "已校正" : "建議")
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundColor(correction.wasApplied ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill((correction.wasApplied ? Color.green : Color.orange).opacity(0.2))
                )
        }
        .padding()
        .background(theme.card)
        .cornerRadius(DesignTokens.CornerRadius.medium)
    }
    
    // MARK: - Toast
    
    private var copiedToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("已複製到剪貼簿")
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            Capsule()
                .fill(theme.card)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    // MARK: - 動作
    
    private func checkTerminology() {
        result = firewall.process(inputText, field: selectedField)
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        showCopiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedToast = false
        }
    }
}

// MARK: - Preview

@available(macOS 26.0, *)
#Preview {
    TerminologyCheckView()
        .environmentObject(AppTheme())
        .frame(width: 900, height: 600)
}
