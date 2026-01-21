# AI Agent 程式碼優化建議報告

**專案：** OVEREND macOS - 智慧文獻管理系統
**檢視日期：** 2026-01-19
**檢視範圍：** AI Agent 核心架構與相關服務

---

## 📋 執行摘要

經過對 OVEREND 專案中 AI Agent 相關程式碼的全面審查，發現該專案採用了 Apple Intelligence (FoundationModels) 作為核心 AI 引擎，架構設計清晰，具備良好的模組化設計。然而，仍有一些可以優化的空間，特別是在錯誤處理、效能優化、並發管理和測試覆蓋率方面。

**整體評分：** 7.5/10

**核心優勢：**
- 清晰的分層架構（Agent → Service → Domain → Tools）
- 良好的任務佇列與優先級管理
- 完善的 Tool Calling 整合
- 合理的 Session Pool 與 Result Cache 機制

**主要改進領域：**
- 錯誤處理與重試策略
- 並發安全性
- 記憶體管理
- 測試覆蓋率

---

## 🏗️ 架構分析

### 1. AgentOrchestrator (簡化版協調器)

**位置：** `Services/Agents/AgentOrchestrator.swift`

**現狀：**
- 目前為 Mock 實作，實際功能主要在 `LiteratureAgent` 中
- 使用 Actor 隔離提供了基礎的並發安全
- 簡單的任務執行與狀態管理

**問題：**
1. ❌ **角色重疊：** 功能與 `LiteratureAgent` 重疊，缺乏明確職責劃分
2. ❌ **錯誤處理簡陋：** 只有簡單的 try-catch，沒有重試或降級策略
3. ❌ **Mock 實作：** Execute 方法只返回模擬結果，未連接實際 AI 服務

**建議：**
```swift
// 建議 1: 明確職責劃分
// Option A: 移除 AgentOrchestrator，讓 LiteratureAgent 直接管理任務
// Option B: 重構為真正的協調器，管理多個 Agent (Literature, Writing, Citation 等)

// 建議 2: 實作真正的任務分發
actor AgentOrchestrator: ObservableObject {
    private let literatureAgent = LiteratureAgent.shared
    private let writingAgent = WritingAgent.shared  // 未來擴展

    func submit(_ task: CoreAgentTask) async throws {
        switch task {
        case .refineText(let text):
            return try await writingAgent.refine(text)
        case .analyzeStructure(let text):
            return try await literatureAgent.analyzeStructure(text)
        // ...
        }
    }
}

// 建議 3: 增強錯誤處理與重試
private func execute(_ task: CoreAgentTask) async throws -> String {
    var attempt = 0
    let maxRetries = 3

    while attempt < maxRetries {
        do {
            return try await performTask(task)
        } catch {
            attempt += 1
            if attempt == maxRetries {
                throw AgentError.taskFailed("Failed after \(maxRetries) attempts: \(error)")
            }
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000)) // 指數退避
        }
    }
    throw AgentError.taskFailed("Unexpected error")
}
```

---

### 2. LiteratureAgent (核心 Agent)

**位置：** `Services/AI/Agent/LiteratureAgent.swift`

**現狀：**
- 1162 行代碼，功能完整但過於龐大
- 支援 8 種任務類型（分析、分類、標籤、整理、摘要、重複檢測、批次處理、PDF 提取）
- 整合了 Apple Intelligence Session 管理
- 使用 Repository 模式存取資料

**問題：**
1. ⚠️ **單一職責違反：** 同時處理任務執行、PDF 解析、OCR、結果管理等多項職責
2. ⚠️ **記憶體風險：** `pendingSuggestions` 無上限，可能累積大量資料
3. ⚠️ **錯誤處理不一致：** 部分方法使用 `try?` 吞掉錯誤，缺乏日誌記錄
4. ⚠️ **硬編碼依賴：** 直接使用 `UnifiedAIService.shared` 和 `AdapterManager.shared`
5. ⚠️ **並發安全疑慮：** `@MainActor` 標註，但內部有大量 async 操作，可能造成 UI 阻塞

**優化建議：**

