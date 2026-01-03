//
//  AcademicStandardsCheckView.swift
//  OVEREND
//
//  台灣學術規範檢查介面
//

import SwiftUI

/// 學術規範檢查視圖
@available(macOS 26.0, *)
struct AcademicStandardsCheckView: View {
    @EnvironmentObject var theme: AppTheme
    
    @StateObject private var aiService = UnifiedAIService.shared
    
    // 輸入狀態
    @State private var inputText: String = ""
    @State private var documentTitle: String = ""
    @State private var documentType: DocumentType = .thesis
    
    // 選項狀態
    @State private var checkTerminology: Bool = true
    @State private var checkCitation: Bool = true
    @State private var checkFormat: Bool = true
    @State private var checkStyle: Bool = true
    @State private var citationStyle: CitationStyle = .apa7
    
    // 結果狀態
    @State private var checkResult: ComplianceReport?
    @State private var selectedIssueType: StandardsIssueType?
    
    // UI 狀態
    @State private var errorMessage: String?
    @State private var showingQuickCheck: Bool = false
    @State private var showDocumentImport: Bool = false
    
    var body: some View {
        HSplitView {
            // 左側：輸入與選項
            inputPanel
                .frame(minWidth: 350, maxWidth: 500)
            
            // 右側：檢查結果
            resultsPanel
                .frame(minWidth: 400)
        }
    }
    
    // MARK: - 輸入面板
    
    private var inputPanel: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // 文件資訊
                documentInfoSection
                
                // 文件內容
                contentSection
                
                // 檢查選項
                optionsSection
                
                // 操作按鈕
                actionButtonsSection
                
                // 錯誤訊息
                if let error = errorMessage {
                    errorView(error)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(theme.background)
        .sheet(isPresented: $showDocumentImport) {
            DocumentPicker { document, content in
                documentTitle = document.title
                inputText = content
            }
            .environmentObject(theme)
        }
    }
    
    // MARK: - 文件資訊區
    
