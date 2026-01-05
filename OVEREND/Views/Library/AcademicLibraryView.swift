//
//  AcademicLibraryView.swift
//  OVEREND
//
//  學術文獻庫 - Master-Detail 佈局 + AI 智能解析
//

import SwiftUI

// MARK: - 學術文獻庫主視圖

struct AcademicLibraryView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    let entries: [Entry]
    var onImportPDF: () -> Void
    
    @State private var searchText = ""
    @State private var selectedEntry: Entry?
    @State private var isAiLoading = false
    @State private var aiSummary: String?
    
    var filteredEntries: [Entry] {
        if searchText.isEmpty { return entries }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // --- 左側文獻列表 ---
            VStack(spacing: 0) {
                // 工具欄
                HStack(spacing: 15) {
                    // 搜尋欄
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(theme.textTertiary)
                        
                        TextField("搜尋標題、作者...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    
                    Button(action: onImportPDF) {
                        Image(systemName: "plus.app.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(theme.accent)
                    .help("匯入文獻")
                }
                .padding(20)
                .background(.ultraThinMaterial)
                
                // 文獻列表
                if entries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 48))
                            .foregroundColor(theme.textTertiary)
                        
                        Text("尚無文獻")
                            .font(.title3)
                            .foregroundColor(theme.textSecondary)
                        
                        Text("拖曳 PDF 或點擊 + 匯入")
                            .font(.caption)
                            .foregroundColor(theme.textTertiary)
                        
                        Button(action: onImportPDF) {
                            Label("匯入 PDF", systemImage: "doc.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(theme.accent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredEntries, selection: $selectedEntry) { entry in
                        EntryRow(entry: entry, theme: theme)
                            .tag(entry)
                            .listRowBackground(
                                selectedEntry == entry ?
                                theme.accent.opacity(0.1) : Color.clear
                            )
                            .listRowInsets(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(minWidth: 400)
            
            // --- 右側詳情面板 ---
            if let entry = selectedEntry {
                EntryDetailPanel(
                    entry: entry,
                    theme: theme,
                    isAiLoading: $isAiLoading,
                    aiSummary: $aiSummary,
                    onGenerateSummary: { generateAISummary(for: entry) },
                    onOpenPDF: { openPDF(for: entry) }
                )
                .transition(.move(edge: .trailing))
            } else {
                // 空狀態
                VStack(spacing: 15) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 40))
                        .foregroundColor(theme.textTertiary.opacity(0.3))
                    
                    Text("選擇一篇文獻以檢視詳情")
                        .font(.subheadline)
                        .foregroundColor(theme.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.elevated)
            }
        }
        .background(theme.background)
    }
    
    // MARK: - 方法
    
    private func generateAISummary(for entry: Entry) {
        isAiLoading = true
        aiSummary = nil
        
        Task {
            do {
                if #available(macOS 26.0, *) {
                    let ai = UnifiedAIService.shared
                    let abstract = entry.fields["abstract"] ?? ""
                    let summary = try await ai.document.generateSummary(title: entry.title, abstract: abstract)
                    
                    await MainActor.run {
                        aiSummary = summary
                        isAiLoading = false
                    }
                } else {
                    await MainActor.run {
                        aiSummary = "AI 功能需要 macOS 26.0 或更新版本。"
                        isAiLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    aiSummary = "生成失敗：\(error.localizedDescription)"
                    isAiLoading = false
                }
            }
        }
    }
    
    private func openPDF(for entry: Entry) {
        guard let attachment = entry.attachmentArray.first else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: attachment.filePath))
    }
}

// MARK: - 文獻列表行

struct EntryRow: View {
    @ObservedObject var entry: Entry
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                
                Spacer()
                
