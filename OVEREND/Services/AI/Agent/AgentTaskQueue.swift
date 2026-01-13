//
//  AgentTaskQueue.swift
//  OVEREND
//
//  Agent 任務佇列 - 管理待執行任務的優先級與執行
//

import Foundation
import Combine

// MARK: - 任務優先級

/// 任務優先級
public enum TaskPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - 佇列任務

/// 佇列中的任務
@available(macOS 26.0, *)
public struct QueuedTask: Identifiable {
    public let id = UUID()
    public let task: AgentTask
    public let priority: TaskPriority
    public let createdAt: Date
    public var retryCount: Int = 0
    public let maxRetries: Int = 3
    
    public init(task: AgentTask, priority: TaskPriority = .normal) {
        self.task = task
        self.priority = priority
        self.createdAt = Date()
    }
    
    public var canRetry: Bool {
        retryCount < maxRetries
    }
}

// MARK: - 任務佇列

/// Agent 任務佇列
/// 
/// 管理待執行任務，支援優先級排序與失敗重試
@available(macOS 26.0, *)
@MainActor
public class AgentTaskQueue: ObservableObject {
    
    // MARK: - 發布屬性
    
    /// 待執行任務
    @Published public private(set) var pendingTasks: [QueuedTask] = []
    
    /// 正在執行的任務
    @Published public private(set) var currentTask: QueuedTask?
    
    /// 已完成任務
    @Published public private(set) var completedTasks: [QueuedTask] = []
    
    /// 失敗任務
    @Published public private(set) var failedTasks: [QueuedTask] = []
    
    /// 是否正在處理
    @Published public private(set) var isProcessing: Bool = false
    
    // MARK: - 私有屬性
    
    private var processingTask: Task<Void, Never>?
    private let maxCompletedHistory = 50
    
    // MARK: - 初始化
    
    public init() {}
    
    // MARK: - 佇列操作
    
    /// 新增任務到佇列
    public func enqueue(_ task: AgentTask, priority: TaskPriority = .normal) {
        let queuedTask = QueuedTask(task: task, priority: priority)
        pendingTasks.append(queuedTask)
        sortPendingTasks()
        
        AppLogger.debug("📋 TaskQueue: 新增任務 \(task.displayName) (優先級: \(priority))")
    }
    
    /// 批次新增任務
    public func enqueueBatch(_ tasks: [AgentTask], priority: TaskPriority = .normal) {
        for task in tasks {
            let queuedTask = QueuedTask(task: task, priority: priority)
            pendingTasks.append(queuedTask)
        }
        sortPendingTasks()
        
        AppLogger.debug("📋 TaskQueue: 批次新增 \(tasks.count) 個任務")
    }
    
    /// 移除任務
    public func remove(_ task: QueuedTask) {
        pendingTasks.removeAll { $0.id == task.id }
    }
    
    /// 清空佇列
    public func clear() {
        pendingTasks.removeAll()
        AppLogger.debug("📋 TaskQueue: 已清空佇列")
    }
    
    /// 開始處理佇列
    public func startProcessing(agent: LiteratureAgent) {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        processingTask = Task {
            while !pendingTasks.isEmpty {
                guard let nextTask = pendingTasks.first else { break }
                
                // 移動到執行中
                pendingTasks.removeFirst()
                currentTask = nextTask
                
                do {
                    _ = try await agent.execute(task: nextTask.task)
                    
                    // 成功：加入已完成
                    completedTasks.insert(nextTask, at: 0)
                    trimCompletedHistory()
                    
                } catch {
                    // 失敗：檢查是否重試
                    var failedTask = nextTask
                    failedTask.retryCount += 1
                    
                    if failedTask.canRetry {
                        // 重新加入佇列
                        pendingTasks.append(failedTask)
                        sortPendingTasks()
                        AppLogger.warning("📋 TaskQueue: 任務失敗，將重試 (\(failedTask.retryCount)/\(failedTask.maxRetries))")
                    } else {
                        // 加入失敗列表
                        failedTasks.insert(failedTask, at: 0)
                        AppLogger.error("📋 TaskQueue: 任務永久失敗: \(error.localizedDescription)")
                    }
                }
                
                currentTask = nil
            }
            
            isProcessing = false
            AppLogger.success("📋 TaskQueue: 佇列處理完成")
        }
    }
    
    /// 停止處理
    public func stopProcessing() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
        currentTask = nil
        AppLogger.debug("📋 TaskQueue: 已停止處理")
    }
    
    /// 重試失敗任務
    public func retryFailed(_ task: QueuedTask) {
        failedTasks.removeAll { $0.id == task.id }
        var retryTask = task
        retryTask.retryCount = 0
        pendingTasks.append(retryTask)
        sortPendingTasks()
    }
    
    /// 重試所有失敗任務
    public func retryAllFailed() {
        for task in failedTasks {
            var retryTask = task
            retryTask.retryCount = 0
            pendingTasks.append(retryTask)
        }
        failedTasks.removeAll()
        sortPendingTasks()
    }
    
    /// 清除失敗歷史
    public func clearFailed() {
        failedTasks.removeAll()
    }
    
    /// 清除完成歷史
    public func clearCompleted() {
        completedTasks.removeAll()
    }
    
    // MARK: - 私有方法
    
    private func sortPendingTasks() {
        pendingTasks.sort { $0.priority > $1.priority }
    }
    
    private func trimCompletedHistory() {
        if completedTasks.count > maxCompletedHistory {
            completedTasks = Array(completedTasks.prefix(maxCompletedHistory))
        }
    }
    
    // MARK: - 統計
    
    /// 佇列統計
    public var stats: QueueStats {
        QueueStats(
            pending: pendingTasks.count,
            completed: completedTasks.count,
            failed: failedTasks.count,
            isProcessing: isProcessing
        )
    }
}

// MARK: - 佇列統計

/// 佇列統計資訊
public struct QueueStats {
    public let pending: Int
    public let completed: Int
    public let failed: Int
    public let isProcessing: Bool
    
    public var total: Int {
        pending + completed + failed
    }
    
    public var successRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}