    private var documentInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("文件資訊")
                .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                // 文件標題
                HStack {
                    Text("標題")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                        .frame(width: 60, alignment: .leading)
                    
                    TextField("文件標題（選填）", text: $documentTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: DesignTokens.Typography.body))
                        .padding(DesignTokens.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(theme.background)
                        )
                }
                
                // 文件類型
                HStack {
                    Text("類型")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                        .frame(width: 60, alignment: .leading)
                    
                    Picker("文件類型", selection: $documentType) {
                        ForEach(DocumentType.allCases, id: \.rawValue) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(theme.card)
            )
        }
    }
    
    // MARK: - 內容區
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("文件內容")
                    .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // 從寫作中心導入按鈕
                Button(action: { showDocumentImport = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("從寫作中心導入")
                    }
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
                .help("從寫作中心導入文稿內容")
                
                Text("\(inputText.count) 字")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            
            TextEditor(text: $inputText)
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(DesignTokens.Spacing.md)
                .frame(minHeight: 200)
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
            Text("檢查項目")
                .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                // 檢查項目切換
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignTokens.Spacing.sm) {
                    checkItemToggle(
                        isOn: $checkTerminology,
                        icon: "textformat",
                        title: "用語規範",
                        description: "教育部繁中用語"
                    )
                    
                    checkItemToggle(
                        isOn: $checkCitation,
                        icon: "quote.bubble",
                        title: "引用格式",
                        description: "學術引用規範"
                    )
                    
                    checkItemToggle(
                        isOn: $checkFormat,
                        icon: "doc.text",
                        title: "論文格式",
                        description: "碩博士論文格式"
                    )
                    
                    checkItemToggle(
                        isOn: $checkStyle,
                        icon: "pencil.line",
                        title: "行文風格",
                        description: "學術寫作風格"
                    )
                }
                
                Divider()
                
                // 引用格式選擇
                HStack {
                    Text("引用格式")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                    
                    Picker("引用格式", selection: $citationStyle) {
                        ForEach(CitationStyle.allCases, id: \.rawValue) { style in
                            Text(style.displayName).tag(style)
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
    
    private func checkItemToggle(
        isOn: Binding<Bool>,
        icon: String,
        title: String,
        description: String
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.small))
                    .foregroundColor(isOn.wrappedValue ? theme.accent : theme.textMuted)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(description)
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                }
            }
        }
        .toggleStyle(.switch)
    }
    
    // MARK: - 操作按鈕區
    
    private var actionButtonsSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 完整檢查按鈕
            Button(action: performFullCheck) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if aiService.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "checkmark.shield")
                    }
                    Text("完整檢查")
                }
                .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(inputText.isEmpty || aiService.isProcessing ? theme.textMuted : theme.accent)
                )
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || aiService.isProcessing)
            
            // 快速檢查按鈕
            Button(action: performQuickCheck) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "bolt")
                    Text("快速檢查")
                }
                .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                .foregroundColor(theme.accent)
                .frame(maxWidth: .infinity)
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
            .disabled(inputText.isEmpty || aiService.isProcessing)
        }
    }
    
    // MARK: - 結果面板
    
    private var resultsPanel: some View {
        VStack(spacing: 0) {
            // 結果標題
            resultsHeader
            
            Divider()
            
            if let result = checkResult {
                // 結果摘要
                resultsSummary(result)
                
                Divider()
                
                // 問題類型過濾
                issueTypeFilter(result)
                
                Divider()
                
                // 問題列表
                issuesList(result)
            } else if aiService.isProcessing {
                // 載入中
                progressView
            } else {
                // 空狀態
                emptyStateView
            }
        }
        .background(theme.card)
    }
    
    private var resultsHeader: some View {
        HStack {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: DesignTokens.IconSize.medium))
                .foregroundColor(theme.accent)
            
            Text("檢查結果")
                .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            if checkResult != nil {
                Button(action: { checkResult = nil }) {
                    Text("清除")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
    
    private func resultsSummary(_ result: ComplianceReport) -> some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            // 錯誤數量
            summaryCard(
                count: result.errorCount,
                label: "錯誤",
                color: .red,
                icon: "xmark.circle.fill"
            )
            
            // 警告數量
            summaryCard(
                count: result.warningCount,
                label: "警告",
                color: .orange,
                icon: "exclamationmark.triangle.fill"
            )
            
            // 建議數量
            summaryCard(
                count: result.suggestionCount,
                label: "建議",
                color: .blue,
                icon: "lightbulb.fill"
            )
            
            Spacer()
            
            // 合規狀態
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: result.isCompliant ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: DesignTokens.IconSize.large))
                    .foregroundColor(result.isCompliant ? .green : .red)
                
                Text(result.isCompliant ? "符合規範" : "需要修正")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundColor(result.isCompliant ? .green : .red)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(theme.background)
    }
    
    private func summaryCard(count: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(count)")
                    .font(.system(size: DesignTokens.Typography.title2, weight: .bold))
                    .foregroundColor(theme.textPrimary)
            }
            
            Text(label)
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
        }
    }
    
    private func issueTypeFilter(_ result: ComplianceReport) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // 全部
                filterButton(
                    title: "全部",
                    count: result.totalCount,
                    isSelected: selectedIssueType == nil,
                    action: { selectedIssueType = nil }
                )
                
                // 各類型
                ForEach(StandardsIssueType.allCases) { type in
                    let count = result.issuesByType[type]?.count ?? 0
                    if count > 0 {
                        filterButton(
                            title: type.displayName,
                            count: count,
                            isSelected: selectedIssueType == type,
                            action: { selectedIssueType = type }
                        )
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
    }
    
    private func filterButton(
        title: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(.system(size: DesignTokens.Typography.caption, weight: isSelected ? .semibold : .regular))
                
                Text("\(count)")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? theme.accent : theme.itemHover)
                    )
                    .foregroundColor(isSelected ? .white : theme.textMuted)
            }
            .foregroundColor(isSelected ? theme.accent : theme.textSecondary)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(isSelected ? theme.accentLight : .clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func issuesList(_ result: ComplianceReport) -> some View {
        let filteredIssues = selectedIssueType == nil 
            ? result.issues 
            : result.issues.filter { $0.type == selectedIssueType }
        
        return ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(filteredIssues) { issue in
                    IssueRow(issue: issue)
                        .environmentObject(theme)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
    
    private var progressView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text("正在檢查中...")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.textMuted)
            
            Text("尚未進行檢查")
                .font(.system(size: DesignTokens.Typography.title3, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
            Text("輸入文件內容並點擊檢查按鈕")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // MARK: - 動作
    
    private func performFullCheck() {
        guard !inputText.isEmpty else { return }
        
        errorMessage = nil
        selectedIssueType = nil
        
        Task {
            do {
                let document = CheckDocument(
                    content: inputText,
                    title: documentTitle.isEmpty ? nil : documentTitle,
                    documentType: documentType
                )
                
                var options = UnifiedStandardsCheckOptions()
                options.checkTerminology = checkTerminology
                options.checkCitation = checkCitation
                options.checkFormat = checkFormat
                options.checkStyle = checkStyle
                options.citationStyle = citationStyle
                
                checkResult = try await aiService.standards.checkCompliance(
                    document: document,
                    options: options
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func performQuickCheck() {
        guard !inputText.isEmpty else { return }
        
        errorMessage = nil
        selectedIssueType = nil
        showingQuickCheck = true
        
        Task {
            do {
                let issues = try await aiService.standards.quickCheck(text: inputText)
                
                checkResult = ComplianceReport(
                    issues: issues,
                    checkedAt: Date(),
                    documentTitle: nil
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            showingQuickCheck = false
        }
    }
}

// MARK: - 問題行視圖

struct IssueRow: View {
    @EnvironmentObject var theme: AppTheme
    
    let issue: StandardsIssue
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // 主要內容
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // 嚴重程度圖標
                Image(systemName: issue.severity.icon)
                    .foregroundColor(issue.severity.color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    // 類型標籤
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: issue.type.icon)
                            .font(.system(size: 10))
                        Text(issue.type.displayName)
                            .font(.system(size: DesignTokens.Typography.caption))
                    }
                    .foregroundColor(theme.textMuted)
                    
                    // 問題描述
                    Text(issue.description)
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(theme.textPrimary)
                    
                    // 原始文字
                    if let original = issue.originalText {
                        Text("「\(original)」")
                            .font(.system(size: DesignTokens.Typography.body))
                            .foregroundColor(issue.severity.color)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                    .fill(issue.severity.color.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
                // 展開按鈕
                if issue.suggestion != nil || issue.reference != nil {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 展開內容
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    // 修正建議
                    if let suggestion = issue.suggestion {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("建議修正為")
                                    .font(.system(size: DesignTokens.Typography.caption))
                                    .foregroundColor(theme.textMuted)
                                
                                Text(suggestion)
                                    .font(.system(size: DesignTokens.Typography.body))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // 參考來源
                    if let reference = issue.reference {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "book")
                                .foregroundColor(theme.textMuted)
                                .frame(width: 20)
                            
                            Text(reference)
                                .font(.system(size: DesignTokens.Typography.caption))
                                .foregroundColor(theme.textMuted)
                        }
                    }
                }
                .padding(.leading, 32)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(issue.severity.color.opacity(0.3), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

