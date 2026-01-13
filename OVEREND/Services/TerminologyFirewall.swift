//
//  TerminologyFirewall.swift
//  OVEREND
//
//  術語防火牆 - 繁簡學術詞彙自動校正服務
//
//  功能：
//  - 自動偵測並校正簡體中文學術用語
//  - 上下文敏感替換（根據學科領域判斷）
//  - 作為 AI 翻譯輸出的後處理器
//

import Foundation
import Combine

// MARK: - 替換動作

/// 術語替換動作類型
enum TerminologyAction: String, Codable {
    case forceReplace = "force"       // 強制替換（任何情況都替換）
    case contextual = "contextual"    // 上下文判斷（根據學科領域決定）
    case suggest = "suggest"          // 建議替換（標記但不自動替換）
}

// MARK: - 上下文類型

/// 術語使用的上下文類型
enum TerminologyContext: String, Codable, CaseIterable {
    case general = "general"              // 通用
    case informationTechnology = "it"     // 資訊科技
    case physics = "physics"              // 物理學
    case management = "management"        // 管理學
    case engineering = "engineering"      // 工程學
    case medicine = "medicine"            // 醫學
    case law = "law"                      // 法律
    case education = "education"          // 教育學
    
    var displayName: String {
        switch self {
        case .general: return "通用"
        case .informationTechnology: return "資訊科技"
        case .physics: return "物理學"
        case .management: return "管理學"
        case .engineering: return "工程學"
        case .medicine: return "醫學"
        case .law: return "法律"
        case .education: return "教育學"
        }
    }
}

// MARK: - 術語規則

/// 術語替換規則
struct TerminologyRule: Identifiable, Codable {
    let id: UUID
    let simplified: String           // 簡體/大陸用語（需避免）
    let traditional: String          // 繁體/台灣用語（偏好）
    let context: TerminologyContext  // 適用上下文
    let action: TerminologyAction    // 替換動作
    let notes: String?               // 備註說明
    
    init(
        simplified: String,
        traditional: String,
        context: TerminologyContext = .general,
        action: TerminologyAction = .forceReplace,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.simplified = simplified
        self.traditional = traditional
        self.context = context
        self.action = action
        self.notes = notes
    }
}

// MARK: - 校正結果

/// 術語校正項目
struct TerminologyCorrection: Identifiable {
    let id: UUID
    let original: String             // 原始詞彙
    let corrected: String            // 校正後詞彙
    let range: Range<String.Index>   // 在原文中的位置
    let rule: TerminologyRule        // 適用的規則
    let wasApplied: Bool             // 是否已套用
    
    init(original: String, corrected: String, range: Range<String.Index>, rule: TerminologyRule, wasApplied: Bool) {
        self.id = UUID()
        self.original = original
        self.corrected = corrected
        self.range = range
        self.rule = rule
        self.wasApplied = wasApplied
    }
}

/// 術語校正結果
struct TerminologyResult {
    let originalText: String         // 原始文字
    let correctedText: String        // 校正後文字
    let corrections: [TerminologyCorrection]  // 校正項目列表
    let processedAt: Date            // 處理時間
    
    /// 校正數量
    var correctionCount: Int {
        corrections.filter { $0.wasApplied }.count
    }
    
    /// 建議數量（未自動套用的）
    var suggestionCount: Int {
        corrections.filter { !$0.wasApplied }.count
    }
    
    /// 是否有任何校正
    var hasCorrections: Bool {
        !corrections.isEmpty
    }
}

// MARK: - 術語防火牆服務

/// 術語防火牆 - 繁簡學術詞彙自動校正
@MainActor
class TerminologyFirewall: ObservableObject {
    
    // MARK: - 單例
    
    static let shared = TerminologyFirewall()
    
    // MARK: - 狀態
    
    @Published var isProcessing: Bool = false
    @Published var lastResult: TerminologyResult?
    
    // MARK: - 規則庫
    
    /// 內建術語規則庫
    private(set) var rules: [TerminologyRule] = []
    
    // MARK: - 初始化
    
    private init() {
        loadBuiltInRules()
    }
    
    // MARK: - 核心處理方法
    
