//
//  AcademicPhrasebankView.swift
//  OVEREND
//
//  學術語料庫瀏覽介面
//
//  功能：
//  - 分類瀏覽學術句型
//  - 關鍵字搜尋
//  - 一鍵複製句型
//  - AI 智慧建議
//

import SwiftUI

/// 學術語料庫視圖
@available(macOS 26.0, *)
struct AcademicPhrasebankView: View {
    @EnvironmentObject var theme: AppTheme
    
    // 服務
    @StateObject private var phrasebank = AcademicPhrasebank.shared
    
    // 狀態
    @State private var searchQuery: String = ""
    @State private var selectedCategory: PhraseCategory? = nil
    @State private var copiedPhraseID: UUID? = nil
    @State private var showCopiedToast: Bool = false
    @State private var contextText: String = ""
    @State private var suggestions: [AcademicPhrase] = []
    @State private var isLoadingSuggestions: Bool = false
    
    var body: some View {
        HSplitView {
            // 左側：分類選單
            categoryList
                .frame(minWidth: 200, maxWidth: 250)
            
            // 右側：句型列表
            phraseList
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
    
    // MARK: - 分類列表
    
    private var categoryList: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(theme.accent)
                Text("學術語料庫")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // 搜尋欄
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.textMuted)
                TextField("搜尋句型...", text: $searchQuery)
                    .textFieldStyle(.plain)
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignTokens.Spacing.sm)
            .background(theme.card)
            .cornerRadius(DesignTokens.CornerRadius.medium)
            .padding(.horizontal)
            .padding(.vertical, DesignTokens.Spacing.sm)
            
            Divider()
            
            // 分類列表
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    // 全部
                    categoryRow(
                        title: "全部句型",
                        icon: "list.bullet",
                        count: phrasebank.allPhrases.count,
                        isSelected: selectedCategory == nil && searchQuery.isEmpty
                    ) {
                        selectedCategory = nil
                    }
                    
                    Divider()
                        .padding(.vertical, DesignTokens.Spacing.xs)
                    
                    // 各分類
                    ForEach(PhraseCategory.allCases) { category in
                        categoryRow(
                            title: category.displayName,
                            icon: category.icon,
                            count: phrasebank.byCategory(category).count,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // AI 建議區
            aiSuggestionSection
        }
        .background(theme.background)
    }
    
    private func categoryRow(title: String, icon: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? theme.accent : theme.textSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(isSelected ? theme.accent : theme.textPrimary)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? theme.accentLight.opacity(0.3) : theme.card)
                    )
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(isSelected ? theme.accentLight.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - AI 建議區
    
    private var aiSuggestionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(theme.accent)
                Text("AI 智慧建議")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }
            
            TextEditor(text: $contextText)
                .font(.system(size: DesignTokens.Typography.caption))
                .frame(height: 60)
                .scrollContentBackground(.hidden)
                .background(theme.card)
                .cornerRadius(DesignTokens.CornerRadius.small)
                .overlay(alignment: .topLeading) {
                    if contextText.isEmpty {
                        Text("貼上目前編輯的段落，取得句型建議...")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textMuted)
                            .padding(DesignTokens.Spacing.xs)
                    }
                }
            
            Button {
                Task {
                    await getSuggestions()
                }
            } label: {
                HStack {
                    if isLoadingSuggestions {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text("取得建議")
                }
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xs)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            .disabled(contextText.isEmpty || isLoadingSuggestions)
        }
        .padding()
    }
    
    // MARK: - 句型列表
    
    private var phraseList: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                if let category = selectedCategory {
                    Image(systemName: category.icon)
                        .foregroundColor(theme.accent)
                    Text(category.displayName)
                        .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                    
                    Text("— \(category.description)")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                } else if !searchQuery.isEmpty {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.accent)
                    Text("搜尋結果：「\(searchQuery)」")
                        .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                } else {
                    Image(systemName: "list.bullet")
                        .foregroundColor(theme.accent)
                    Text("全部句型")
                        .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                }
                
                Spacer()
                
                Text("\(displayedPhrases.count) 個句型")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            .padding()
            
            Divider()
            
            // 句型列表
            if displayedPhrases.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.md) {
                        ForEach(displayedPhrases) { phrase in
                            phraseCard(phrase)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(theme.background)
    }
    
    private var displayedPhrases: [AcademicPhrase] {
        if !searchQuery.isEmpty {
            return phrasebank.search(query: searchQuery)
        } else if let category = selectedCategory {
            return phrasebank.byCategory(category)
        } else {
            return phrasebank.allPhrases
        }
    }
    
    private func phraseCard(_ phrase: AcademicPhrase) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // 分類標籤
            HStack {
                Text(phrase.phraseCategory.displayName)
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(theme.accentLight.opacity(0.2))
                    )
                
                Spacer()
                
                // 複製按鈕
                Button {
                    copyPhrase(phrase)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedPhraseID == phrase.id ? "checkmark" : "doc.on.doc")
                        Text(copiedPhraseID == phrase.id ? "已複製" : "複製")
                    }
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(copiedPhraseID == phrase.id ? .green : theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            // 中文句型
            Text(phrase.chinese)
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textPrimary)
                .textSelection(.enabled)
            
            // 英文對照
            if let english = phrase.english {
                Text(english)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textSecondary)
                    .italic()
                    .textSelection(.enabled)
            }
            
            // 使用範例
            if let example = phrase.example {
                VStack(alignment: .leading, spacing: 4) {
                    Text("範例：")
                        .font(.system(size: DesignTokens.Typography.caption, weight: .semibold))
                        .foregroundColor(theme.textMuted)
                    Text(example)
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textSecondary)
                        .textSelection(.enabled)
                }
                .padding(DesignTokens.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.card.opacity(0.5))
                .cornerRadius(DesignTokens.CornerRadius.small)
            }
            
            // 變數提示
            if phrase.hasVariables {
                HStack {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 10))
                    Text("可替換：\(phrase.variables.joined(separator: ", "))")
                        .font(.system(size: DesignTokens.Typography.caption))
                }
                .foregroundColor(theme.textMuted)
            }
        }
        .padding()
        .background(theme.card)
        .cornerRadius(DesignTokens.CornerRadius.large)
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.textMuted)
            
            Text("找不到符合的句型")
                .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
            Text("嘗試其他關鍵字或選擇不同分類")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private func copyPhrase(_ phrase: AcademicPhrase) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(phrase.chinese, forType: .string)
        
        copiedPhraseID = phrase.id
        showCopiedToast = true
        
        // 3 秒後隱藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedPhraseID == phrase.id {
                copiedPhraseID = nil
            }
            showCopiedToast = false
        }
    }
    
    private func getSuggestions() async {
        isLoadingSuggestions = true
        defer { isLoadingSuggestions = false }
        
        suggestions = await phrasebank.suggest(for: contextText)
        
        // 如果有建議，自動選擇第一個建議的分類
        if let firstSuggestion = suggestions.first {
            selectedCategory = firstSuggestion.phraseCategory
        }
    }
}

// MARK: - Preview

@available(macOS 26.0, *)
#Preview {
    AcademicPhrasebankView()
        .environmentObject(AppTheme())
        .frame(width: 900, height: 600)
}
