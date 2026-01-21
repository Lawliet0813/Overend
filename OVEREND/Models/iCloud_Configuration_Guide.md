# iCloud + Core Data 配置指南

本文檔說明如何在 macOS 上為 OVEREND 啟用 iCloud 同步功能。

## 📋 前置要求

1. **Apple Developer 帳號**（免費或付費都可以）
2. **macOS 開發環境**（Xcode 15+）
3. **iCloud 帳號**（用於測試）

## 🛠️ Xcode 配置步驟

### 步驟 1：添加 Signing & Capabilities

1. 在 Xcode 中打開專案
2. 選擇你的 Target（OVEREND）
3. 切換到 **Signing & Capabilities** 標籤
4. 點擊 **+ Capability** 按鈕

### 步驟 2：添加 iCloud 能力

1. 搜尋並添加 **iCloud**
2. 在 iCloud 設置中，勾選：
   - ✅ **CloudKit**
   - ✅ **CloudKit Database** (選擇 Private Database)
3. 在 Containers 列表中，確保有：
   - `iCloud.$(CFBundleIdentifier)` 或
   - `iCloud.你的Bundle ID`（例如：`iCloud.com.lawliet.OVEREND`）

### 步驟 3：配置 Entitlements

確保你的專案已設置 Entitlements 文件：

1. 在專案設置中，找到 **Build Settings**
2. 搜尋 **Code Signing Entitlements**
3. 設置為：`OVEREND.entitlements`

**OVEREND.entitlements** 檔案應該包含：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- iCloud 容器 -->
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.$(CFBundleIdentifier)</string>
    </array>
    
    <!-- iCloud 服務 -->
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
        <string>CloudDocuments</string>
    </array>
    
    <!-- App 沙盒 -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- 網路訪問 -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- 檔案訪問 -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

### 步驟 4：驗證 Bundle ID

1. 在專案設置中，確認 **Bundle Identifier** 設置正確
2. 例如：`com.lawliet.OVEREND`
3. CloudKit Container 將會是：`iCloud.com.lawliet.OVEREND`

## ✅ 已完成的程式碼配置

以下功能已在程式碼中實現：

### 1. PersistenceController.swift
- ✅ 使用 `NSPersistentCloudKitContainer`
- ✅ 啟用 Persistent History Tracking
- ✅ 啟用遠端變更通知
- ✅ 自動合併變更
- ✅ 衝突解決策略

### 2. CloudSyncManager.swift
- ✅ 同步狀態監控
- ✅ iCloud 帳號狀態檢查
- ✅ 錯誤處理和重試邏輯
- ✅ 手動同步觸發

### 3. CloudSyncStatusView.swift
- ✅ UI 狀態顯示
- ✅ 即時同步指示器
- ✅ 錯誤提示
- ✅ 手動同步按鈕

## 🧪 測試 iCloud 同步

### 1. 本機測試

運行 App 並檢查控制台輸出：

```
✅ iCloud 帳號可用
📦 CloudKit Container: iCloud.com.lawliet.OVEREND
☁️ CloudKit Event: setup, Ended: true
```

### 2. 多設備測試

1. 在第一台 Mac 上運行 App，創建一些數據
2. 等待數據同步到 iCloud（查看狀態指示器）
3. 在第二台 Mac 上登入同一個 iCloud 帳號
4. 運行 App，數據應該自動下載

### 3. CloudKit Dashboard

1. 訪問：https://icloud.developer.apple.com/dashboard/
2. 選擇你的 Container
3. 查看 **Data** → **Default Zone**
4. 你應該能看到同步的記錄（如 `CD_Library`、`CD_Entry` 等）

## 🐛 常見問題排查

### 問題 1：同步狀態顯示「iCloud 帳號不可用」

**解決方案：**
1. 打開 **系統設置** → **Apple ID**
2. 確認已登入 iCloud
3. 確認 **iCloud Drive** 已啟用

### 問題 2：數據沒有同步

**檢查清單：**
- ✅ 已在 Xcode 中啟用 iCloud Capability
- ✅ Bundle ID 和 CloudKit Container 匹配
- ✅ 已登入 iCloud 帳號
- ✅ 網路連線正常
- ✅ 檢查控制台是否有錯誤訊息

### 問題 3：CloudKit 錯誤代碼

常見錯誤及解決方案：

| 錯誤 | 說明 | 解決方案 |
|-----|------|---------|
| `CKErrorNotAuthenticated` | 未登入 iCloud | 登入 iCloud 帳號 |
| `CKErrorNetworkFailure` | 網路問題 | 檢查網路連線 |
| `CKErrorQuotaExceeded` | iCloud 空間已滿 | 清理 iCloud 儲存空間 |
| `CKErrorServerRecordChanged` | 記錄衝突 | Core Data 會自動處理 |

## 📱 在 UI 中顯示同步狀態

在你的主視圖中添加同步狀態視圖：

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            // 你的主要內容
            
            Spacer()
            
            // 同步狀態指示器
            CloudSyncStatusView()
                .padding()
        }
    }
}
```

或者使用 CloudSyncManager：

```swift
import SwiftUI

struct SettingsView: View {
    @StateObject private var syncManager = CloudSyncManager.shared
    
    var body: some View {
        Form {
            Section("iCloud 同步") {
                HStack {
                    Text("狀態")
                    Spacer()
                    Text(syncManager.statusDescription())
                        .foregroundColor(.secondary)
                }
                
                if syncManager.accountStatus == .available {
                    Button("手動同步") {
                        syncManager.triggerManualSync()
                    }
                    .disabled(syncManager.isSyncing)
                } else {
                    Text("請在系統設置中登入 iCloud")
                        .foregroundColor(.red)
                }
            }
        }
    }
}
```

## 🔐 隱私和安全

- ✅ 所有數據都儲存在用戶的**私人 CloudKit 容器**中
- ✅ 數據已加密傳輸和儲存
- ✅ 只有用戶本人可以訪問自己的數據
- ✅ 符合 Apple 的隱私政策

## 📚 進階功能

### 自定義同步行為

如需更細緻的控制，可以在 `PersistenceController.swift` 中調整：

```swift
// 只同步特定實體
let description = container.persistentStoreDescriptions.first
description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.lawliet.OVEREND"
)

// 設置同步模式（預設是自動）
// description?.setOption(NSNumber(value: true), forKey: NSPersistentCloudKitContainerOptionsKey)
```

### 處理同步衝突

Core Data + CloudKit 會自動處理大部分衝突。如需自定義策略：

```swift
// 在 PersistenceController 中
container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

// 可選的衝突策略：
// - NSMergeByPropertyStoreTrumpMergePolicy：伺服器優先
// - NSMergeByPropertyObjectTrumpMergePolicy：本地優先
// - NSOverwriteMergePolicy：覆寫
// - NSRollbackMergePolicy：回滾
```

## 🎉 完成！

現在你的 OVEREND App 已經完全支援 iCloud 同步！

數據將自動在所有登入同一 iCloud 帳號的 Mac 之間同步。

---

**提示：** 在正式發布前，建議在多台設備上徹底測試同步功能。
