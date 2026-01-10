//
//  CitationCheckView.swift
//  OVEREND
//
//  引用檢查視圖 - 檢查引用格式與掠奪性期刊
//

import SwiftUI
import FoundationModels

/// 引用檢查結果
struct FormatCheckResult: Identifiable {
    let id = UUID()
    let citation: String
    let issues: [FormatIssue]
    let isPredatoryJournal: Bool
    let journalName: String?
    
    var hasIssues: Bool { !issues.isEmpty || isPredatoryJournal }
}

/// 引用問題類型
struct FormatIssue: Identifiable {
    let id = UUID()
    let type: IssueType
    let description: String
    let suggestion: String
    
    enum IssueType: String {
        case format = "格式問題"
        case missingField = "欄位缺失"
        case predatoryJournal = "掠奪性期刊"
        case dateFormat = "日期格式"
        case authorFormat = "作者格式"
        
        var icon: String {
            switch self {
            case .format: return "doc.text.magnifyingglass"
            case .missingField: return "exclamationmark.triangle"
            case .predatoryJournal: return "exclamationmark.shield"
            case .dateFormat: return "calendar.badge.exclamationmark"
            case .authorFormat: return "person.badge.minus"
            }
        }
        
        var color: Color {
            switch self {
            case .predatoryJournal: return .red
            case .missingField: return .orange
            default: return .yellow
            }
        }
    }
}

