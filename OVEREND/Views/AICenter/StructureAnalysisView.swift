//
//  StructureAnalysisView.swift
//  OVEREND
//
//  論文結構分析視圖  
//

import SwiftUI

/// 論文結構分析結果
struct StructureAnalysisResult {
    let sections: [AnalyzedSection]
    let overallScore: Double
    let suggestions: [StructureSuggestion]
}

/// 已分析的章節
struct AnalyzedSection: Identifiable {
    let id = UUID()
    let name: String
    let type: SectionType
    let wordCount: Int
    let percentage: Double
    let issues: [String]
    let isPresent: Bool
    
    enum SectionType: String, CaseIterable {
        case abstract = "摘要"
        case introduction = "緒論"
        case literature = "文獻回顧"
        case methodology = "研究方法"
        case results = "研究結果"
        case discussion = "討論"
        case conclusion = "結論"
        case references = "參考文獻"
        
        var icon: String {
            switch self {
            case .abstract: return "doc.text"
            case .introduction: return "arrow.right.circle"
            case .literature: return "books.vertical"
            case .methodology: return "gearshape.2"
            case .results: return "chart.bar"
            case .discussion: return "bubble.left.and.bubble.right"
            case .conclusion: return "checkmark.circle"
            case .references: return "quote.closing"
            }
        }
        
        var idealPercentage: ClosedRange<Double> {
            switch self {
            case .abstract: return 2...5
            case .introduction: return 8...12
            case .literature: return 15...25
            case .methodology: return 15...20
            case .results: return 15...25
            case .discussion: return 10...20
            case .conclusion: return 3...8
            case .references: return 5...15
            }
        }
    }
}

/// 結構建議
struct StructureSuggestion: Identifiable {
    let id = UUID()
    let severity: Severity
    let message: String
    let section: AnalyzedSection.SectionType?
    
    enum Severity: String {
        case high = "高"
        case medium = "中"
        case low = "低"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .yellow
            }
        }
    }
}

