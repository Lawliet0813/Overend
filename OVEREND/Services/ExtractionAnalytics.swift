//
//  ExtractionAnalytics.swift
//  OVEREND
//
//  AI 提取分析服務
//

import Foundation
import CoreData

/// AI 提取分析服務
struct ExtractionAnalytics {
    let context: NSManagedObjectContext
    
    // MARK: - 準確率分析
    
    /// 計算各提取方法的準確率
    func calculateMethodAccuracies() -> [MethodAccuracy] {
        let logs = ExtractionLog.fetchAllRated(context: context)
        
        // 依方法分組
        var methodStats: [String: (count: Int, totalRating: Int, corrected: Int)] = [:]
        
        for log in logs {
            let method = log.extractionMethod ?? "unknown"
            
            if methodStats[method] == nil {
                methodStats[method] = (0, 0, 0)
            }
            
            methodStats[method]!.count += 1
            methodStats[method]!.totalRating += Int(log.userRating)
            if log.needsCorrection {
                methodStats[method]!.corrected += 1
            }
        }
        
        return methodStats.map { method, stats in
            MethodAccuracy(
                method: method,
                displayName: displayName(for: method),
                totalCount: stats.count,
                averageRating: stats.count > 0 ? Double(stats.totalRating) / Double(stats.count) : 0,
                correctionRate: stats.count > 0 ? Double(stats.corrected) / Double(stats.count) * 100 : 0
            )
        }.sorted { $0.averageRating > $1.averageRating }
    }
    
    /// 計算整體統計
    func calculateSummary() -> AnalyticsSummary {
        let allLogs = ExtractionLog.fetchAll(context: context)
        let ratedLogs = allLogs.filter { $0.userRating > 0 }
        let correctedLogs = allLogs.filter { $0.needsCorrection }
        
        let totalRating = ratedLogs.reduce(0) { $0 + Int($1.userRating) }
        let averageRating = ratedLogs.isEmpty ? 0 : Double(totalRating) / Double(ratedLogs.count)
        
        return AnalyticsSummary(
            totalExtractions: allLogs.count,
            ratedExtractions: ratedLogs.count,
            correctedExtractions: correctedLogs.count,
            averageRating: averageRating,
            methodAccuracies: calculateMethodAccuracies(),
            commonErrors: findCommonErrors(),
            suggestions: generatePromptSuggestions()
        )
    }
    
    // MARK: - 錯誤模式分析
    
    /// 找出常見錯誤模式
    func findCommonErrors() -> [ErrorPattern] {
        let logs = ExtractionLog.fetchAllWithCorrections(context: context)
        
        var patterns: [String: [ErrorPattern]] = [:]
        
        for log in logs {
            // 分析標題錯誤
            if let aiTitle = log.aiTitle,
               let correctTitle = log.userCorrectedTitle,
               !correctTitle.isEmpty,
               aiTitle != correctTitle {
                let pattern = ErrorPattern(
                    field: "title",
                    aiValue: aiTitle,
                    correctValue: correctTitle,
                    pdfSample: String(log.pdfText?.prefix(200) ?? ""),
                    frequency: 1
                )
                if patterns["title"] == nil { patterns["title"] = [] }
                patterns["title"]!.append(pattern)
            }
            
            // 分析作者錯誤
            if let aiAuthors = log.aiAuthors,
               let correctAuthors = log.userCorrectedAuthors,
               !correctAuthors.isEmpty,
               aiAuthors != correctAuthors {
                let pattern = ErrorPattern(
                    field: "authors",
                    aiValue: aiAuthors,
                    correctValue: correctAuthors,
                    pdfSample: String(log.pdfText?.prefix(200) ?? ""),
                    frequency: 1
                )
                if patterns["authors"] == nil { patterns["authors"] = [] }
                patterns["authors"]!.append(pattern)
            }
            
            // 分析年份錯誤
            if let aiYear = log.aiYear,
               let correctYear = log.userCorrectedYear,
               !correctYear.isEmpty,
               aiYear != correctYear {
                let pattern = ErrorPattern(
                    field: "year",
                    aiValue: aiYear,
                    correctValue: correctYear,
                    pdfSample: String(log.pdfText?.prefix(200) ?? ""),
                    frequency: 1
                )
                if patterns["year"] == nil { patterns["year"] = [] }
                patterns["year"]!.append(pattern)
            }
        }
        
        // 取各欄位前 5 個最常見錯誤
        return patterns.values.flatMap { errors -> [ErrorPattern] in
            Array(errors.prefix(5))
        }
    }
    
    // MARK: - Prompt 改進建議
    
    /// 生成 Prompt 改進建議
    func generatePromptSuggestions() -> [PromptSuggestion] {
        let errors = findCommonErrors()
        var suggestions: [PromptSuggestion] = []
        
        // 分析作者欄位的錯誤模式
        let authorErrors = errors.filter { $0.field == "authors" }
        
        // 檢查是否常把「主編」當作「作者」
        let editorMistakes = authorErrors.filter { 
            $0.aiValue.contains("主編") || 
            $0.aiValue.contains("編者") ||
            $0.aiValue.contains("Editor")
        }
        
        if editorMistakes.count >= 2 {
            suggestions.append(
                PromptSuggestion(
                    issue: "常將主編/編者誤認為作者",
                    currentPrompt: "提取所有作者姓名",
                    suggestedPrompt: "提取論文作者姓名，排除主編、編者、譯者等角色",
                    affectedCount: editorMistakes.count,
                    priority: .high
                )
            )
        }
        
        // 檢查年份錯誤
        let yearErrors = errors.filter { $0.field == "year" }
        if yearErrors.count >= 3 {
            suggestions.append(
                PromptSuggestion(
                    issue: "年份提取不準確",
                    currentPrompt: "提取出版年份",
                    suggestedPrompt: "提取論文的出版年份，優先使用 PDF 首頁或引用格式中的年份，忽略參考文獻中的年份",
                    affectedCount: yearErrors.count,
                    priority: .medium
                )
            )
        }
        
        // 檢查標題錯誤
        let titleErrors = errors.filter { $0.field == "title" }
        let subtitleMistakes = titleErrors.filter {
            $0.aiValue.count < $0.correctValue.count - 10 ||
            !$0.correctValue.hasPrefix($0.aiValue.prefix(20))
        }
        
        if subtitleMistakes.count >= 2 {
            suggestions.append(
                PromptSuggestion(
                    issue: "標題提取不完整（可能遺漏副標題）",
                    currentPrompt: "提取論文標題",
                    suggestedPrompt: "提取論文完整標題，包含副標題（如有冒號或破折號分隔）",
                    affectedCount: subtitleMistakes.count,
                    priority: .medium
                )
            )
        }
        
        // 依優先級排序
        return suggestions.sorted { 
            let priority1 = ["high": 0, "medium": 1, "low": 2][$0.priority.rawValue.lowercased()] ?? 2
            let priority2 = ["high": 0, "medium": 1, "low": 2][$1.priority.rawValue.lowercased()] ?? 2
            return priority1 < priority2
        }
    }
    
    // MARK: - Helpers
    
    private func displayName(for method: String) -> String {
        switch method {
        case "apple_ai": return "Apple Intelligence"
        case "doi": return "DOI Lookup"
        case "regex": return "Regex"
        case "pdf_attributes": return "PDF Metadata"
        case "filename": return "Filename"
        default: return method
        }
    }
}
