//
//  AITextAnalysisPanel.swift
//  OVEREND
//
//  AI 文本分析面板 - 提供語法、拼寫、風格建議
//  類似 Claude Writing Assistant 的分析功能
//

import SwiftUI

// MARK: - AI 文本分析面板

struct AITextAnalysisPanel: View {
    @EnvironmentObject var theme: AppTheme
    @Binding var isVisible: Bool
    let attributedText: NSAttributedString
    let onApplySuggestion: (TextSuggestion) -> Void
    
    @State private var suggestions: [TextSuggestion] = []
    @State private var isAnalyzing = false
    @State private var activeCategory: SuggestionCategory = .all
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            header
            
            Divider()
            
            // 分類篩選
            categoryFilter
            
            Divider()
            
            // 建議列表
            if isAnalyzing {
                analyzingView
            } else if let error = error {
                errorView(error)
            } else if suggestions.isEmpty {
                emptyView
            } else {
                suggestionsList
            }
        }
        .frame(width: 320)
        .background(theme.elevated)  // 修正：使用 elevated 而非不存在的 surface
    }
    
    // MARK: - 標題列
    
    private var header: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(theme.accent)  // 修正：使用 accent 而非不存在的 primary
            
            Text("AI 文本分析")
                .font(theme.fontDisplaySmall)  // 修正：使用正確的字體屬性
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Button(action: analyzeText) {
                Image(systemName: isAnalyzing ? "stop.circle" : "arrow.clockwise")
                    .foregroundColor(theme.accent)  // 修正：使用 accent
            }
            .buttonStyle(.plain)
            .disabled(isAnalyzing)
            .help("分析文本")
            
            Button(action: { isVisible = false }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(theme.textTertiary)
            }
            .buttonStyle(.plain)
            .help("關閉")
        }
        .padding()
    }
    
    // MARK: - 分類篩選
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SuggestionCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        count: suggestions.filter { $0.category == category || category == .all }.count,
                        isActive: activeCategory == category,
                        action: { activeCategory = category }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 建議列表
    
    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredSuggestions) { suggestion in
                    SuggestionCard(
                        suggestion: suggestion,
                        onApply: { onApplySuggestion(suggestion) },
                        onDismiss: { dismissSuggestion(suggestion) }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - 狀態視圖
    
    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            
            Text("正在分析文本...")
                .font(theme.fontBodyMedium)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(theme.accent)

            Text("沒有建議")
                .font(theme.fontDisplaySmall)
                .foregroundColor(theme.textPrimary)
            
            Text("您的文本看起來很好！\n點擊上方按鈕重新分析。")
                .font(theme.fontBodySmall)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("分析失敗")
                .font(theme.fontDisplaySmall)
                .foregroundColor(theme.textPrimary)
            
            Text(message)
                .font(theme.fontBodySmall)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("重試") {
                analyzeText()
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private var filteredSuggestions: [TextSuggestion] {
        if activeCategory == .all {
            return suggestions
        }
        return suggestions.filter { $0.category == activeCategory }
    }
    
    private func analyzeText() {
        isAnalyzing = true
        error = nil
        
        // 提取純文本
        let text = attributedText.string
        
        // TODO: 整合 AI Service 進行分析
        // 目前使用模擬數據
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.suggestions = generateMockSuggestions(for: text)
            self.isAnalyzing = false
        }
    }
    
    private func dismissSuggestion(_ suggestion: TextSuggestion) {
        suggestions.removeAll { $0.id == suggestion.id }
    }
    
    // 模擬建議生成（實際應用中應替換為真實 AI 分析）
    private func generateMockSuggestions(for text: String) -> [TextSuggestion] {
        var result: [TextSuggestion] = []
        
        // 檢查常見問題
        if text.contains("的的") {
            result.append(TextSuggestion(
                category: .grammar,
                issue: "的的",
                suggestion: "的",
                explanation: "重複的助詞「的」可以刪除一個",
                position: text.range(of: "的的")?.lowerBound.utf16Offset(in: text) ?? 0
            ))
        }
        
        if text.contains("很好的") {
            result.append(TextSuggestion(
                category: .style,
                issue: "很好的",
                suggestion: "優秀的",
                explanation: "建議使用更具體、更專業的形容詞",
                position: text.range(of: "很好的")?.lowerBound.utf16Offset(in: text) ?? 0
            ))
        }
        
        return result
    }
}

// MARK: - 分類按鈕

private struct CategoryButton: View {
    @EnvironmentObject var theme: AppTheme
    let category: SuggestionCategory
    let count: Int
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(category.displayName)
                    .font(theme.fontBodySmall)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(theme.fontBodySmall)
                }
            }
            .foregroundColor(isActive ? .white : theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? categoryColor : theme.card)
            .cornerRadius(theme.cornerRadiusSM)  // 修正：使用 cornerRadiusSM
        }
        .buttonStyle(.plain)
    }
    
    private var categoryColor: Color {
        switch category {
        case .all: return theme.accent  // 修正：使用 accent
        case .grammar: return .blue
        case .spelling: return .red
        case .punctuation: return .orange
        case .style: return .green
        case .clarity: return .purple
        }
    }
}

