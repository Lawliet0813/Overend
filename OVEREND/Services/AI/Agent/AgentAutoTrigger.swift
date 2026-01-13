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
    
    // MARK: - 初始化
    
    private init() {
        // 讀取用戶設定
        isAutoAnalysisEnabled = UserDefaults.standard.bool(forKey: "agentAutoAnalysisEnabled")
        
        // 預設開啟自動分析
        if !UserDefaults.standard.contains(key: "agentAutoAnalysisEnabled") {
            isAutoAnalysisEnabled = true
        }
        
        // 監聽匯入通知
        setupNotificationObserver()
        
        AppLogger.debug("📡 AgentAutoTrigger: 開始監聽匯入事件")
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
            AppLogger.debug("📡 AgentAutoTrigger: 自動分析已停用，跳過")
            return
        }
        
        guard let userInfo = notification.userInfo,
              let entryIDs = userInfo[EntryImportNotificationKeys.entryIDs] as? [UUID] else {
            return
        }
        
        let source = userInfo[EntryImportNotificationKeys.source] as? String ?? "unknown"
        
        AppLogger.aiLog("📡 收到匯入通知: \(entryIDs.count) 篇文獻 (來源: \(source))")
        
        recentImportCount = entryIDs.count
        pendingAnalysisCount += entryIDs.count
        
        // 非同步觸發分析
        Task {
            await triggerAnalysis(for: entryIDs)
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
        
        AppLogger.aiLog("🤖 開始自動分析 \(entries.count) 篇文獻...")
        
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
            
            AppLogger.success("🤖 自動分析完成: \(result.suggestions.count) 個建議")
            
        } catch {
            pendingAnalysisCount = 0
            AppLogger.error("🤖 自動分析失敗: \(error.localizedDescription)")
        }
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
