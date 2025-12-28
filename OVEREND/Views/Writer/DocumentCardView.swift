//
//  DocumentCardView.swift
//  OVEREND
//
//  文稿卡片 - 寫作中心列表項目
//

import SwiftUI

/// 文稿卡片視圖
struct DocumentCardView: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var document: Document
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // 圖標
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isHovered ? theme.accent : theme.accentLight)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isHovered ? .white : theme.accent)
                }
                .padding(.bottom, 16)
                
                // 標題
                Text(document.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                    .padding(.bottom, 4)
                
                // 上次編輯
                Text("上次編輯：\(formatDate(document.updatedAt))")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMuted)
                    .padding(.bottom, 16)
                
                Spacer()
                
                // 底部資訊
                HStack {
                    Text("\(wordCount) 字")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
                .padding(.top, 16)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(theme.border)
                        .frame(height: 1)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isHovered ? theme.accent : theme.border, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - 計算屬性
    
    private var wordCount: Int {
        let text = document.attributedString.string
        var count = 0
        text.enumerateSubstrings(in: text.startIndex..., options: .byWords) { _, _, _, _ in
            count += 1
        }
        // 中文字符
        let chineseCount = text.unicodeScalars.filter {
            CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}").contains($0)
        }.count
        return count + chineseCount
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        if diff < 60 {
            return "剛才"
        } else if diff < 3600 {
            return "\(Int(diff / 60)) 分鐘前"
        } else if diff < 86400 {
            return "\(Int(diff / 3600)) 小時前"
        } else if diff < 604800 {
            return "\(Int(diff / 86400)) 天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    let theme = AppTheme()
    let context = PersistenceController.preview.container.viewContext
    let doc = Document(context: context, title: "政大碩士論文草稿")
    
    return DocumentCardView(document: doc, onTap: {})
        .environmentObject(theme)
        .frame(width: 280, height: 220)
        .padding()
        .background(Color.gray.opacity(0.1))
}
