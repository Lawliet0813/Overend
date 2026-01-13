//
//  AcademicPhrasebank.swift
//  OVEREND
//
//  學術語料庫 - 提供繁體中文學術寫作句型建議
//
//  參考來源：
//  - 國立臺灣大學寫作教學中心 (NTU AWEC)
//  - 香港大學學術寫作資源
//  - 教育部學術論文寫作規範
//

import Foundation
import SwiftUI
import Combine

// MARK: - 語料庫分類

/// 學術寫作段落分類
enum PhraseCategory: String, CaseIterable, Identifiable {
    case introduction = "introduction"          // 緒論/引言
    case literatureReview = "literature_review" // 文獻回顧
    case methodology = "methodology"            // 研究方法
    case results = "results"                    // 結果呈現
    case discussion = "discussion"              // 討論
    case conclusion = "conclusion"              // 結論
    case transition = "transition"              // 過渡連接
    case citation = "citation"                  // 引用表達
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .introduction: return "緒論/引言"
        case .literatureReview: return "文獻回顧"
        case .methodology: return "研究方法"
        case .results: return "結果呈現"
        case .discussion: return "討論"
        case .conclusion: return "結論"
        case .transition: return "過渡連接"
        case .citation: return "引用表達"
        }
    }
    
    var icon: String {
        switch self {
        case .introduction: return "text.book.closed"
        case .literatureReview: return "books.vertical"
        case .methodology: return "gearshape.2"
        case .results: return "chart.bar"
        case .discussion: return "bubble.left.and.bubble.right"
        case .conclusion: return "checkmark.seal"
        case .transition: return "arrow.right"
        case .citation: return "quote.bubble"
        }
    }
    
    var description: String {
        switch self {
        case .introduction:
            return "用於介紹研究背景、目的與重要性"
        case .literatureReview:
            return "用於回顧與評述相關研究文獻"
        case .methodology:
            return "用於描述研究設計、方法與程序"
        case .results:
            return "用於呈現研究發現與數據"
        case .discussion:
            return "用於詮釋結果並與文獻對話"
        case .conclusion:
            return "用於總結研究並提出建議"
        case .transition:
            return "用於段落間的邏輯銜接"
        case .citation:
            return "用於正確引用他人研究成果"
        }
    }
}

// MARK: - 學術句型

/// 學術句型結構
struct AcademicPhrase: Identifiable, Codable {
    let id: UUID
    let chinese: String              // 繁體中文句型
    let english: String?             // 英文對照
    let category: String             // 分類 rawValue
    let variables: [String]          // 可替換變數 (e.g., "{{主題}}", "{{作者}}")
    let example: String?             // 使用範例
    let notes: String?               // 使用說明
    let formalityLevel: Int          // 正式程度 (1-3, 3 最正式)
    
    /// 分類物件
    var phraseCategory: PhraseCategory {
        PhraseCategory(rawValue: category) ?? .introduction
    }
    
    /// 是否含有可替換變數
    var hasVariables: Bool {
        !variables.isEmpty
    }
    
    /// 初始化
    init(
        chinese: String,
        english: String? = nil,
        category: PhraseCategory,
        variables: [String] = [],
        example: String? = nil,
        notes: String? = nil,
        formalityLevel: Int = 3
    ) {
        self.id = UUID()
        self.chinese = chinese
        self.english = english
        self.category = category.rawValue
        self.variables = variables
        self.example = example
        self.notes = notes
        self.formalityLevel = formalityLevel
    }
    
    /// 替換變數
    func fillVariables(_ values: [String: String]) -> String {
        var result = chinese
        for (variable, value) in values {
            result = result.replacingOccurrences(of: "{{\(variable)}}", with: value)
        }
        return result
    }
}

// MARK: - 學術語料庫服務

/// 學術語料庫服務
@MainActor
class AcademicPhrasebank: ObservableObject {
    
    // MARK: - 單例
    
    static let shared = AcademicPhrasebank()
    
    // MARK: - 狀態
    
    @Published var isLoading: Bool = false
    @Published var searchQuery: String = ""
    @Published var selectedCategory: PhraseCategory?
    
