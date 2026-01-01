//
//  DynamicToolbar.swift
//  OVEREND
//
//  動態工具列 - 根據視圖模式變化
//

import SwiftUI

/// 動態工具列
struct DynamicToolbar: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    
    @Binding var searchText: String
    var onNewItem: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 左側：返回按鈕 + 標題
            HStack(spacing: 12) {
                // 返回按鈕（僅在編輯器模式顯示）
                if case .editorFull = viewState.mode {
                    Button(action: { viewState.backToEditorList() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.itemHover)
                    )
                }
                
                // 標題
                Text(toolbarTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.textPrimary)
            }
            
            Spacer()
            
            // 右側：搜尋 + 主題切換 + 新建按鈕
            HStack(spacing: 12) {
                // 主題切換
                Button(action: { theme.isDarkMode.toggle() }) {
                    Image(systemName: theme.isDarkMode ? "sun.max" : "moon")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textPrimary)
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.itemHover)
                )
                
                // 搜尋欄
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                    
                    TextField("搜尋...", text: $searchText)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(width: searchText.isEmpty ? 140 : 200)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.itemHover)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.border, lineWidth: 1)
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: searchText)
                
                // 新建按鈕
                Button(action: onNewItem) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text(newButtonTitle)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.accent)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background(theme.toolbar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
    
    // MARK: - 計算屬性
    
    private var toolbarTitle: String {
        switch viewState.mode {
        case .library:
            return "全部文獻庫"
        case .editorList:
            return "寫作中心"
        case .editorFull(let doc):
            return "正在編輯：\(doc.title)"
        }
    }
    
    private var newButtonTitle: String {
        switch viewState.mode {
        case .library:
            return "匯入文獻"
        case .editorList, .editorFull:
            return "新建文稿"
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    
    return VStack {
        DynamicToolbar(searchText: .constant(""), onNewItem: {})
            .environmentObject(theme)
            .environmentObject(viewState)
        
        Spacer()
    }
    .frame(width: 800, height: 400)
}
