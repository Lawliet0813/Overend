//
//  CloudSyncManager.swift
//  OVEREND
//
//  iCloud 同步管理器
//  處理 CloudKit 同步、衝突解決和錯誤處理
//

import Foundation
import CoreData
import CloudKit
import Combine

/// iCloud 同步狀態
enum CloudSyncStatus {
    case notStarted
    case inProgress
    case success(Date)
    case failed(Error)
    case noAccount
}

/// iCloud 同步管理器
@MainActor
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var syncStatus: CloudSyncStatus = .notStarted
    @Published var lastSyncTime: Date?
    @Published var isSyncing: Bool = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    
    private var cancellables = Set<AnyCancellable>()
    private let container = CKContainer.default()
    
    private init() {
        setupNotificationObservers()
        checkAccountStatus()
    }
    
    // MARK: - 通知監聽
    
    private func setupNotificationObservers() {
        // 監聽遠端變更
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.lastSyncTime = Date()
                    self?.isSyncing = false
                    self?.syncStatus = .success(Date())
                    #if DEBUG
                    print("☁️ iCloud: 收到遠端變更通知")
                    #endif
                }
            }
            .store(in: &cancellables)
        
        // 監聽 CloudKit 事件
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .compactMap { notification in
                notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] 
                    as? NSPersistentCloudKitContainer.Event
            }
            .sink { [weak self] event in
                Task { @MainActor in
                    self?.handleCloudKitEvent(event)
                }
            }
            .store(in: &cancellables)
        
        // 監聽 iCloud 帳號變更
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkAccountStatus()
                    #if DEBUG
                    print("☁️ iCloud: 帳號狀態可能已變更")
                    #endif
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CloudKit 事件處理
    
    private func handleCloudKitEvent(_ event: NSPersistentCloudKitContainer.Event) {
        #if DEBUG
        print("☁️ CloudKit Event:")
        print("  - Type: \(event.type.rawValue)")
        print("  - Start: \(event.startDate)")
        print("  - End: \(event.endDate?.description ?? "進行中")")
        if let error = event.error {
            print("  - Error: \(error.localizedDescription)")
        }
        #endif
        
        if event.endDate == nil {
            // 事件正在進行
            isSyncing = true
            syncStatus = .inProgress
        } else {
            // 事件已結束
            isSyncing = false
            
            if let error = event.error {
                syncStatus = .failed(error)
                handleSyncError(error)
            } else {
                if event.type == .import || event.type == .export {
                    lastSyncTime = event.endDate
                    syncStatus = .success(event.endDate!)
                }
            }
        }
    }
    
    // MARK: - 帳號狀態檢查
    
    func checkAccountStatus() {
        Task {
            do {
                let status = try await container.accountStatus()
                await MainActor.run {
                    self.accountStatus = status
                    
                    #if DEBUG
                    print("☁️ iCloud 帳號狀態: \(self.accountStatusString(status))")
                    #endif
                    
                    if status != .available {
                        self.syncStatus = .noAccount
                    }
                }
            } catch {
                #if DEBUG
                print("❌ 無法檢查 iCloud 帳號狀態: \(error)")
                #endif
            }
        }
    }
    
    private func accountStatusString(_ status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "可用"
        case .noAccount:
            return "未登入"
        case .restricted:
            return "受限"
        case .couldNotDetermine:
            return "無法確定"
        case .temporarilyUnavailable:
            return "暫時不可用"
        @unknown default:
            return "未知"
        }
    }
    
    // MARK: - 錯誤處理
    
    private func handleSyncError(_ error: Error) {
        let nsError = error as NSError
        
        #if DEBUG
        print("❌ CloudKit 同步錯誤:")
        print("  - Domain: \(nsError.domain)")
        print("  - Code: \(nsError.code)")
        print("  - Description: \(nsError.localizedDescription)")
        #endif
        
        // 處理常見錯誤
        if nsError.domain == CKErrorDomain {
            handleCloudKitError(nsError)
        }
    }
    
    private func handleCloudKitError(_ error: NSError) {
        guard let ckError = CKError.Code(rawValue: error.code) else { return }
        
        switch ckError {
        case .networkUnavailable, .networkFailure:
            #if DEBUG
            print("⚠️ 網路不可用，將在網路恢復後自動同步")
            #endif
            
        case .notAuthenticated:
            #if DEBUG
            print("⚠️ iCloud 未登入")
            #endif
            checkAccountStatus()
            
        case .quotaExceeded:
            #if DEBUG
            print("⚠️ iCloud 儲存空間已滿")
            #endif
            
        case .serverRecordChanged:
            #if DEBUG
            print("⚠️ 伺服器記錄已變更，Core Data 將自動處理衝突")
            #endif
            
        default:
            #if DEBUG
            print("⚠️ 其他 CloudKit 錯誤: \(ckError)")
            #endif
        }
    }
    
    // MARK: - 手動同步
    
    /// 觸發手動同步
    func triggerManualSync() {
        let context = PersistenceController.shared.container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                #if DEBUG
                print("☁️ 手動觸發同步")
                #endif
            } catch {
                #if DEBUG
                print("❌ 手動同步失敗: \(error)")
                #endif
                syncStatus = .failed(error)
            }
        } else {
            #if DEBUG
            print("ℹ️ 沒有待同步的變更")
            #endif
        }
    }
    
    // MARK: - 同步狀態查詢
    
    /// 檢查是否有待同步的變更
    func hasPendingChanges() -> Bool {
        return PersistenceController.shared.container.viewContext.hasChanges
    }
    
    /// 獲取同步狀態描述
    func statusDescription() -> String {
        switch syncStatus {
        case .notStarted:
            return "尚未開始"
        case .inProgress:
            return "同步中..."
        case .success(let date):
            return "上次同步: \(formatDate(date))"
        case .failed(let error):
            return "同步失敗: \(error.localizedDescription)"
        case .noAccount:
            return "iCloud 帳號不可用"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
