//
//  AgentAutoTrigger.swift
//  OVEREND
//
//  Agent 自動觸發器 - 監聽匯入事件並觸發 Agent 分析
//
//  當有新文獻匯入時，自動進行：
//  - 關鍵詞提取
//  - 分類建議
//  - 標籤建議
//

import Foundation
import CoreData
import Combine

// MARK: - 通知名稱

extension Notification.Name {
    /// 文獻匯入完成通知
    static let entriesDidImport = Notification.Name("entriesDidImport")
    
    /// Agent 分析完成通知
    static let agentAnalysisComplete = Notification.Name("agentAnalysisComplete")
    
    // MARK: - App Navigation
    
    /// 顯示新增文件視圖
    static let showNewDocument = Notification.Name("showNewDocument")
    
    /// 切換到文獻庫
    static let switchToLibrary = Notification.Name("switchToLibrary")
    
    /// 顯示 AI 助手
    static let showAIAssistant = Notification.Name("showAIAssistant")
    
    /// 開啟 PDF 檔案
    static let openPDFFile = Notification.Name("openPDFFile")
    
    /// 快速搜尋
    static let quickSearch = Notification.Name("quickSearch")
}

// MARK: - 通知 UserInfo Keys

struct EntryImportNotificationKeys {
    /// 匯入的 Entry IDs (型別: [UUID])
    static let entryIDs = "entryIDs"
    
    /// 匯入的 Library ID (型別: UUID)
    static let libraryID = "libraryID"
    
    /// 匯入來源 (型別: String)
    static let source = "source"
}

/// 匯入來源類型
public enum ImportSource: String {
    case bibtex = "bibtex"
    case pdf = "pdf"
    case manual = "manual"
    case doi = "doi"
    case ris = "ris"
    case zotero = "zotero"
}

// MARK: - Agent 自動觸發器

/// 監聽匯入事件並自動觸發 Agent 分析
@available(macOS 26.0, *)
@MainActor
public class AgentAutoTrigger: ObservableObject {
    
    // MARK: - 單例
    
    public static let shared = AgentAutoTrigger()
    
    // MARK: - 發布屬性
    