    // MARK: - 資料
    
    /// 所有句型
    private(set) var allPhrases: [AcademicPhrase] = []
    
    /// 依分類索引
    private var phrasesByCategory: [PhraseCategory: [AcademicPhrase]] = [:]
    
    // MARK: - 初始化
    
    private init() {
        loadBuiltInPhrases()
        buildCategoryIndex()
    }
    
    // MARK: - 查詢方法
    
    /// 搜尋句型
    func search(query: String) -> [AcademicPhrase] {
        guard !query.isEmpty else { return allPhrases }
        
        let lowercaseQuery = query.lowercased()
        return allPhrases.filter { phrase in
            phrase.chinese.lowercased().contains(lowercaseQuery) ||
            (phrase.english?.lowercased().contains(lowercaseQuery) ?? false) ||
            (phrase.example?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }
    
    /// 依分類取得句型
    func byCategory(_ category: PhraseCategory) -> [AcademicPhrase] {
        return phrasesByCategory[category] ?? []
    }
    
    /// 取得所有分類及其句型數量
    var categoryCounts: [(category: PhraseCategory, count: Int)] {
        PhraseCategory.allCases.map { category in
            (category, phrasesByCategory[category]?.count ?? 0)
        }
    }
    
    /// 隨機取得句型建議
    func randomSuggestions(count: Int = 5) -> [AcademicPhrase] {
        return Array(allPhrases.shuffled().prefix(count))
    }
    
    // MARK: - AI 智慧建議
    
    /// 根據上下文推薦句型
    /// - Parameter context: 當前編輯的文字內容
    /// - Returns: 推薦的句型列表
    @available(macOS 26.0, *)
    func suggest(for context: String) async -> [AcademicPhrase] {
        // 簡單的關鍵字匹配（可擴展為 AI 推薦）
        var suggestions: [AcademicPhrase] = []
        
        // 分析上下文判斷可能的段落類型
        let introKeywords = ["背景", "目的", "研究", "探討", "旨在"]
        let methodKeywords = ["方法", "樣本", "資料", "分析", "問卷", "訪談"]
        let resultKeywords = ["結果", "發現", "顯示", "表明", "數據"]
        let conclusionKeywords = ["綜上", "結論", "總結", "未來", "建議"]
        
        // 判斷上下文類型
        var detectedCategory: PhraseCategory?
        
        if introKeywords.contains(where: { context.contains($0) }) {
            detectedCategory = .introduction
        } else if methodKeywords.contains(where: { context.contains($0) }) {
            detectedCategory = .methodology
        } else if resultKeywords.contains(where: { context.contains($0) }) {
            detectedCategory = .results
        } else if conclusionKeywords.contains(where: { context.contains($0) }) {
            detectedCategory = .conclusion
        }
        
        // 取得相關分類的句型
        if let category = detectedCategory {
            suggestions = Array(byCategory(category).prefix(5))
        } else {
            // 無法判斷時，提供通用過渡句型
            suggestions = Array(byCategory(.transition).prefix(3))
        }
        
        return suggestions
    }
    
    // MARK: - 私有方法
    
    /// 建立分類索引
    private func buildCategoryIndex() {
        phrasesByCategory = Dictionary(grouping: allPhrases) { phrase in
            phrase.phraseCategory
        }
    }
    
    /// 載入內建句型庫
    private func loadBuiltInPhrases() {
        allPhrases = [
            // ========================
            // 緒論/引言
            // ========================
            AcademicPhrase(
                chinese: "本研究旨在探討{{主題}}。",
                english: "This study aims to investigate {{topic}}.",
                category: .introduction,
                variables: ["主題"],
                example: "本研究旨在探討社群媒體對青少年心理健康的影響。"
            ),
            AcademicPhrase(
                chinese: "近年來，關於{{主題}}的議題備受關注。",
                english: "In recent years, the issue of {{topic}} has received considerable attention.",
                category: .introduction,
                variables: ["主題"],
                example: "近年來，關於人工智慧倫理的議題備受關注。"
            ),
            AcademicPhrase(
                chinese: "隨著{{趨勢}}的發展，{{現象}}逐漸成為學界關注的焦點。",
                english: "With the development of {{trend}}, {{phenomenon}} has gradually become a focus of academic attention.",
                category: .introduction,
                variables: ["趨勢", "現象"]
            ),
            AcademicPhrase(
                chinese: "儘管{{領域}}已有豐富的研究成果，但關於{{議題}}的探討仍相當有限。",
                english: "Despite extensive research in {{field}}, exploration of {{topic}} remains limited.",
                category: .introduction,
                variables: ["領域", "議題"]
            ),
            AcademicPhrase(
                chinese: "本文擬從{{視角}}出發，分析{{對象}}的{{特質}}。",
                english: "This paper intends to analyze the {{attribute}} of {{subject}} from the perspective of {{perspective}}.",
                category: .introduction,
                variables: ["視角", "對象", "特質"]
            ),
            AcademicPhrase(
                chinese: "有鑑於此，本研究提出以下研究問題：",
                english: "In light of this, the present study proposes the following research questions:",
                category: .introduction
            ),
            AcademicPhrase(
                chinese: "本研究的主要貢獻在於：",
                english: "The main contributions of this study are:",
                category: .introduction
            ),
            
            // ========================
            // 文獻回顧
            // ========================
            AcademicPhrase(
                chinese: "學者{{作者}}指出，{{觀點}}。",
                english: "Scholar {{author}} points out that {{viewpoint}}.",
                category: .literatureReview,
                variables: ["作者", "觀點"],
                example: "學者王建國指出，數位落差對偏鄉教育產生深遠影響。"
            ),
            AcademicPhrase(
                chinese: "根據{{作者}}（{{年份}}）的研究，{{發現}}。",
                english: "According to {{author}}'s ({{year}}) research, {{finding}}.",
                category: .literatureReview,
                variables: ["作者", "年份", "發現"]
            ),
            AcademicPhrase(
                chinese: "然而，現有研究尚未解決{{問題}}。",
                english: "However, existing studies have not yet addressed {{problem}}.",
                category: .literatureReview,
                variables: ["問題"]
            ),
            AcademicPhrase(
                chinese: "相較於{{觀點A}}，{{作者}}則主張{{觀點B}}。",
                english: "In contrast to {{viewpoint A}}, {{author}} argues for {{viewpoint B}}.",
                category: .literatureReview,
                variables: ["觀點A", "作者", "觀點B"]
            ),
            AcademicPhrase(
                chinese: "綜觀過往文獻，可歸納出以下幾個主要論點：",
                english: "Reviewing the existing literature, the following main arguments can be summarized:",
                category: .literatureReview
            ),
            AcademicPhrase(
                chinese: "承上所述，本研究將聚焦於{{焦點}}。",
                english: "Building on the above, this study will focus on {{focus}}.",
                category: .literatureReview,
                variables: ["焦點"]
            ),
            AcademicPhrase(
                chinese: "此外，{{作者}}亦提出類似觀點，認為{{觀點}}。",
                english: "Furthermore, {{author}} also proposes a similar view, arguing that {{viewpoint}}.",
                category: .literatureReview,
                variables: ["作者", "觀點"]
            ),
            
            // ========================
            // 研究方法
            // ========================
            AcademicPhrase(
                chinese: "本研究採用{{方法}}進行資料蒐集與分析。",
                english: "This study employs {{method}} for data collection and analysis.",
                category: .methodology,
                variables: ["方法"],
                example: "本研究採用半結構式訪談法進行資料蒐集與分析。"
            ),
            AcademicPhrase(
                chinese: "研究對象為{{對象}}，共計{{數量}}人。",
                english: "The research subjects are {{subjects}}, totaling {{number}} participants.",
                category: .methodology,
                variables: ["對象", "數量"]
            ),
            AcademicPhrase(
                chinese: "資料收集自{{來源}}，時間範圍為{{時間}}。",
                english: "Data were collected from {{source}}, covering the period of {{duration}}.",
                category: .methodology,
                variables: ["來源", "時間"]
            ),
            AcademicPhrase(
                chinese: "本研究使用{{工具}}進行{{分析類型}}分析。",
                english: "This study uses {{tool}} for {{analysis type}} analysis.",
                category: .methodology,
                variables: ["工具", "分析類型"]
            ),
            AcademicPhrase(
                chinese: "為確保研究信效度，本研究採取以下措施：",
                english: "To ensure research validity and reliability, this study adopts the following measures:",
                category: .methodology
            ),
            AcademicPhrase(
                chinese: "研究倫理方面，本研究已獲得{{機構}}之研究倫理審查通過。",
                english: "Regarding research ethics, this study has received approval from {{institution}}'s research ethics review.",
                category: .methodology,
                variables: ["機構"]
            ),
            
            // ========================
            // 結果呈現
            // ========================
            AcademicPhrase(
                chinese: "研究結果顯示，{{發現}}。",
                english: "The research results show that {{finding}}.",
                category: .results,
                variables: ["發現"]
            ),
            AcademicPhrase(
                chinese: "如表{{編號}}所示，{{描述}}。",
                english: "As shown in Table {{number}}, {{description}}.",
                category: .results,
                variables: ["編號", "描述"]
            ),
            AcademicPhrase(
                chinese: "從圖{{編號}}可觀察到{{現象}}。",
                english: "From Figure {{number}}, {{phenomenon}} can be observed.",
                category: .results,
                variables: ["編號", "現象"]
            ),
            AcademicPhrase(
                chinese: "統計分析結果指出，{{變項A}}與{{變項B}}呈顯著正相關（r = {{數值}}, p < {{顯著水準}}）。",
                english: "Statistical analysis indicates that {{variable A}} and {{variable B}} show a significant positive correlation (r = {{value}}, p < {{significance level}}).",
                category: .results,
                variables: ["變項A", "變項B", "數值", "顯著水準"]
            ),
            AcademicPhrase(
                chinese: "值得注意的是，{{發現}}。",
                english: "It is worth noting that {{finding}}.",
                category: .results,
                variables: ["發現"]
            ),
            AcademicPhrase(
                chinese: "整體而言，研究結果支持了研究假設{{編號}}。",
                english: "Overall, the research results support hypothesis {{number}}.",
                category: .results,
                variables: ["編號"]
            ),
            
            // ========================
            // 討論
            // ========================
            AcademicPhrase(
                chinese: "本研究發現與{{作者}}的研究結果一致，顯示{{解釋}}。",
                english: "The findings of this study are consistent with {{author}}'s research, indicating that {{explanation}}.",
                category: .discussion,
                variables: ["作者", "解釋"]
            ),
            AcademicPhrase(
                chinese: "此結果可能的解釋為{{解釋}}。",
                english: "A possible explanation for this result is {{explanation}}.",
                category: .discussion,
                variables: ["解釋"]
            ),
            AcademicPhrase(
                chinese: "然而，本研究結果與{{作者}}的發現有所差異，可能原因在於{{原因}}。",
                english: "However, the results of this study differ from {{author}}'s findings, possibly because {{reason}}.",
                category: .discussion,
                variables: ["作者", "原因"]
            ),
            AcademicPhrase(
                chinese: "從理論層面而言，本研究結果支持了{{理論}}。",
                english: "From a theoretical perspective, the results of this study support {{theory}}.",
                category: .discussion,
                variables: ["理論"]
            ),
            AcademicPhrase(
                chinese: "就實務應用而言，本研究建議{{建議}}。",
                english: "In terms of practical application, this study suggests {{suggestion}}.",
                category: .discussion,
                variables: ["建議"]
            ),
            
            // ========================
            // 結論
            // ========================
            AcademicPhrase(
                chinese: "綜上所述，本研究發現{{主要發現}}。",
                english: "In summary, this study finds that {{main finding}}.",
                category: .conclusion,
                variables: ["主要發現"]
            ),
            AcademicPhrase(
                chinese: "本研究的主要貢獻包括：第一，{{貢獻一}}；第二，{{貢獻二}}。",
                english: "The main contributions of this study include: first, {{contribution 1}}; second, {{contribution 2}}.",
                category: .conclusion,
                variables: ["貢獻一", "貢獻二"]
            ),
            AcademicPhrase(
                chinese: "未來研究可朝向{{方向}}發展。",
                english: "Future research could focus on {{direction}}.",
                category: .conclusion,
                variables: ["方向"]
            ),
            AcademicPhrase(
                chinese: "本研究雖有若干限制，包括{{限制}}，但研究結果仍具參考價值。",
                english: "Although this study has some limitations, including {{limitation}}, the results still hold reference value.",
                category: .conclusion,
                variables: ["限制"]
            ),
            AcademicPhrase(
                chinese: "總結而言，本研究對於{{領域}}的理論與實務發展具有重要意涵。",
                english: "In conclusion, this study has significant implications for the theoretical and practical development of {{field}}.",
                category: .conclusion,
                variables: ["領域"]
            ),
            
            // ========================
            // 過渡連接
            // ========================
            AcademicPhrase(
                chinese: "然而，值得注意的是，",
                english: "However, it is worth noting that",
                category: .transition,
                notes: "用於引入對立觀點或例外情況"
            ),
            AcademicPhrase(
                chinese: "此外，",
                english: "Furthermore, / In addition,",
                category: .transition,
                notes: "用於補充說明"
            ),
            AcademicPhrase(
                chinese: "相較之下，",
                english: "In comparison, / By contrast,",
                category: .transition,
                notes: "用於比較對照"
            ),
            AcademicPhrase(
                chinese: "換言之，",
                english: "In other words,",
                category: .transition,
                notes: "用於換句話說或解釋"
            ),
            AcademicPhrase(
                chinese: "因此，",
                english: "Therefore, / Thus,",
                category: .transition,
                notes: "用於推論結果"
            ),
            AcademicPhrase(
                chinese: "儘管如此，",
                english: "Nevertheless, / Nonetheless,",
                category: .transition,
                notes: "用於讓步轉折"
            ),
            AcademicPhrase(
                chinese: "具體而言，",
                english: "Specifically, / To be specific,",
                category: .transition,
                notes: "用於具體說明"
            ),
            AcademicPhrase(
                chinese: "就{{方面}}而言，",
                english: "In terms of {{aspect}},",
                category: .transition,
                variables: ["方面"],
                notes: "用於限定討論範圍"
            ),
            
            // ========================
            // 引用表達
            // ========================
            AcademicPhrase(
                chinese: "如{{作者}}（{{年份}}）所述，",
                english: "As {{author}} ({{year}}) states,",
                category: .citation,
                variables: ["作者", "年份"]
            ),
            AcademicPhrase(
                chinese: "{{作者}}（{{年份}}）認為，{{觀點}}。",
                english: "{{author}} ({{year}}) argues that {{viewpoint}}.",
                category: .citation,
                variables: ["作者", "年份", "觀點"]
            ),
            AcademicPhrase(
                chinese: "依據{{作者}}（{{年份}}）的定義，{{概念}}係指{{定義}}。",
                english: "According to {{author}}'s ({{year}}) definition, {{concept}} refers to {{definition}}.",
                category: .citation,
                variables: ["作者", "年份", "概念", "定義"]
            ),
            AcademicPhrase(
                chinese: "多位學者（{{作者群}}）皆指出，{{共識}}。",
                english: "Several scholars ({{authors}}) have pointed out that {{consensus}}.",
                category: .citation,
                variables: ["作者群", "共識"]
            ),
            AcademicPhrase(
                chinese: "前人研究（{{文獻}}）已證實，{{發現}}。",
                english: "Previous studies ({{references}}) have confirmed that {{finding}}.",
                category: .citation,
                variables: ["文獻", "發現"]
            )
        ]
        
        AppLogger.success("📚 AcademicPhrasebank: 載入 \(allPhrases.count) 個學術句型")
    }
}

// MARK: - 句型搜尋結果

/// 句型搜尋結果
struct PhraseSearchResult {
    let phrase: AcademicPhrase
    let relevanceScore: Double
    let matchedText: String
}
