# 在 Xcode 中添加 iPad Target

這份指南說明如何在 Xcode 中為 OVEREND 專案添加 iPad target。

## 步驟 1：打開專案

1. 在 Xcode 中開啟 `/Users/lawliet/OVEREND/OVEREND.xcodeproj`

## 步驟 2：添加新 Target

1. 在 **Project Navigator** 中點擊專案文件 (藍色圖標的 OVEREND)
2. 在編輯區域，點擊左下角的 **"+"** 按鈕
3. 選擇 **iOS > App**
4. 點擊 **Next**

## 步驟 3：配置 Target 設定

填入以下資訊：

| 欄位 | 值 |
|------|-----|
| **Product Name** | `OVEREND iPad` |
| **Team** | 選擇您的開發團隊 (M74G8Q369T) |
| **Organization Identifier** | `com.overend` |
| **Bundle Identifier** | `com.overend.OVEREND-iPad` (自動生成) |
| **Interface** | SwiftUI |
| **Language** | Swift |
| **Storage** | Core Data ❌ (不勾選，使用共享的) |
| **Include Tests** | 勾選 (可選) |

1. 點擊 **Finish**

## 步驟 4：配置 Build Settings

1. 選擇新創建的 **OVEREND iPad** target
2. 進入 **Build Settings** 標籤
3. 搜尋並設定：

| 設定 | 值 |
|------|-----|
| **iOS Deployment Target** | `18.0` |
| **Targeted Device Families** | `iPad` (2) |
| **Swift Language Version** | `5.0` |

## 步驟 5：配置檔案關聯

### 5a. 排除 iPad 專屬檔案從 macOS Target

1. 選擇 **OVEREND** (macOS) target
2. 進入 **Build Phases** > **Compile Sources**
3. 確認以下檔案 **不包含** 在 macOS target 中：
   - `Platform/iPad/*` (所有 iPad 資料夾內的檔案)

### 5b. 設定 iPad Target 的檔案

1. 選擇 **OVEREND iPad** target
2. 進入 **Build Phases** > **Compile Sources**
3. 點擊 **"+"** 添加以下檔案：

**共享程式碼：**

- `Models/` - 所有檔案
- `Repositories/` - 所有檔案
- `Core/` - 所有檔案
- `Theme/` - 所有檔案
- `ViewModels/` - 所有檔案
- `Platform/Shared/PlatformAbstraction.swift`

**iPad 專屬程式碼：**

- `Platform/iPad/OVERENDApp_iPad.swift`
- `Platform/iPad/FileDialogs_iPad.swift`
- `Platform/iPad/Views/iPadContentView.swift`

### 5c. 排除 macOS 專屬檔案

確認以下檔案 **不包含** 在 iPad target：

- `OVERENDApp.swift` (macOS 入口點)
- `Platform/macOS/*`
- `Views/Settings/` (macOS 設定)
- 所有使用 `NSSavePanel`, `NSOpenPanel` 的服務

## 步驟 6：設定 Core Data

1. 選擇 **OVEREND iPad** target
2. 進入 **Build Phases** > **Copy Bundle Resources**
3. 添加 `OVEREND.xcdatamodeld` (Core Data 模型)

## 步驟 7：設定 Asset Catalog

1. 選擇 **OVEREND iPad** target
2. 進入 **Build Phases** > **Copy Bundle Resources**
3. 添加 `Assets.xcassets`

## 步驟 8：驗證編譯

1. 在 Xcode 頂部工具欄選擇 **OVEREND iPad** scheme
2. 選擇 **iPad Pro 13-inch (M4)** 模擬器
3. 按 `Cmd + B` 編譯

如果編譯成功，您應該可以看到 **Build Succeeded** 訊息。

## 常見問題

### Q: 出現 "Multiple commands produce" 錯誤

**A:** 確認每個檔案只被一個 target 包含。

### Q: 找不到 PersistenceController

**A:** 確認 `Core/PersistenceController.swift` 已添加到 iPad target。

### Q: 出現 AppKit 相關錯誤

**A:** 確認沒有將使用 `import AppKit` 的檔案添加到 iPad target。

---

完成以上步驟後，您就可以在 iPad 模擬器上運行 OVEREND iPad 版本了！