    /// 處理文字，進行術語校正
    /// - Parameters:
    ///   - text: 待處理的文字
    ///   - field: 學術領域（用於上下文判斷）
    /// - Returns: 校正結果
    func process(_ text: String, field: AcademicField? = nil) -> TerminologyResult {
        guard !text.isEmpty else {
            return TerminologyResult(
                originalText: text,
                correctedText: text,
                corrections: [],
                processedAt: Date()
            )
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        var processedText = text
        var corrections: [TerminologyCorrection] = []
        
        // 將 AcademicField 映射到 TerminologyContext
        let context = mapFieldToContext(field)
        
        // 遍歷所有規則
        for rule in rules {
            // 檢查規則是否適用於當前上下文
            let shouldApply = shouldApplyRule(rule, context: context, text: processedText)
            
            if shouldApply {
                // 尋找所有匹配項
                let matches = findMatches(for: rule.simplified, in: processedText)
                
                for match in matches.reversed() {  // 從後往前替換，避免位置偏移
                    let correction = TerminologyCorrection(
                        original: rule.simplified,
                        corrected: rule.traditional,
                        range: match,
                        rule: rule,
                        wasApplied: rule.action != .suggest
                    )
                    corrections.append(correction)
                    
                    // 執行替換（除非是建議模式）
                    if rule.action != .suggest {
                        processedText.replaceSubrange(match, with: rule.traditional)
                    }
                }
            }
        }
        
        let result = TerminologyResult(
            originalText: text,
            correctedText: processedText,
            corrections: corrections.reversed(),  // 恢復正向順序
            processedAt: Date()
        )
        
        lastResult = result
        return result
    }
    
    /// 快速校正（只回傳校正後文字）
    func quickCorrect(_ text: String, field: AcademicField? = nil) -> String {
        return process(text, field: field).correctedText
    }
    
    /// 檢查文字是否包含需要校正的術語
    func check(_ text: String) -> Bool {
        for rule in rules {
            if text.contains(rule.simplified) {
                return true
            }
        }
        return false
    }
    
    // MARK: - 輔助方法
    
    /// 將 AcademicField 映射到 TerminologyContext
    private func mapFieldToContext(_ field: AcademicField?) -> TerminologyContext {
        guard let field = field else { return .general }
        
        switch field {
        case .engineering:
            return .engineering
        case .naturalSciences:
            return .physics
        case .business:
            return .management
        case .medicine:
            return .medicine
        case .law:
            return .law
        case .education:
            return .education
        default:
            return .general
        }
    }
    
    /// 判斷規則是否應該套用
    private func shouldApplyRule(_ rule: TerminologyRule, context: TerminologyContext, text: String) -> Bool {
        // 通用規則總是適用
        if rule.context == .general {
            return true
        }
        
        // 上下文匹配時適用
        if rule.context == context {
            return true
        }
        
        // 特殊處理：「質量」在物理學上下文保留，其他替換為「品質」
        if rule.simplified == "質量" && context == .physics {
            return false  // 物理學中不替換「質量」
        }
        
        return rule.context == .general
    }
    
    /// 尋找所有匹配項的位置
    private func findMatches(for term: String, in text: String) -> [Range<String.Index>] {
        var matches: [Range<String.Index>] = []
        var searchRange = text.startIndex..<text.endIndex
        
        while let range = text.range(of: term, range: searchRange) {
            matches.append(range)
            searchRange = range.upperBound..<text.endIndex
        }
        
        return matches
    }
    
    // MARK: - 規則庫載入
    
    /// 載入內建規則
    private func loadBuiltInRules() {
        rules = [
            // ========================
            // 資訊科技領域
            // ========================
            TerminologyRule(
                simplified: "軟件",
                traditional: "軟體",
                context: .general,
                action: .forceReplace,
                notes: "Software"
            ),
            TerminologyRule(
                simplified: "硬件",
                traditional: "硬體",
                context: .general,
                action: .forceReplace,
                notes: "Hardware"
            ),
            TerminologyRule(
                simplified: "信息",
                traditional: "資訊",
                context: .general,
                action: .forceReplace,
                notes: "Information"
            ),
            TerminologyRule(
                simplified: "互聯網",
                traditional: "網際網路",
                context: .general,
                action: .forceReplace,
                notes: "Internet"
            ),
            TerminologyRule(
                simplified: "視頻",
                traditional: "影片",
                context: .general,
                action: .forceReplace,
                notes: "Video"
            ),
            TerminologyRule(
                simplified: "音頻",
                traditional: "音訊",
                context: .general,
                action: .forceReplace,
                notes: "Audio"
            ),
            TerminologyRule(
                simplified: "鏈接",
                traditional: "連結",
                context: .general,
                action: .forceReplace,
                notes: "Link"
            ),
            TerminologyRule(
                simplified: "服務器",
                traditional: "伺服器",
                context: .general,
                action: .forceReplace,
                notes: "Server"
            ),
            TerminologyRule(
                simplified: "數據庫",
                traditional: "資料庫",
                context: .general,
                action: .forceReplace,
                notes: "Database"
            ),
            TerminologyRule(
                simplified: "數據",
                traditional: "資料",
                context: .general,
                action: .forceReplace,
                notes: "Data"
            ),
            TerminologyRule(
                simplified: "文檔",
                traditional: "文件",
                context: .general,
                action: .forceReplace,
                notes: "Document/File"
            ),
            TerminologyRule(
                simplified: "程序",
                traditional: "程式",
                context: .informationTechnology,
                action: .forceReplace,
                notes: "Program"
            ),
            TerminologyRule(
                simplified: "字節",
                traditional: "位元組",
                context: .informationTechnology,
                action: .forceReplace,
                notes: "Byte"
            ),
            TerminologyRule(
                simplified: "代碼",
                traditional: "程式碼",
                context: .informationTechnology,
                action: .forceReplace,
                notes: "Code"
            ),
            TerminologyRule(
                simplified: "網絡",
                traditional: "網路",
                context: .general,
                action: .forceReplace,
                notes: "Network"
            ),
            TerminologyRule(
                simplified: "默認",
                traditional: "預設",
                context: .general,
                action: .forceReplace,
                notes: "Default"
            ),
            TerminologyRule(
                simplified: "用戶",
                traditional: "使用者",
                context: .general,
                action: .forceReplace,
                notes: "User"
            ),
            TerminologyRule(
                simplified: "接口",
                traditional: "介面",
                context: .informationTechnology,
                action: .forceReplace,
                notes: "Interface"
            ),
            TerminologyRule(
                simplified: "兼容",
                traditional: "相容",
                context: .general,
                action: .forceReplace,
                notes: "Compatible"
            ),
            TerminologyRule(
                simplified: "優化",
                traditional: "最佳化",
                context: .general,
                action: .suggest,
                notes: "Optimize - 兩者皆可接受"
            ),
            
            // ========================
            // 學術通用詞彙
            // ========================
            TerminologyRule(
                simplified: "通過",
                traditional: "透過",
                context: .general,
                action: .forceReplace,
                notes: "Through/Via (作為介系詞時)"
            ),
            TerminologyRule(
                simplified: "項目",
                traditional: "專案",
                context: .management,
                action: .forceReplace,
                notes: "Project"
            ),
            TerminologyRule(
                simplified: "質量",
                traditional: "品質",
                context: .management,
                action: .contextual,
                notes: "Quality (管理學) / Mass (物理學保留)"
            ),
            TerminologyRule(
                simplified: "水平",
                traditional: "水準",
                context: .general,
                action: .forceReplace,
                notes: "Level/Standard"
            ),
            TerminologyRule(
                simplified: "支持",
                traditional: "支援",
                context: .general,
                action: .forceReplace,
                notes: "Support"
            ),
            TerminologyRule(
                simplified: "進行",
                traditional: "進行",
                context: .general,
                action: .suggest,
                notes: "建議改為更具體動詞"
            ),
            TerminologyRule(
                simplified: "采用",
                traditional: "採用",
                context: .general,
                action: .forceReplace,
                notes: "Adopt"
            ),
            TerminologyRule(
                simplified: "并且",
                traditional: "並且",
                context: .general,
                action: .forceReplace,
                notes: "And"
            ),
            TerminologyRule(
                simplified: "針對",
                traditional: "針對",
                context: .general,
                action: .suggest,
                notes: "兩岸用法相同，無需替換"
            ),
            TerminologyRule(
                simplified: "后",
                traditional: "後",
                context: .general,
                action: .forceReplace,
                notes: "After/Behind"
            ),
            TerminologyRule(
                simplified: "里",
                traditional: "裡",
                context: .general,
                action: .forceReplace,
                notes: "Inside (位置詞)"
            ),
            TerminologyRule(
                simplified: "于",
                traditional: "於",
                context: .general,
                action: .forceReplace,
                notes: "At/In/To"
            ),
            
            // ========================
            // 學術寫作專用
            // ========================
            TerminologyRule(
                simplified: "分析",
                traditional: "分析",
                context: .general,
                action: .suggest,
                notes: "兩岸用法相同"
            ),
            TerminologyRule(
                simplified: "研究表明",
                traditional: "研究顯示",
                context: .general,
                action: .forceReplace,
                notes: "Research shows"
            ),
            TerminologyRule(
                simplified: "結果表明",
                traditional: "結果顯示",
                context: .general,
                action: .forceReplace,
                notes: "Results show"
            ),
            TerminologyRule(
                simplified: "魯棒性",
                traditional: "強健性",
                context: .general,
                action: .forceReplace,
                notes: "Robustness"
            ),
            TerminologyRule(
                simplified: "概率",
                traditional: "機率",
                context: .general,
                action: .forceReplace,
                notes: "Probability"
            ),
            TerminologyRule(
                simplified: "隨機",
                traditional: "隨機",
                context: .general,
                action: .suggest,
                notes: "Random - 兩岸用法相同"
            ),
            TerminologyRule(
                simplified: "偏差",
                traditional: "偏差",
                context: .general,
                action: .suggest,
                notes: "Bias/Deviation - 兩岸用法相同"
            ),
            
            // ========================
            // 工程與科技
            // ========================
            TerminologyRule(
                simplified: "激光",
                traditional: "雷射",
                context: .engineering,
                action: .forceReplace,
                notes: "Laser"
            ),
            TerminologyRule(
                simplified: "芯片",
                traditional: "晶片",
                context: .engineering,
                action: .forceReplace,
                notes: "Chip"
            ),
            TerminologyRule(
                simplified: "打印",
                traditional: "列印",
                context: .general,
                action: .forceReplace,
                notes: "Print"
            ),
            TerminologyRule(
                simplified: "掃描",
                traditional: "掃描",
                context: .general,
                action: .suggest,
                notes: "Scan - 兩岸用法相同"
            ),
            TerminologyRule(
                simplified: "人工智能",
                traditional: "人工智慧",
                context: .general,
                action: .forceReplace,
                notes: "Artificial Intelligence"
            ),
            TerminologyRule(
                simplified: "機器學習",
                traditional: "機器學習",
                context: .general,
                action: .suggest,
                notes: "Machine Learning - 兩岸用法相同"
            ),
            TerminologyRule(
                simplified: "深度學習",
                traditional: "深度學習",
                context: .general,
                action: .suggest,
                notes: "Deep Learning - 兩岸用法相同"
            ),
            
            // ========================
            // 商業與管理
            // ========================
            TerminologyRule(
                simplified: "營銷",
                traditional: "行銷",
                context: .management,
                action: .forceReplace,
                notes: "Marketing"
            ),
            TerminologyRule(
                simplified: "企業",
                traditional: "企業",
                context: .general,
                action: .suggest,
                notes: "Enterprise - 兩岸用法相同"
            ),
            TerminologyRule(
                simplified: "博客",
                traditional: "部落格",
                context: .general,
                action: .forceReplace,
                notes: "Blog"
            ),
            
            // ========================
            // 標點符號修正
            // ========================
            TerminologyRule(
                simplified: "、",
                traditional: "、",
                context: .general,
                action: .suggest,
                notes: "頓號 - 兩岸相同"
            )
        ]
        
        AppLogger.success("📚 TerminologyFirewall: 載入 \(rules.count) 條術語規則")
    }
    
    // MARK: - 規則管理
    
    /// 新增自訂規則
    func addCustomRule(_ rule: TerminologyRule) {
        rules.append(rule)
    }
    
    /// 移除規則
    func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
    }
    
    /// 取得特定上下文的規則
    func rules(for context: TerminologyContext) -> [TerminologyRule] {
        return rules.filter { $0.context == context || $0.context == .general }
    }
    
    /// 統計資訊
    var statistics: (total: Int, forceReplace: Int, contextual: Int, suggest: Int) {
        let force = rules.filter { $0.action == .forceReplace }.count
        let contextual = rules.filter { $0.action == .contextual }.count
        let suggest = rules.filter { $0.action == .suggest }.count
        return (rules.count, force, contextual, suggest)
    }
}

// MARK: - 便捷擴展

extension String {
    /// 套用術語防火牆校正
    @MainActor
    func applyTerminologyFirewall(field: AcademicField? = nil) -> String {
        return TerminologyFirewall.shared.quickCorrect(self, field: field)
    }
}
