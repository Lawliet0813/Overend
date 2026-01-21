# OVEREND 專案細部審查報告

> 審查日期：2026-01-21
> 審查版本：1.0.1

## 📋 執行摘要

OVEREND 是一款原生 macOS 應用程式，專為學術研究者設計的文獻管理與論文寫作工具。使用 SwiftUI + AppKit 開發，採用 MVVM 架構，整合 Apple Intelligence 和 Gemini API 進行 AI 驅動的元數據提取。

### 整體評分

| 類別 | 評分 | 說明 |
|------|------|------|
| 架構設計 | ⭐⭐⭐⭐ | 良好的 MVVM + Repository 模式 |
| 程式碼品質 | ⭐⭐⭐⭐ | 結構清晰，註解完整 |
| 安全性 | ⭐⭐⭐ | 需要改進 API Key 處理 |
| 測試覆蓋 | ⭐⭐⭐ | 基礎測試完善，但覆蓋率可提升 |
| 文件完整性 | ⭐⭐⭐⭐ | 中英文文件齊全 |

---

## 🏗️ 架構分析

### 1. 專案結構

```
OVEREND/
├── Models/          # Core Data 實體（10+ 個實體）
├── ViewModels/      # MVVM 視圖模型（8 個）
├── Views/           # SwiftUI 視圖組件
├── Services/        # 業務邏輯服務（30+ 個）
├── Repositories/    # 資料存取層
├── Core/            # 核心服務協議
├── Utilities/       # 工具類
└── Theme/           # 主題樣式
```

### 2. 架構優點

✅ **MVVM 架構清晰**
- ViewModels 使用 `@MainActor` 確保 UI 線程安全
- 使用 `@Published` 實現響應式資料綁定
- 良好的關注點分離

✅ **Repository 模式**
- 抽象化 Core Data 存取
- 支援依賴注入，便於測試
- 統一的錯誤處理（`RepositoryError`）

✅ **服務層設計**
- 統一的服務協議（`AppService`）
- 支援裝飾器模式（計時、日誌）
- 服務註冊表（`ServiceRegistry`）

✅ **程式化 Core Data 模型**
- 無需 `.xcdatamodeld` 檔案
- 完整的關聯關係設定
- 支援持久化歷史追蹤

---

## 🔒 安全性審查

### 1. API Key 管理

**現狀**：使用 Keychain 儲存 Gemini API Key

**檔案**：`OVEREND/Services/AI/GeminiService.swift`

```swift
// 第 597-638 行：KeychainHelper
private struct KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
```

**✅ 優點**：
- 使用 macOS Keychain 安全儲存
- 不將敏感資訊寫入 UserDefaults 或日誌

**⚠️ 建議改進**：
- 添加 `kSecAttrAccessible` 屬性設定存取控制
- 考慮使用 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- 驗證 API Key 格式，防止無效輸入

### 2. 網路安全

**檔案**：`OVEREND/Services/NetworkService.swift`

```swift
// 第 24-40 行：URL 代理處理
func proxiedURL(for originalURL: URL) -> URL {
    guard !proxyURLPrefix.isEmpty else {
        return originalURL
    }
    
    // 防止重複代理
    if originalURL.absoluteString.hasPrefix(proxyURLPrefix) {
        return originalURL
    }
    ...
}
```

**✅ 優點**：
- 防止重複代理
- 使用標準 User-Agent

**⚠️ 建議改進**：
- 實作 URL 驗證，防止開放重定向攻擊
- 考慮 Certificate Pinning 用於敏感 API

### 3. 日誌安全

**檔案**：`OVEREND/Utilities/Logger.swift`

**✅ 優點**：
- 使用 `#if DEBUG` 條件編譯
- 敏感日誌不會在 Release 版本輸出

---

## 🧪 測試分析

### 測試覆蓋概況

| 測試檔案 | 覆蓋模組 | 測試案例數 |
|---------|---------|----------|
| BibTeXParserTests | BibTeX 解析器 | 15+ |
| CitationServiceTests | 引用格式服務 | - |
| PDFMetadataExtractorTests | PDF 元數據提取 | - |
| RepositoryTests | Repository 層 | - |
| AIServiceTests | AI 服務 | - |

### BibTeX 解析器測試評估

**檔案**：`OVERENDTests/BibTeXParserTests.swift`

**✅ 測試覆蓋良好**：
- 基本解析測試
- 多書目解析
- 特殊字元處理
- 中文內容測試
- 錯誤處理測試
- DOI 欄位測試

**⚠️ 建議增加**：
- 邊界條件測試（超大檔案）
- 效能測試
- 異常格式測試

---

## 🐛 潛在問題

### 1. 正則表達式效能

