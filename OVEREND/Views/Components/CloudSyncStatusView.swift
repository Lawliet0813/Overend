//
//  CloudSyncStatusView.swift
//  OVEREND
//
//  iCloud 同步狀態顯示視圖
//

import SwiftUI
import CoreData

struct CloudSyncStatusView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var lastSyncTime: Date?
    @State private var isSyncing: Bool = false
    @State private var syncError: String?
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            if isSyncing {
                ProgressView()
                    .controlSize(.small)
                Text("正在同步...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let error = syncError {
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.red)
                Text("同步錯誤")
                    .font(.caption)
                    .foregroundColor(.red)
                    .help(error)
            } else {
                Image(systemName: "icloud")
                    .foregroundColor(.green)
                    .symbolEffect(.pulse, isActive: isSyncing)
                if let lastSync = lastSyncTime {
                    Text("上次同步: \(formatDate(lastSync))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("iCloud 已啟用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 手動同步按鈕（懸停時顯示）
            if isHovering {
                Button(action: triggerManualSync) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("手動同步")
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
        .onHover { hovering in
            isHovering = hovering
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
            // 收到遠端變更通知，更新同步時間
            self.lastSyncTime = Date()
            self.isSyncing = false
            #if DEBUG
            print("☁️ iCloud: 收到遠端變更")
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)) { notification in
            // 監聽 CloudKit 容器事件
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
                return
            }
            
            #if DEBUG
            print("☁️ CloudKit Event: \(event.type.rawValue), Ended: \(event.endDate != nil)")
            #endif
            
            if event.endDate == nil {
                self.isSyncing = true
            } else {
                self.isSyncing = false
                if let error = event.error {
                    self.syncError = error.localizedDescription
                    #if DEBUG
                    print("❌ CloudKit Error: \(error)")
                    #endif
                } else {
                    self.syncError = nil
                    if event.type == .import {
                        self.lastSyncTime = event.endDate
                    }
                }
            }
        }
        .onAppear {
            // 檢查 iCloud 帳號狀態
            checkICloudStatus()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func triggerManualSync() {
        // 觸發手動同步（保存上下文）
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                #if DEBUG
                print("☁️ 手動觸發同步")
                #endif
            } catch {
                #if DEBUG
                print("❌ 同步失敗: \(error)")
                #endif
            }
        }
    }
    
    private func checkICloudStatus() {
        Task {
            let container = CKContainer.default()
            do {
                let status = try await container.accountStatus()
                #if DEBUG
                switch status {
                case .available:
                    print("✅ iCloud 帳號可用")
                case .noAccount:
                    print("⚠️ 未登入 iCloud 帳號")
                case .restricted:
                    print("⚠️ iCloud 受限")
                case .couldNotDetermine:
                    print("⚠️ 無法確定 iCloud 狀態")
                case .temporarilyUnavailable:
                    print("⚠️ iCloud 暫時不可用")
                @unknown default:
                    print("⚠️ 未知的 iCloud 狀態")
                }
                #endif
                
                if status != .available {
                    await MainActor.run {
                        self.syncError = "iCloud 帳號不可用，請在系統設置中登入"
                    }
                }
            } catch {
                #if DEBUG
                print("❌ 無法檢查 iCloud 狀態: \(error)")
                #endif
            }
        }
    }
}

// 導入 CloudKit 用於帳號狀態檢查
import CloudKit

#Preview {
    CloudSyncStatusView()
}
