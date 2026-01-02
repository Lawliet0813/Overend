//
//  DocumentEditorView.swift
//  OVEREND
//
//  文檔編輯器包裝視圖 - 支援切換編輯模式
//

import SwiftUI

struct DocumentEditorView: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showModeSwitch = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 根據模式顯示不同的編輯器
            if document.currentEditorMode == .richText {
                WriterView(document: document)
                    .transition(.opacity)
            } else {
                NotionStyleEditorView(document: document)
                    .transition(.opacity)
            }
            
            // 模式切換按鈕
            modeSwitchButton
                .padding(16)
        }
        .animation(.easeInOut(duration: 0.3), value: document.currentEditorMode)
    }
    
    private var modeSwitchButton: some View {
        Menu {
            Button(action: {
                switchMode(to: .richText)
            }) {
                Label(
                    document.currentEditorMode == .richText ? "✓ 富文本模式" : "富文本模式",
                    systemImage: "doc.richtext"
                )
            }
            
            Button(action: {
                switchMode(to: .notion)
            }) {
                Label(
                    document.currentEditorMode == .notion ? "✓ Notion 模式" : "Notion 模式",
                    systemImage: "square.grid.3x3"
                )
            }
            
            Divider()
            
            Section("關於編輯模式") {
                Text("富文本：傳統的所見即所得編輯器")
                Text("Notion：區塊式編輯，支援拖放排序")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: document.currentEditorMode == .richText ? "doc.richtext" : "square.grid.3x3")
                Text(document.currentEditorMode == .richText ? "富文本" : "Notion")
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.card)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("切換編輯模式")
    }
    
    private func switchMode(to mode: Document.EditorMode) {
        guard document.currentEditorMode != mode else { return }
        
        // 如果有內容，詢問是否轉換
        if let rtfData = document.rtfData, !rtfData.isEmpty {
            showConversionAlert(to: mode)
        } else {
            document.currentEditorMode = mode
            saveDocument()
        }
    }
    
    private func showConversionAlert(to mode: Document.EditorMode) {
        let alert = NSAlert()
        alert.messageText = "切換編輯模式"
        alert.informativeText = "切換編輯模式可能會影響格式。是否繼續？"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "繼續")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            document.currentEditorMode = mode
            saveDocument()
        }
    }
    
    private func saveDocument() {
        document.updatedAt = Date()
        do {
            try viewContext.save()
        } catch {
            print("Failed to save document mode: \(error)")
        }
    }
}

#Preview {
    DocumentEditorView(
        document: PersistenceController.preview.container.viewContext.registeredObjects
            .compactMap { $0 as? Document }
            .first!
    )
    .environmentObject(AppTheme())
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
