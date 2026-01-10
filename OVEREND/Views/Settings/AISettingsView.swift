//
//  AISettingsView.swift
//  OVEREND
//
//  AI 設定視圖 - Gemini API 配置
//

import SwiftUI

struct AISettingsView: View {
    @ObservedObject private var geminiService = GeminiService.shared
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var testStatus: TestStatus = .idle
    
    enum TestStatus {
        case idle
        case testing
        case success
        case failed(String)
    }
    
    var body: some View {
        Form {
            // Apple Intelligence 狀態
            Section("Apple Intelligence") {
                HStack {
                    Image(systemName: "apple.intelligence")
                        .foregroundColor(.green)
                    Text("已啟用")
                        .foregroundColor(.green)
                    Spacer()
                    Text("macOS 26.0+")
                        .foregroundColor(.secondary)
                }
                
                Text("Apple Intelligence 用於處理短文本（< 1000 字元）")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Gemini API 設定
            Section("Gemini API（備用）") {
                Text("當文本超過 Apple Intelligence 上下文視窗限制時，將使用 Gemini API 處理")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    if showAPIKey {
                        TextField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button(action: { showAPIKey.toggle() }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
                
                HStack {
                    Button("儲存") {
                        geminiService.configure(apiKey: apiKey)
                    }
                    .disabled(apiKey.isEmpty || apiKey == "••••••••••••••••")
                    
                    Button("測試連線") {
                        testConnection()
                    }
                    .disabled(apiKey.isEmpty)
                    
                    Spacer()
                    
                    statusView
                }
                
                if geminiService.isConfigured {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        Text("API Key 已設定")
                        .foregroundColor(.green)
                    }
                }
            }
            
            // Gemini PDF 導入設定
            Section("PDF 導入設定") {
                Toggle(isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "useGeminiForPDF") },
                    set: { UserDefaults.standard.set($0, forKey: "useGeminiForPDF") }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("使用 Gemini 分析 PDF")
                        Text("直接上傳 PDF 到 Gemini 進行分析，可提取更完整的書目資訊")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!geminiService.isConfigured)
                
                if !geminiService.isConfigured {
                    Text("需要先設定 Gemini API Key")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // 快取管理
            Section("快取管理") {
                Button("清除 AI 快取") {
                    if #available(macOS 26.0, *) {
                        UnifiedAIService.shared.clearCache()
                    }
                    geminiService.clearCache()
                }
            }
            
            // 使用說明
            Section("說明") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("取得 Gemini API Key：")
                        .font(.headline)
                    
                    Link("前往 Google AI Studio",
                         destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                    
                    Text("1. 登入 Google 帳號")
                    Text("2. 點擊「建立 API 金鑰」")
                    Text("3. 複製金鑰並貼到上方欄位")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            // 載入已儲存的 API key（部分遮蔽顯示）
            if geminiService.isConfigured {
                apiKey = "••••••••••••••••"
            }
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch testStatus {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView()
                .scaleEffect(0.8)
        case .success:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("連線成功")
                    .foregroundColor(.green)
            }
        case .failed(let message):
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
        }
    }
    
    private func testConnection() {
        testStatus = .testing
        
        // 只有當 API Key 不是遮蔽字串時才更新配置
        if apiKey != "••••••••••••••••" {
            geminiService.configure(apiKey: apiKey)
        }
        
        Task {
            do {
                let response = try await geminiService.generateContent(prompt: "回覆「連線成功」")
                await MainActor.run {
                    if response.contains("成功") || !response.isEmpty {
                        testStatus = .success
                    } else {
                        testStatus = .failed("回應異常")
                    }
                }
            } catch {
                await MainActor.run {
                    testStatus = .failed(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    AISettingsView()
}
