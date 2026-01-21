# OVEREND 按鈕與 UX 導航全面審查報告

## 執行時間
2026-01-17 21:30 TST

## 摘要

通過全面審查，發現 **21 個空 action 按鈕** 和多層級的 UX 導航問題。這些問題嚴重影響用戶體驗，需要分批修復。

### 問題統計

| 類別 | 數量 | 優先級分佈 |
|------|------|-----------|
| 空 action 按鈕 | 21 | CRITICAL: 10, HIGH: 8, MEDIUM: 3 |
| UX 導航缺陷 | 8 | HIGH: 5, MEDIUM: 3 |
| 無障礙性問題 | 45+ | MEDIUM |
| 狀態管理問題 | 5 | HIGH: 3, MEDIUM: 2 |

---

## CRITICAL 級別問題（需立即修復）

### 1. ❌ Home View 右鍵選單全為空

**檔案**: `OVEREND/Views/Emerald/EmeraldHomeView.swift`
**位置**: Lines 414-428
**影響**: 用戶無法編輯或刪除專案

```swift
// ❌ 目前狀況
.contextMenu {
    Button(action: {}) {  // 空的!
        Label("開啟", systemImage: "doc.text")
    }
    Button(action: {}) {  // 空的!
        Label("重新命名", systemImage: "pencil")
    }
    Button(action: {}) {  // 空的!
        Label("複製", systemImage: "doc.on.doc")
    }
    Button(role: .destructive, action: {}) {  // 空的!
        Label("刪除", systemImage: "trash")
    }
}
```

**建議修復**:
```swift
// ✅ 建議實作
.contextMenu {
    Button(action: {
        // 開啟專案邏輯
        openProject(project)
    }) {
        Label("開啟", systemImage: "doc.text")
    }

    Button(action: {
        projectToRename = project
        showRenameSheet = true
    }) {
        Label("重新命名", systemImage: "pencil")
    }

    Button(action: {
        // 複製專案邏輯
        duplicateProject(project)
    }) {
        Label("複製", systemImage: "doc.on.doc")
    }

    Divider()

    Button(role: .destructive, action: {
        projectToDelete = project
        showDeleteAlert = true
    }) {
        Label("刪除", systemImage: "trash")
    }
}
```

---

### 2. ❌ Recent Projects 導航箭頭無功能

**檔案**: `OVEREND/Views/Emerald/EmeraldHomeView.swift`
**位置**: Lines 273, 283
**影響**: 用戶無法瀏覽多頁的專案列表

```swift
// ❌ 目前狀況
Button(action: {}) {  // 左箭頭 - 空的!
    Image(systemName: "chevron.left")
        .foregroundColor(theme.textSecondary)
}

Button(action: {}) {  // 右箭頭 - 空的!
    Image(systemName: "chevron.right")
        .foregroundColor(theme.textSecondary)
}
```

**建議修復**:
```swift
// ✅ 建議實作
// 1. 新增狀態變數
@State private var currentProjectPage = 0
private let projectsPerPage = 4

private var paginatedProjects: [Project] {
    let start = currentProjectPage * projectsPerPage
    let end = min(start + projectsPerPage, recentProjects.count)
    guard start < recentProjects.count else { return [] }
    return Array(recentProjects[start..<end])
}

private var hasPreviousPage: Bool {
    currentProjectPage > 0
}

private var hasNextPage: Bool {
    (currentProjectPage + 1) * projectsPerPage < recentProjects.count
}

// 2. 更新按鈕
Button(action: {
    withAnimation {
        currentProjectPage -= 1
    }
}) {
    Image(systemName: "chevron.left")
        .foregroundColor(hasPreviousPage ? theme.textSecondary : theme.textTertiary)
}
.disabled(!hasPreviousPage)

Button(action: {
    withAnimation {
        currentProjectPage += 1
    }
}) {
    Image(systemName: "chevron.right")
        .foregroundColor(hasNextPage ? theme.textSecondary : theme.textTertiary)
}
.disabled(!hasNextPage)

// 3. 使用 paginatedProjects 而非 recentProjects
ForEach(paginatedProjects) { project in
    // ...
}
```

---

### 3. ❌ HomeQuickActionCard 點擊無反應

**檔案**: `OVEREND/Views/Emerald/EmeraldHomeView.swift`
**位置**: Line 215
**影響**: 主要快速操作無法使用

```swift
// ❌ 目前狀況
HomeQuickActionCard(
    icon: "folder_open",
    title: "開啟專案",
    subtitle: "瀏覽現有專案",
    iconColor: theme.accent
) {}  // 空 action!
```

