//
//  LiteratureAgentTests.swift
//  OVERENDTests
//
//  LiteratureAgent 單元測試
//  測試 Agent 任務執行、狀態管理、建議系統
//

import XCTest
import CoreData
@testable import OVEREND

// MARK: - AgentTask 測試

final class AgentTaskTests: XCTestCase {
    
    var testHelper: CoreDataTestHelper!
    
    @MainActor
    override func setUp() {
        testHelper = CoreDataTestHelper(inMemory: true)
    }
    
    @MainActor
    override func tearDown() {
        testHelper = nil
    }
    
    @MainActor
    func testTaskIdentifiers() {
        // Given - 使用 mock 資料建立任務
        let context = testHelper.viewContext
        let library = Library(context: context)
        library.id = UUID()
        library.name = "Test Library"
        
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.citationKey = "test2024"
        
        // When
        let analyzeTask = AgentTask.analyzeEntry(entry)
        let organizeTask = AgentTask.organizeByTopic(library)
        let duplicatesTask = AgentTask.findDuplicates(library)
        
        // Then
        XCTAssertTrue(analyzeTask.id.hasPrefix("analyze-"), "分析任務 ID 應以 analyze- 開頭")
        XCTAssertTrue(organizeTask.id.hasPrefix("organize-"), "整理任務 ID 應以 organize- 開頭")
        XCTAssertTrue(duplicatesTask.id.hasPrefix("duplicates-"), "重複任務 ID 應以 duplicates- 開頭")
    }
    
    @MainActor
    func testTaskDisplayNames() {
        // Given
        let context = testHelper.viewContext
        let library = Library(context: context)
        library.id = UUID()
        
        let entry = Entry(context: context)
        entry.id = UUID()
        
        // When/Then
        XCTAssertEqual(AgentTask.analyzeEntry(entry).displayName, "分析文獻")
        XCTAssertEqual(AgentTask.classifyEntries([entry]).displayName, "智慧分類")
        XCTAssertEqual(AgentTask.autoTagEntries([entry]).displayName, "自動標籤")
        XCTAssertEqual(AgentTask.organizeByTopic(library).displayName, "主題整理")
        XCTAssertEqual(AgentTask.generateSummaries([entry]).displayName, "生成摘要")
        XCTAssertEqual(AgentTask.findDuplicates(library).displayName, "尋找重複")
        XCTAssertEqual(AgentTask.batchProcess([entry]).displayName, "批次處理")
    }
    
    @MainActor
    func testTaskIcons() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        
        // When/Then
        XCTAssertEqual(AgentTask.analyzeEntry(entry).icon, "doc.text.magnifyingglass")
        XCTAssertEqual(AgentTask.classifyEntries([entry]).icon, "folder.badge.gearshape")
        XCTAssertEqual(AgentTask.autoTagEntries([entry]).icon, "tag.fill")
    }
    
    @MainActor
    func testTaskEquality() {
        // Given
        let context = testHelper.viewContext
        let entry1 = Entry(context: context)
        entry1.id = UUID()
        
        let entry2 = Entry(context: context)
        entry2.id = entry1.id // 相同 ID
        
        // When
        let task1 = AgentTask.analyzeEntry(entry1)
        let task2 = AgentTask.analyzeEntry(entry2)
        
        // Then
        XCTAssertEqual(task1, task2, "相同 Entry ID 的任務應相等")
    }
}

// MARK: - AgentState 測試

final class AgentStateTests: XCTestCase {
    
    func testIsExecutingStates() {
        // Given/When/Then
        XCTAssertFalse(AgentState.idle.isExecuting, "idle 不應在執行中")
        XCTAssertFalse(AgentState.completed.isExecuting, "completed 不應在執行中")
        XCTAssertFalse(AgentState.failed("error").isExecuting, "failed 不應在執行中")
        
        XCTAssertTrue(AgentState.analyzing.isExecuting, "analyzing 應在執行中")
        XCTAssertTrue(AgentState.classifying.isExecuting, "classifying 應在執行中")
        XCTAssertTrue(AgentState.tagging.isExecuting, "tagging 應在執行中")
        XCTAssertTrue(AgentState.organizing.isExecuting, "organizing 應在執行中")
        XCTAssertTrue(AgentState.summarizing.isExecuting, "summarizing 應在執行中")
    }
    
    func testStatusText() {
        // Given/When/Then
        XCTAssertEqual(AgentState.idle.statusText, "準備就緒")
        XCTAssertEqual(AgentState.analyzing.statusText, "正在分析...")
        XCTAssertEqual(AgentState.classifying.statusText, "正在分類...")
        XCTAssertEqual(AgentState.tagging.statusText, "正在標籤...")
        XCTAssertEqual(AgentState.organizing.statusText, "正在整理...")
        XCTAssertEqual(AgentState.summarizing.statusText, "正在摘要...")
        XCTAssertEqual(AgentState.completed.statusText, "已完成")
        XCTAssertTrue(AgentState.failed("test error").statusText.contains("失敗"))
    }
    
