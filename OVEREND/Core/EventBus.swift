//
//  EventBus.swift
//  OVEREND
//
//  事件匯流排系統 - 解耦服務間通信
//  提供發布/訂閱模式的事件處理
//

import Foundation
import Combine

// MARK: - App Events

/// 應用程式事件類型
enum AppEvent {
    
    // MARK: - Library Events
    
    /// 資料庫創建
    case libraryCreated(libraryId: UUID, name: String)
    
    /// 資料庫刪除
    case libraryDeleted(libraryId: UUID)
    
    /// 資料庫更新
    case libraryUpdated(libraryId: UUID)
    
    // MARK: - Entry Events
    
    /// 文獻條目導入
    case entryImported(entryId: UUID, libraryId: UUID)
    
    /// 批量文獻導入
    case entriesImported(entryIds: [UUID], libraryId: UUID)
    
    /// 文獻條目更新
    case entryUpdated(entryId: UUID)
    
    /// 文獻條目刪除
    case entryDeleted(entryId: UUID)
    
    /// 批量刪除
    case entriesDeleted(entryIds: [UUID])
    
    // MARK: - PDF Events
    
    /// PDF 元資料抽取完成
    case pdfMetadataExtracted(entryId: UUID, success: Bool)
    
    /// PDF 全文抽取完成
    case pdfTextExtracted(entryId: UUID, textLength: Int)
    
    /// PDF 附件添加
    case pdfAttached(entryId: UUID, filePath: String)
    
    // MARK: - AI Events
    
    /// AI 分析開始
    case aiAnalysisStarted(entryId: UUID, taskType: String)
    
    /// AI 分析完成
    case aiAnalysisCompleted(entryId: UUID, taskType: String, success: Bool)
    
    /// AI 建議生成
    case aiSuggestionGenerated(entryId: UUID, suggestionType: String)
    
    // MARK: - Sync Events
    
    /// 同步開始
    case syncStarted(source: String)
    
    /// 同步完成
    case syncCompleted(source: String, success: Bool, entriesCount: Int)
    
    /// 同步失敗
    case syncFailed(source: String, error: Error)
    
    // MARK: - Document Events
    
    /// 文檔保存
    case documentSaved(documentId: UUID)
    
    /// 文檔導出
    case documentExported(documentId: UUID, format: String)
    
    // MARK: - UI Events
    
    /// 視圖切換
    case viewChanged(viewName: String)
    
    /// 選擇變更
    case selectionChanged(selectedIds: [UUID])
    
    /// 搜尋執行
    case searchPerformed(query: String, resultsCount: Int)
    
    // MARK: - System Events
    
    /// 應用啟動完成
    case appDidFinishLaunching
    
    /// 應用進入背景
    case appDidEnterBackground
    
    /// 應用將終止
    case appWillTerminate
    
    /// 記憶體警告
    case memoryWarning
}

// MARK: - Event Bus

/// 事件匯流排 - 集中式事件發布訂閱系統
final class EventBus {
    
    // MARK: - Singleton
    
    static let shared = EventBus()
    
    // MARK: - Properties
    
    /// 事件發布者
    private let eventSubject = PassthroughSubject<AppEvent, Never>()
    
    /// 事件發布者（公開）
    var publisher: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    /// 訂閱者存儲
    private var subscribers: [String: Set<AnyCancellable>] = [:]
    private let lock = NSLock()
    
    /// 事件歷史記錄（用於調試）
    private var eventHistory: [EventRecord] = []
    private let maxHistorySize = 100
    
    // MARK: - Event Record
    
    struct EventRecord {
        let event: AppEvent
        let timestamp: Date
        let thread: String
    }
    
    // MARK: - Initialization
    
    private init() {
        logInfo("EventBus initialized", category: .general)
    }
    
    // MARK: - Publish
    
    /// 發布事件
    /// - Parameter event: 要發布的事件
    func publish(_ event: AppEvent) {
        // 記錄事件
        recordEvent(event)
        
        logDebug("Publishing event: \(String(describing: event))", category: .general)
        
        // 在主線程發布 UI 相關事件
        if isUIEvent(event) {
            DispatchQueue.main.async { [weak self] in
                self?.eventSubject.send(event)
            }
        } else {
            eventSubject.send(event)
        }
    }
    