#### 建議 1：拆分職責
```swift
// 將 LiteratureAgent 拆分為多個專門的 Agent

// 核心 Agent - 只負責任務協調
@MainActor
public class LiteratureAgent: ObservableObject {
    private let classificationService = ClassificationService()
    private let taggingService = TaggingService()
    private let pdfExtractor = PDFMetadataExtractor()

    public func execute(task: AgentTask) async throws -> AgentResult {
        switch task {
        case .classifyEntries(let entries):
            return try await classificationService.classify(entries)
        case .autoTagEntries(let entries):
            return try await taggingService.tag(entries)
        case .extractPDFMetadata(let url):
            return try await pdfExtractor.extract(from: url)
        // ...
        }
    }
}

// 獨立的 PDF 提取服務
actor PDFMetadataExtractor {
    func extract(from url: URL) async throws -> PDFExtractionResult {
        // 所有 PDF 相關邏輯移到這裡
    }
}
```

#### 建議 2：改善錯誤處理
```swift
// 統一的錯誤處理策略
private func classifyEntriesTask(_ entries: [Entry]) async throws -> AgentResult {
    var allSuggestions: [AgentSuggestion] = []
    var failures: [(Entry, Error)] = []

    for (index, entry) in entries.enumerated() {
        progress = Double(index) / Double(entries.count)

        do {
            let categories = try await aiService.document.suggestCategories(...)
            // 處理結果
        } catch {
            // ✅ 不再使用 try? 吞掉錯誤
            AppLogger.shared.error("分類失敗 [\(entry.title)]: \(error)")
            failures.append((entry, error))
            // 繼續處理其他文獻，而非整個任務失敗
        }
    }

    return AgentResult(
        task: .classifyEntries(entries),
        success: failures.isEmpty,
        message: "已處理 \(entries.count) 篇，\(failures.count) 篇失敗",
        suggestions: allSuggestions
    )
}
```

#### 建議 3：限制記憶體使用
```swift
// 在 LiteratureAgent 中
private let maxSuggestions = 1000  // 設定上限

public func execute(task: AgentTask) async throws -> AgentResult {
    // ...

    // ✅ 限制建議數量
    if pendingSuggestions.count + suggestions.count > maxSuggestions {
        // 移除舊的建議（FIFO）
        let overflow = (pendingSuggestions.count + suggestions.count) - maxSuggestions
        pendingSuggestions.removeFirst(overflow)
    }

    pendingSuggestions.append(contentsOf: suggestions)

    return result
}
```

#### 建議 4：依賴注入
```swift
// ✅ 使用依賴注入，方便測試
@MainActor
public class LiteratureAgent: ObservableObject {
    private let aiService: UnifiedAIService
    private let adapterManager: AdapterManager

    public init(
        aiService: UnifiedAIService = .shared,
        adapterManager: AdapterManager = .shared
    ) {
        self.aiService = aiService
        self.adapterManager = adapterManager
    }
}
```

#### 建議 5：非同步任務管理
```swift
// ✅ 避免在 @MainActor 上執行耗時操作
public func execute(task: AgentTask) async throws -> AgentResult {
    currentTask = task

    // 在背景執行耗時操作
    let result = try await Task.detached {
        // 實際的 AI 處理
        return try await self.performTask(task)
    }.value

    // 回到主執行緒更新 UI
    await MainActor.run {
        self.lastResult = result
        self.currentTask = nil
    }

    return result
}
```

---

### 3. AgentTaskQueue (任務佇列)

**位置：** `Services/AI/Agent/AgentTaskQueue.swift`

**現狀：**
- 良好的優先級管理與任務排序
- 支援任務重試（最多 3 次）
- 維護完成與失敗歷史

**問題：**
1. ⚠️ **並發安全疑慮：** `@MainActor` 標註，但在背景 Task 中修改狀態
2. ⚠️ **無任務取消機制：** 只能停止整個佇列，無法取消單一任務
3. ⚠️ **無任務逾時處理：** 長時間執行的任務可能卡住佇列
4. ⚠️ **歷史記錄無限制：** 雖有 `maxCompletedHistory = 50`，但失敗歷史無限制

**優化建議：**

#### 建議 1：改善並發模型
```swift
// ✅ 使用 Actor 取代 @MainActor
actor AgentTaskQueue: ObservableObject {
    @MainActor @Published private(set) var pendingTasks: [QueuedTask] = []
    @MainActor @Published private(set) var isProcessing: Bool = false

    private var processingTask: Task<Void, Never>?

    func enqueue(_ task: AgentTask, priority: TaskPriority = .normal) async {
        let queuedTask = QueuedTask(task: task, priority: priority)

        await MainActor.run {
            self.pendingTasks.append(queuedTask)
            self.sortPendingTasks()
        }
    }
}
```

