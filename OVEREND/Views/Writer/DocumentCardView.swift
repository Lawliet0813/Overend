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
    
    // 選擇模式參數
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    
    let onTap: () -> Void
    var onToggleSelection: (() -> Void)? = nil
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 主卡片
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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(2)
                        .padding(.bottom, 4)
                    
                    // 上次編輯
                    Text("上次編輯：\(formatDate(document.updatedAt))")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)
                        .padding(.bottom, 16)
                    
                    Spacer()
                    
                    // 底部資訊
                    HStack {
                        Text("\(wordCount) 字")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.textMuted)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
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
                    ZStack {
                        // 基礎卡片背景
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.card)
                        
                        // 添加微妙漸變光澤
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDarkMode ? 0.05 : 0.4),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 邊框
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isHovered ? theme.accent : theme.border, lineWidth: 1)
                    }
                )
                // 增強陰影效果
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.15 : 0.08),
                    radius: isHovered ? 20 : 10,
                    x: 0,
                    y: isHovered ? 8 : 4
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(AnimationSystem.Easing.quick) {
                    isHovered = hovering
                }
            }
            
            // 選擇模式下顯示複選框
            if isSelectionMode {
                Button(action: { onToggleSelection?() }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? theme.accent : theme.textMuted.opacity(0.8))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .buttonStyle(.plain)
                .padding(12)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            } else if isHovered {
                // 刪除按鈕（非選擇模式且懸停時顯示）
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(theme.destructive))
                }
                .buttonStyle(.plain)
                .padding(12)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        // 選中狀態邊框
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 3)
        )
        .alert("確定刪除？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                withAnimation(AnimationSystem.Easing.spring) {
                    onDelete()
                }
            }
        } message: {
            Text("此操作將刪除「\(document.title)」，無法還原。")
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
    
    DocumentCardView(document: doc, onTap: {}, onDelete: {})
        .environmentObject(theme)
        .frame(width: 280, height: 220)
        .padding()
        .background(Color.gray.opacity(0.1))
}
