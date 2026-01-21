//
//  WritingAIDomain.swift
//  OVEREND
//
//  寫作輔助領域 (演算法版本)
//  整合 ToneAdjuster, ContentExpander, ContentSimplifier
//

import Foundation
import AppKit

// MARK: - 寫作選項

public struct WritingOptions {
    public var checkGrammar: Bool = true
    public var checkStyle: Bool = true
    public var checkLogic: Bool = true
    public var academicMode: Bool = true
    public var language: WritingLanguage = .traditionalChinese
    
    public init() {}
    
    public enum WritingLanguage: String {
        case traditionalChinese = "zh-TW"
        case english = "en"
    }
}

public enum RewriteStyle: String, CaseIterable {
    case formal = "formal"
    case academic = "academic"
    case concise = "concise"
    case elaborate = "elaborate"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .formal: return "正式"
        case .academic: return "學術"
        case .concise: return "精簡"
        case .elaborate: return "詳細"
        case .neutral: return "中立客觀"
        }
    }
}

// MARK: - 寫作建議結果

public struct WritingSuggestions {
    public let grammarIssues: [GrammarIssue]
    public let styleIssues: [StyleIssue]
    public let logicIssues: [LogicIssue]
    public let overallFeedback: String
    
    public var hasIssues: Bool {
        !grammarIssues.isEmpty || !styleIssues.isEmpty || !logicIssues.isEmpty
    }
    
    public var totalIssueCount: Int {
        grammarIssues.count + styleIssues.count + logicIssues.count
    }
}

public struct GrammarIssue: Identifiable {
    public let id = UUID()
    public let original: String
    public let suggestion: String
    public let explanation: String
}

public struct StyleIssue: Identifiable {
    public let id = UUID()
    public let original: String
    public let suggestion: String
    public let reason: String
    public let severity: IssueSeverity
    
    public enum IssueSeverity: String {
        case high = "high"
        case medium = "medium"
        case low = "low"
    }
}

public struct LogicIssue: Identifiable {
    public let id = UUID()
    public let description: String
    public let suggestion: String
}

// MARK: - 寫作 AI 領域 (演算法版)

@available(macOS 26.0, *)
@MainActor
public class WritingAIDomain {
    
    private let toneAdjuster = ToneAdjuster.shared
    private let expander = ContentExpander.shared
    private let simplifier = ContentSimplifier.shared
    
    init() {}
    
    public func getSuggestions(for text: String, options: WritingOptions = WritingOptions()) async throws -> WritingSuggestions {
        var styleIssues: [StyleIssue] = []
        var grammarIssues: [GrammarIssue] = []
        let logicIssues: [LogicIssue] = []
        
        if options.checkStyle || options.academicMode {
            let suggestions = toneAdjuster.checkStyle(text: text)
            for (_, original, suggestion) in suggestions {
                styleIssues.append(StyleIssue(original: original, suggestion: suggestion, reason: "非學術慣用語", severity: .medium))
            }
        }
        
        if options.checkGrammar && options.language == .traditionalChinese {
            if text.contains(",") { grammarIssues.append(GrammarIssue(original: ",", suggestion: "，", explanation: "建議使用全形標點")) }
        }
        
        let overallFeedback = styleIssues.isEmpty && grammarIssues.isEmpty ? "寫作風格良好" : "建議進行部分修改以符合學術規範"
        return WritingSuggestions(grammarIssues: grammarIssues, styleIssues: styleIssues, logicIssues: logicIssues, overallFeedback: overallFeedback)
    }
    
    public func checkAcademicStyle(text: String) async throws -> [StyleIssue] {
        let suggestions = toneAdjuster.checkStyle(text: text)
        return suggestions.map { (_, original, suggestion) in
            StyleIssue(original: original, suggestion: suggestion, reason: "非學術慣用語", severity: .medium)
        }
    }
    
    public func rewrite(text: String, style: RewriteStyle) async throws -> String {
        switch style {
        case .academic, .formal: return toneAdjuster.rewriteToAcademic(text: text)
        case .concise: return simplifier.simplify(text)
        case .elaborate: return expander.expand(text: text)
        case .neutral: return toneAdjuster.rewriteToAcademic(text: text)
        }
    }
    
    public func condense(text: String, targetRatio: Double = 0.7) async throws -> String {
        return simplifier.simplify(text)
    }
}

// MARK: - Algorithm Services

public class ToneAdjuster {
    public static let shared = ToneAdjuster()
    private let colloquialToAcademic: [String: String] = [
        "我認為": "本研究認為 / 研究者認為", "覺得": "認為", "我們發現": "研究結果顯示", "很明顯": "顯然 / 由此可見", "大家都知道": "眾所周知", "好處": "優勢", "壞處": "劣勢", "差不多": "近似", "越來越多": "日益增加", "非常": "極為", "因為": "由於", "所以": "因此", "但是": "然而"
    ]
    
    public func checkStyle(text: String) -> [(NSRange, String, String)] {
        var suggestions: [(NSRange, String, String)] = []
        let nsText = text as NSString
        for (colloquial, academic) in colloquialToAcademic {
            var searchRange = NSRange(location: 0, length: nsText.length)
            while searchRange.location < nsText.length {
                let range = nsText.range(of: colloquial, options: [], range: searchRange)
                if range.location == NSNotFound { break }
                suggestions.append((range, colloquial, academic))
                searchRange.location = range.location + range.length
                searchRange.length = nsText.length - searchRange.location
            }
        }
        return suggestions.sorted { $0.0.location < $1.0.location }
    }
    
    public func rewriteToAcademic(text: String) -> String {
        var result = text
        for (colloquial, academic) in colloquialToAcademic {
            let preferred = academic.components(separatedBy: " / ").first ?? academic
            result = result.replacingOccurrences(of: colloquial, with: preferred)
        }
        return result
    }
}

public class ContentExpander {
    public static let shared = ContentExpander()
    public enum SentenceType { case argument, evidence, conclusion, neutral }
    private let templates: [SentenceType: [String]] = [
        .argument: ["根據現有研究，XXX。", "本研究認為，XXX。", "值得注意的是，XXX。"],
        .evidence: ["研究顯示，XXX。", "相關研究指出，XXX。", "正如文獻所述，XXX。"],
        .conclusion: ["總結來說，XXX。", "因此，XXX。", "綜上所述，XXX。"]
    ]
    
    public func expand(text: String, type: SentenceType? = nil) -> String {
        let detectedType = type ?? detectType(text)
        guard detectedType != .neutral, let options = templates[detectedType], !options.isEmpty else { return text }
        let template = options.first!
        var cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.hasSuffix("。") || cleanText.hasSuffix(".") { cleanText = String(cleanText.dropLast()) }
        return template.replacingOccurrences(of: "XXX", with: cleanText) + "。"
    }
    
    private func detectType(_ text: String) -> SentenceType {
        if text.contains("因為") || text.contains("數據") { return .evidence }
        if text.contains("所以") || text.contains("總之") { return .conclusion }
        if text.contains("認為") || text.contains("主張") { return .argument }
        return .neutral
    }
}

public class ContentSimplifier {
    public static let shared = ContentSimplifier()
    private let redundantPhrases: [String: String] = [
        "非常重要": "重要", "可以說是": "為", "進行研究": "研究", "做出決定": "決定", "涉及到": "涉及", "用來": "以", "之中的": "的", "為了要": "為", "若是以": "若"
    ]
    
    public func simplify(_ text: String) -> String {
        var result = text
        for (phrase, replacement) in redundantPhrases {
           result = result.replacingOccurrences(of: phrase, with: replacement)
        }
        return result
    }
}
