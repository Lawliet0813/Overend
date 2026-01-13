//
//  AcademicPhrasebankIntents.swift
//  OVEREND
//
//  學術語料庫 App Intents
//
//  功能：
//  - 透過 Shortcuts 搜尋學術句型
//  - 複製句型到剪貼簿
//  - Siri 語音觸發
//

import AppIntents
import SwiftUI

// MARK: - 搜尋學術句型 Intent

/// 搜尋學術語料庫句型
@available(macOS 26.0, *)
struct SearchAcademicPhrasesIntent: AppIntent {
    static var title: LocalizedStringResource = "搜尋學術句型"
    static var description = IntentDescription("在學術語料庫中搜尋句型")
    
    @Parameter(title: "搜尋關鍵字")
    var query: String
    
    @Parameter(title: "分類", default: nil)
    var category: PhraseCategoryEntity?
    
    static var parameterSummary: some ParameterSummary {
        Summary("搜尋「\(\.$query)」") {
            \.$category
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let phrasebank = AcademicPhrasebank.shared
        
        var results: [AcademicPhrase]
        
        if !query.isEmpty {
            results = phrasebank.search(query: query)
        } else if let categoryEntity = category,
                  let phraseCategory = PhraseCategory(rawValue: categoryEntity.id) {
            results = phrasebank.byCategory(phraseCategory)
        } else {
            results = phrasebank.randomSuggestions(count: 5)
        }
        
        let phrases = results.prefix(10).map { $0.chinese }
        return .result(value: Array(phrases))
    }
}

// MARK: - 複製學術句型 Intent

/// 複製學術句型到剪貼簿
@available(macOS 26.0, *)
struct CopyAcademicPhraseIntent: AppIntent {
    static var title: LocalizedStringResource = "複製學術句型"
    static var description = IntentDescription("搜尋並複製學術句型到剪貼簿")
    
    @Parameter(title: "搜尋關鍵字")
    var query: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("複製符合「\(\.$query)」的句型")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let phrasebank = AcademicPhrasebank.shared
        let results = phrasebank.search(query: query)
        
        guard let firstPhrase = results.first else {
            return .result(dialog: "找不到符合「\(query)」的句型")
        }
        
        // 複製到剪貼簿
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(firstPhrase.chinese, forType: .string)
        
        return .result(dialog: "已複製：\(firstPhrase.chinese)")
    }
}

// MARK: - 取得句型建議 Intent

/// 根據上下文取得句型建議
@available(macOS 26.0, *)
struct GetPhraseSuggestionsIntent: AppIntent {
    static var title: LocalizedStringResource = "取得句型建議"
    static var description = IntentDescription("根據您的寫作內容提供句型建議")
    
    @Parameter(title: "目前內容")
    var context: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("為「\(\.$context)」取得建議")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let phrasebank = AcademicPhrasebank.shared
        let suggestions = await phrasebank.suggest(for: context)
        let phrases = suggestions.map { $0.chinese }
        return .result(value: phrases)
    }
}

// MARK: - 瀏覽分類句型 Intent

/// 瀏覽特定分類的句型
@available(macOS 26.0, *)
struct BrowsePhraseCategoryIntent: AppIntent {
    static var title: LocalizedStringResource = "瀏覽分類句型"
    static var description = IntentDescription("瀏覽特定分類的學術句型")
    
    @Parameter(title: "分類")
    var category: PhraseCategoryEntity
    
    @Parameter(title: "數量", default: 5)
    var count: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("瀏覽 \(\.$count) 個「\(\.$category)」句型")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let phrasebank = AcademicPhrasebank.shared
        
        guard let phraseCategory = PhraseCategory(rawValue: category.id) else {
            return .result(value: [])
        }
        
        let phrases = phrasebank.byCategory(phraseCategory)
            .prefix(count)
            .map { $0.chinese }
        
        return .result(value: Array(phrases))
    }
}

// MARK: - 分類實體

/// 句型分類實體
@available(macOS 26.0, *)
struct PhraseCategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "句型分類"
    static var defaultQuery = PhraseCategoryQuery()
    
    var id: String
    var displayName: String
    var icon: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            image: .init(systemName: icon)
        )
    }
    
    static let introduction = PhraseCategoryEntity(
        id: "introduction",
        displayName: "緒論/引言",
        icon: "text.book.closed"
    )
    
    static let literatureReview = PhraseCategoryEntity(
        id: "literature_review",
        displayName: "文獻回顧",
        icon: "books.vertical"
    )
    
    static let methodology = PhraseCategoryEntity(
        id: "methodology",
        displayName: "研究方法",
        icon: "gearshape.2"
    )
    
    static let results = PhraseCategoryEntity(
        id: "results",
        displayName: "結果呈現",
        icon: "chart.bar"
    )
    
    static let discussion = PhraseCategoryEntity(
        id: "discussion",
        displayName: "討論",
        icon: "bubble.left.and.bubble.right"
    )
    
    static let conclusion = PhraseCategoryEntity(
        id: "conclusion",
        displayName: "結論",
        icon: "checkmark.seal"
    )
    
    static let transition = PhraseCategoryEntity(
        id: "transition",
        displayName: "過渡連接",
        icon: "arrow.right"
    )
    
    static let citation = PhraseCategoryEntity(
        id: "citation",
        displayName: "引用表達",
        icon: "quote.bubble"
    )
    
    static let allCategories: [PhraseCategoryEntity] = [
        .introduction, .literatureReview, .methodology,
        .results, .discussion, .conclusion, .transition, .citation
    ]
}

/// 分類查詢
@available(macOS 26.0, *)
struct PhraseCategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PhraseCategoryEntity] {
        PhraseCategoryEntity.allCategories.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [PhraseCategoryEntity] {
        PhraseCategoryEntity.allCategories
    }
    
    func defaultResult() async -> PhraseCategoryEntity? {
        .introduction
    }
}

// NOTE: Shortcuts are integrated into OVERENDShortcuts in AgentAppIntents.swift
