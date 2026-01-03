//
//  EntryPreviewCard.swift
//  OVEREND
//
//  文獻懸停預覽卡片 - 顯示摘要、關鍵字、DOI 等快速資訊
//

import SwiftUI

/// 文獻預覽卡片（懸停時顯示）
struct EntryPreviewCard: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var entry: Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // 標題
            Text(entry.title)
                .font(.system(size: DesignTokens.Typography.body, weight: .bold))
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
            
            // 作者和年份
            if let author = entry.fields["author"], !author.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                    Text(formatAuthors(author))
                        .font(.system(size: DesignTokens.Typography.caption))
                    
                    if let year = entry.fields["year"], !year.isEmpty {
                        Text("• \(year)")
                            .font(.system(size: DesignTokens.Typography.caption))
                    }
                }
                .foregroundColor(theme.textMuted)
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // 摘要
            if let abstract = entry.fields["abstract"], !abstract.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("摘要")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.textMuted)
                        .textCase(.uppercase)
                    
                    Text(String(abstract.prefix(200)) + (abstract.count > 200 ? "..." : ""))
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(4)
                }
            }
            
            // 關鍵字
            if let keywords = entry.fields["keywords"], !keywords.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("關鍵字")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.textMuted)
                        .textCase(.uppercase)
                    
                    FlowLayout(spacing: 4) {
                        ForEach(parseKeywords(keywords), id: \.self) { keyword in
                            Text(keyword)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(theme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.accentLight)
                                )
                        }
                    }
                }
            }
            
            // DOI 連結
            if let doi = entry.fields["doi"], !doi.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                    Text("DOI: \(doi)")
                        .font(.system(size: 11))
                        .foregroundColor(theme.accent)
                        .underline()
                }
                .onTapGesture {
                    if let url = URL(string: "https://doi.org/\(doi)") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            
            // 底部資訊
            HStack {
                // 文獻類型
                Text(entry.entryType)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.accentLight)
                    )
                
                Spacer()
                
                // 附件數
                if !entry.attachmentArray.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 10))
                        Text("\(entry.attachmentArray.count) 個附件")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(theme.textMuted)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(theme.card)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func formatAuthors(_ authors: String) -> String {
        let parts = authors.components(separatedBy: " and ")
        if parts.count > 2 {
            return "\(parts[0]) 等"
        }
        return authors
    }
    
    private func parseKeywords(_ keywords: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",;")
        return keywords
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { String($0) }
    }
}

// FlowLayout is defined in Views/Common/FlowLayout.swift


#Preview {
    let theme = AppTheme()
    let context = PersistenceController.preview.container.viewContext
    
    let entry = Entry(context: context)
    entry.id = UUID()
    entry.entryType = "article"
    entry.citationKey = "smith2024"
    entry.fields = [
        "title": "A Comprehensive Study of Machine Learning in Academic Writing",
        "author": "John Smith and Jane Doe and Robert Johnson",
        "year": "2024",
        "journal": "Journal of Academic Technology",
        "abstract": "This study explores the application of machine learning techniques in academic writing assistance. We present a comprehensive framework for integrating AI-powered tools into the scholarly writing process, demonstrating significant improvements in writing quality and efficiency.",
        "keywords": "machine learning, academic writing, AI, natural language processing, education",
        "doi": "10.1234/example.2024.001"
    ]
    entry.createdAt = Date()
    entry.updatedAt = Date()
    
    return EntryPreviewCard(entry: entry)
        .environmentObject(theme)
        .padding()
        .background(Color.gray.opacity(0.2))
}
