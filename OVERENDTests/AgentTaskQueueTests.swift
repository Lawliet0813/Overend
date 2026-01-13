//
//  AgentTaskQueueTests.swift
//  OVERENDTests
//
//  AgentTaskQueue 單元測試
//  測試任務佇列管理、優先級排序、重試機制
//

import XCTest
import CoreData
@testable import OVEREND

// MARK: - AgentTaskQueue 測試

@available(macOS 26.0, *)
@MainActor
final class AgentTaskQueueTests: XCTestCase {
    
    var queue: AgentTaskQueue!
    var testHelper: CoreDataTestHelper!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        queue = AgentTaskQueue()
        testHelper = CoreDataTestHelper(inMemory: true)
        context = testHelper.viewContext
    }
    
    override func tearDown() async throws {
        queue.clear()
        queue = nil
        testHelper = nil
        context = nil
    }
    
    func testInitialState() {
        XCTAssertTrue(queue.pendingTasks.isEmpty, "初始佇列應為空")
        XCTAssertFalse(queue.isProcessing, "初始不應在處理中")
        XCTAssertNil(queue.currentTask, "初始當前任務應為 nil")
    }
    
    func testEnqueueTask() {
        // Given
        let entry = createTestEntry()
        let task = AgentTask.analyzeEntry(entry)
        
        // When
        queue.enqueue(task, priority: .normal)
        
        // Then
        XCTAssertFalse(queue.pendingTasks.isEmpty, "佇列不應為空")
        XCTAssertEqual(queue.pendingTasks.count, 1, "應有 1 個任務")
    }
    
    func testEnqueueMultipleTasks() {
        // Given
        let entry = createTestEntry()
        
        // When
        queue.enqueue(AgentTask.analyzeEntry(entry), priority: .low)
        queue.enqueue(AgentTask.classifyEntries([entry]), priority: .normal)
        queue.enqueue(AgentTask.autoTagEntries([entry]), priority: .high)
        
        // Then
        XCTAssertEqual(queue.pendingTasks.count, 3, "應有 3 個任務")
    }
    
    func testEnqueueBatch() {
        // Given
        let entry = createTestEntry()
        let tasks: [AgentTask] = [
            .analyzeEntry(entry),
            .classifyEntries([entry]),
            .autoTagEntries([entry])
        ]
        
        // When
        queue.enqueueBatch(tasks, priority: .normal)
        
        // Then
        XCTAssertEqual(queue.pendingTasks.count, 3, "應有 3 個任務")
    }
    
    func testRemoveTask() {
        // Given
        let entry = createTestEntry()
        queue.enqueue(AgentTask.analyzeEntry(entry), priority: .normal)
        queue.enqueue(AgentTask.classifyEntries([entry]), priority: .normal)
        let firstTask = queue.pendingTasks.first!
        
        // When
        queue.remove(firstTask)
        
        // Then
        XCTAssertEqual(queue.pendingTasks.count, 1, "應剩 1 個任務")
    }
    
    func testClearQueue() {
        // Given
        let entry = createTestEntry()
        queue.enqueue(AgentTask.analyzeEntry(entry), priority: .normal)
        queue.enqueue(AgentTask.classifyEntries([entry]), priority: .normal)
        XCTAssertFalse(queue.pendingTasks.isEmpty)
        
        // When
        queue.clear()
        
        // Then
        XCTAssertTrue(queue.pendingTasks.isEmpty, "佇列應為空")
    }
    
    func testQueueStats() {
        // Given
        let entry = createTestEntry()
        queue.enqueue(AgentTask.analyzeEntry(entry), priority: .low)
        queue.enqueue(AgentTask.classifyEntries([entry]), priority: .normal)
        queue.enqueue(AgentTask.autoTagEntries([entry]), priority: .high)
        
        // When
        let stats = queue.stats
        
        // Then
        XCTAssertEqual(stats.total, 3)
        XCTAssertEqual(stats.pending, 3)
        XCTAssertEqual(stats.completed, 0)
        XCTAssertEqual(stats.failed, 0)
    }
    
    func testPriorityOrdering() {
        // Given
        let entry = createTestEntry()
        
        // When - 以不同順序加入不同優先級的任務
        queue.enqueue(AgentTask.analyzeEntry(entry), priority: .low)
        queue.enqueue(AgentTask.classifyEntries([entry]), priority: .urgent)
        queue.enqueue(AgentTask.autoTagEntries([entry]), priority: .normal)
        
        // Then - 應按優先級排序（高優先級在前）
        XCTAssertEqual(queue.pendingTasks[0].priority, .urgent)
        XCTAssertEqual(queue.pendingTasks[2].priority, .low)
    }
    
    // MARK: - Helper Methods
    
    private func createTestEntry() -> Entry {
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.citationKey = "test\(UUID().uuidString.prefix(4))"
        entry.entryType = "article"
        entry.fieldsJSON = "{\"title\":\"Test Paper\"}"
        entry.createdAt = Date()
        entry.updatedAt = Date()
        return entry
    }
}