    func testStateEquality() {
        XCTAssertEqual(AgentState.idle, AgentState.idle)
        XCTAssertEqual(AgentState.analyzing, AgentState.analyzing)
        XCTAssertNotEqual(AgentState.idle, AgentState.analyzing)
    }
}

// MARK: - AgentResult 測試

final class AgentResultTests: XCTestCase {
    
    var testHelper: CoreDataTestHelper!
    
    @MainActor
    override func setUp() {
        testHelper = CoreDataTestHelper(inMemory: true)
    }
    
    @MainActor
    override func tearDown() {
        testHelper = nil
    }
    
    @MainActor
    func testResultCreation() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        let task = AgentTask.analyzeEntry(entry)
        
        // When
        let result = AgentResult(
            task: task,
            success: true,
            message: "分析完成",
            suggestions: [],
            duration: 1.5
        )
        
        // Then
        XCTAssertEqual(result.task, task)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "分析完成")
        XCTAssertEqual(result.suggestions.count, 0)
        XCTAssertEqual(result.duration, 1.5, accuracy: 0.01)
    }
    
    @MainActor
    func testResultWithSuggestions() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.citationKey = "test2024"
        
        let suggestion = AgentSuggestion(
            entry: entry,
            type: .tag("machine learning"),
            value: "machine learning",
            confidence: 0.85
        )
        
        let task = AgentTask.autoTagEntries([entry])
        
        // When
        let result = AgentResult(
            task: task,
            success: true,
            message: "標籤完成",
            suggestions: [suggestion]
        )
        
        // Then
        XCTAssertEqual(result.suggestions.count, 1)
        XCTAssertEqual(result.suggestions.first?.value, "machine learning")
    }
}

// MARK: - AgentSuggestion 測試

final class AgentSuggestionTests: XCTestCase {
    
    var testHelper: CoreDataTestHelper!
    
    @MainActor
    override func setUp() {
        testHelper = CoreDataTestHelper(inMemory: true)
    }
    
    @MainActor
    override func tearDown() {
        testHelper = nil
    }
    
    @MainActor
    func testGroupSuggestion() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        
        // When
        let suggestion = AgentSuggestion(
            entry: entry,
            type: .group("Machine Learning"),
            value: "Machine Learning",
            confidence: 0.9
        )
        
        // Then
        XCTAssertNotNil(suggestion.id)
        XCTAssertEqual(suggestion.value, "Machine Learning")
        XCTAssertEqual(suggestion.confidence, 0.9, accuracy: 0.01)
        
        if case .group(let name) = suggestion.type {
            XCTAssertEqual(name, "Machine Learning")
        } else {
            XCTFail("Suggestion type should be .group")
        }
    }
    
    @MainActor
    func testTagSuggestion() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        
        // When
        let suggestion = AgentSuggestion(
            entry: entry,
            type: .tag("deep learning"),
            value: "deep learning",
            confidence: 0.85
        )
        
        // Then
        if case .tag(let name) = suggestion.type {
            XCTAssertEqual(name, "deep learning")
        } else {
            XCTFail("Suggestion type should be .tag")
        }
    }
    
    @MainActor
    func testSummarySuggestion() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        
        // When
        let summaryText = "這是一篇關於機器學習的研究論文。"
        let suggestion = AgentSuggestion(
            entry: entry,
            type: .summary(summaryText),
            value: summaryText,
            confidence: 0.7
        )
        
        // Then
        if case .summary(let text) = suggestion.type {
            XCTAssertEqual(text, summaryText)
        } else {
            XCTFail("Suggestion type should be .summary")
        }
    }
    
    @MainActor
    func testDuplicateSuggestion() {
        // Given
        let context = testHelper.viewContext
        let entry1 = Entry(context: context)
        entry1.id = UUID()
        entry1.citationKey = "paper2024a"
        
        let entry2 = Entry(context: context)
        entry2.id = UUID()
        entry2.citationKey = "paper2024b"
        
        // When
        let suggestion = AgentSuggestion(
            entry: entry1,
            type: .duplicate(entry2),
            value: "與 paper2024b 重複",
            confidence: 0.95
        )
        
        // Then
        if case .duplicate(let other) = suggestion.type {
            XCTAssertEqual(other.citationKey, "paper2024b")
        } else {
            XCTFail("Suggestion type should be .duplicate")
        }
    }
}

// MARK: - AgentError 測試

final class AgentErrorTests: XCTestCase {
    