#### 建議 2：任務取消機制
```swift
public struct QueuedTask: Identifiable {
    public let id = UUID()
    public let task: AgentTask
    public let priority: TaskPriority
    public var cancellationToken: Task<Void, Never>?  // ✅ 新增
    public var isCancelled: Bool = false  // ✅ 新增
}

// 取消單一任務
public func cancel(_ task: QueuedTask) {
    task.cancellationToken?.cancel()
    pendingTasks.removeAll { $0.id == task.id }
}
```

#### 建議 3：任務逾時處理
```swift
public func startProcessing(agent: LiteratureAgent) {
    processingTask = Task {
        while !pendingTasks.isEmpty {
            guard let nextTask = pendingTasks.first else { break }
            pendingTasks.removeFirst()
            currentTask = nextTask

            // ✅ 增加逾時機制
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 分鐘
                if !Task.isCancelled {
                    AppLogger.shared.warning("任務逾時: \(nextTask.task.displayName)")
                }
            }

            do {
                let executionTask = Task {
                    try await agent.execute(task: nextTask.task)
                }

                let result = try await executionTask.value
                timeoutTask.cancel()  // 取消逾時檢查

                completedTasks.insert(nextTask, at: 0)
            } catch {
                timeoutTask.cancel()
                // 處理失敗...
            }
        }
    }
}
```

---

### 4. UnifiedAIService (AI 服務層)

**位置：** `Services/AI/Core/UnifiedAIService.swift`

**現狀：**
- 優秀的設計：Session Pool、Result Cache、Domain 分層
- 使用 SHA256-like hash 作為快取鍵
- 定期清理過期快取

**問題：**
1. ⚠️ **Session Pool 缺乏清理：** Session 可能長期駐留記憶體
2. ⚠️ **Cache 鍵碰撞風險：** 使用簡化的 djb2 雜湊，可能發生碰撞
3. ⚠️ **無快取統計：** 無法追蹤快取命中率
4. ⚠️ **線程安全性不足：** `sessionLock` 只保護 Pool，但 `resultCache` 未加鎖

**優化建議：**

#### 建議 1：Session 生命週期管理
```swift
private struct PooledSession {
    let session: LanguageModelSession
    let lastUsed: Date
    var useCount: Int
}

private var sessionPool: [PooledSession] = []
private let sessionMaxAge: TimeInterval = 600  // 10 分鐘
private let sessionMaxUse = 100  // 最多使用 100 次

func acquireSession() -> LanguageModelSession {
    sessionLock.lock()
    defer { sessionLock.unlock() }

    // ✅ 清理過期或過度使用的 Session
    sessionPool.removeAll { session in
        Date().timeIntervalSince(session.lastUsed) > sessionMaxAge ||
        session.useCount > sessionMaxUse
    }

    if let pooled = sessionPool.popLast() {
        var updated = pooled
        updated.useCount += 1
        return updated.session
    }

    return LanguageModelSession()
}

func releaseSession(_ session: LanguageModelSession) {
    sessionLock.lock()
    defer { sessionLock.unlock() }

    guard sessionPool.count < maxPoolSize else { return }

    let pooled = PooledSession(
        session: session,
        lastUsed: Date(),
        useCount: 1
    )
    sessionPool.append(pooled)
}
```

#### 建議 2：使用真正的 SHA256
```swift
import CryptoKit  // ✅ 使用系統提供的 Crypto

func cacheKey(operation: String, input: String) -> String {
    let combined = "\(operation):\(input)"
    guard let data = combined.data(using: .utf8) else {
        return String(combined.prefix(64))
    }

    // ✅ 使用真正的 SHA256
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}
```

#### 建議 3：快取統計
```swift
@Published public private(set) var cacheStats = CacheStats()

public struct CacheStats {
    var hits: Int = 0
    var misses: Int = 0

    var hitRate: Double {
        let total = hits + misses
        return total > 0 ? Double(hits) / Double(total) : 0
    }
}

func getCachedResult(for key: String) -> String? {
    guard let cached = resultCache[key] else {
        cacheStats.misses += 1
        return nil
    }

    if Date().timeIntervalSince(cached.timestamp) > cacheTTL {
        resultCache.removeValue(forKey: key)
        cacheStats.misses += 1
        return nil
    }

    cacheStats.hits += 1  // ✅ 記錄命中
    return cached.value
}
```

