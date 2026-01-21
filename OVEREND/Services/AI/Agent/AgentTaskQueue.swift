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
    public var isCancelled: Bool = false  // ✅ 新增：取消標記
    public var timeout: TimeInterval = 300  // ✅ 新增：逾時設定（預設 5 分鐘）

    public init(task: AgentTask, priority: TaskPriority = .normal, timeout: TimeInterval = 300) {
        self.task = task
        self.priority = priority
        self.createdAt = Date()
        self.timeout = timeout
    }

    public var canRetry: Bool {
        retryCount < maxRetries && !isCancelled
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
    private let maxFailedHistory = 50  // ✅ 新增：失敗歷史上限
    private var runningTasks: [UUID: Task<Void, Error>] = [:]  // ✅ 追蹤執行中的任務

    // MARK: - 初始化

    public init() {}

    deinit {
        // ✅ 清理所有任務
        processingTask?.cancel()
        processingTask = nil
        runningTasks.values.forEach { $0.cancel() }
        runningTasks.removeAll()
    }
    
    // MARK: - 佇列操作
    
    /// 新增任務到佇列
    public func enqueue(_ task: AgentTask, priority: TaskPriority = .normal) {
        let queuedTask = QueuedTask(task: task, priority: priority)
        pendingTasks.append(queuedTask)
        sortPendingTasks()
        
        AppLogger.shared.debug("📋 TaskQueue: 新增任務 \(task.displayName) (優先級: \(priority))")
    }
    
    /// 批次新增任務
    public func enqueueBatch(_ tasks: [AgentTask], priority: TaskPriority = .normal) {
        for task in tasks {
            let queuedTask = QueuedTask(task: task, priority: priority)
            pendingTasks.append(queuedTask)
        }
        sortPendingTasks()
        
        AppLogger.shared.debug("📋 TaskQueue: 批次新增 \(tasks.count) 個任務")
    }
    
    /// 移除任務
    public func remove(_ task: QueuedTask) {
        pendingTasks.removeAll { $0.id == task.id }
    }

    /// ✅ 取消單一任務
    public func cancel(_ task: QueuedTask) {
        // 從佇列移除
        pendingTasks.removeAll { $0.id == task.id }

        // 如果正在執行，取消該任務
        if let runningTask = runningTasks[task.id] {
            runningTask.cancel()
            runningTasks.removeValue(forKey: task.id)
            AppLogger.shared.debug("📋 TaskQueue: 已取消任務 \(task.task.displayName)")
        }

        // 標記為已取消
        var cancelledTask = task
        cancelledTask.isCancelled = true
    }

    /// ✅ 取消所有待執行任務
    public func cancelAll() {
        pendingTasks.removeAll()
        runningTasks.values.forEach { $0.cancel() }
        runningTasks.removeAll()
        AppLogger.shared.debug("📋 TaskQueue: 已取消所有任務")
    }

    /// 清空佇列
    public func clear() {
        pendingTasks.removeAll()
        AppLogger.shared.debug("📋 TaskQueue: 已清空佇列")
    }
    
    /// 開始處理佇列
    public func startProcessing(agent: LiteratureAgent) {
        guard !isProcessing else { return }

        isProcessing = true

        processingTask = Task {
            while !pendingTasks.isEmpty {
                guard let nextTask = pendingTasks.first else { break }

                // 檢查是否已取消
                guard !nextTask.isCancelled else {
                    pendingTasks.removeFirst()
                    continue
                }

                // 移動到執行中
                pendingTasks.removeFirst()
                currentTask = nextTask

                // ✅ 建立逾時檢查任務
                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(nextTask.timeout * 1_000_000_000))
                    if !Task.isCancelled {
                        AppLogger.shared.warning("⏱️ 任務逾時: \(nextTask.task.displayName) (\(nextTask.timeout)秒)")
                    }
                }

                // ✅ 執行任務並追蹤
                let executionTask = Task {
                    do {
                        _ = try await agent.execute(task: nextTask.task)

                        // 取消逾時檢查
                        timeoutTask.cancel()

                        // 成功：加入已完成
                        completedTasks.insert(nextTask, at: 0)
                        trimCompletedHistory()

                    } catch {
                        // 取消逾時檢查
                        timeoutTask.cancel()

                        // 檢查是否為逾時錯誤
                        let isTimeout = !timeoutTask.isCancelled

                        // 失敗：檢查是否重試
                        var failedTask = nextTask
                        failedTask.retryCount += 1

                        if failedTask.canRetry && !isTimeout {
                            // 重新加入佇列（但不重試逾時任務）
                            pendingTasks.append(failedTask)
                            sortPendingTasks()
                            AppLogger.shared.warning("📋 TaskQueue: 任務失敗，將重試 (\(failedTask.retryCount)/\(failedTask.maxRetries))")
                        } else {
                            // 加入失敗列表
                            failedTasks.insert(failedTask, at: 0)
                            trimFailedHistory()
                            let reason = isTimeout ? "逾時" : error.localizedDescription
                            AppLogger.shared.error("📋 TaskQueue: 任務永久失敗: \(reason)")
                        }

                        throw error
                    }
                }

                // 追蹤執行中的任務
                runningTasks[nextTask.id] = executionTask

                // 等待完成或失敗
                do {
                    try await executionTask.value
                } catch {
                    // 已在 catch 塊中處理
                }

                // 清除追蹤
                runningTasks.removeValue(forKey: nextTask.id)
                currentTask = nil
            }

            isProcessing = false
            AppLogger.shared.notice("📋 TaskQueue: 佇列處理完成")
        }
    }
    
    /// 停止處理
    public func stopProcessing() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
        currentTask = nil
        AppLogger.shared.debug("📋 TaskQueue: 已停止處理")
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

    /// ✅ 限制失敗歷史
    private func trimFailedHistory() {
        if failedTasks.count > maxFailedHistory {
            failedTasks = Array(failedTasks.prefix(maxFailedHistory))
            AppLogger.shared.debug("📋 TaskQueue: 失敗歷史已達上限，移除舊紀錄")
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
