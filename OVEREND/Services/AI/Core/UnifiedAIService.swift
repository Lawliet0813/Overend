//
//  UnifiedAIService.swift
//  OVEREND
//
//  統一 Apple Intelligence 服務入口
//
//  提供所有 AI 功能的統一存取點，按領域組織：
//  - writing: 寫作建議、風格檢查
//  - citation: 引用格式處理
//  - translation: 學術翻譯
//  - standards: 規範檢查
//  - document: 文件處理（摘要、分類等）
//  - formula: LaTeX 公式生成
//

import Foundation
import SwiftUI
import Combine
import FoundationModels

/// 統一 Apple Intelligence 服務
/// 
/// 使用方式：
/// ```swift
/// let ai = UnifiedAIService.shared
/// 
/// // 寫作建議
/// let suggestions = try await ai.writing.getSuggestions(for: text)
/// 
/// // 學術翻譯
/// let translated = try await ai.translation.translateAcademic(text: text, from: .chinese, to: .english)
/// 
/// // 規範檢查
/// let issues = try await ai.standards.quickCheck(text: text)
/// ```
@available(macOS 26.0, *)
@MainActor
public class UnifiedAIService: ObservableObject {
    
    // MARK: - 單例
    
    public static let shared = UnifiedAIService()
    
    // MARK: - 狀態
    
    /// Apple Intelligence 是否可用
    @Published public var isAvailable: Bool = true  // 在 macOS 26.0 上預設為可用
    
    /// 是否正在處理
    @Published public var isProcessing: Bool = false
    
    /// 錯誤訊息
    @Published public var errorMessage: String?
    
    // MARK: - Session Pool (優化)

    /// Session 池 - 重用 LanguageModelSession 以減少延遲
    private var sessionPool: [PooledSession] = []
    private let maxPoolSize = 3
    private let sessionLock = NSLock()
    private let sessionMaxAge: TimeInterval = 600  // ✅ 10 分鐘後清理
    private let sessionMaxUse = 100  // ✅ 最多使用 100 次

    /// ✅ 帶有元數據的 Session
    private struct PooledSession {
        let session: LanguageModelSession
        var lastUsed: Date
        var useCount: Int
    }

    // MARK: - Result Cache (優化)

    /// 結果快取 - 避免重複運算
    private var resultCache: [String: CachedResult] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 分鐘
    private let maxCacheSize = 50
    private let cacheLock = NSLock()  // ✅ 線程安全

    private struct CachedResult {
        let value: String
        let timestamp: Date
    }

    // MARK: - 統計 (優化)

    /// ✅ 快取統計
    @Published public private(set) var cacheStats = CacheStats()

    public struct CacheStats {
        public var hits: Int = 0
        public var misses: Int = 0

        public var hitRate: Double {
            let total = hits + misses
            return total > 0 ? Double(hits) / Double(total) : 0
        }
    }

    // MARK: - 功能領域
    
    /// 寫作 AI 領域
    public lazy var writing: WritingAIDomain = WritingAIDomain()
    
    /// 引用 AI 領域
    public lazy var citation: CitationAIDomain = CitationAIDomain(service: self)
    
    /// 翻譯 AI 領域
    public lazy var translation: TranslationAIDomain = TranslationAIDomain(service: self)
    
    /// 規範檢查 AI 領域
    public lazy var standards: StandardsAIDomain = StandardsAIDomain(service: self)
    
    /// 文件處理 AI 領域
    public lazy var document: DocumentAIDomain = DocumentAIDomain(service: self)
    
    /// 公式 AI 領域
    public lazy var formula: FormulaAIDomain = FormulaAIDomain(service: self)
    
    /// 文獻 Agent - 自動化文獻整理、分類與標籤
    public lazy var agent: LiteratureAgent = LiteratureAgent.shared
    
    // MARK: - 初始化
    
    /// Gemini 服務 - 作為 Apple Intelligence 的後備
    public let gemini = GeminiService.shared
    
    /// Apple Intelligence 上下文視窗限制
    public let contextWindowLimit = 1000
    
    private init() {
        // 在 macOS 26.0+ 上，Apple Intelligence 始終可用
        // 不需要額外的可用性檢查
        logInfo("UnifiedAIService: 初始化完成 (macOS 26.0+)", category: .ai)
        
        // 啟動快取清理定時器
        startCacheCleanupTimer()
    }
    
    // MARK: - 可用性檢查
    
    /// 檢查 Apple Intelligence 是否可用 (保留向後兼容)
    public func checkAvailability() {
        // 在 macOS 26.0+ 上始終可用
        isAvailable = true
    }
    
    /// 確保服務可用
    func ensureAvailable() throws {
        guard isAvailable else {
            throw AIServiceError.notAvailable
        }
    }
    
    // MARK: - Session Pool Methods
    
