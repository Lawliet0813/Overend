//
//  AIAssistantView.swift
//  OVEREND
//
//  AI 助手介面 - 使用 Apple Intelligence
//

import SwiftUI

/// AI 助手面板
struct AIAssistantView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AppleAIService.shared
    
    @ObservedObject var entry: Entry
    var onDismiss: (() -> Void)?
    
    @State private var generatedSummary: String = ""
    @State private var extractedKeywords: [String] = []
    @State private var selectedAction: AIAction = .summary
    @State private var errorMessage: String?
    
    enum AIAction: String, CaseIterable {
        case summary = "摘要"
        case keywords = "關鍵詞"
        case category = "分類"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accent)
                    
                    Text("AI 助手")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                // 可用性指示
                if aiService.isAvailable {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("已就緒")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("不可用")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                    }
                }
                
                // 關閉按鈕（總是顯示）
                Button(action: { 
                    onDismiss?()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                        .padding(4)
                        .background(Circle().fill(theme.itemHover))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(theme.toolbar)
            
            Divider()
            
            // 功能選擇
            HStack(spacing: 8) {
                ForEach(AIAction.allCases, id: \.self) { action in
                    Button(action: { selectedAction = action }) {
                        Text(action.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedAction == action ? .white : theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedAction == action ? theme.accent : theme.itemHover)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            
            Divider()
            
            // 內容區
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedAction {
                    case .summary:
                        summarySection
                    case .keywords:
                        keywordsSection
                    case .category:
                        categorySection
                    }
                }
                .padding(16)
            }
            
            // 錯誤訊息
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
            }
        }
        .frame(width: 320)
        .background(theme.sidebar)
    }
    
    // MARK: - 摘要區
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("文獻摘要")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.textMuted)
            
            if aiService.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在生成...")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if !generatedSummary.isEmpty {
                Text(generatedSummary)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textPrimary)
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.card)
                    )
                
                Button(action: copySummary) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("複製摘要")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: generateSummary) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("生成摘要")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.accent)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!aiService.isAvailable)
            }
        }
    }
    
    // MARK: - 關鍵詞區
    
    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("關鍵詞提取")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.textMuted)
            
            if aiService.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在提取...")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if !extractedKeywords.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(extractedKeywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.accentLight)
                            )
                    }
                }
            } else {
                Button(action: extractKeywords) {
                    HStack {
                        Image(systemName: "tag")
                        Text("提取關鍵詞")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.accent)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!aiService.isAvailable)
            }
        }
    }
    
    // MARK: - 分類區
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智慧分類建議")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.textMuted)
            
            Text("即將推出")
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
    }
    
    // MARK: - 方法
    
    private func generateSummary() {
        Task {
            do {
                let abstract = entry.fields["abstract"] ?? ""
                generatedSummary = try await aiService.generateSummary(
                    title: entry.title,
                    abstract: abstract.isEmpty ? nil : abstract
                )
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func extractKeywords() {
        Task {
            do {
                let abstract = entry.fields["abstract"] ?? entry.title
                extractedKeywords = try await aiService.extractKeywords(
                    title: entry.title,
                    abstract: abstract
                )
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func copySummary() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedSummary, forType: .string)
        ToastManager.shared.showSuccess("已複製摘要")
    }
}

// MARK: - 簡易 FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = Entry(context: context)
    entry.id = UUID()
    entry.entryType = "article"
    entry.fields = [
        "title": "深度學習在自然語言處理中的應用",
        "author": "張三",
        "year": "2024"
    ]
    
    return AIAssistantView(entry: entry)
        .environmentObject(AppTheme())
        .frame(height: 500)
}