**建議修復**:
```swift
// ✅ 建議實作
HomeQuickActionCard(
    icon: "folder_open",
    title: "開啟專案",
    subtitle: "瀏覽現有專案",
    iconColor: theme.accent
) {
    showProjectPicker = true  // 觸發文件選擇器
}

HomeQuickActionCard(
    icon: "add",
    title: "新增文獻",
    subtitle: "匯入 PDF 或 BibTeX",
    iconColor: .blue
) {
    selectedTab = "library"  // 切換到 Library 標籤
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        showImportPanel = true  // 延遲觸發匯入
    }
}

// ... 其他快速操作
```

---

### 4. ❌ PDF Tab Close 按鈕無功能

**檔案**: `OVEREND/Views/Emerald/EmeraldReaderView.swift`
**位置**: Line 540
**影響**: 用戶無法關閉 PDF 標籤

```swift
// ❌ 目前狀況
Button(action: {}) {  // 空的!
    Image(systemName: "xmark")
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(theme.textSecondary)
}
```

**建議修復**:
```swift
// ✅ 建議實作
Button(action: {
    withAnimation {
        // 移除該標籤
        pdfTabs.removeAll { $0.id == tab.id }

        // 如果關閉的是當前標籤，選擇前一個或後一個
        if selectedPDFTab == tab.id {
            if let nextTab = pdfTabs.first {
                selectedPDFTab = nextTab.id
            } else {
                selectedPDFTab = nil
            }
        }
    }
}) {
    Image(systemName: "xmark")
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(theme.textSecondary)
}
.buttonStyle(.plain)
.help("關閉標籤")
```

---

### 5. ❌ RecentProjectCard 主按鈕無反應

**檔案**: `OVEREND/Views/Emerald/EmeraldHomeView.swift`
**位置**: Line 338
**影響**: 用戶無法點擊卡片開啟專案

```swift
// ❌ 目前狀況
Button(action: {}) {  // 空的!
    VStack(alignment: .leading, spacing: 12) {
        // ... 卡片內容
    }
}
```

**建議修復**:
```swift
// ✅ 建議實作
Button(action: {
    openProject(project)  // 開啟專案
}) {
    VStack(alignment: .leading, spacing: 12) {
        // ... 卡片內容
    }
}
.buttonStyle(.plain)

// 新增開啟專案函數
private func openProject(_ project: Project) {
    Task { @MainActor in
        do {
            // 載入專案資料
            let projectData = try await loadProjectData(project.path)

            // 切換到對應的工作區
            currentProject = projectData
            selectedTab = "library"  // 或其他主要視圖

            ToastManager.shared.showSuccess("已開啟專案「\(project.name)」")
        } catch {
            ErrorLogger.shared.log(error, context: "HomeView.openProject")
            ToastManager.shared.showError("無法開啟專案")
        }
    }
}
```

---

## HIGH 級別問題（本週內修復）

### 6. ❌ AI 快速操作按鈕無實作

**檔案**: `OVEREND/Views/Emerald/EmeraldAIAssistantView.swift`
**位置**: Lines 420-422, 444
**影響**: 預設 AI 功能無法使用

```swift
// ❌ 目前狀況
QuickActionButton(icon: "doc.text", title: "Summarize") {}  // 空的!
QuickActionButton(icon: "globe", title: "Translate") {}  // 空的!
QuickActionButton(icon: "checkmark.circle", title: "Proofread") {}  // 空的!
```

**建議修復**:
```swift
// ✅ 建議實作
QuickActionButton(icon: "doc.text", title: "Summarize") {
    sendMessage("請幫我總結這篇文獻的主要內容", action: .summarize)
}

QuickActionButton(icon: "globe", title: "Translate") {
    sendMessage("請將這段文字翻譯成中文", action: .translate)
}

QuickActionButton(icon: "checkmark.circle", title: "Proofread") {
    sendMessage("請檢查這段文字的語法和拼寫", action: .proofread)
}

// 新增 AI 任務處理
enum AIAction {
    case summarize, translate, proofread, custom
}

private func sendMessage(_ text: String, action: AIAction = .custom) {
    guard !text.isEmpty else { return }

    inputText = text
    onSend()

    // 可選：記錄 AI 任務類型以用於分析
    AnalyticsManager.shared.logAIAction(action)
}
```

---

### 7. ❌ Dashboard 篩選按鈕無實作

**檔案**: `OVEREND/Views/Emerald/EmeraldDashboardView.swift`
**位置**: Line 511
**影響**: 無法篩選引用列表

```swift
// ❌ 目前狀況
Button(action: {}) {  // 空的!
    Text(title)
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(isSelected ? theme.accent : theme.textMuted)
}
```