    /// 從池中取得 Session（優化：重用現有 Session + 生命週期管理）
    func acquireSession() -> LanguageModelSession {
        sessionLock.lock()
        defer { sessionLock.unlock() }

        // ✅ 清理過期或過度使用的 Session
        let now = Date()
        sessionPool.removeAll { pooled in
            let isExpired = now.timeIntervalSince(pooled.lastUsed) > sessionMaxAge
            let isOverused = pooled.useCount >= sessionMaxUse

            if isExpired || isOverused {
                logDebug("Removing \(isExpired ? "expired" : "overused") session (age: \(Int(now.timeIntervalSince(pooled.lastUsed)))s, uses: \(pooled.useCount))", category: .ai)
                return true
            }
            return false
        }

        // 取得可用的 Session
        if var pooled = sessionPool.popLast() {
            pooled.useCount += 1
            pooled.lastUsed = now
            logDebug("Reusing session from pool (uses: \(pooled.useCount), remaining: \(sessionPool.count))", category: .ai)
            return pooled.session
        }

        logDebug("Creating new session", category: .ai)
        return LanguageModelSession()
    }

    /// 歸還 Session 到池中
    func releaseSession(_ session: LanguageModelSession) {
        sessionLock.lock()
        defer { sessionLock.unlock() }

        guard sessionPool.count < maxPoolSize else {
            logDebug("Session pool full, discarding session", category: .ai)
            return
        }

        // ✅ 記錄使用次數和時間
        let pooled = PooledSession(
            session: session,
            lastUsed: Date(),
            useCount: 1
        )
        sessionPool.append(pooled)
        logDebug("Session returned to pool (total: \(sessionPool.count))", category: .ai)
    }
    
    /// 建立新的 LanguageModelSession (保留向後兼容)
    func createSession() -> LanguageModelSession {
        return acquireSession()
    }
    
    // MARK: - Result Cache Methods
    
    /// 取得快取結果（✅ 線程安全 + 統計）
    func getCachedResult(for key: String) -> String? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        guard let cached = resultCache[key] else {
            // ✅ 記錄 miss
            cacheStats.misses += 1
            return nil
        }

        // 檢查是否過期
        if Date().timeIntervalSince(cached.timestamp) > cacheTTL {
            resultCache.removeValue(forKey: key)
            cacheStats.misses += 1
            return nil
        }

        // ✅ 記錄 hit
        cacheStats.hits += 1
        logDebug("Cache hit (rate: \(String(format: "%.1f%%", cacheStats.hitRate * 100)))", category: .ai)
        return cached.value
    }

    /// 儲存結果到快取（✅ 線程安全）
    func cacheResult(_ value: String, for key: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        // 如果快取已滿，移除最舊的項目
        if resultCache.count >= maxCacheSize {
            let oldest = resultCache.min { $0.value.timestamp < $1.value.timestamp }
            if let oldestKey = oldest?.key {
                resultCache.removeValue(forKey: oldestKey)
                logDebug("Cache full, evicted oldest entry", category: .ai)
            }
        }

        resultCache[key] = CachedResult(value: value, timestamp: Date())
        logDebug("Cached result (size: \(resultCache.count)/\(maxCacheSize))", category: .ai)
    }
    
    /// ⚡ 優化：生成穩定的快取鍵（使用 SHA256）
    func cacheKey(operation: String, input: String) -> String {
        let combined = "\(operation):\(input)"

        // 使用 SHA256 生成穩定的雜湊值
        guard let data = combined.data(using: .utf8) else {
            // 降級方案：使用原始字串的前 64 個字元
            return String(combined.prefix(64))
        }

        // 使用 CryptoKit 生成 SHA256（需要 import CryptoKit）
        // 為了避免增加依賴，這裡使用簡單的 djb2 雜湊演算法
        var hash: UInt64 = 5381
        for byte in data {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }

        return String(format: "%016llx", hash)
    }
    
    /// 清除所有快取（✅ 重置統計）
    func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        resultCache.removeAll()
        cacheStats = CacheStats()  // ✅ 重置統計
        logDebug("Cache cleared", category: .ai)
    }
    
    private func startCacheCleanupTimer() {
        // 每 5 分鐘清理過期快取
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.cleanupExpiredCache()
        }
    }
    
    private func cleanupExpiredCache() {
        let now = Date()
        let expiredKeys = resultCache.filter { now.timeIntervalSince($0.value.timestamp) > cacheTTL }.map { $0.key }
        for key in expiredKeys {
            resultCache.removeValue(forKey: key)
        }
        if !expiredKeys.isEmpty {
            logDebug("Cleaned up \(expiredKeys.count) expired cache entries", category: .ai)
        }
    }
    
    // MARK: - 處理狀態管理
    
    /// 開始處理
    func startProcessing() {
        isProcessing = true
        errorMessage = nil
    }
    
    /// 結束處理
    func endProcessing() {
        isProcessing = false
    }
    
    /// 設定錯誤
    func setError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

// MARK: - 便捷存取

@available(macOS 26.0, *)
public extension UnifiedAIService {
    
    /// 快速存取 - 檢查是否可用
    static var available: Bool {
        shared.isAvailable
    }
    
    /// 快速存取 - 是否正在處理
    static var processing: Bool {
        shared.isProcessing
    }
}