#### 建議 4：線程安全的快取
```swift
// ✅ 使用 Actor 確保線程安全
actor ResultCache {
    private var cache: [String: CachedResult] = [:]
    private let ttl: TimeInterval
    private let maxSize: Int

    func get(_ key: String) -> String? {
        guard let cached = cache[key] else { return nil }

        if Date().timeIntervalSince(cached.timestamp) > ttl {
            cache.removeValue(forKey: key)
            return nil
        }

        return cached.value
    }

    func set(_ value: String, for key: String) {
        if cache.count >= maxSize {
            let oldest = cache.min { $0.value.timestamp < $1.value.timestamp }
            if let oldestKey = oldest?.key {
                cache.removeValue(forKey: oldestKey)
            }
        }

        cache[key] = CachedResult(value: value, timestamp: Date())
    }
}
```

---

### 5. AgentAutoTrigger (自動觸發器)

**位置：** `Services/AI/Agent/AgentAutoTrigger.swift`

**現狀：**
- 監聽文獻匯入事件，自動觸發分析
- 使用 Combine 處理通知
- 用戶可設定開關

**問題：**
1. ⚠️ **無節流機制：** 大量匯入可能觸發過多任務
2. ⚠️ **記憶體洩漏風險：** Combine 訂閱未妥善管理生命週期
3. ⚠️ **無錯誤恢復：** 分析失敗後無重試

**優化建議：**

#### 建議 1：節流與批次處理
```swift
private var importBuffer: [UUID] = []
private var debounceTask: Task<Void, Never>?

private func handleImportNotification(_ notification: Notification) {
    guard isAutoAnalysisEnabled else { return }

    guard let entryIDs = notification.userInfo?[EntryImportNotificationKeys.entryIDs] as? [UUID] else {
        return
    }

    // ✅ 緩衝匯入事件
    importBuffer.append(contentsOf: entryIDs)

    // ✅ 取消之前的延遲任務
    debounceTask?.cancel()

    // ✅ 延遲 2 秒後批次處理
    debounceTask = Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        guard !Task.isCancelled else { return }

        let idsToProcess = importBuffer
        importBuffer.removeAll()

        await triggerAnalysis(for: idsToProcess)
    }
}
```

#### 建議 2：改善生命週期管理
```swift
deinit {
    // ✅ 確保取消所有訂閱
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
}
```

---

## 🧪 測試覆蓋率分析

**現有測試：**
- ✅ `LiteratureAgentTests.swift` - 484 行，涵蓋基礎功能
- ✅ `AgentTaskQueueTests.swift` - 254 行，測試佇列邏輯

**測試覆蓋情況：**

| 模組 | 覆蓋率估計 | 問題 |
|------|-----------|------|
| AgentOrchestrator | ❌ 0% | 無測試 |
| LiteratureAgent | ⚠️ ~40% | 缺少 PDF 提取、OCR、錯誤場景測試 |
| AgentTaskQueue | ✅ ~75% | 缺少並發場景測試 |
| UnifiedAIService | ❌ 0% | 無測試 |
| AgentAutoTrigger | ❌ 0% | 無測試 |
| AgentTools | ❌ 0% | 無測試 |

**建議補充測試：**

#### 1. UnifiedAIService 測試
```swift
@available(macOS 26.0, *)
final class UnifiedAIServiceTests: XCTestCase {
    var service: UnifiedAIService!

    override func setUp() {
        service = UnifiedAIService.shared
        service.clearCache()
    }

    func testSessionPoolReuse() async {
        // 測試 Session 重用
        let session1 = service.acquireSession()
        service.releaseSession(session1)

        let session2 = service.acquireSession()
        XCTAssertTrue(session1 === session2, "應重用同一 Session")
    }

    func testCacheHitRate() async {
        let key = service.cacheKey(operation: "test", input: "data")

        // Miss
        XCTAssertNil(service.getCachedResult(for: key))

        // Set
        service.cacheResult("result", for: key)

        // Hit
        XCTAssertEqual(service.getCachedResult(for: key), "result")
    }

    func testCacheSizeLimit() {
        // 測試快取大小限制
        for i in 0..<60 {
            service.cacheResult("value\(i)", for: "key\(i)")
        }

        // 應該只保留最新的 50 個
        XCTAssertLessThanOrEqual(service.resultCache.count, 50)
    }
}
```