**建議修復**:
```swift
// ✅ 建議實作
// 1. 定義篩選類型
enum ReferenceFilter: String, CaseIterable {
    case all = "全部"
    case books = "書籍"
    case articles = "期刊論文"
    case webpages = "網頁"
    case thesis = "學位論文"
}

// 2. 新增狀態
@State private var selectedFilter: ReferenceFilter = .all

// 3. 更新按鈕
ForEach(ReferenceFilter.allCases, id: \.self) { filter in
    FilterButton(
        title: filter.rawValue,
        isSelected: selectedFilter == filter
    ) {
        withAnimation {
            selectedFilter = filter
        }
    }
}

// 4. 過濾邏輯
private var filteredReferences: [Entry] {
    guard selectedFilter != .all else { return recentReferences }

    return recentReferences.filter { entry in
        switch selectedFilter {
        case .all:
            return true
        case .books:
            return entry.entryType.lowercased().contains("book")
        case .articles:
            return entry.entryType.lowercased().contains("article")
        case .webpages:
            return entry.entryType.lowercased().contains("webpage")
        case .thesis:
            return entry.entryType.lowercased().contains("thesis")
        }
    }
}
```

---

### 8. ❌ PDF 工具按鈕狀態未同步

**檔案**: `OVEREND/Views/Emerald/EmeraldReaderView.swift`
**位置**: Lines 437-441
**影響**: 下劃線和便籤工具無法選取

```swift
// ❌ 目前狀況
PDFToolButton(icon: "format_underlined", isActive: false) {}  // 永遠禁用
PDFToolButton(icon: "sticky_note_2", isActive: false) {}       // 永遠禁用
```

**建議修復**:
```swift
// ✅ 建議實作
PDFToolButton(
    icon: "format_underlined",
    isActive: selectedTool == "underline"
) {
    selectedTool = "underline"
}

PDFToolButton(
    icon: "sticky_note_2",
    isActive: selectedTool == "note"
) {
    selectedTool = "note"
}
```

---

### 9. ❌ AI Assistant 關閉按鈕無功能

**檔案**: `OVEREND/Views/Emerald/EmeraldAIAssistantView.swift`
**位置**: Line 159
**影響**: 無法關閉 AI 助理面板

```swift
// ❌ 目前狀況
Button(action: {}) {  // 空的!
    Image(systemName: "xmark")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(theme.textSecondary)
}
```

**建議修復**:
```swift
// ✅ 建議實作
Button(action: {
    withAnimation {
        // 方案 A: 如果是模態窗口
        dismiss()

        // 方案 B: 如果是側邊欄
        isAIAssistantVisible = false
    }
}) {
    Image(systemName: "xmark")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(theme.textSecondary)
}
.buttonStyle(.plain)
.help("關閉 AI 助理 (ESC)")
.keyboardShortcut(.escape)  // 新增快捷鍵
```

---

### 10. ❌ Editor 格式工具按鈕無實作

**檔案**: `OVEREND/Views/Emerald/EmeraldDashboardView.swift`
**位置**: Line 388
**影響**: 編輯器格式化功能不可用

```swift
// ❌ 目前狀況
FormatToolButton(icon: "format_bold", isActive: false) {}  // 空的!
```

**建議修復**:
```swift
// ✅ 建議實作
// 1. 定義格式狀態
@State private var isBold = false
@State private var isItalic = false
@State private var isUnderline = false

// 2. 更新按鈕
FormatToolButton(icon: "format_bold", isActive: isBold) {
    toggleFormat(.bold)
}

FormatToolButton(icon: "format_italic", isActive: isItalic) {
    toggleFormat(.italic)
}

FormatToolButton(icon: "format_underlined", isActive: isUnderline) {
    toggleFormat(.underline)
}

// 3. 實作格式切換
enum TextFormat {
    case bold, italic, underline
}

private func toggleFormat(_ format: TextFormat) {
    guard !editorText.isEmpty else { return }

    switch format {
    case .bold:
        isBold.toggle()
        applyMarkdown(isBold ? "**" : "", at: selectedRange)
    case .italic:
        isItalic.toggle()
        applyMarkdown(isItalic ? "*" : "", at: selectedRange)
    case .underline:
        isUnderline.toggle()
        applyMarkdown(isUnderline ? "__" : "", at: selectedRange)
    }
}

private func applyMarkdown(_ marker: String, at range: NSRange) {
    // 在選取的文字前後加上 Markdown 標記
    // 實作細節依編輯器類型而定
}
```

---

## MEDIUM 級別問題（本月內修復）

### 11. ⚠️ 缺少鍵盤快捷鍵支援