                // 狀態標籤
                StatusBadge(status: entry.readingStatus, theme: theme)
            }
            
            // 作者與年份
            HStack(spacing: 12) {
                Text(entry.author)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
                
                if !entry.author.isEmpty && !entry.year.isEmpty {
                    Circle()
                        .fill(theme.textTertiary.opacity(0.3))
                        .frame(width: 3, height: 3)
                }
                
                if !entry.year.isEmpty {
                    Text(entry.year)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            // 標籤
            if !entry.tagArray.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.tagArray.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(theme.textTertiary)
                            .cornerRadius(4)
                    }
                    
                    if entry.tagArray.count > 3 {
                        Text("+\(entry.tagArray.count - 3)")
                            .font(.system(size: 9))
                            .foregroundColor(theme.textTertiary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 狀態 Badge

struct StatusBadge: View {
    let status: String
    let theme: AppTheme
    
    var body: some View {
        Text(status.isEmpty ? "未讀" : status)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    var statusColor: Color {
        switch status {
        case "已讀": return theme.accent
        case "標註中": return .blue
        default: return theme.textTertiary
        }
    }
}

// MARK: - 詳情面板 (分頁設計)

struct EntryDetailPanel: View {
    @ObservedObject var entry: Entry
    let theme: AppTheme
    @Binding var isAiLoading: Bool
    @Binding var aiSummary: String?
    var onGenerateSummary: () -> Void
    var onOpenPDF: () -> Void
    
    @State private var activeTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 分頁選擇器
            Picker("", selection: $activeTab) {
                Text("資訊").tag(0)
                Text("引用").tag(1)
                Text("AI").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    switch activeTab {
                    case 0:
                        metadataTab
                    case 1:
                        citationTab
                    case 2:
                        aiTab
                    default:
                        metadataTab
                    }
                }
                .padding(30)
            }
            
            // 底部操作按鈕
            HStack(spacing: 15) {
                if !entry.attachmentArray.isEmpty {
                    Button(action: onOpenPDF) {
                        Label("閱讀原文", systemImage: "doc.viewfinder.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
                    .foregroundColor(.black)
                }
            }
            .padding(25)
            .background(.ultraThinMaterial)
        }
        .frame(width: 400)
        .background(theme.elevated)
    }
    
    // MARK: - 資訊分頁
    
    private var metadataTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(entry.title)
                .font(.title3)
                .bold()
                .foregroundColor(theme.textPrimary)
            
            metadataItem(label: "作者", value: entry.author)
            metadataItem(label: "年份", value: entry.year)
            metadataItem(label: "刊物", value: entry.publication)
            
            if let doi = entry.fields["doi"], !doi.isEmpty {
                metadataItem(label: "DOI", value: doi)
            }
            
            if let abstract = entry.fields["abstract"], !abstract.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("摘要")
                        .font(.caption2)
                        .foregroundColor(theme.textTertiary)
                        .tracking(1)
                    
                    Text(abstract)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                        .lineSpacing(6)
                }
            }
        }
    }
    
    // MARK: - 引用分頁
    
    private var citationTab: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("快速複製引用格式")
                .font(.headline)
                .foregroundColor(theme.accent)
            
            ForEach(CitationStyle.allCases) { style in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(style.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.textTertiary)
                        
                        Spacer()
                        
                        Button("複製") {
                            copyToClipboard(entry.formattedCitation(style: style))
                            ToastManager.shared.showSuccess("已複製 \(style.rawValue) 格式")
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundColor(theme.accent)
                    }
                    
                    Text(entry.formattedCitation(style: style))
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(theme.textSecondary)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
            }
            
            Divider().padding(.vertical, 10)
            
            // 內文引用
            VStack(alignment: .leading, spacing: 15) {
                Text("內文引用標記")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                
                let inTextStyles: [CitationStyle] = [.apa7, .mla, .chicago]
                HStack(spacing: 12) {
                    ForEach(inTextStyles, id: \.self) { style in
                        Button(action: {
                            copyToClipboard(entry.inTextCitation(style: style))
                            ToastManager.shared.showSuccess("已複製內文引用")
                        }) {
                            Text(entry.inTextCitation(style: style))
                                .font(.system(size: 11, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(theme.cardGlass)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(theme.textPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - AI 分頁
    
    private var aiTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("AI 智能解析", systemImage: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.accent)
                
                Spacer()
                
                if isAiLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(theme.accent)
                }
            }
            
            Button(action: onGenerateSummary) {
                Text("執行 AI 深度解析")
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(theme.accent)
            .disabled(isAiLoading)
            
            if let summary = aiSummary {
                Text(summary)
                    .font(.system(size: 13))
                    .lineSpacing(6)
                    .foregroundColor(theme.textSecondary)
                    .textSelection(.enabled)
            } else {
                Text("點擊上方按鈕，讓 AI 為您深度解析這篇文獻的核心貢獻與研究方法。")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textTertiary)
                    .italic()
            }
        }
    }
    
    // MARK: - 輔助方法
    
    private func metadataItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textTertiary)
                .tracking(1)
            
            Text(value.isEmpty ? "-" : value)
                .font(.system(size: 13))
                .foregroundColor(theme.textPrimary)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Entry 擴展 (引用格式化)

extension Entry {
    /// 閱讀狀態
    var readingStatus: String {
        // TODO: 從 Core Data 讀取實際狀態
        return ""
    }
    
    /// 標籤陣列
    var tagArray: [String] {
        // TODO: 從 Core Data 讀取實際標籤
        return []
    }
    
    /// 格式化為指定引用格式
    func formattedCitation(style: CitationStyle) -> String {
        let authors = formatAuthorsForCitation(author, style: style)
        let yearStr = year
        let titleStr = title
        let journal = publication
        let doi = fields["doi"] ?? ""
        
        switch style {
        case .apa7, .apa6:
            var citation = "\(authors) (\(yearStr)). \(titleStr)."
            if !journal.isEmpty { citation += " \(journal)." }
            if !doi.isEmpty { citation += " https://doi.org/\(doi)" }
            return citation
            
        case .mla:
            var citation = "\(authors). \"\(titleStr).\""
            if !journal.isEmpty { citation += " \(journal)," }
            citation += " \(yearStr)."
            return citation
            
        case .chicago:
            var citation = "\(authors). \"\(titleStr).\""
            if !journal.isEmpty { citation += " \(journal)" }
            citation += " (\(yearStr))"
            if !doi.isEmpty { citation += ": \(doi)" }
            return citation + "."
            
        case .harvard:
            var citation = "\(authors) (\(yearStr)) '\(titleStr)'"
            if !journal.isEmpty { citation += ", \(journal)" }
            return citation + "."
            
        case .ieee:
            var citation = "\(authors), \"\(titleStr),\""
            if !journal.isEmpty { citation += " \(journal)," }
            return citation + " \(yearStr)."
        }
    }
    
    /// 生成內文引用標記
    func inTextCitation(style: CitationStyle) -> String {
        let firstAuthor = author.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
        let lastName = firstAuthor.components(separatedBy: " ").last ?? firstAuthor
        let yearStr = year
        
        switch style {
        case .apa7, .apa6, .harvard:
            return "(\(lastName), \(yearStr))"
        case .mla:
            return "(\(lastName))"
        case .chicago:
            return "(\(lastName) \(yearStr))"
        case .ieee:
            return "[\(citationKey)]"
        }
    }
    
    /// 格式化作者名稱
    private func formatAuthorsForCitation(_ authors: String, style: CitationStyle) -> String {
        let authorList = authors.components(separatedBy: " and ")
            .flatMap { $0.components(separatedBy: ",") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !authorList.isEmpty else { return "Unknown" }
        
        switch style {
        case .apa7, .apa6, .harvard:
            if authorList.count == 1 {
                return authorList[0]
            } else if authorList.count == 2 {
                return "\(authorList[0]) & \(authorList[1])"
            } else if authorList.count <= 7 {
                let allButLast = authorList.dropLast().joined(separator: ", ")
                return "\(allButLast), & \(authorList.last!)"
            } else {
                return "\(authorList[0]) et al."
            }
            
        case .mla:
            if authorList.count == 1 {
                return authorList[0]
            } else if authorList.count == 2 {
                return "\(authorList[0]), and \(authorList[1])"
            } else {
                return "\(authorList[0]), et al."
            }
            
        case .chicago, .ieee:
            if authorList.count <= 3 {
                return authorList.joined(separator: ", ")
            } else {
                return "\(authorList[0]) et al."
            }
        }
    }
}

// MARK: - 預覽

#Preview {
    AcademicLibraryView(
        entries: [],
        onImportPDF: {}
    )
    .environmentObject(AppTheme())
    .frame(width: 900, height: 600)
}