    func testErrorDescriptions() {
        // Given/When/Then
        XCTAssertEqual(AgentError.serviceNotAvailable.localizedDescription, "AI 服務不可用")
        XCTAssertTrue(AgentError.taskFailed("test").localizedDescription.contains("失敗"))
        XCTAssertEqual(AgentError.noEntriesProvided.localizedDescription, "未提供文獻")
        XCTAssertEqual(AgentError.cancelled.localizedDescription, "任務已取消")
    }
}

// MARK: - LiteratureAgent 測試 (需 macOS 26.0)

@available(macOS 26.0, *)
@MainActor
final class LiteratureAgentTests: XCTestCase {
    
    var agent: LiteratureAgent!
    var testHelper: CoreDataTestHelper!
    
    override func setUp() async throws {
        agent = LiteratureAgent.shared
        testHelper = CoreDataTestHelper(inMemory: true)
        
        // 注入測試用的 Repository
        let testRepo = EntryRepository(context: testHelper.viewContext)
        agent.setEntryRepository(testRepo)
        
        agent.reset()
    }
    
    override func tearDown() async throws {
        agent.reset()
        agent.clearPendingSuggestions()
        testHelper = nil
    }
    
    func testSharedInstance() {
        XCTAssertNotNil(LiteratureAgent.shared, "共享實例應存在")
        XCTAssertTrue(agent === LiteratureAgent.shared, "應為同一實例")
    }
    
    func testInitialState() {
        XCTAssertEqual(agent.state, .idle, "初始狀態應為 idle")
        XCTAssertNil(agent.currentTask, "初始應無當前任務")
        XCTAssertEqual(agent.progress, 0, "初始進度應為 0")
        XCTAssertTrue(agent.progressMessage.isEmpty, "初始進度訊息應為空")
        XCTAssertNil(agent.lastResult, "初始應無結果")
        XCTAssertTrue(agent.pendingSuggestions.isEmpty, "初始待處理建議應為空")
    }
    
    func testReset() {
        // Given
        agent.progress = 0.5
        agent.progressMessage = "Testing..."
        
        // When
        agent.reset()
        
        // Then
        XCTAssertEqual(agent.state, .idle)
        XCTAssertNil(agent.currentTask)
        XCTAssertEqual(agent.progress, 0)
        XCTAssertTrue(agent.progressMessage.isEmpty)
    }
    
    func testClearPendingSuggestions() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        
        // 手動添加建議
        let suggestion = AgentSuggestion(
            entry: entry,
            type: .tag("test"),
            value: "test",
            confidence: 0.8
        )
        agent.pendingSuggestions.append(suggestion)
        
        XCTAssertFalse(agent.pendingSuggestions.isEmpty)
        
        // When
        agent.clearPendingSuggestions()
        
        // Then
        XCTAssertTrue(agent.pendingSuggestions.isEmpty)
    }
    
    func testFindDuplicatesWithoutDuplicates() async throws {
        // Given
        let context = testHelper.viewContext
        let library = Library(context: context)
        library.id = UUID()
        library.name = "Test Library"
        
        let entry1 = Entry(context: context)
        entry1.id = UUID()
        entry1.citationKey = "paper1"
        entry1.fieldsJSON = try! JSONEncoder().encode(["title": "Paper One"]).toString()
        entry1.library = library
        
        let entry2 = Entry(context: context)
        entry2.id = UUID()
        entry2.citationKey = "paper2"
        entry2.fieldsJSON = try! JSONEncoder().encode(["title": "Paper Two"]).toString()
        entry2.library = library
        
        try? context.save()
        
        // When
        let result = try await agent.execute(task: .findDuplicates(library))
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.suggestions.count, 0, "不應找到重複")
    }
    
    func testFindDuplicatesWithDuplicates() async throws {
        // Given
        let context = testHelper.viewContext
        let library = Library(context: context)
        library.id = UUID()
        library.name = "Test Library"
        
        let entry1 = Entry(context: context)
        entry1.id = UUID()
        entry1.citationKey = "paper1"
        entry1.fieldsJSON = try! JSONEncoder().encode(["title": "Same Title"]).toString()
        entry1.library = library
        
        let entry2 = Entry(context: context)
        entry2.id = UUID()
        entry2.citationKey = "paper2"
        entry2.fieldsJSON = try! JSONEncoder().encode(["title": "Same Title"]).toString()
        entry2.library = library
        
        try? context.save()
        
        // When
        let result = try await agent.execute(task: .findDuplicates(library))
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertGreaterThan(result.suggestions.count, 0, "應找到重複")
    }
}

// MARK: - Data 擴展 (測試用)

private extension Data {
    func toString() -> String {
        String(data: self, encoding: .utf8) ?? "{}"
    }
}