#### 2. PDF 提取測試
```swift
@available(macOS 26.0, *)
final class PDFExtractionTests: XCTestCase {
    var agent: LiteratureAgent!

    func testExtractFromValidPDF() async throws {
        let url = Bundle(for: type(of: self)).url(forResource: "sample", withExtension: "pdf")!

        let result = try await agent.extractPDFMetadata(from: url)

        XCTAssertFalse(result.title.isEmpty)
        XCTAssertGreaterThan(result.confidence, 0.5)
    }

    func testExtractFromScannedPDF() async throws {
        // 測試 OCR 流程
        let url = Bundle(for: type(of: self)).url(forResource: "scanned", withExtension: "pdf")!

        let result = try await agent.extractPDFMetadata(from: url)

        XCTAssertFalse(result.title.isEmpty)
    }

    func testExtractFromInvalidPDF() async {
        let url = URL(fileURLWithPath: "/nonexistent.pdf")

        do {
            _ = try await agent.extractPDFMetadata(from: url)
            XCTFail("應該拋出錯誤")
        } catch {
            // Expected
        }
    }
}
```

---

## ⚡ 效能優化建議

### 1. 減少記憶體使用

**問題：** `LiteratureAgent.pendingSuggestions` 和 `UnifiedAIService.resultCache` 可能累積大量資料

**建議：**
```swift
// ✅ 使用弱引用避免循環引用
public struct AgentSuggestion: Identifiable {
    public let id = UUID()
    public weak var entry: Entry?  // 改為 weak
    public let type: SuggestionType
    public let value: String
    public let confidence: Double
}

// ✅ 定期清理過期建議
private func cleanupOldSuggestions() {
    let oneHourAgo = Date().addingTimeInterval(-3600)
    pendingSuggestions.removeAll { suggestion in
        guard let entry = suggestion.entry else { return true }  // 移除已釋放的 Entry
        return entry.updatedAt < oneHourAgo
    }
}
```

### 2. 批次處理優化

**問題：** `classifyEntriesTask` 和 `autoTagEntriesTask` 逐一處理文獻，效率低

**建議：**
```swift
// ✅ 批次處理，減少 API 呼叫
private func classifyEntriesTask(_ entries: [Entry]) async throws -> AgentResult {
    let batchSize = 10
    var allSuggestions: [AgentSuggestion] = []

    // 分批處理
    for batch in entries.chunked(into: batchSize) {
        let batchText = batch.map { "\($0.title): \($0.fields["abstract"] ?? "")" }
            .joined(separator: "\n\n---\n\n")

        // ✅ 一次 API 呼叫處理多篇文獻
        let categories = try await aiService.document.suggestCategoriesBatch(
            texts: batchText,
            count: batch.count
        )

        // 處理結果...
    }

    return AgentResult(...)
}

// 擴展 Array
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

### 3. 快取策略優化

**建議：**
```swift
// ✅ 使用分層快取
class CacheManager {
    private let l1Cache = NSCache<NSString, NSString>()  // 記憶體快取
    private let l2CachePath: URL  // 磁碟快取

    init() {
        l1Cache.countLimit = 100
        l2CachePath = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AIResults")
    }

    func get(_ key: String) -> String? {
        // L1: 檢查記憶體
        if let cached = l1Cache.object(forKey: key as NSString) {
            return cached as String
        }

        // L2: 檢查磁碟
        let filePath = l2CachePath.appendingPathComponent(key)
        if let cached = try? String(contentsOf: filePath) {
            l1Cache.setObject(cached as NSString, forKey: key as NSString)
            return cached
        }

        return nil
    }

