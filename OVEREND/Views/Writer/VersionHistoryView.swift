//
//  VersionHistoryView.swift
//  OVEREND
//
//  版本歷史視圖 - 顯示文檔版本列表，支援預覽與還原
//

import SwiftUI

/// 版本歷史視圖
struct VersionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: AppTheme
    
    @ObservedObject var document: Document
    @StateObject private var versionService = VersionHistoryService.shared
    
    // MARK: - 狀態
    @State private var versions: [DocumentVersionSnapshot] = []
    @State private var selectedVersion: DocumentVersionSnapshot?
    @State private var isLoading = true
    @State private var showRestoreConfirm = false
    @State private var versionToRestore: DocumentVersionSnapshot?
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            header
            
            Divider()
            
            // 主內容
            HStack(spacing: 0) {
                // 左側版本列表
                versionList
                    .frame(width: 280)
                
                Divider()
                
                // 右側預覽
                previewPanel
            }
        }
        .frame(width: 800, height: 500)
        .background(theme.card)
        .onAppear {
            loadVersions()
        }
        .alert("確認還原", isPresented: $showRestoreConfirm) {
            Button("取消", role: .cancel) { }
            Button("還原", role: .destructive) {
                if let version = versionToRestore {
                    restoreVersion(version)
                }
            }
        } message: {
            if let version = versionToRestore {
                Text("確定要還原到 \(version.formattedDate) 的版本嗎？當前內容將被覆蓋（會自動建立備份）。")
            }
        }
    }
    
    // MARK: - 子視圖
    
    private var header: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 16))
                .foregroundColor(theme.accent)
            
            Text("版本歷史")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            Text("・\(document.title)")
                .font(.system(size: 14))
                .foregroundColor(theme.textMuted)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
    
    private var versionList: some View {
        VStack(spacing: 0) {
            // 列表標題
            HStack {
                Text("版本紀錄")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
                
                Text("\(versions.count) 個版本")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.background)
            
            Divider()
            
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if versions.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(theme.textMuted)
                    Text("尚無版本紀錄")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(versions.enumerated()), id: \.element.id) { index, version in
                            versionRow(version, index: index)
                            
                            if index < versions.count - 1 {
                                Divider()
                                    .padding(.leading, 54)
                            }
                        }
                    }
                }
            }
        }
        .background(theme.card)
    }
    
    private func versionRow(_ version: DocumentVersionSnapshot, index: Int) -> some View {
        Button(action: {
            withAnimation(AnimationSystem.Easing.quick) {
                selectedVersion = version
            }
        }) {
            HStack(spacing: 12) {
                // 時間線
                VStack(spacing: 0) {
                    if index > 0 {
                        Rectangle()
                            .fill(theme.border)
                            .frame(width: 2)
                    } else {
                        Color.clear
                    }
                    
                    Circle()
                        .fill(selectedVersion?.id == version.id ? theme.accent : theme.textMuted)
                        .frame(width: 10, height: 10)
                    
                    if index < versions.count - 1 {
                        Rectangle()
                            .fill(theme.border)
                            .frame(width: 2)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 20)
                
                // 版本資訊
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(version.formattedDate)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                        
                        Text(version.relativeTime)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textMuted)
                    }
                    
                    HStack(spacing: 8) {
                        // 字數
                        HStack(spacing: 4) {
                            Image(systemName: "textformat.abc")
                                .font(.system(size: 10))
                            Text("\(version.wordCount) 字")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                        
                        // 與上一版本的差異
                        if index < versions.count - 1 {
                            let diff = versionService.compareVersions(versions[index + 1], version)
                            if diff.changed {
                                Text(diff.summary)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(diff.added > 0 ? .green : .red)
                            }
                        }
                    }
                    
                    // 備註
                    if let note = version.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if selectedVersion?.id == version.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                selectedVersion?.id == version.id
                    ? theme.accentLight.opacity(0.3)
                    : Color.clear
            )
        }
        .buttonStyle(.plain)
    }
    
    private var previewPanel: some View {
        VStack(spacing: 0) {
            if let version = selectedVersion {
                // 預覽標題
                HStack {
                    Text("預覽")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                    
                    // 還原按鈕
                    Button(action: {
                        versionToRestore = version
                        showRestoreConfirm = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("還原此版本")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(theme.accent)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.background)
                
                Divider()
                
                // 預覽內容
                ScrollView {
                    Text(previewText(from: version))
                        .font(.system(size: 14))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            } else {
                // 未選擇版本
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(theme.textMuted)
                    
                    Text("選擇版本以預覽內容")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .background(theme.card)
    }
    
    // MARK: - 輔助方法
    
    private func loadVersions() {
        isLoading = true
        
        Task {
            let loadedVersions = await versionService.getVersions(for: document.id)
            
            await MainActor.run {
                versions = loadedVersions
                selectedVersion = loadedVersions.first
                isLoading = false
            }
        }
    }
    
    private func restoreVersion(_ version: DocumentVersionSnapshot) {
        Task {
            await versionService.restoreVersion(version, to: document)
            
            await MainActor.run {
                ToastManager.shared.showSuccess("已還原到 \(version.formattedDate)")
                dismiss()
            }
        }
    }
    
    private func previewText(from version: DocumentVersionSnapshot) -> String {
        guard let attrString = try? NSAttributedString(
            data: version.content,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            return "（無法預覽）"
        }
        
        return attrString.string
    }
}

// MARK: - 預覽

#Preview {
    VersionHistoryView(document: Document())
        .environmentObject(AppTheme())
}
