//
//  SectionDetector.swift
//  OVEREND
//
//  章節偵測服務 - 自動辨識當前寫作位置
//
//  根據文件內容分析當前章節類型：
//  - 摘要、緒論、文獻回顧、研究方法等
//  - 提供對應的寫作建議上下文
//

import Foundation
import SwiftUI
import Combine

// MARK: - 學術論文章節類型

/// 學術論文章節類型
public enum AcademicSection: String, CaseIterable, Identifiable {
    case abstract = "摘要"
    case introduction = "緒論"
    case literature = "文獻回顧"
    case methodology = "研究方法"
    case results = "研究結果"
    case discussion = "討論"
    case conclusion = "結論"
    case references = "參考文獻"
    case appendix = "附錄"
    case unknown = "未知"
    
    public var id: String { rawValue }
    
    /// 章節圖標
    public var icon: String {
        switch self {
        case .abstract: return "doc.text"
        case .introduction: return "flag"
        case .literature: return "books.vertical"
        case .methodology: return "gearshape.2"
        case .results: return "chart.bar"
        case .discussion: return "bubble.left.and.bubble.right"
        case .conclusion: return "checkmark.seal"
        case .references: return "bookmark"
        case .appendix: return "doc.append"
        case .unknown: return "questionmark.circle"
        }
    }
    
    /// 常見的章節標題關鍵字
    public var keywords: [String] {
        switch self {
        case .abstract:
            return ["摘要", "abstract", "概要", "summary"]
        case .introduction:
            return ["緒論", "introduction", "前言", "引言", "研究背景", "background"]
        case .literature:
            return ["文獻回顧", "文獻探討", "literature review", "相關研究", "理論基礎"]
        case .methodology:
            return ["研究方法", "methodology", "methods", "研究設計", "資料收集"]
        case .results:
            return ["研究結果", "results", "findings", "資料分析", "研究發現"]
        case .discussion:
            return ["討論", "discussion", "研究討論", "結果討論"]
        case .conclusion:
            return ["結論", "conclusion", "建議", "研究限制", "未來研究"]
        case .references:
            return ["參考文獻", "references", "bibliography", "引用文獻"]
        case .appendix:
            return ["附錄", "appendix", "supplementary"]
        case .unknown:
            return []
        }
    }
    
    /// 寫作建議提示
    public var writingHints: [String] {
        switch self {
        case .abstract:
            return [
                "摘要應包含：研究目的、方法、主要發現、結論",
                "字數通常控制在 300-500 字",
                "使用獨立段落，避免引用其他章節"
            ]
        case .introduction:
            return [
                "明確陳述研究問題與目的",
                "說明研究的重要性與貢獻",
                "簡要預覽研究架構"
            ]
        case .literature:
            return [
                "按主題或時間順序組織文獻",
                "批判性地評述現有研究",
                "指出研究缺口，連結到你的研究"
            ]
        case .methodology:
            return [
                "詳細描述研究設計與方法",
                "說明資料收集與分析程序",
                "討論研究倫理與限制"
            ]
        case .results:
            return [
                "客觀呈現研究發現，不做詮釋",
                "使用表格與圖表輔助說明",
                "按研究問題順序報告結果"
            ]
        case .discussion:
            return [
                "詮釋研究結果的意義",
                "與先前研究進行比較",
                "討論研究的理論與實務意涵"
            ]
        case .conclusion:
            return [
                "總結主要研究發現",
                "說明研究貢獻與限制",
                "提出未來研究建議"
            ]
        case .references:
            return [
                "確保格式一致（APA/MLA）",
                "檢查內文引用是否都有對應文獻",
                "依格式要求排序"
            ]
        case .appendix:
            return [
                "附錄應編號並有標題",
                "在內文提及附錄位置",
                "適合放問卷、詳細數據等"
            ]
        case .unknown:
            return [
                "請問您目前在寫什麼內容？",
                "我可以根據您的寫作內容提供建議"
            ]
        }
    }
}

// MARK: - 章節偵測結果

/// 章節偵測結果
public struct SectionDetectionResult {
    /// 偵測到的章節類型
    public let section: AcademicSection
    