    func set(_ value: String, for key: String) {
        l1Cache.setObject(value as NSString, forKey: key as NSString)

        // 非同步寫入磁碟
        Task.detached {
            let filePath = self.l2CachePath.appendingPathComponent(key)
            try? value.write(to: filePath, atomically: true, encoding: .utf8)
        }
    }
}
```

---

## 🔒 安全性建議

### 1. 輸入驗證

**問題：** 缺少對使用者輸入的驗證

**建議：**
```swift
// ✅ 驗證 PDF URL
private func extractPDFMetadataTask(_ url: URL) async throws -> AgentResult {
    // 驗證檔案存在
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw AgentError.taskFailed("PDF 檔案不存在: \(url.path)")
    }

    // 驗證檔案大小（避免過大檔案）
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    let fileSize = attributes[.size] as? Int64 ?? 0
    let maxSize: Int64 = 50 * 1024 * 1024  // 50 MB

    guard fileSize <= maxSize else {
        throw AgentError.taskFailed("PDF 檔案過大: \(fileSize) bytes")
    }

    // 驗證檔案類型
    guard url.pathExtension.lowercased() == "pdf" else {
        throw AgentError.taskFailed("不是 PDF 檔案")
    }

    // 繼續處理...
}
```

### 2. API Rate Limiting

**建議：**
```swift
// ✅ API 速率限制
actor RateLimiter {
    private var tokens: Int
    private let maxTokens: Int
    private let refillRate: TimeInterval
    private var lastRefill: Date

    init(maxTokens: Int = 100, refillRate: TimeInterval = 60) {
        self.tokens = maxTokens
        self.maxTokens = maxTokens
        self.refillRate = refillRate
        self.lastRefill = Date()
    }

    func acquire() async throws {
        refillTokens()

        if tokens > 0 {
            tokens -= 1
        } else {
            throw AgentError.taskFailed("API 速率限制")
        }
    }

    private func refillTokens() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        let newTokens = Int(elapsed / refillRate * Double(maxTokens))

        if newTokens > 0 {
            tokens = min(tokens + newTokens, maxTokens)
            lastRefill = now
        }
    }
}

// 在 UnifiedAIService 中使用
private let rateLimiter = RateLimiter()

func performAIRequest() async throws {
    try await rateLimiter.acquire()
    // 執行 API 呼叫
}
```

---

## 📊 效能監控建議

**建議增加效能追蹤：**

```swift
// ✅ Agent 效能監控
@MainActor
public class AgentPerformanceMonitor: ObservableObject {
    @Published public private(set) var metrics: PerformanceMetrics

    public struct PerformanceMetrics {
        var totalTasks: Int = 0
        var successfulTasks: Int = 0
        var failedTasks: Int = 0
        var averageExecutionTime: TimeInterval = 0
        var cacheHitRate: Double = 0

        var successRate: Double {
            totalTasks > 0 ? Double(successfulTasks) / Double(totalTasks) : 0
        }
    }

    func recordTaskCompletion(duration: TimeInterval, success: Bool) {
        metrics.totalTasks += 1
        if success {
            metrics.successfulTasks += 1
        } else {
            metrics.failedTasks += 1
        }

        // 更新平均執行時間（移動平均）
        metrics.averageExecutionTime = (metrics.averageExecutionTime * Double(metrics.totalTasks - 1) + duration) / Double(metrics.totalTasks)
    }
}
```

---

## 📝 優先級別建議

### 🔴 高優先級（建議立即處理）

1. **錯誤處理改善** - 避免使用 `try?` 吞掉錯誤，增加日誌記錄
2. **記憶體管理** - 限制 `pendingSuggestions` 和快取大小
3. **並發安全** - 修正 `AgentTaskQueue` 和快取的並發問題
4. **輸入驗證** - 增加 PDF 提取的輸入驗證

### 🟡 中優先級（1-2 週內處理）

1. **職責拆分** - 將 `LiteratureAgent` 拆分為更小的服務
2. **測試覆蓋率** - 補充 `UnifiedAIService` 和 PDF 提取測試
3. **效能優化** - 實作批次處理和分層快取
4. **任務取消** - 增加單一任務取消機制

### 🟢 低優先級（未來改進）

1. **重構 AgentOrchestrator** - 決定保留或移除
2. **效能監控** - 增加詳細的指標追蹤
3. **API Rate Limiting** - 防止過度呼叫
4. **進階快取策略** - 實作 L2 磁碟快取

---

## 🎯 總結

OVEREND 的 AI Agent 架構設計良好，具備清晰的分層和模組化設計。主要改進空間在於：

1. **健壯性：** 改善錯誤處理，避免靜默失敗
2. **效能：** 優化批次處理和快取策略
3. **可維護性：** 拆分過大的類別，增加測試覆蓋率
4. **並發安全：** 修正潛在的資料競爭問題

建議優先處理高優先級項目，特別是錯誤處理和記憶體管理相關的問題，以提升系統的穩定性和可靠性。

---

**報告結束**