/// 引用檢查視圖
@available(macOS 26.0, *)
struct CitationCheckView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var results: [FormatCheckResult] = []
    @State private var selectedStyle: CitationStyle = .apa7
    @State private var showPredatoryWarning: Bool = false
    
    // 掠奪性期刊清單 (部分範例)
    private let predatoryIndicators: Set<String> = [
        "omics", "sciencepg", "mdpi", "frontiers", "hindawi",
        "bentham", "dove", "intech", "scirp", "waset"
    ]
    
    enum CitationStyle: String, CaseIterable {
        case apa7 = "APA 7th"
        case mla9 = "MLA 9th"
        case chicago = "Chicago"
        
        var description: String {
            switch self {
            case .apa7: return "美國心理學會格式第七版"
            case .mla9: return "現代語言學會格式第九版"
            case .chicago: return "芝加哥格式"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            toolbarView
            
            Divider()
            
            // 主內容
            HStack(spacing: 0) {
                // 輸入區
                inputSection
                
                Divider()
                
                // 結果區
                resultSection
            }
        }
        .background(theme.background)
    }
    
    // MARK: - 子視圖
    
    private var toolbarView: some View {
        HStack(spacing: 16) {
            // 格式選擇
            Picker("引用格式", selection: $selectedStyle) {
                ForEach(CitationStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // 掠奪性期刊警告開關
            Toggle(isOn: $showPredatoryWarning) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.shield")
                        .foregroundColor(.red)
                    Text("檢查掠奪性期刊")
                }
            }
            .toggleStyle(.switch)
            
            // 檢查按鈕
            Button(action: checkCitations) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle")
                    }
                    Text("檢查引用")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.isEmpty || isProcessing)
        }
        .padding()
        .background(theme.elevated)
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("輸入引用文字")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            Text("貼上您的引用列表，每條引用一行")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            TextEditor(text: $inputText)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(theme.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
            
            // 範例按鈕
            Button("載入範例") {
                inputText = """
                Smith, J. (2023). Machine learning applications. Journal of AI Research, 15(2), 45-67.
                Wang, L., & Chen, M. (2022). Deep learning fundamentals. OMICS International Journal, 8, 123-145.
                Brown (2021). Missing journal title and volume.
                """
            }
            .font(.caption)
        }
        .padding()
        .frame(minWidth: 350)
    }
    
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("檢查結果")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                if !results.isEmpty {
                    let issueCount = results.filter { $0.hasIssues }.count
                    Text("\(issueCount) / \(results.count) 項有問題")
                        .font(.caption)
                        .foregroundColor(issueCount > 0 ? .orange : .green)
                }
            }
            
            if results.isEmpty && !isProcessing {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(theme.textTertiary)
                    Text("輸入引用文字後點擊「檢查引用」")
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(results) { result in
                            CitationResultCard(result: result, theme: theme)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 400)
    }
    
    // MARK: - 方法
    
    private func checkCitations() {
        isProcessing = true
        results = []
        
        Task {
            let lines = inputText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            for line in lines {
                let result = await analyzeCitation(line)
                await MainActor.run {
                    results.append(result)
                }
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func analyzeCitation(_ citation: String) async -> FormatCheckResult {
        var issues: [FormatIssue] = []
        var isPredatory = false
        var journalName: String? = nil
        
        // 1. 檢查基本格式
        if !citation.contains("(") || !citation.contains(")") {
            issues.append(FormatIssue(
                type: .format,
                description: "缺少年份括號",
                suggestion: "APA 格式要求年份使用括號，如：(2023)"
            ))
        }
        
        // 2. 檢查作者格式
        if !citation.contains(",") {
            issues.append(FormatIssue(
                type: .authorFormat,
                description: "作者格式可能不正確",
                suggestion: "使用「姓, 名縮寫.」格式，如：Smith, J."
            ))
        }
        
        // 3. 檢查是否有期刊名稱
        let hasItalicIndicator = citation.contains("Journal") || 
                                  citation.contains("期刊") ||
                                  citation.contains("Review")
        if !hasItalicIndicator && selectedStyle == .apa7 {
            issues.append(FormatIssue(
                type: .missingField,
                description: "可能缺少期刊名稱或書名",
                suggestion: "APA 格式要求包含期刊名稱（斜體）"
            ))
        }
        
        // 4. 檢查掠奪性期刊
        if showPredatoryWarning {
            let lowercaseCitation = citation.lowercased()
            for indicator in predatoryIndicators {
                if lowercaseCitation.contains(indicator) {
                    isPredatory = true
                    journalName = extractJournalName(from: citation)
                    issues.append(FormatIssue(
                        type: .predatoryJournal,
                        description: "此期刊可能為掠奪性期刊",
                        suggestion: "建議查閱 Beall's List 或 DOAJ 確認期刊合法性"
                    ))
                    break
                }
            }
        }
        
        // 5. 使用 AI 進行更深入分析（如果可用）
        if #available(macOS 26.0, *) {
            do {
                let aiIssues = try await checkWithAI(citation)
                issues.append(contentsOf: aiIssues)
            } catch {
                print("AI 檢查失敗: \(error)")
            }
        }
        
        return FormatCheckResult(
            citation: citation,
            issues: issues,
            isPredatoryJournal: isPredatory,
            journalName: journalName
        )
    }
    
    private func extractJournalName(from citation: String) -> String? {
        // 簡單提取：找到斜體部分或期刊關鍵字後的文字
        if let range = citation.range(of: "Journal[^,\\.]+", options: .regularExpression) {
            return String(citation[range])
        }
        return nil
    }
    
    @available(macOS 26.0, *)
    private func checkWithAI(_ citation: String) async throws -> [FormatIssue] {
        let ai = UnifiedAIService.shared
        
        // 使用快取
        let cacheKey = ai.cacheKey(operation: "citation_check_\(selectedStyle.rawValue)", input: citation)
        if let cached = ai.getCachedResult(for: cacheKey) {
            // 解析快取結果
            return parseCachedIssues(cached)
        }
        
        let session = ai.acquireSession()
        defer { ai.releaseSession(session) }
        
        let prompt = """
        你是引用格式專家。請檢查以下引用是否符合 \(selectedStyle.rawValue) 格式：
        
        引用：\(citation)
        
        請以 JSON 格式回覆（不要 markdown 標記）：
        [
          {"type": "format|missing|author|date", "description": "問題描述", "suggestion": "修正建議"}
        ]
        
        如果沒有問題，回覆空陣列 []
        """
        
        let response = try await session.respond(to: prompt)
        ai.cacheResult(response.content, for: cacheKey)
        
        return parseCachedIssues(response.content)
    }
    
    private func parseCachedIssues(_ json: String) -> [FormatIssue] {
        guard let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        
        return array.compactMap { dict in
            guard let desc = dict["description"],
                  let suggestion = dict["suggestion"] else { return nil }
            
            let type: FormatIssue.IssueType
            switch dict["type"] {
            case "missing": type = .missingField
            case "author": type = .authorFormat
            case "date": type = .dateFormat
            default: type = .format
            }
            
            return FormatIssue(type: type, description: desc, suggestion: suggestion)
        }
    }
}

// MARK: - 結果卡片

struct CitationResultCard: View {
    let result: FormatCheckResult
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 引用文字
            Text(result.citation)
                .font(.system(.body, design: .serif))
                .foregroundColor(theme.textPrimary)
                .lineLimit(3)
            
            // 問題列表
            if result.hasIssues {
                Divider()
                
                ForEach(result.issues) { issue in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: issue.type.icon)
                            .foregroundColor(issue.type.color)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.description)
                                .font(.caption)
                                .foregroundColor(theme.textPrimary)
                            
                            Text(issue.suggestion)
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("格式正確")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(result.isPredatoryJournal ? Color.red.opacity(0.1) : theme.card)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(result.isPredatoryJournal ? Color.red : theme.border, lineWidth: 1)
        )
    }
}
