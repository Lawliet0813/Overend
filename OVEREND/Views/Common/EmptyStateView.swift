//
//  EmptyStateView.swift
//  OVEREND
//
//  空狀態視圖 - 通用的空狀態引導元件
//

import SwiftUI

/// 空狀態類型
enum EmptyStateType {
    case library       // 文獻庫是空的
    case documents     // 寫作中心是空的
    case search        // 搜尋無結果
    case filter        // 篩選無結果
    
    var icon: String {
        switch self {
        case .library: return "books.vertical"
        case .documents: return "doc.text"
        case .search: return "magnifyingglass"
        case .filter: return "line.3.horizontal.decrease.circle"
        }
    }
    
    var title: String {
        switch self {
        case .library: return "尚無文獻"
        case .documents: return "尚無文稿"
        case .search: return "找不到結果"
        case .filter: return "無符合條件的項目"
        }
    }
    
    var message: String {
        switch self {
        case .library: return "拖曳 PDF 或 BibTeX 檔案\n開始建立您的文獻庫"
        case .documents: return "建立您的第一篇文稿\n開始寫作"
        case .search: return "試試其他搜尋條件"
        case .filter: return "調整篩選條件以查看更多結果"
        }
    }
    
    var buttonTitle: String? {
        switch self {
        case .library: return "匯入文獻"
        case .documents: return "新增文稿"
        case .search, .filter: return nil
        }
    }
}

/// 通用空狀態視圖
struct EmptyStateView: View {
    @EnvironmentObject var theme: AppTheme
    
    let type: EmptyStateType
    let action: (() -> Void)?
    
    init(type: EmptyStateType, action: (() -> Void)? = nil) {
        self.type = type
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 圖示
            ZStack {
                Circle()
                    .fill(theme.accentLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: type.icon)
                    .font(.system(size: 40))
                    .foregroundColor(theme.accent)
            }
            
            // 標題和說明
            VStack(spacing: 12) {
                Text(type.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text(type.message)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // 操作按鈕
            if let buttonTitle = type.buttonTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text(buttonTitle)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.accent)
                    )
                }
                .buttonStyle(.plain)
                .shadow(color: theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

/// 文獻庫空狀態（帶動畫效果）
struct LibraryEmptyState: View {
    @EnvironmentObject var theme: AppTheme
    
    let onImport: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // 動畫圖示組
            ZStack {
                // 背景圓
                Circle()
                    .fill(theme.accentLight.opacity(0.5))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                // 書籍圖示
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 50))
                    .foregroundColor(theme.accent)
                    .offset(y: isAnimating ? -3 : 3)
                
                // 加號裝飾
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.accent)
                    .offset(x: 45, y: -35)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
            }
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            
            // 文字內容
            VStack(spacing: 12) {
                Text("開始建立您的文獻庫")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("匯入學術文獻、PDF 檔案或 BibTeX 書目\n讓 OVEREND 協助您整理研究資料")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // 匯入按鈕
            Button(action: onImport) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                    Text("匯入文獻")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accent)
                )
            }
            .buttonStyle(.plain)
            .shadow(color: theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            
            // 拖曳提示
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 11))
                Text("或拖曳檔案到此處")
                    .font(.system(size: 12))
            }
            .foregroundColor(theme.textMuted.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

/// 寫作中心空狀態
struct DocumentsEmptyState: View {
    @EnvironmentObject var theme: AppTheme
    
    let onCreate: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // 動畫圖示組
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.accentLight.opacity(0.5))
                    .frame(width: 120, height: 150)
                    .rotationEffect(.degrees(isAnimating ? 2 : -2))
                
                // 文稿圖示
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 50))
                    .foregroundColor(theme.accent)
                
                // 筆圖示
                Image(systemName: "pencil")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.accent)
                    .offset(x: 35, y: 45)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
            }
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isAnimating)
            
            // 文字內容
            VStack(spacing: 12) {
                Text("開始您的寫作之旅")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("建立新文稿並開始撰寫\n輕鬆引用您的文獻庫")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // 新增按鈕
            Button(action: onCreate) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("建立新文稿")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accent)
                )
            }
            .buttonStyle(.plain)
            .shadow(color: theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("文獻庫空狀態") {
    LibraryEmptyState(onImport: {})
        .environmentObject(AppTheme())
        .frame(width: 600, height: 500)
}

#Preview("寫作中心空狀態") {
    DocumentsEmptyState(onCreate: {})
        .environmentObject(AppTheme())
        .frame(width: 600, height: 500)
}

#Preview("通用空狀態") {
    EmptyStateView(type: .library, action: {})
        .environmentObject(AppTheme())
        .frame(width: 600, height: 500)
}