    /// 非同步發布事件
    /// - Parameter event: 要發布的事件
    func publishAsync(_ event: AppEvent) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.publish(event)
        }
    }
    
    // MARK: - Subscribe
    
    /// 訂閱所有事件
    /// - Parameters:
    ///   - subscriberId: 訂閱者 ID
    ///   - handler: 事件處理器
    /// - Returns: 可取消的訂閱
    @discardableResult
    func subscribe(
        id subscriberId: String,
        handler: @escaping (AppEvent) -> Void
    ) -> AnyCancellable {
        let cancellable = eventSubject
            .receive(on: DispatchQueue.main)
            .sink { event in
                handler(event)
            }
        
        storeSubscription(cancellable, for: subscriberId)
        return cancellable
    }
    
    /// 訂閱特定類型的事件
    /// - Parameters:
    ///   - subscriberId: 訂閱者 ID
    ///   - filter: 事件過濾器
    ///   - handler: 事件處理器
    /// - Returns: 可取消的訂閱
    @discardableResult
    func subscribe(
        id subscriberId: String,
        filter: @escaping (AppEvent) -> Bool,
        handler: @escaping (AppEvent) -> Void
    ) -> AnyCancellable {
        let cancellable = eventSubject
            .filter(filter)
            .receive(on: DispatchQueue.main)
            .sink { event in
                handler(event)
            }
        
        storeSubscription(cancellable, for: subscriberId)
        return cancellable
    }
    
    /// 訂閱 Entry 相關事件
    /// - Parameters:
    ///   - subscriberId: 訂閱者 ID
    ///   - handler: 事件處理器
    /// - Returns: 可取消的訂閱
    @discardableResult
    func subscribeToEntryEvents(
        id subscriberId: String,
        handler: @escaping (AppEvent) -> Void
    ) -> AnyCancellable {
        subscribe(id: subscriberId, filter: { event in
            switch event {
            case .entryImported, .entriesImported, .entryUpdated, .entryDeleted, .entriesDeleted:
                return true
            default:
                return false
            }
        }, handler: handler)
    }
    
    /// 訂閱 AI 相關事件
    /// - Parameters:
    ///   - subscriberId: 訂閱者 ID
    ///   - handler: 事件處理器
    /// - Returns: 可取消的訂閱
    @discardableResult
    func subscribeToAIEvents(
        id subscriberId: String,
        handler: @escaping (AppEvent) -> Void
    ) -> AnyCancellable {
        subscribe(id: subscriberId, filter: { event in
            switch event {
            case .aiAnalysisStarted, .aiAnalysisCompleted, .aiSuggestionGenerated:
                return true
            default:
                return false
            }
        }, handler: handler)
    }
    
    /// 訂閱 PDF 相關事件
    /// - Parameters:
    ///   - subscriberId: 訂閱者 ID
    ///   - handler: 事件處理器
    /// - Returns: 可取消的訂閱
    @discardableResult
    func subscribeToPDFEvents(
        id subscriberId: String,
        handler: @escaping (AppEvent) -> Void
    ) -> AnyCancellable {
        subscribe(id: subscriberId, filter: { event in
            switch event {
            case .pdfMetadataExtracted, .pdfTextExtracted, .pdfAttached:
                return true
            default:
                return false
            }
        }, handler: handler)
    }
    
    // MARK: - Unsubscribe
    
    /// 取消特定訂閱者的所有訂閱
    /// - Parameter subscriberId: 訂閱者 ID
    func unsubscribe(id subscriberId: String) {
        lock.lock()
        defer { lock.unlock() }
        
        subscribers[subscriberId]?.forEach { $0.cancel() }
        subscribers.removeValue(forKey: subscriberId)
        
        logDebug("Unsubscribed: \(subscriberId)", category: .general)
    }
    
    /// 取消所有訂閱
    func unsubscribeAll() {
        lock.lock()
        defer { lock.unlock() }
        
        subscribers.values.forEach { cancellables in
            cancellables.forEach { $0.cancel() }
        }
        subscribers.removeAll()
        
        logDebug("All subscriptions cancelled", category: .general)
    }
    
    // MARK: - Private Methods
    
    private func storeSubscription(_ cancellable: AnyCancellable, for subscriberId: String) {
        lock.lock()
        defer { lock.unlock() }
        
        if subscribers[subscriberId] == nil {
            subscribers[subscriberId] = Set<AnyCancellable>()
        }
        subscribers[subscriberId]?.insert(cancellable)
    }
    
    private func recordEvent(_ event: AppEvent) {
        lock.lock()
        defer { lock.unlock() }
        
        let record = EventRecord(
            event: event,
            timestamp: Date(),
            thread: Thread.isMainThread ? "main" : "background"
        )
        
        eventHistory.append(record)
        
        // 限制歷史記錄大小
        if eventHistory.count > maxHistorySize {
            eventHistory.removeFirst(eventHistory.count - maxHistorySize)
        }
    }
    
    private func isUIEvent(_ event: AppEvent) -> Bool {
        switch event {
        case .viewChanged, .selectionChanged, .searchPerformed:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Debug
    
    /// 獲取事件歷史（用於調試）
    func getEventHistory() -> [EventRecord] {
        lock.lock()
        defer { lock.unlock() }
        return eventHistory
    }
    
    /// 清除事件歷史
    func clearEventHistory() {
        lock.lock()
        defer { lock.unlock() }
        eventHistory.removeAll()
    }
}

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI 環境值擴展
struct EventBusKey: EnvironmentKey {
    static let defaultValue = EventBus.shared
}

extension EnvironmentValues {
    var eventBus: EventBus {
        get { self[EventBusKey.self] }
        set { self[EventBusKey.self] = newValue }
    }
}

/// SwiftUI View 擴展
extension View {
    /// 訂閱事件
    func onEvent(
        id: String = UUID().uuidString,
        filter: @escaping (AppEvent) -> Bool = { _ in true },
        perform: @escaping (AppEvent) -> Void
    ) -> some View {
        onAppear {
            EventBus.shared.subscribe(id: id, filter: filter, handler: perform)
        }
        .onDisappear {
            EventBus.shared.unsubscribe(id: id)
        }
    }
}
#endif
