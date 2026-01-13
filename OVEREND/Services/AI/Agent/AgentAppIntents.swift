//
//  AgentAppIntents.swift
//  OVEREND
//
//  Siri App Intents - 讓 Siri 可以執行 Agent 功能
//
//  支援語音指令：
//  「用 OVEREND 整理文獻」
//  「用 OVEREND 分類文獻」
//  「用 OVEREND 標籤文獻」
//

import Foundation
import AppIntents
import CoreData

// MARK: - 整理文獻庫 Intent

/// Siri Intent: 整理文獻庫
@available(macOS 26.0, *)
struct OrganizeLibraryIntent: AppIntent {
    
    static var title: LocalizedStringResource = "整理文獻庫"
    static var description = IntentDescription("使用 AI 自動分類和標籤文獻")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let agent = LiteratureAgent.shared
        let context = PersistenceController.shared.container.viewContext
        
        // 取得第一個文獻庫
        let libraryRequest = Library.fetchRequest()
        libraryRequest.fetchLimit = 1
        
        guard let library = try? context.fetch(libraryRequest).first else {
            return .result(dialog: "找不到文獻庫，請先建立一個文獻庫。")
        }
        
        // 執行整理任務
        do {
            let result = try await agent.execute(task: .organizeByTopic(library))
            let suggestionCount = result.suggestions.count
            
            if suggestionCount > 0 {
                return .result(dialog: "已完成文獻庫整理！產生了 \(suggestionCount) 個分類建議，請到應用程式中確認。")
            } else {
                return .result(dialog: "文獻庫整理完成，所有文獻都已經分類好了！")
            }
        } catch {
            return .result(dialog: "整理時發生錯誤：\(error.localizedDescription)")
        }
    }
}

// MARK: - 智慧分類 Intent

/// Siri Intent: 智慧分類文獻
@available(macOS 26.0, *)
struct ClassifyLiteratureIntent: AppIntent {
    
    static var title: LocalizedStringResource = "分類文獻"
    static var description = IntentDescription("使用 AI 為未分類的文獻建議分類")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let agent = LiteratureAgent.shared
        let context = PersistenceController.shared.container.viewContext
        
        // 取得所有未分類文獻
        let entryRequest = Entry.fetchRequest()
        entryRequest.predicate = NSPredicate(format: "groups.@count == 0")
        
        let unclassifiedEntries = (try? context.fetch(entryRequest)) ?? []
        
        if unclassifiedEntries.isEmpty {
            return .result(dialog: "太棒了！所有文獻都已經分類完成。")
        }
        
        do {
            let result = try await agent.execute(task: .classifyEntries(unclassifiedEntries))
            let suggestionCount = result.suggestions.count
            
            return .result(dialog: "已為 \(unclassifiedEntries.count) 篇文獻產生 \(suggestionCount) 個分類建議，請到應用程式中確認。")
        } catch {
            return .result(dialog: "分類時發生錯誤：\(error.localizedDescription)")
        }
    }
}

// MARK: - 自動標籤 Intent

/// Siri Intent: 自動標籤文獻
@available(macOS 26.0, *)
struct AutoTagLiteratureIntent: AppIntent {
    
    static var title: LocalizedStringResource = "標籤文獻"
    static var description = IntentDescription("使用 AI 為文獻自動產生標籤")
    
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "文獻數量", default: 10)
    var count: Int
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let agent = LiteratureAgent.shared
        let context = PersistenceController.shared.container.viewContext
        
        // 取得最近的文獻
        let entryRequest = Entry.fetchRequest()
        entryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
        entryRequest.fetchLimit = count
        
        let entries = (try? context.fetch(entryRequest)) ?? []
        
        if entries.isEmpty {
            return .result(dialog: "找不到文獻，請先匯入一些文獻。")
        }
        
        do {
            let result = try await agent.execute(task: .autoTagEntries(entries))
            let suggestionCount = result.suggestions.count
            
            return .result(dialog: "已為 \(entries.count) 篇文獻產生 \(suggestionCount) 個標籤建議，請到應用程式中確認。")
        } catch {
            return .result(dialog: "標籤時發生錯誤：\(error.localizedDescription)")
        }
    }
}

// MARK: - 尋找重複 Intent

