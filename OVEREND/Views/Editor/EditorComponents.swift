//
//  EditorComponents.swift
//  OVEREND
//
//  編輯器次要元件 - 從 DocumentEditorView 拆分
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - 狀態列

struct EditorStatusBar: View {
    @EnvironmentObject var theme: AppTheme
    let wordCount: Int
    let characterCount: Int
    let isPandocAvailable: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            Label("\(wordCount) 字詞", systemImage: "textformat.abc")
            Label("\(characterCount) 字元", systemImage: "character")
            
            Spacer()
            
            Text("DOCX / PDF 匯出")
                .foregroundColor(theme.textTertiary)
        }
        .font(.caption)
        .foregroundColor(theme.textSecondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(theme.toolbarGlass)
    }
}

// MARK: - 匯入表單

struct ImportDocumentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: AppTheme
    
    let onImport: (URL) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("匯入 DOCX 文件")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("選擇一個 DOCX 檔案匯入編輯器")
                .foregroundColor(theme.textSecondary)
            
            Button(action: selectFile) {
                Label("選擇檔案", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            
            Button("取消") { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(theme.textSecondary)
        }
        .padding(40)
        .frame(width: 400)
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "選擇 DOCX 檔案"
        panel.allowedContentTypes = [UTType(filenameExtension: "docx") ?? .data]
        panel.allowsMultipleSelection = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onImport(url)
                dismiss()
            }
        }
    }
}

// MARK: - 匯出中遮罩

struct ExportingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("正在匯出...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}