// MARK: - TaskPriority 測試

final class TaskPriorityTests: XCTestCase {
    
    func testPriorityValues() {
        XCTAssertEqual(TaskPriority.low.rawValue, 0)
        XCTAssertEqual(TaskPriority.normal.rawValue, 1)
        XCTAssertEqual(TaskPriority.high.rawValue, 2)
        XCTAssertEqual(TaskPriority.urgent.rawValue, 3)
    }
    
    func testPriorityComparison() {
        XCTAssertTrue(TaskPriority.urgent > TaskPriority.high)
        XCTAssertTrue(TaskPriority.high > TaskPriority.normal)
        XCTAssertTrue(TaskPriority.normal > TaskPriority.low)
    }
}

// MARK: - QueuedTask 測試

@available(macOS 26.0, *)
@MainActor
final class QueuedTaskTests: XCTestCase {
    
    var testHelper: CoreDataTestHelper!
    
    override func setUp() async throws {
        testHelper = CoreDataTestHelper(inMemory: true)
    }
    
    override func tearDown() async throws {
        testHelper = nil
    }
    
    func testQueuedTaskCreation() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.citationKey = "test"
        
        let agentTask = AgentTask.analyzeEntry(entry)
        
        // When
        let task = QueuedTask(task: agentTask, priority: .high)
        
        // Then
        XCTAssertNotNil(task.id)
        XCTAssertEqual(task.priority, TaskPriority.high)
        XCTAssertEqual(task.retryCount, 0)
        XCTAssertTrue(task.canRetry)
    }
    
    func testQueuedTaskDefaultPriority() {
        // Given
        let context = testHelper.viewContext
        let entry = Entry(context: context)
        entry.id = UUID()
        
        let agentTask = AgentTask.analyzeEntry(entry)
        
        // When
        let task = QueuedTask(task: agentTask)
        
        // Then
        XCTAssertEqual(task.priority, TaskPriority.normal)
    }
}

// MARK: - QueueStats 測試

final class QueueStatsTests: XCTestCase {
    
    func testStatsTotal() {
        // Given
        let stats = QueueStats(pending: 5, completed: 10, failed: 2, isProcessing: false)
        
        // Then
        XCTAssertEqual(stats.total, 17)
    }
    
    func testStatsSuccessRate() {
        // Given
        let stats = QueueStats(pending: 0, completed: 8, failed: 2, isProcessing: false)
        
        // Then
        XCTAssertEqual(stats.successRate, 0.8, accuracy: 0.01)
    }
    
    func testStatsEmptySuccessRate() {
        // Given
        let stats = QueueStats(pending: 0, completed: 0, failed: 0, isProcessing: false)
        
        // Then
        XCTAssertEqual(stats.successRate, 0)
    }
}