    /// 偵測信心度 (0.0 - 1.0)
    public let confidence: Double
    
    /// 相關的上下文文字
    public let contextText: String
    
    /// 游標所在行號
    public let cursorLine: Int
    
    /// 建議的寫作提示
    public var hints: [String] {
        section.writingHints
    }
}

// MARK: - 章節偵測服務

/// 章節偵測服務
/// 
/// 分析編輯器內容，自動辨識當前寫作章節
/// 
/// 使用方式：
/// ```swift
/// let detector = SectionDetector.shared
/// let result = detector.detectSection(
///     text: documentText,
///     cursorPosition: 1500
/// )
/// print("目前章節：\(result.section.rawValue)")
/// ```
@MainActor
public class SectionDetector: ObservableObject {
    
    // MARK: - 單例
    
    public static let shared = SectionDetector()
    
    // MARK: - 發布屬性
    
    /// 當前偵測到的章節
    @Published public var currentSection: AcademicSection = .unknown
    
    /// 偵測信心度
    @Published public var confidence: Double = 0.0
    
    // MARK: - 初始化
    
    private init() {
        AppLogger.shared.notice("📍 SectionDetector: 初始化完成")
    }
    
    // MARK: - 章節偵測
    
    /// 根據文字內容與游標位置偵測章節
    /// - Parameters:
    ///   - text: 完整文件文字
    ///   - cursorPosition: 游標位置（字元索引）
    /// - Returns: 偵測結果
    public func detectSection(text: String, cursorPosition: Int) -> SectionDetectionResult {
        // 尋找游標附近的標題
        let lines = text.components(separatedBy: .newlines)
        var currentLineIndex = 0
        var characterCount = 0
        
        // 找到游標所在行
        for (index, line) in lines.enumerated() {
            characterCount += line.count + 1 // +1 for newline
            if characterCount >= cursorPosition {
                currentLineIndex = index
                break
            }
        }
        
        // 向上搜尋最近的標題
        var detectedSection: AcademicSection = .unknown
        var detectedConfidence: Double = 0.0
        var contextText = ""
        
        for i in stride(from: currentLineIndex, through: 0, by: -1) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            // 檢查是否為標題（可能以數字、「第X章」開頭，或全大寫）
            if let section = matchSectionByKeywords(line) {
                detectedSection = section
                detectedConfidence = calculateConfidence(line: line, section: section)
                contextText = line
                break
            }
        }
        
        // 更新發布屬性
        currentSection = detectedSection
        confidence = detectedConfidence
        
        return SectionDetectionResult(
            section: detectedSection,
            confidence: detectedConfidence,
            contextText: contextText,
            cursorLine: currentLineIndex
        )
    }
    
    /// 根據純文字標題偵測章節（不需游標位置）
    /// - Parameter title: 標題文字
    /// - Returns: 偵測到的章節，若無法辨識則為 .unknown
    public func detectSectionByTitle(_ title: String) -> AcademicSection {
        return matchSectionByKeywords(title) ?? .unknown
    }
    
    // MARK: - 私有方法
    
    /// 根據關鍵字匹配章節類型
    private func matchSectionByKeywords(_ text: String) -> AcademicSection? {
        let lowercased = text.lowercased()
        
        for section in AcademicSection.allCases where section != .unknown {
            for keyword in section.keywords {
                if lowercased.contains(keyword.lowercased()) {
                    return section
                }
            }
        }
        
        return nil
    }
    
    /// 計算偵測信心度
    private func calculateConfidence(line: String, section: AcademicSection) -> Double {
        var score: Double = 0.5
        
        // 如果標題完全匹配（如「第一章 緒論」）
        if section.keywords.contains(where: { line.lowercased().contains($0.lowercased()) }) {
            score += 0.3
        }
        
        // 如果有章節編號（如「1.」「第一章」）
        if line.range(of: "^\\d+\\.", options: .regularExpression) != nil ||
           line.contains("第") && (line.contains("章") || line.contains("節")) {
            score += 0.2
        }
        
        return min(score, 1.0)
    }
}
