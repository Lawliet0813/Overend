//
//  ZoteroBridgeView.swift
//  OVEREND
//
//  Zotero 連接管理介面
//
//  功能：
//  - 顯示連線狀態
//  - 即時搜尋 Zotero 文獻庫
//  - 搜尋結果列表與一鍵匯入
//  - 故障排除提示
//

import SwiftUI
import CoreData

/// Zotero 橋接視圖
@available(macOS 26.0, *)
struct ZoteroBridgeView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // 服務
    @StateObject private var bridge = ZoteroBridge.shared
    
    // 狀態
    @State private var searchQuery: String = ""
    @State private var selectedItems: Set<String> = []
    @State private var isImporting: Bool = false
    @State private var showImportSuccess: Bool = false
    @State private var importedCount: Int = 0
    @State private var showHelp: Bool = false
    
    // 目標文獻庫
    var targetLibrary: Library?
    
    var body: some View {
        HSplitView {
            // 左側：搜尋與設定
            leftPanel
                .frame(minWidth: 300, maxWidth: 400)
            
            // 右側：搜尋結果
            rightPanel
                .frame(minWidth: 400)
        }
        .overlay(alignment: .top) {
            if showImportSuccess {
                successToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showImportSuccess)
        .sheet(isPresented: $showHelp) {
            helpSheet
        }
    }
    
    // MARK: - 左側面板
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(theme.accent)
                Text("Zotero 連接")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                
                Spacer()
                
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // 連線狀態
            connectionStatusView
            
            Divider()
            
            // 搜尋區
            searchSection
            
            Divider()
            
            // 操作說明
            instructionsSection
            
            Spacer()
        }
        .background(theme.background)
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 狀態指示燈
            Circle()
                .fill(bridge.isConnected ? Color.green : Color.red)
                .frame(width: 12, height: 12)
                .shadow(color: bridge.isConnected ? Color.green.opacity(0.5) : Color.red.opacity(0.5), radius: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(bridge.isConnected ? "已連線" : "未連線")
                    .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                    .foregroundColor(bridge.isConnected ? .green : .red)
                
                if let error = bridge.lastError {
                    Text(error)
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // 重新連線按鈕
            Button {
                Task {
                    await bridge.checkConnection()
                }
            } label: {
                if bridge.isChecking {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.bordered)
            .disabled(bridge.isChecking)
        }
        .padding()
        .background(theme.card)
    }
    
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("搜尋 Zotero 文獻庫")
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.textMuted)
                
                TextField("輸入關鍵字搜尋...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        performSearch()
                    }
                    .disabled(!bridge.isConnected)
                
                if bridge.isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        bridge.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignTokens.Spacing.sm)
            .background(theme.background)
            .cornerRadius(DesignTokens.CornerRadius.medium)
            
            Button {
                performSearch()
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("搜尋")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            .disabled(!bridge.isConnected || searchQuery.isEmpty || bridge.isSearching)
        }
        .padding()
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Label("使用說明", systemImage: "info.circle")
                .font(.system(size: DesignTokens.Typography.caption, weight: .semibold))
                .foregroundColor(theme.textSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                instructionRow("1", "確認 Zotero 已開啟")
                instructionRow("2", "安裝 Better BibTeX 插件")
                instructionRow("3", "搜尋並選擇文獻")
                instructionRow("4", "點擊匯入至 OVEREND")
            }
        }
        .padding()
        .background(theme.card)
    }
    
    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(theme.accent))
            
            Text(text)
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textSecondary)
        }
    }
    
    // MARK: - 右側面板
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(theme.accent)
                Text("搜尋結果")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                
                Spacer()
                
                if !bridge.searchResults.isEmpty {
                    Text("\(bridge.searchResults.count) 筆結果")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                }
            }
            .padding()
            
            Divider()
            
            if bridge.searchResults.isEmpty {
                // 空狀態
                emptyState
            } else {
                // 結果列表
                resultsList
            }
            
            Divider()
            
            // 匯入控制
            importControlBar
        }
        .background(theme.background)
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: bridge.isConnected ? "doc.text.magnifyingglass" : "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(theme.textMuted)
            
            Text(bridge.isConnected ? "輸入關鍵字搜尋 Zotero 文獻" : "請先連接 Zotero")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textSecondary)
            
            if !bridge.isConnected {
                Button {
                    showHelp = true
                } label: {
                    Text("查看連接說明")
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(bridge.searchResults) { item in
                    ZoteroItemRow(
                        item: item,
                        isSelected: selectedItems.contains(item.id),
                        onToggle: {
                            if selectedItems.contains(item.id) {
                                selectedItems.remove(item.id)
                            } else {
                                selectedItems.insert(item.id)
                            }
                        }
                    )
                    .environmentObject(theme)
                }
            }
            .padding()
        }
    }
    
    private var importControlBar: some View {
        HStack {
            // 全選/取消全選
            Button {
                if selectedItems.count == bridge.searchResults.count {
                    selectedItems.removeAll()
                } else {
                    selectedItems = Set(bridge.searchResults.map { $0.id })
                }
            } label: {
                Text(selectedItems.count == bridge.searchResults.count ? "取消全選" : "全選")
            }
            .buttonStyle(.borderless)
            .disabled(bridge.searchResults.isEmpty)
            
            Spacer()
            
            Text("已選擇 \(selectedItems.count) 筆")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
            
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
                    Text("匯入選取項目")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            .disabled(selectedItems.isEmpty || isImporting || targetLibrary == nil)
        }
        .padding()
        .background(theme.toolbar)
    }
    
    // MARK: - Toast
    
    private var successToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("成功匯入 \(importedCount) 筆書目")
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            Capsule()
                .fill(theme.card)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    // MARK: - 說明彈出視窗
    
    private var helpSheet: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            HStack {
                Text("Zotero 連接指南")
                    .font(.system(size: DesignTokens.Typography.title2, weight: .bold))
                
                Spacer()
                
                Button {
                    showHelp = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    // 步驟 1
                    helpStep(
                        number: "1",
                        title: "安裝 Zotero",
                        description: "請從官網下載並安裝 Zotero 書目管理軟體。",
                        link: "https://www.zotero.org/download/"
                    )
                    
                    // 步驟 2
                    helpStep(
                        number: "2",
                        title: "安裝 Better BibTeX 插件",
                        description: "OVEREND 透過 Better BibTeX 插件與 Zotero 通訊。請下載並安裝此插件。",
                        link: "https://retorque.re/zotero-better-bibtex/installation/"
                    )
                    
                    // 步驟 3
                    helpStep(
                        number: "3",
                        title: "啟動 Zotero",
                        description: "確保 Zotero 應用程式正在運行。Better BibTeX 會自動在本機開啟 JSON-RPC 服務（端口 23119）。",
                        link: nil
                    )
                    
                    // 步驟 4
                    helpStep(
                        number: "4",
                        title: "開始搜尋",
                        description: "在 OVEREND 中點擊「重新連線」按鈕，確認連線成功後即可搜尋您的 Zotero 文獻庫。",
                        link: nil
                    )
                    
                    Divider()
                    
                    // 故障排除
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("常見問題")
                            .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                        
                        Text("• 連線失敗：確認 Zotero 正在運行且 Better BibTeX 已安裝")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textSecondary)
                        
                        Text("• 搜尋無結果：嘗試使用不同的關鍵字或檢查 Zotero 資料庫是否有內容")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textSecondary)
                        
                        Text("• 防火牆問題：允許 Zotero 在 localhost:23119 監聽連線")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 500, height: 600)
        .background(theme.background)
    }
    
    private func helpStep(number: String, title: String, description: String, link: String?) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(theme.accent))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textSecondary)
                
                if let link = link {
                    Link(destination: URL(string: link)!) {
                        HStack(spacing: 4) {
                            Text("前往下載")
                            Image(systemName: "arrow.up.right.square")
                        }
                        .font(.system(size: DesignTokens.Typography.caption))
                    }
                }
            }
        }
    }
    
    // MARK: - 動作
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        Task {
            do {
                let _ = try await bridge.search(query: searchQuery)
                selectedItems.removeAll()
            } catch {
                AppLogger.debug("⚠️ ZoteroBridgeView: 搜尋失敗 - \(error.localizedDescription)")
            }
        }
    }
    
    private func performImport() {
        guard let library = targetLibrary else { return }
        
        let itemsToImport = bridge.searchResults.filter { selectedItems.contains($0.id) }
        guard !itemsToImport.isEmpty else { return }
        
        isImporting = true
        
        Task {
            do {
                let count = try bridge.importItems(itemsToImport, into: library, context: viewContext)
                importedCount = count
                selectedItems.removeAll()
                
                showImportSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showImportSuccess = false
                }
            } catch {
                AppLogger.debug("⚠️ ZoteroBridgeView: 匯入失敗 - \(error.localizedDescription)")
            }
            
            isImporting = false
        }
    }
}

