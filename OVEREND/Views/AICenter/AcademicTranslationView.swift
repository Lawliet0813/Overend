//
//  AcademicTranslationView.swift
//  OVEREND
//
//  學術翻譯介面
//

import SwiftUI

/// 學術翻譯視圖
@available(macOS 26.0, *)
struct AcademicTranslationView: View {
    @EnvironmentObject var theme: AppTheme
    
    @StateObject private var service = AcademicLanguageService.shared
    
    // 輸入狀態
    @State private var inputText: String = ""
    @State private var sourceLanguage: AcademicLanguage = .chinese
    @State private var targetLanguage: AcademicLanguage = .english
    @State private var preserveStyle: Bool = true
    @State private var selectedField: AcademicField?
    
    // 輸出狀態
    @State private var translatedText: String = ""
    @State private var bilingualResult: BilingualResult?
    @State private var showBilingual: Bool = false
    
    // UI 狀態
    @State private var errorMessage: String?
    @State private var showCopiedToast: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                // 語言選擇區
                languageSelectionSection
                
                // 輸入區
                inputSection
                
                // 選項區
                optionsSection
                
                // 操作按鈕
                actionButtons
                
                // 輸出區
                if !translatedText.isEmpty || bilingualResult != nil {
                    outputSection
                }
                
