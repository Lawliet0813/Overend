//
//  NotionSettingsView.swift
//  OVEREND
//
//  Notion 整合設定頁面
//

import SwiftUI
import UniformTypeIdentifiers

struct NotionSettingsView: View {
    @EnvironmentObject var theme: AppTheme
    
    @State private var apiKey: String = NotionConfig.apiKey
    @State private var databaseId: String = NotionConfig.databaseId
    @State private var isAutoCreateEnabled: Bool = NotionConfig.isAutoCreateEnabled
    
    @State private var diaryPageId: String = NotionConfig.diaryPageId
    @State private var isSyncingDiary = false
    @State private var syncMessage = ""
    @State private var showFileImporter = false
    
    @State private var isTestingConnection = false
    @State private var connectionResult: Bool?
    @State private var connectionMessage: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Notion API 設定").font(.headline)) {
                SecureField("Internal Integration Token (API Key)", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: apiKey) { newValue in
                        NotionConfig.apiKey = newValue
                        connectionResult = nil
                    }
                
                TextField("Database ID", text: $databaseId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: databaseId) { newValue in
                        NotionConfig.databaseId = newValue
                        connectionResult = nil
                    }
                
                Text("請確保您的 Integration 已邀請至該 Database")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("自動化").font(.headline)) {
                Toggle("匯入 PDF 時自動建立測試記錄", isOn: $isAutoCreateEnabled)
                    .onChange(of: isAutoCreateEnabled) { newValue in
                        NotionConfig.isAutoCreateEnabled = newValue
                    }
            }
            
            Section {
                HStack {
                    Button(action: testConnection) {
                        if isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 16, height: 16)
                        } else {
                            Text("測試連接")
                        }
                    }
                    .disabled(apiKey.isEmpty || databaseId.isEmpty || isTestingConnection)
                    
                    if let result = connectionResult {
                        Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result ? .green : .red)
                        Text(connectionMessage)
                            .foregroundColor(result ? .green : .red)
                            .font(.caption)
                    }
                }
            }
            
            Section(header: Text("說明").font(.headline)) {
                Text("此功能用於自動將 PDF 提取結果記錄到 Notion 資料庫，以便進行準確度測試與追蹤。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Link("查看資料庫模板規格", destination: URL(string: "https://www.notion.so")!) // 這裡可以放實際的模板連結
                    .font(.caption)
            }
            
            Section(header: Text("開發日記同步").font(.headline)) {
                TextField("Diary Page ID", text: $diaryPageId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: diaryPageId) { newValue in
                        NotionConfig.diaryPageId = newValue
                    }
                
                Button(action: { showFileImporter = true }) {
                    if isSyncingDiary {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                    } else {
                        Text("選取日記檔案並同步最新一筆")
                    }
                }
                .disabled(apiKey.isEmpty || diaryPageId.isEmpty || isSyncingDiary)
                
                if !syncMessage.isEmpty {
                    Text(syncMessage)
                        .font(.caption)
                        .foregroundColor(syncMessage.contains("錯誤") ? .red : .green)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        syncDiary(url: url)
                    }
                case .failure(let error):
                    syncMessage = "選取檔案失敗：\(error.localizedDescription)"
                }
            }
        }
        .padding()
        .frame(width: 500)
    }
    

    
    private func testConnection() {
        isTestingConnection = true
        connectionResult = nil
        connectionMessage = ""
        
        Task {
            do {
                let success = try await NotionService.shared.testConnection()
                await MainActor.run {
                    isTestingConnection = false
                    connectionResult = success
                    connectionMessage = success ? "連接成功" : "連接失敗：無法存取資料庫"
                }
            } catch {
                await MainActor.run {
                    isTestingConnection = false
                    connectionResult = false
                    connectionMessage = "連接錯誤：\(error.localizedDescription)"
                }
            }
        }
    }
    
    private func syncDiary(url: URL) {
        isSyncingDiary = true
        syncMessage = "讀取檔案中..."
        
        Task {
            do {
                // Read file content
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                
                let content = try String(contentsOf: url, encoding: .utf8)
                
                // Extract latest entry (last ### section)
                let lines = content.components(separatedBy: .newlines)
                var lastEntryLines: [String] = []
                
                // Reverse scan to find the last entry
                // Strategy: Find the last "### " line, and take everything from there to the end
                if let lastHeaderIndex = lines.lastIndex(where: { $0.hasPrefix("### ") }) {
                    lastEntryLines = Array(lines[lastHeaderIndex...])
                } else {
                    lastEntryLines = lines // Fallback: sync whole file if no headers
                }
                
                let entryContent = lastEntryLines.joined(separator: "\n")
                
                await MainActor.run { syncMessage = "正在同步至 Notion..." }
                
                try await NotionService.shared.syncDiaryEntry(content: entryContent)
                
                await MainActor.run {
                    isSyncingDiary = false
                    syncMessage = "✅ 同步成功！"
                }
            } catch {
                await MainActor.run {
                    isSyncingDiary = false
                    syncMessage = "❌ 錯誤：\(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NotionSettingsView()
        .environmentObject(AppTheme())
}
