//
//  AcademicEditorToolbar.swift
//  OVEREND
//
//  學術模式專用工具列
//

import SwiftUI

struct AcademicEditorToolbar: View {
    @EnvironmentObject var theme: AppTheme
    
    var onInsertCitation: () -> Void
    var onInsertFootnote: () -> Void
    var onInsertBibliography: () -> Void
    var onToggleSplitView: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // 引用工具
            SwiftUI.Group {
                Button(action: onInsertCitation) {
                    Label("插入引用", systemImage: "text.quote")
                }
                .help("插入引用 (⌘⇧C)")
                
                Button(action: onInsertFootnote) {
                    Label("插入註腳", systemImage: "text.alignleft")
                }
                .help("插入註腳")
                
                Button(action: onInsertBibliography) {
                    Label("插入參考文獻", systemImage: "list.bullet.rectangle")
                }
                .help("插入參考文獻列表")
            }
            .buttonStyle(AcademicToolbarButtonStyle())
            
            Divider()
                .frame(height: 16)
            
            // 視圖控制
            Button(action: onToggleSplitView) {
                Label("對照模式", systemImage: "square.split.2x1")
            }
            .buttonStyle(AcademicToolbarButtonStyle())
            .help("開啟/關閉文獻對照模式")
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

struct AcademicToolbarButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .foregroundColor(theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? theme.itemHover : Color.clear)
            )
            .contentShape(Rectangle())
    }
}
