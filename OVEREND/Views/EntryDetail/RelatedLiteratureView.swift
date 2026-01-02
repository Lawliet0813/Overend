//
//  RelatedLiteratureView.swift
//  OVEREND
//
//  相關文獻推薦視圖 - 顯示與當前文獻相似的文獻
//

import SwiftUI

/// 相關文獻視圖
struct RelatedLiteratureView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    let entry: Entry
    var onSelect: ((Entry) -> Void)?
    
    @State private var relatedEntries: [RelatedEntry] = []
    @State private var isLoading = true
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題列
            Button(action: {
                withAnimation(AnimationSystem.Panel.slideIn) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                    
                    Text("相關文獻")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    if !isLoading && !relatedEntries.isEmpty {
                        Text("(\(relatedEntries.count))")
                            .font(.system(size: 13))
                            .foregroundColor(theme.textMuted)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(theme.itemHover)
                )
            }
            .buttonStyle(.plain)
            
            // 內容
            if isExpanded {
                if isLoading {
                    loadingView
                } else if relatedEntries.isEmpty {
                    emptyView
                } else {
                    relatedList
                }
            }
        }
        .onAppear {
            loadRelatedEntries()
        }
        .onChange(of: entry.id) { _, _ in
            loadRelatedEntries()
        }
    }
    
    // MARK: - 子視圖
    
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("分析中...")
                .font(.system(size: 13))
                .foregroundColor(theme.textMuted)
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    private var emptyView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.system(size: 24))
                    .foregroundColor(theme.textMuted)
                Text("暫無相關文獻")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMuted)
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    private var relatedList: some View {
        VStack(spacing: 8) {
            ForEach(relatedEntries) { related in
                relatedEntryRow(related)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private func relatedEntryRow(_ related: RelatedEntry) -> some View {
        Button(action: {
            onSelect?(related.entry)
        }) {
            VStack(alignment: .leading, spacing: 6) {
                // 標題
                Text(related.entry.fields["title"] ?? "無標題")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 作者與年份
                HStack(spacing: 8) {
                    if let author = related.entry.fields["author"] {
                        Text(formatAuthor(author))
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    if let year = related.entry.fields["year"] {
                        Text(year)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textMuted)
                    }
                }
                
                // 相似原因標籤
                HStack(spacing: 4) {
                    ForEach(Array(related.reasons.prefix(2)), id: \.self) { reason in
                        reasonTag(reason)
                    }
                    
                    if related.reasons.count > 2 {
                        Text("+\(related.reasons.count - 2)")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(theme.itemHover)
                            )
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func reasonTag(_ reason: SimilarityReason) -> some View {
        HStack(spacing: 3) {
            Image(systemName: reason.icon)
                .font(.system(size: 9))
            
            Text(reasonShortDescription(reason))
                .font(.system(size: 10))
                .lineLimit(1)
        }
        .foregroundColor(theme.accent)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(theme.accentLight.opacity(0.5))
        )
    }
    
    private func reasonShortDescription(_ reason: SimilarityReason) -> String {
        switch reason {
        case .sameAuthor(let author):
            return formatAuthor(author)
        case .sameKeyword(let keyword):
            return keyword
        case .sameJournal:
            return "同期刊"
        case .sameYear(let year):
            return year
        case .sameTopic:
            return "相似主題"
        }
    }
    
    // MARK: - 輔助方法
    
    private func loadRelatedEntries() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let results = RelatedLiteratureService.shared.findRelated(
                to: entry,
                in: viewContext,
                limit: 5
            )
            
            DispatchQueue.main.async {
                withAnimation(AnimationSystem.Content.load) {
                    relatedEntries = results
                    isLoading = false
                }
            }
        }
    }
    
    private func formatAuthor(_ author: String) -> String {
        let parts = author.components(separatedBy: " and ")
        guard let first = parts.first else { return author }
        
        if parts.count > 1 {
            let lastName = first.components(separatedBy: ", ").first ?? first
            return "\(lastName) 等"
        }
        
        return first.components(separatedBy: ", ").first ?? first
    }
}

// MARK: - 預覽

#Preview {
    RelatedLiteratureView(entry: Entry())
        .environmentObject(AppTheme())
        .padding()
        .frame(width: 300)
}