/// Siri Intent: 尋找重複文獻
@available(macOS 26.0, *)
struct FindDuplicatesIntent: AppIntent {
    
    static var title: LocalizedStringResource = "尋找重複文獻"
    static var description = IntentDescription("使用 AI 檢測文獻庫中的重複文獻")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let agent = LiteratureAgent.shared
        let context = PersistenceController.shared.container.viewContext
        
        // 取得第一個文獻庫
        let libraryRequest = Library.fetchRequest()
        libraryRequest.fetchLimit = 1
        
        guard let library = try? context.fetch(libraryRequest).first else {
            return .result(dialog: "找不到文獻庫，請先建立一個文獻庫。")
        }
        
        do {
            let result = try await agent.execute(task: .findDuplicates(library))
            let duplicateCount = result.suggestions.count
            
            if duplicateCount > 0 {
                return .result(dialog: "找到 \(duplicateCount) 組重複文獻，請到應用程式中處理。")
            } else {
                return .result(dialog: "太好了！文獻庫中沒有重複的文獻。")
            }
        } catch {
            return .result(dialog: "檢測時發生錯誤：\(error.localizedDescription)")
        }
    }
}

// MARK: - 生成摘要 Intent

/// Siri Intent: 生成文獻摘要
@available(macOS 26.0, *)
struct GenerateSummariesIntent: AppIntent {
    
    static var title: LocalizedStringResource = "生成文獻摘要"
    static var description = IntentDescription("使用 AI 為缺少摘要的文獻生成摘要")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let agent = LiteratureAgent.shared
        let context = PersistenceController.shared.container.viewContext
        
        // 取得缺少摘要的文獻
        let entryRequest = Entry.fetchRequest()
        let allEntries = (try? context.fetch(entryRequest)) ?? []
        let entriesNeedingSummary = allEntries.filter { 
            ($0.fields["abstract"]?.isEmpty ?? true) 
        }
        
        if entriesNeedingSummary.isEmpty {
            return .result(dialog: "所有文獻都已經有摘要了！")
        }
        
        do {
            let result = try await agent.execute(task: .generateSummaries(entriesNeedingSummary))
            let summaryCount = result.suggestions.count
            
            return .result(dialog: "已為 \(summaryCount) 篇文獻生成摘要建議，請到應用程式中確認。")
        } catch {
            return .result(dialog: "生成摘要時發生錯誤：\(error.localizedDescription)")
        }
    }
}

// MARK: - App Shortcuts Provider

/// 提供給 Siri 的快捷指令
@available(macOS 26.0, *)
struct OVERENDShortcuts: AppShortcutsProvider {
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OrganizeLibraryIntent(),
            phrases: [
                "用 \(.applicationName) 整理文獻",
                "整理 \(.applicationName) 文獻庫",
                "\(.applicationName) 自動整理"
            ],
            shortTitle: "整理文獻庫",
            systemImageName: "folder.badge.gearshape"
        )
        
        AppShortcut(
            intent: ClassifyLiteratureIntent(),
            phrases: [
                "用 \(.applicationName) 分類文獻",
                "\(.applicationName) 智慧分類",
                "自動分類 \(.applicationName) 文獻"
            ],
            shortTitle: "智慧分類",
            systemImageName: "rectangle.3.group"
        )
        
        AppShortcut(
            intent: AutoTagLiteratureIntent(),
            phrases: [
                "用 \(.applicationName) 標籤文獻",
                "\(.applicationName) 自動標籤",
                "為 \(.applicationName) 文獻加標籤"
            ],
            shortTitle: "自動標籤",
            systemImageName: "tag.fill"
        )
        
        AppShortcut(
            intent: FindDuplicatesIntent(),
            phrases: [
                "用 \(.applicationName) 找重複",
                "\(.applicationName) 檢查重複",
                "找 \(.applicationName) 重複文獻"
            ],
            shortTitle: "尋找重複",
            systemImageName: "doc.on.doc"
        )
        
        AppShortcut(
            intent: GenerateSummariesIntent(),
            phrases: [
                "用 \(.applicationName) 生成摘要",
                "\(.applicationName) 自動摘要",
                "為 \(.applicationName) 文獻加摘要"
            ],
            shortTitle: "生成摘要",
            systemImageName: "doc.plaintext"
        )
    }
}