// MARK: - Zotero 項目列

@available(macOS 26.0, *)
struct ZoteroItemRow: View {
    @EnvironmentObject var theme: AppTheme
    
    let item: ZoteroItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // 選取框
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? theme.accent : theme.textMuted)
                    .font(.system(size: 20))
                
                // 類型圖標
                itemTypeIcon
                
                // 內容
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        if !item.authorString.isEmpty {
                            Text(item.authorString)
                                .font(.system(size: DesignTokens.Typography.caption))
                                .foregroundColor(theme.textSecondary)
                                .lineLimit(1)
                        }
                        
                        if let year = item.year {
                            Text("(\(year))")
                                .font(.system(size: DesignTokens.Typography.caption))
                                .foregroundColor(theme.textMuted)
                        }
                    }
                    
                    if let journal = item.publicationTitle {
                        Text(journal)
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textMuted)
                            .italic()
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Citation Key
                if let citekey = item.citationKey {
                    Text(citekey)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.accentLight.opacity(0.2))
                        )
                }
            }
            .padding(DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(isSelected ? theme.accentLight.opacity(0.1) : (isHovered ? theme.card : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var itemTypeIcon: some View {
        let iconName: String
        let iconColor: Color
        
        switch item.itemType {
        case "journalArticle":
            iconName = "doc.text"
            iconColor = .blue
        case "book":
            iconName = "book.closed"
            iconColor = .brown
        case "bookSection":
            iconName = "text.book.closed"
            iconColor = .orange
        case "conferencePaper":
            iconName = "person.3"
            iconColor = .purple
        case "thesis":
            iconName = "graduationcap"
            iconColor = .green
        case "report":
            iconName = "doc.richtext"
            iconColor = .gray
        case "webpage":
            iconName = "globe"
            iconColor = .cyan
        default:
            iconName = "doc"
            iconColor = .gray
        }
        
        return Image(systemName: iconName)
            .foregroundColor(iconColor)
            .frame(width: 24, height: 24)
    }
}

// MARK: - Preview

@available(macOS 26.0, *)
#Preview {
    ZoteroBridgeView()
        .environmentObject(AppTheme())
        .frame(width: 900, height: 600)
}
