//
//  AdapterManager.swift
//  OVEREND
//
//  Custom Adapter 管理器 - 管理 Foundation Models 的 LoRA Adapter
//
//  支援：
//  - 載入 Bundle 內建的 Adapter
//  - 動態下載遠端 Adapter
//  - 建立適配的 LanguageModelSession
//
//  注意：AdapterAsset API 需要 Xcode 26 beta 或更高版本
//

import Foundation
import Combine
import FoundationModels

// MARK: - Adapter 類型

/// 可用的 Adapter 類型
@available(macOS 26.0, *)
public enum AdapterType: String, CaseIterable {
    case literature = "overend_literature"      // 文獻管理專用
    case academicWriting = "academic_writing"   // 學術寫作專用
    case citation = "citation_format"           // 引用格式專用
    
    var filename: String {
        return rawValue
    }
    
    var displayName: String {
        switch self {
        case .literature:
            return "文獻管理"
        case .academicWriting:
            return "學術寫作"
        case .citation:
            return "引用格式"
        }
    }
}

// MARK: - Adapter 資訊

/// Adapter 資訊（用於追蹤已載入的 Adapter）
@available(macOS 26.0, *)
public struct AdapterInfo {
    public let type: AdapterType
    public let url: URL
    public let loadedAt: Date
    
    public init(type: AdapterType, url: URL) {
        self.type = type
        self.url = url
        self.loadedAt = Date()
    }
}

// MARK: - Adapter 管理器

/// Custom Adapter 管理器
///
/// 使用方式：
/// ```swift
/// let manager = AdapterManager.shared
///
/// // 取得帶有 Adapter 的 Session
/// let session = manager.createSession(with: .literature)
/// let response = try await session.respond(to: prompt)
/// ```
///
/// 注意：完整的 Adapter 支援需要：
/// 1. Xcode 26 或更高版本
/// 2. 已訓練的 .fmadapter 檔案
/// 3. AdapterAsset API（目前可能尚未公開）
@available(macOS 26.0, *)
@MainActor
public class AdapterManager: ObservableObject {
    
    // MARK: - 單例
    
    public static let shared = AdapterManager()
    
    // MARK: - 狀態
    
    /// 已載入的 Adapter 資訊
    @Published public private(set) var loadedAdapters: [AdapterType: AdapterInfo] = [:]
    
    /// 是否正在載入
    @Published public var isLoading: Bool = false
    
    /// 錯誤訊息
    @Published public var errorMessage: String?
    
    /// Adapter 功能是否可用
    @Published public private(set) var isAdapterAPIAvailable: Bool = false
    
    // MARK: - 增強 Prompt 模板
    
    /// 文獻分析專用 Instructions
    private let literatureInstructions = """
    你是專業的學術文獻管理專家，熟悉 APA 7、Chicago、IEEE 等引用格式。
    你擅長分析學術文獻的主題、方法論、貢獻與限制。
    
    回應規則：
    1. 使用繁體中文
    2. 保持學術嚴謹性
    3. 提供結構化的輸出
    4. 優先使用已存在的分類和標籤
    """
    
    // MARK: - 初始化
    
    private init() {
        checkAPIAvailability()
        loadBundledAdapters()
    }
    
    // MARK: - API 可用性檢查
    
    private func checkAPIAvailability() {
        // 目前 AdapterAsset API 可能尚未公開
        // 當 API 可用時，這裡會返回 true
        isAdapterAPIAvailable = false
        
        if !isAdapterAPIAvailable {
            logDebug("📦 AdapterAsset API 尚未可用，使用增強 Prompt 模式", category: .ai)
        }
    }
    
    // MARK: - 載入 Adapter
    
    /// 載入 Bundle 內建的 Adapter
    private func loadBundledAdapters() {
        for type in AdapterType.allCases {
            if let url = Bundle.main.url(forResource: type.filename, withExtension: "fmadapter") {
                loadedAdapters[type] = AdapterInfo(type: type, url: url)
                logInfo("🔌 Adapter 檔案已找到: \(type.displayName)", category: .ai)
            }
        }
        
        if loadedAdapters.isEmpty {
            logDebug("📦 尚未安裝任何 Custom Adapter", category: .ai)
        }
    }
    
    /// 從 URL 載入 Adapter
    public func loadAdapter(from url: URL, as type: AdapterType) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // 檢查檔案是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            let error = NSError(domain: "AdapterManager", code: 404, 
                              userInfo: [NSLocalizedDescriptionKey: "Adapter 檔案不存在"])
            errorMessage = error.localizedDescription
            throw error
        }
        
        loadedAdapters[type] = AdapterInfo(type: type, url: url)
        logInfo("🔌 Adapter 載入成功: \(type.displayName)", category: .ai)
    }
    
    // MARK: - 建立 Session
    
    /// 建立帶有指定 Adapter 的 Session
    ///
    /// 如果 AdapterAsset API 可用且 Adapter 已載入，會使用 Custom Adapter。
    /// 否則會建立使用增強 Instructions 的標準 Session。
    public func createSession(with type: AdapterType) -> LanguageModelSession {
        // TODO: 當 AdapterAsset API 公開時啟用
        // if isAdapterAPIAvailable, let info = loadedAdapters[type] {
        //     if let adapter = try? AdapterAsset(contentsOf: info.url) {
        //         return LanguageModelSession(adapter: adapter)
        //     }
        // }
        
        // 使用增強 Instructions 作為替代方案
        logDebug("📦 使用增強 Prompt 模式 for \(type.displayName)", category: .ai)
        return createEnhancedSession(for: type)
    }
    
    /// 建立使用增強 Instructions 的 Session
    private func createEnhancedSession(for type: AdapterType) -> LanguageModelSession {
        let instructions: String
        
        switch type {
        case .literature:
            instructions = literatureInstructions
        case .academicWriting:
            instructions = """
            你是學術寫作專家，專精於繁體中文學術文章的潤飾與改進。
            請保持客觀、嚴謹的學術風格，避免第一人稱和口語化表達。
            """
        case .citation:
            instructions = """
            你是引用格式專家，熟悉 APA 7、Chicago、IEEE、MLA 等主要引用格式。
            請確保引用格式的準確性和一致性。
            """
        }
        
        return LanguageModelSession(
            instructions: Instructions {
                instructions
            }
        )
    }
    
    /// 建立帶有文獻專用 Adapter 的 Session（便捷方法）
    public func createLiteratureSession() -> LanguageModelSession {
        return createSession(with: .literature)
    }
    
    /// 檢查 Adapter 是否已載入
    public func hasAdapter(_ type: AdapterType) -> Bool {
        return loadedAdapters[type] != nil
    }
    
    /// 取得所有可用的 Adapter
    public var availableAdapters: [AdapterType] {
        return Array(loadedAdapters.keys)
    }
}

// MARK: - UnifiedAIService Extension

@available(macOS 26.0, *)
public extension UnifiedAIService {
    
    /// 取得 Adapter 管理器
    var adapterManager: AdapterManager {
        return AdapterManager.shared
    }
    
    /// 建立帶有文獻 Adapter 的 Session
    func acquireAdaptedSession(for type: AdapterType = .literature) -> LanguageModelSession {
        return adapterManager.createSession(with: type)
    }
}