**檔案**：`OVEREND/Services/BibTeXParser.swift`

```swift
// 第 36-42 行
let pattern = #"@(\w+)\s*\{\s*([^,\s]+)\s*,\s*((?:[^{}]|\{[^}]*\})*)\s*\}"#
```

**問題**：複雜的正則表達式在大型 BibTeX 檔案上可能影響效能

**建議**：
- 考慮使用狀態機解析器替代
- 添加解析超時機制
- 對大檔案進行分批處理

### 2. Core Data 排序限制

**檔案**：`OVEREND/Models/Entry.swift`

```swift
// 第 339-354 行
enum SortOption {
    case title
    case author
    case year
    ...
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .title:
            return [NSSortDescriptor(keyPath: \Entry.fieldsJSON, ascending: true)]
        ...
        }
    }
}
```

**問題**：按 `fieldsJSON` 排序不會正確按標題/作者排序（JSON 字串比較）

**建議**：
- 將 `title`、`author`、`year` 作為獨立的 Core Data 屬性
- 或在記憶體中排序

### 3. PDF 提取錯誤處理

**檔案**：`OVEREND/Services/PDFMetadataExtractor.swift`

```swift
// 第 108-146 行
if #available(macOS 26.0, *) {
    // ...
    if UnifiedAIService.shared.isAvailable {
        // ...
    } else {
        logger.log("ℹ️ Apple Intelligence 不可用")
    }
    // ...
}
```

**建議**：
- 確保所有降級路徑都有適當的使用者通知
- 添加重試機制

### 4. 快取管理

**檔案**：`OVEREND/Services/AI/UnifiedAIService.swift`

```swift
// 第 64-72 行
private var resultCache: [String: CachedResult] = [:]
private let cacheTTL: TimeInterval = 300 // 5 分鐘
private let maxCacheSize = 50
```

**建議**：
- 考慮使用 `NSCache` 取代字典，可自動回應記憶體壓力
- 添加快取持久化機制

---

## 📊 程式碼品質

### 1. 命名規範

✅ **優點**：
- Swift 命名規範一致
- 中英文註解清晰
- 函數命名描述性強

### 2. 錯誤處理

✅ **統一錯誤協議** (`AppError`)：
```swift
protocol AppError: Error, LocalizedError {
    var code: String { get }
    var userMessage: String { get }
    var technicalDetails: String? { get }
    var category: ErrorCategory { get }
}
```

✅ **錯誤類別分類**：
- network、persistence、validation
- authentication、fileSystem、parsing
- business、unknown

### 3. 文件品質

✅ **優點**：
- 豐富的中英文註解
- 完整的 README.md
- 產品規劃書和設計文件

---

## 🔧 技術建議

### 優先級 1：高優先

1. **改進 API Key 安全性**
   - 添加 Keychain 存取控制屬性
   - 驗證 API Key 格式

2. **修復 Entry 排序**
   - 將常用欄位提升為獨立屬性

3. **添加更多單元測試**
   - Repository 層測試
   - ViewModel 測試

### 優先級 2：中優先

4. **效能優化**
   - 使用 `NSCache` 取代字典快取
   - 大型 BibTeX 分批解析

5. **改進錯誤處理**
   - 統一錯誤日誌格式
   - 添加使用者友好錯誤訊息

### 優先級 3：低優先

6. **程式碼重構**
   - 將 `PDFMetadataExtractor` 拆分為更小的模組
   - 統一日誌輸出格式

---

## 📁 相關文件審查

### 網站組件 (overend-website/)

✅ **優點**：
- 響應式設計
- 中英文雙語支援
- 清晰的 Beta 測試申請流程

### 文件完整性

| 文件 | 存在 | 品質 |
|------|------|------|
| README.md | ✅ | 優秀 |
| INSTALL_GUIDE.md | ✅ | 良好 |
| RELEASE_NOTES_v1.0.1.md | ✅ | 良好 |
| RELEASE_CHECKLIST.md | ✅ | 良好 |

---

## ✅ 結論

OVEREND 是一個架構良好、程式碼品質優秀的 macOS 應用程式專案。主要優點包括：

1. **清晰的 MVVM 架構**
2. **完善的 Repository 模式**
3. **豐富的 AI 整合功能**
4. **良好的本地化支援（繁體中文優先）**
5. **完整的文件和規劃**

需要改進的領域：

1. **安全性強化**（API Key 管理）
2. **測試覆蓋率提升**
3. **效能優化**（大檔案處理）
4. **Core Data 欄位設計**（排序問題）

整體而言，專案已達到可發布 Beta 版本的品質水準。

---

*審查者：GitHub Copilot Coding Agent*
*審查工具：Code Review + Manual Analysis*
