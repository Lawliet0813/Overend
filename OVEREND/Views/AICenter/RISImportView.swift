//
//  RISImportView.swift
//  OVEREND
//
//  RIS 書目匯入介面
//
//  功能：
//  - RIS 檔案拖放匯入
//  - 自動編碼偵測（Big5/UTF-8）
//  - 解析預覽（顯示即將匯入的書目）
//  - 批次匯入與錯誤處理
//

import SwiftUI
import UniformTypeIdentifiers
import CoreData

/// RIS 匯入視圖
@available(macOS 26.0, *)
struct RISImportView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 目標文獻庫
    var targetLibrary: Library?
    
    // 狀態
    @State private var isDragging: Bool = false
    @State private var selectedFileURL: URL?
    @State private var fileData: Data?
    @State private var encodingDetection: EncodingDetectionResult?
    @State private var parsedEntries: [RISEntry] = []
    @State private var parseError: String?
    @State private var isImporting: Bool = false
    @State private var importResult: ImportResult?
    
    /// 匯入結果
    struct ImportResult {
        let successCount: Int
        let skipCount: Int
        let errorMessage: String?
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            headerView
            
            Divider()
            
            // 內容區
            if selectedFileURL == nil {
                // 拖放區
                dropZone
            } else {
                // 預覽區
                previewArea
            }
            
            Divider()
            
            // 操作按鈕
            actionBar
        }
        .frame(width: 700, height: 550)
        .background(theme.background)
    }
    
    // MARK: - 標題
    
    private var headerView: some View {
        HStack {
            Image(systemName: "doc.badge.arrow.up")
                .foregroundColor(theme.accent)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("RIS 書目匯入")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("從 .ris 檔案匯入書目資料")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - 拖放區
    
    private var dropZone: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(isDragging ? theme.accent : theme.textMuted)
            
            Text("拖放 RIS 檔案至此處")
                .font(.system(size: DesignTokens.Typography.title3, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
            Text("支援 EndNote、Mendeley、學術資料庫匯出的 .ris 檔案")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
            
            Button {
                selectRISFile()
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("選擇檔案")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            
            // 編碼說明
            VStack(spacing: DesignTokens.Spacing.xs) {
                Label("自動偵測編碼", systemImage: "text.magnifyingglass")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                
                Text("支援 UTF-8、Big5（台灣常見）等編碼格式")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .stroke(isDragging ? theme.accent : theme.border, style: StrokeStyle(lineWidth: 2, dash: [10]))
                .padding()
        )
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - 預覽區
    
    private var previewArea: some View {
        VStack(spacing: 0) {
            // 檔案資訊
            fileInfoSection
            
            Divider()
            
            // 解析結果
            if let error = parseError {
                errorView(error)
            } else if parsedEntries.isEmpty {
                parsingView
            } else {
                entriesPreview
            }
        }
    }
    
    private var fileInfoSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 檔案圖標
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(theme.accent)
            
            // 檔案名稱
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedFileURL?.lastPathComponent ?? "")
                    .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                
                if let detection = encodingDetection {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        // 編碼
                        encodingBadge(detection.encodingName)
                        
                        // 信心度
                        if detection.confidence >= 0.8 {
                            Label("高信心", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if detection.confidence >= 0.5 {
                            Label("中信心", systemImage: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                        } else {
                            Label("低信心", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .font(.system(size: DesignTokens.Typography.caption))
                }
            }
            
            Spacer()
            
            // 更換檔案
            Button {
                resetSelection()
            } label: {
                Text("更換檔案")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(theme.card)
    }
    
    private func encodingBadge(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(theme.accent)
            )
    }
    
    private var parsingView: some View {
        VStack {
            ProgressView("解析中...")
            Text("正在分析 RIS 檔案內容")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("解析失敗")
                .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            Text(message)
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                resetSelection()
            } label: {
                Text("選擇其他檔案")
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var entriesPreview: some View {
        VStack(spacing: 0) {
            // 統計
            HStack {
                Label("\(parsedEntries.count) 筆書目", systemImage: "doc.text")
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // 類型分佈
                let typeCounts = Dictionary(grouping: parsedEntries) { $0.type }.mapValues { $0.count }
                ForEach(Array(typeCounts.keys.prefix(3)), id: \.self) { type in
                    Text("\(type.displayName): \(typeCounts[type] ?? 0)")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                }
            }
            .padding()
            .background(theme.toolbar)
            
            // 預覽列表
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(Array(parsedEntries.prefix(50).enumerated()), id: \.offset) { index, entry in
                        entryPreviewRow(entry, index: index + 1)
                    }
                    
                    if parsedEntries.count > 50 {
                        Text("...以及 \(parsedEntries.count - 50) 筆更多書目")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textMuted)
                            .padding()
                    }
                }
                .padding()
            }
        }
    }
    
    private func entryPreviewRow(_ entry: RISEntry, index: Int) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            // 序號
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(theme.accent.opacity(0.7)))
            
            // 書目資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title ?? "無標題")
                    .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if !entry.authors.isEmpty {
                        Text(entry.authors.joined(separator: "; "))
                            .lineLimit(1)
                    }
                    
                    if let year = entry.year {
                        Text("(\(year))")
                    }
                }
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textSecondary)
                
                if let journal = entry.journal {
                    Text(journal)
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                        .italic()
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 類型標籤
            Text(entry.type.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(colorForType(entry.type))
                )
        }
        .padding(DesignTokens.Spacing.sm)
        .background(theme.card)
        .cornerRadius(DesignTokens.CornerRadius.medium)
    }
    
    private func colorForType(_ type: RISType) -> Color {
        switch type {
        case .journal: return .blue
        case .book: return .brown
        case .bookSection: return .orange
        case .conference: return .purple
        case .thesis: return .green
        case .report: return .gray
        case .webpage: return .cyan
        default: return .secondary
        }
    }
    
    // MARK: - 操作欄
    
    private var actionBar: some View {
        HStack {
            // 目標文獻庫
            if let library = targetLibrary {
                Label("目標：\(library.name)", systemImage: "folder")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textSecondary)
            } else {
                Label("請先選擇目標文獻庫", systemImage: "exclamationmark.triangle")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            // 匯入結果
            if let result = importResult {
                if result.errorMessage != nil {
                    Label("匯入失敗", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                } else {
                    Label("成功 \(result.successCount) 筆，跳過 \(result.skipCount) 筆", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            // 匯入按鈕
            Button {
                performImport()
            } label: {
                HStack {
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text("匯入 \(parsedEntries.count) 筆書目")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            .disabled(parsedEntries.isEmpty || isImporting || targetLibrary == nil)
        }
        .padding()
        .background(theme.toolbar)
    }
    
    // MARK: - 動作
    
    private func selectRISFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "ris") ?? .text]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            loadFile(from: url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            DispatchQueue.main.async {
                loadFile(from: url)
            }
        }
    }
    
    private func loadFile(from url: URL) {
        selectedFileURL = url
        parseError = nil
        parsedEntries = []
        importResult = nil
        
        do {
            // 讀取檔案
            let data = try Data(contentsOf: url)
            fileData = data
            
            // 偵測編碼
            encodingDetection = EncodingDetector.detect(data: data)
            
            // 解析 RIS
            let entries = try RISParser.parseData(data)
            parsedEntries = entries
            
        } catch {
            parseError = error.localizedDescription
        }
    }
    
    private func resetSelection() {
        selectedFileURL = nil
        fileData = nil
        encodingDetection = nil
        parsedEntries = []
        parseError = nil
        importResult = nil
    }
    
    private func performImport() {
        guard let library = targetLibrary, !parsedEntries.isEmpty else { return }
        
        isImporting = true
        
        Task {
            do {
                let count = try RISParser.importEntries(parsedEntries, into: library, context: viewContext)
                
                await MainActor.run {
                    importResult = ImportResult(
                        successCount: count,
                        skipCount: parsedEntries.count - count,
                        errorMessage: nil
                    )
                    isImporting = false
                    
                    // 延遲關閉
                    if count > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    importResult = ImportResult(
                        successCount: 0,
                        skipCount: 0,
                        errorMessage: error.localizedDescription
                    )
                    isImporting = false
                }
            }
        }
    }
}

// MARK: - Preview

@available(macOS 26.0, *)
#Preview {
    RISImportView()
        .environmentObject(AppTheme())
}