**影響範圍**: 全專案
**優先級**: MEDIUM

**建議實作的快捷鍵**:
```swift
// 全局快捷鍵 (在 App 層級)
.onKeyPress { key, modifiers in
    if modifiers.contains(.command) {
        switch key.character {
        case "n":  // Cmd+N - 新增文檔
            showNewDocument = true
            return .handled
        case "k":  // Cmd+K - 快速引用
            showQuickCite = true
            return .handled
        case ",":  // Cmd+, - 設定
            showSettings = true
            return .handled
        case "w":  // Cmd+W - 關閉標籤/窗口
            closeCurrentTab()
            return .handled
        default:
            break
        }
    } else if key == .escape {
        // ESC - 關閉所有模態
        dismissAllModals()
        return .handled
    }
    return .ignored
}
```

---

### 12. ⚠️ 缺少 Help Tooltips

**影響範圍**: 45+ 個按鈕
**優先級**: MEDIUM

**建議添加位置**:
```swift
// 所有互動元素都應該有 .help()
Button(action: { /* ... */ }) {
    Image(systemName: "doc.text")
}
.help("新增文檔 (Cmd+N)")  // ✅ 添加這個

// 複雜操作應該有更詳細的提示
Button(action: { showCitationPanel.toggle() }) {
    MaterialIcon(name: "school", size: 20, color: theme.accent)
}
.help("插入引用 (Cmd+K)\n從文獻庫選擇並插入格式化的引用")
```

---

### 13. ⚠️ 無障礙標籤缺失

**影響範圍**: 45+ 個互動元素
**優先級**: MEDIUM

**建議實作**:
```swift
Button(action: { /* ... */ }) {
    Image(systemName: "trash")
}
.accessibilityLabel("刪除文獻")
.accessibilityHint("將選中的文獻移至垃圾桶")
.accessibilityAction(named: "永久刪除") {
    permanentlyDelete()
}
```

---

## 修復計劃

### 第一階段 (本日完成 - CRITICAL)
- [x] Home View 右鍵選單
- [ ] Recent Projects 導航箭頭
- [ ] HomeQuickActionCard 點擊
- [ ] PDF Tab Close
- [ ] RecentProjectCard 主按鈕

### 第二階段 (本週完成 - HIGH)
- [ ] AI 快速操作按鈕
- [ ] Dashboard 篩選按鈕
- [ ] PDF 工具狀態同步
- [ ] AI Assistant 關閉按鈕
- [ ] Editor 格式工具

### 第三階段 (本月完成 - MEDIUM)
- [ ] 鍵盤快捷鍵系統
- [ ] Help Tooltips 全覆蓋
- [ ] 無障礙標籤
- [ ] 視覺反饋一致性
- [ ] 批量刪除完成

---

## 修改檔案清單

### 必須修改的檔案 (CRITICAL)
1. `OVEREND/Views/Emerald/EmeraldHomeView.swift` - 7 個問題
2. `OVEREND/Views/Emerald/EmeraldReaderView.swift` - 2 個問題
3. `OVEREND/Views/Emerald/EmeraldLibrarySubviews.swift` - 1 個問題

### 應該修改的檔案 (HIGH)
4. `OVEREND/Views/Emerald/EmeraldAIAssistantView.swift` - 6 個問題
5. `OVEREND/Views/Emerald/EmeraldDashboardView.swift` - 2 個問題

### 可選修改的檔案 (MEDIUM)
6. `OVEREND/Views/Emerald/LibraryTableComponents.swift` - 1 個問題
7. `OVEREND/Views/Emerald/EmeraldSettingsView.swift` - 1 個問題

---

## 測試檢查清單

### 功能測試
- [ ] Home View 右鍵選單所有操作
- [ ] Recent Projects 翻頁功能
- [ ] 快速操作卡片導航
- [ ] PDF 標籤開啟/關閉
- [ ] AI 快速按鈕執行
- [ ] Dashboard 篩選功能
- [ ] 編輯器格式工具

### UX 測試
- [ ] 所有按鈕有 hover 效果
- [ ] 懸停時顯示 tooltip
- [ ] 快捷鍵正常工作
- [ ] 鍵盤導航順暢
- [ ] 屏幕閱讀器支援

### 效能測試
- [ ] 按鈕點擊響應時間 < 100ms
- [ ] 動畫流暢度 60fps
- [ ] 無記憶體洩漏

---

**報告生成時間**: 2026-01-17 21:30 TST
**審查範圍**: 全專案 Emerald 模組
**發現問題**: 21 個空 action + 多個 UX 缺陷
**建議修復時程**: 3 階段，1 個月完成