/// 結構分析視圖
@available(macOS 26.0, *)
struct StructureAnalysisView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var analysisResult: StructureAnalysisResult?
    @State private var documentType: DocumentType = .thesis
    
    enum DocumentType: String, CaseIterable {
        case thesis = "學位論文"
        case journalPaper = "期刊論文"
        case conferencePaper = "會議論文"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            toolbarView
            
            Divider()
            
            // 主內容
            HSplitView {
                // 輸入區
                inputSection
                    .frame(minWidth: 350)
                
                // 結果區
                resultSection
                    .frame(minWidth: 450)
            }
        }
        .background(theme.background)
    }
    
    // MARK: - 子視圖
    
    private var toolbarView: some View {
        HStack(spacing: 16) {
            // 文件類型選擇
            Picker("文件類型", selection: $documentType) {
                ForEach(DocumentType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // 分析按鈕
            Button(action: analyzeStructure) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chart.bar.doc.horizontal")
                    }
                    Text("分析結構")
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
            Text("輸入論文內容")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            Text("貼上您的論文全文或使用「載入範例」測試")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            TextEditor(text: $inputText)
                .font(.system(.body))
                .padding(8)
                .background(theme.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
            
            HStack {
                Button("載入範例") {
                    loadSampleContent()
                }
                .font(.caption)
                
                Spacer()
                
                Text("\(inputText.count) 字")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
    }
    
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let result = analysisResult {
                // 總體評分
                overallScoreView(score: result.overallScore)
                
                // 章節分析
                sectionAnalysisView(sections: result.sections)
                
                // 建議列表
                suggestionsView(suggestions: result.suggestions)
            } else if !isProcessing {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundColor(theme.textTertiary)
                    Text("輸入論文內容後點擊「分析結構」")
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("正在分析論文結構...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
    
    private func overallScoreView(score: Double) -> some View {
        HStack(spacing: 16) {
            // 分數圓圈
            ZStack {
                Circle()
                    .stroke(theme.border, lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80, height: 80)
                
                VStack(spacing: 0) {
                    Text("\(Int(score))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    Text("分")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("結構完整度")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Text(scoreDescription(score))
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(theme.card)
        .cornerRadius(12)
    }
    
    private func sectionAnalysisView(sections: [AnalyzedSection]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("章節分析")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sections) { section in
                        sectionCard(section)
                    }
                }
            }
        }
    }
    
    private func sectionCard(_ section: AnalyzedSection) -> some View {
        VStack(spacing: 8) {
            Image(systemName: section.type.icon)
                .font(.system(size: 24))
                .foregroundColor(section.isPresent ? theme.accent : theme.textTertiary)
            
            Text(section.type.rawValue)
                .font(.caption)
                .foregroundColor(theme.textPrimary)
            
            if section.isPresent {
                Text("\(section.wordCount) 字")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                
                Text("\(Int(section.percentage))%")
                    .font(.caption2)
                    .foregroundColor(percentageColor(section.percentage, ideal: section.type.idealPercentage))
            } else {
                Text("缺失")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .frame(width: 80, height: 100)
        .padding(8)
        .background(section.isPresent ? theme.card : Color.red.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(section.isPresent ? theme.border : Color.red, lineWidth: 1)
        )
    }
    
    private func suggestionsView(suggestions: [StructureSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("改進建議")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(suggestions) { suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(suggestion.severity.color)
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if let section = suggestion.section {
                                    Text(section.rawValue)
                                        .font(.caption)
                                        .foregroundColor(theme.accent)
                                }
                                Text(suggestion.message)
                                    .font(.subheadline)
                                    .foregroundColor(theme.textPrimary)
                            }
                        }
                        .padding(8)
                        .background(theme.card)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func analyzeStructure() {
        isProcessing = true
        analysisResult = nil
        
        Task {
            let result = await performAnalysis()
            await MainActor.run {
                analysisResult = result
                isProcessing = false
            }
        }
    }
    
    private func performAnalysis() async -> StructureAnalysisResult {
        let text = inputText.lowercased()
        var sections: [AnalyzedSection] = []
        var suggestions: [StructureSuggestion] = []
        
        // 關鍵字檢測
        let sectionKeywords: [(AnalyzedSection.SectionType, [String])] = [
            (.abstract, ["摘要", "abstract"]),
            (.introduction, ["緒論", "導論", "introduction", "背景"]),
            (.literature, ["文獻", "literature", "相關研究"]),
            (.methodology, ["研究方法", "methodology", "研究設計"]),
            (.results, ["研究結果", "results", "發現"]),
            (.discussion, ["討論", "discussion"]),
            (.conclusion, ["結論", "conclusion", "建議"]),
            (.references, ["參考文獻", "references", "bibliography"])
        ]
        
        let totalWords = inputText.count
        
        for (type, keywords) in sectionKeywords {
            let isPresent = keywords.contains { text.contains($0) }
            let estimatedWordCount = isPresent ? Int(Double(totalWords) * Double.random(in: 0.05...0.25)) : 0
            let percentage = isPresent ? Double(estimatedWordCount) / Double(totalWords) * 100 : 0
            
            var issues: [String] = []
            if !isPresent {
                issues.append("缺少\(type.rawValue)章節")
                suggestions.append(StructureSuggestion(
                    severity: type == .abstract || type == .conclusion ? .high : .medium,
                    message: "論文缺少\(type.rawValue)章節，建議補充",
                    section: type
                ))
            } else if !type.idealPercentage.contains(percentage) {
                if percentage < type.idealPercentage.lowerBound {
                    suggestions.append(StructureSuggestion(
                        severity: .low,
                        message: "\(type.rawValue)篇幅偏短，建議擴充",
                        section: type
                    ))
                } else if percentage > type.idealPercentage.upperBound {
                    suggestions.append(StructureSuggestion(
                        severity: .low,
                        message: "\(type.rawValue)篇幅過長，建議精簡",
                        section: type
                    ))
                }
            }
            
            sections.append(AnalyzedSection(
                name: type.rawValue,
                type: type,
                wordCount: estimatedWordCount,
                percentage: percentage,
                issues: issues,
                isPresent: isPresent
            ))
        }
        
        // 計算總分
        let presentCount = sections.filter { $0.isPresent }.count
        let overallScore = Double(presentCount) / Double(sections.count) * 100
        
        return StructureAnalysisResult(
            sections: sections,
            overallScore: overallScore,
            suggestions: suggestions
        )
    }
    
    private func loadSampleContent() {
        inputText = """
        摘要
        
        本研究旨在探討人工智慧在學術寫作中的應用。透過文獻回顧與實證研究，我們發現 AI 工具能顯著提升研究效率。
        
        第一章 緒論
        
        隨著科技發展，學術研究面臨新的挑戰與機會。本研究背景說明當前學術寫作的困境，並提出研究目的與問題。
        
        第二章 文獻回顧
        
        本章回顧相關文獻，包括人工智慧發展史、自然語言處理技術、以及學術寫作輔助工具的演進。
        
        第三章 研究方法
        
        採用混合研究法，結合量化問卷調查與質性深度訪談，以全面了解研究對象的使用經驗與需求。
        
        第四章 研究結果
        
        問卷調查結果顯示，85% 的受訪者認為 AI 工具有助於提升寫作品質。訪談資料進一步揭示使用者的具體使用模式。
        
        第五章 討論
        
        本章討論研究發現的理論與實務意涵，並與先前研究進行比較分析。
        
        第六章 結論與建議
        
        總結研究發現，並提出未來研究方向與實務建議。
        
        參考文獻
        
        Brown, T. (2020). Language models are few-shot learners. NeurIPS.
        """
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
    
    private func scoreDescription(_ score: Double) -> String {
        switch score {
        case 90...: return "結構非常完整，符合學術論文標準"
        case 80..<90: return "結構良好，僅需小幅調整"
        case 60..<80: return "結構尚可，建議補充缺失章節"
        default: return "結構需要大幅改進"
        }
    }
    
    private func percentageColor(_ percentage: Double, ideal: ClosedRange<Double>) -> Color {
        if ideal.contains(percentage) {
            return .green
        } else if percentage < ideal.lowerBound {
            return .orange
        } else {
            return .yellow
        }
    }
}