// MARK: - 建議卡片

private struct SuggestionCard: View {
    @EnvironmentObject var theme: AppTheme
    let suggestion: TextSuggestion
    let onApply: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分類標籤
            HStack {
                categoryBadge
                Spacer()
                highlightIndicator
            }
            
            // 修改建議
            HStack(spacing: 8) {
                Text(suggestion.issue)
                    .font(theme.fontBodySmall)
                    .foregroundColor(.red)
                    .strikethrough()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textTertiary)
                
                Text(suggestion.suggestion)
                    .font(theme.fontBodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            // 說明
            Text(suggestion.explanation)
                .font(theme.fontBodySmall)
                .foregroundColor(theme.textSecondary)
            
            // 操作按鈕 - 修正：使用正確的 Button 語法
            HStack(spacing: 8) {
                Button {
                    onApply()
                } label: {
                    Label("套用", systemImage: "checkmark")
                        .font(theme.fontBodySmall)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button {
                    onDismiss()
                } label: {
                    Label("忽略", systemImage: "xmark")
                        .font(theme.fontBodySmall)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(theme.card)
        .cornerRadius(theme.cornerRadiusMD)  // 修正：使用 cornerRadiusMD
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var categoryBadge: some View {
        Text(suggestion.category.displayName)
            .font(theme.fontBodySmall)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor)
            .cornerRadius(theme.cornerRadiusSM)  // 修正：使用 cornerRadiusSM
    }
    
    private var highlightIndicator: some View {
        Circle()
            .fill(categoryColor.opacity(0.5))
            .frame(width: 12, height: 12)
    }
    
    private var categoryColor: Color {
        switch suggestion.category {
        case .all: return theme.accent  // 修正：使用 accent
        case .grammar: return .blue
        case .spelling: return .red
        case .punctuation: return .orange
        case .style: return .green
        case .clarity: return .purple
        }
    }
}

// MARK: - 數據模型

struct TextSuggestion: Identifiable {
    let id = UUID()
    let category: SuggestionCategory
    let issue: String
    let suggestion: String
    let explanation: String
    let position: Int
}

enum SuggestionCategory: String, CaseIterable {
    case all = "all"
    case grammar = "grammar"
    case spelling = "spelling"
    case punctuation = "punctuation"
    case style = "style"
    case clarity = "clarity"
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .grammar: return "文法"
        case .spelling: return "拼寫"
        case .punctuation: return "標點"
        case .style: return "風格"
        case .clarity: return "清晰度"
        }
    }
}

#Preview {
    let sampleText = NSAttributedString(string: """
    這是一個測試文本，包含一些的的問題。
    這個方法是很好的解決方案。
    """)
    
    return AITextAnalysisPanel(
        isVisible: .constant(true),
        attributedText: sampleText,
        onApplySuggestion: { _ in }
    )
    .environmentObject(AppTheme())
    .frame(height: 600)
}