    /// 是否啟用自動分析
    @Published public var isAutoAnalysisEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAutoAnalysisEnabled, forKey: "agentAutoAnalysisEnabled")
        }
    }
    
    /// 最近匯入的文獻數量
    @Published public var recentImportCount: Int = 0

    /// 待分析的文獻數量
    @Published public var pendingAnalysisCount: Int = 0

    // MARK: - 私有屬性

    private var cancellables = Set<AnyCancellable>()
    private let agent = LiteratureAgent.shared

    /// ✅ 匯入緩衝區（用於批次處理）
    private var importBuffer: [UUID] = []

    /// ✅ 防抖任務
    private var debounceTask: Task<Void, Never>?

    /// ✅ 防抖延遲（秒）
    private let debounceDelay: TimeInterval = 2.0
    
    // MARK: - 初始化
    
    private init() {
        // 檢測是否在測試環境中
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        
        // 讀取用戶設定
        isAutoAnalysisEnabled = UserDefaults.standard.bool(forKey: "agentAutoAnalysisEnabled")
        
        // 預設開啟自動分析，但在測試環境中強制關閉
        if !UserDefaults.standard.contains(key: "agentAutoAnalysisEnabled") {
            isAutoAnalysisEnabled = !isTesting
        }
        
        if isTesting {
            isAutoAnalysisEnabled = false
            AppLogger.shared.debug("📡 AgentAutoTrigger: 測試環境，自動分析已停用")
            return
        }
        
        // 監聽匯入通知
        setupNotificationObserver()
        
        AppLogger.shared.debug("📡 AgentAutoTrigger: 開始監聽匯入事件")
    }
    
    // MARK: - 設置監聽
    
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: .entriesDidImport)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleImportNotification(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 處理匯入通知

    private func handleImportNotification(_ notification: Notification) {
        guard isAutoAnalysisEnabled else {
            AppLogger.shared.debug("📡 AgentAutoTrigger: 自動分析已停用，跳過")
            return
        }

        guard let userInfo = notification.userInfo,
              let entryIDs = userInfo[EntryImportNotificationKeys.entryIDs] as? [UUID] else {
            return
        }

        let source = userInfo[EntryImportNotificationKeys.source] as? String ?? "unknown"

        AppLogger.shared.info("📡 收到匯入通知: \(entryIDs.count) 篇文獻 (來源: \(source))")

        recentImportCount = entryIDs.count

        // ✅ 使用防抖機制：緩衝匯入事件，延遲批次處理
        importBuffer.append(contentsOf: entryIDs)
        pendingAnalysisCount = importBuffer.count

        // 取消之前的防抖任務
        debounceTask?.cancel()

        // 建立新的防抖任務
        debounceTask = Task { [weak self] in
            guard let self = self else { return }

            // 等待防抖延遲
            try? await Task.sleep(nanoseconds: UInt64(self.debounceDelay * 1_000_000_000))

            // 檢查任務是否被取消
            guard !Task.isCancelled else { return }

            // 取出所有緩衝的 ID
            let idsToProcess = self.importBuffer
            self.importBuffer.removeAll()

            AppLogger.shared.info("📡 批次處理 \(idsToProcess.count) 篇文獻")

            await self.triggerAnalysis(for: idsToProcess)
        }
    }
    
    // MARK: - 觸發分析

    private func triggerAnalysis(for entryIDs: [UUID]) async {
        let context = PersistenceController.shared.container.viewContext

        // 載入 Entry 物件
        let entries = entryIDs.compactMap { id -> Entry? in
            let request: NSFetchRequest<Entry> = Entry.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            return try? context.fetch(request).first
        }

        guard !entries.isEmpty else {
            pendingAnalysisCount = 0
            return
        }

        AppLogger.shared.info("🤖 開始自動分析 \(entries.count) 篇文獻...")

        // ✅ 加入重試機制
        var attempt = 0
        let maxRetries = 2
        var lastError: Error?

        while attempt <= maxRetries {
            do {
                // 執行分析任務
                let result = try await agent.execute(task: .classifyEntries(entries))

                pendingAnalysisCount = 0

                // 發送分析完成通知
                NotificationCenter.default.post(
                    name: .agentAnalysisComplete,
                    object: nil,
                    userInfo: [
                        "entryCount": entries.count,
                        "suggestionCount": result.suggestions.count,
                        "success": result.success
                    ]
                )

                AppLogger.shared.notice("🤖 自動分析完成: \(result.suggestions.count) 個建議")
                return  // 成功，退出

            } catch {
                lastError = error
                attempt += 1

                if attempt <= maxRetries {
                    AppLogger.shared.warning("🤖 自動分析失敗 (嘗試 \(attempt)/\(maxRetries + 1)): \(error.localizedDescription)")

                    // ✅ 指數退避
                    let delay = pow(2.0, Double(attempt - 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        // 所有嘗試都失敗
        pendingAnalysisCount = 0
        AppLogger.shared.error("🤖 自動分析失敗（已重試 \(maxRetries) 次）: \(lastError?.localizedDescription ?? "未知錯誤")")
    }
    
    // MARK: - 公開方法
    
    /// 手動觸發分析
    public func manuallyTriggerAnalysis(for entries: [Entry]) async {
        guard !entries.isEmpty else { return }
        
        pendingAnalysisCount = entries.count
        await triggerAnalysis(for: entries.map { $0.id })
    }
    
    /// 發送匯入完成通知（供其他模組呼叫）
    public static func notifyImport(entryIDs: [UUID], libraryID: UUID, source: ImportSource) {
        NotificationCenter.default.post(
            name: .entriesDidImport,
            object: nil,
            userInfo: [
                EntryImportNotificationKeys.entryIDs: entryIDs,
                EntryImportNotificationKeys.libraryID: libraryID,
                EntryImportNotificationKeys.source: source.rawValue
            ]
        )
    }
}

// MARK: - UserDefaults 擴展

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