                // 錯誤訊息
                if let error = errorMessage {
                    errorView(error)
                }
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .overlay {
            if showCopiedToast {
                copiedToastView
            }
        }
    }
    
    // MARK: - 語言選擇區
    
    private var languageSelectionSection: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            // 來源語言
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("來源語言")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundColor(theme.textMuted)
                
                Picker("來源語言", selection: $sourceLanguage) {
                    ForEach(AcademicLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // 交換按鈕
            Button(action: swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: DesignTokens.IconSize.medium))
                    .foregroundColor(theme.accent)
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        Circle()
                            .fill(theme.accentLight)
                    )
            }
            .buttonStyle(.plain)
            .help("交換語言")
            
            // 目標語言
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("目標語言")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundColor(theme.textMuted)
                
                Picker("目標語言", selection: $targetLanguage) {
                    ForEach(AcademicLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(theme.card)
        )
        .onChange(of: sourceLanguage) { _, newValue in
            if newValue == targetLanguage {
                targetLanguage = newValue == .chinese ? .english : .chinese
            }
        }
        .onChange(of: targetLanguage) { _, newValue in
            if newValue == sourceLanguage {
                sourceLanguage = newValue == .chinese ? .english : .chinese
            }
        }
    }
    
    // MARK: - 輸入區
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("輸入文本")
                    .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(inputText.count) 字")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            
            TextEditor(text: $inputText)
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(DesignTokens.Spacing.md)
                .frame(minHeight: 150, maxHeight: 300)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(theme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                .stroke(theme.border, lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - 選項區
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("翻譯選項")
                .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: DesignTokens.Spacing.xl) {
                // 保持學術風格
                Toggle(isOn: $preserveStyle) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "graduationcap")
                            .foregroundColor(theme.accent)
                        Text("保持學術風格")
                            .font(.system(size: DesignTokens.Typography.body))
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .toggleStyle(.switch)
                
                Divider()
                    .frame(height: 20)
                
                // 學科領域
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "books.vertical")
                        .foregroundColor(theme.accent)
                    
                    Picker("學科領域", selection: $selectedField) {
                        Text("通用").tag(nil as AcademicField?)
                        ForEach(AcademicField.allCases) { field in
                            Text(field.displayName).tag(field as AcademicField?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(theme.card)
            )
        }
    }
    
    // MARK: - 操作按鈕
    
    private var actionButtons: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 翻譯按鈕
            Button(action: translateText) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if service.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    Text("翻譯")
                }
                .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(inputText.isEmpty || service.isProcessing ? theme.textMuted : theme.accent)
                )
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || service.isProcessing)
            
            // 雙語對照按鈕
            Button(action: generateBilingual) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if service.isProcessing && showBilingual {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "text.below.photo")
                    }
                    Text("雙語對照")
                }
                .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                .foregroundColor(theme.accent)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(theme.accentLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                .stroke(theme.accent, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || service.isProcessing)
            
            Spacer()
            
            // 清除按鈕
            if !inputText.isEmpty || !translatedText.isEmpty {
                Button(action: clearAll) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "trash")
                        Text("清除")
                    }
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - 輸出區
    
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("翻譯結果")
                    .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // 複製按鈕
                Button(action: copyTranslation) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "doc.on.doc")
                        Text("複製")
                    }
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            }
            
            if let bilingual = bilingualResult, showBilingual {
                // 雙語對照視圖
                bilingualView(bilingual)
            } else {
                // 單語翻譯結果
                Text(translatedText)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textPrimary)
                    .textSelection(.enabled)
                    .padding(DesignTokens.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(theme.card)
                    )
            }
        }
    }
    
    // MARK: - 雙語對照視圖
    
    private func bilingualView(_ result: BilingualResult) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // 原文
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text("原文（\(result.sourceLanguage.displayName)）")
                        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                }
                
                Text(result.original)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textPrimary)
                    .textSelection(.enabled)
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(theme.background)
                    )
            }
            
            // 譯文
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text("譯文（\(result.targetLanguage.displayName)）")
                        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                }
                
                Text(result.translated)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textPrimary)
                    .textSelection(.enabled)
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(theme.accentLight)
                    )
            }
            
            // 術語註解
            if let notes = result.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("術語說明")
                        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    ForEach(notes, id: \.term) { note in
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Text("•")
                                .foregroundColor(theme.accent)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.term)
                                    .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                                    .foregroundColor(theme.textPrimary)
                                
                                Text(note.explanation)
                                    .font(.system(size: DesignTokens.Typography.caption))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                .stroke(theme.border, lineWidth: 1)
                        )
                )
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(theme.card)
        )
    }
    
    // MARK: - 錯誤視圖
    
    private func errorView(_ message: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(.red)
            
            Spacer()
            
            Button(action: { errorMessage = nil }) {
                Image(systemName: "xmark")
                    .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(Color.red.opacity(0.1))
        )
    }
    
    // MARK: - Toast 視圖
    
    private var copiedToastView: some View {
        VStack {
            Spacer()
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("已複製到剪貼簿")
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textPrimary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(theme.card)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            )
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - 動作
    
    private func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        
        // 同時交換文字
        if !translatedText.isEmpty {
            let tempText = inputText
            inputText = translatedText
            translatedText = tempText
        }
    }
    
    private func translateText() {
        guard !inputText.isEmpty else { return }
        
        errorMessage = nil
        showBilingual = false
        
        Task {
            do {
                var options = TranslationOptions()
                options.preserveStyle = preserveStyle
                options.fieldContext = selectedField
                
                translatedText = try await service.translateAcademicExpression(
                    text: inputText,
                    from: sourceLanguage,
                    to: targetLanguage,
                    options: options
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func generateBilingual() {
        guard !inputText.isEmpty else { return }
        
        errorMessage = nil
        showBilingual = true
        
        Task {
            do {
                bilingualResult = try await service.generateBilingualComparison(
                    text: inputText,
                    sourceLanguage: sourceLanguage
                )
                translatedText = bilingualResult?.translated ?? ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func copyTranslation() {
        let textToCopy: String
        if showBilingual, let result = bilingualResult {
            textToCopy = """
            【原文】
            \(result.original)
            
            【譯文】
            \(result.translated)
            """
        } else {
            textToCopy = translatedText
        }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToCopy, forType: .string)
        
        withAnimation {
            showCopiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    private func clearAll() {
        inputText = ""
        translatedText = ""
        bilingualResult = nil
        showBilingual = false
        errorMessage = nil
    }
}
