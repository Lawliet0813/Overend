# LaTeX 混合模式使用指南

## 概述

OVEREND 已實現 **LaTeX 混合模式**，結合了傳統 WYSIWYG（所見即所得）編輯器與 LaTeX 數學公式渲染的優勢。

### 核心特性

✅ **NSTextView 編輯器**：熟悉的文字編輯體驗
✅ **內聯 LaTeX 公式**：支援 `$公式$` 語法
✅ **即時渲染**：公式自動轉換為圖片顯示
✅ **AI 智慧生成**：用自然語言描述公式，AI 自動轉 LaTeX
✅ **雙擊編輯**：點擊渲染後的公式可重新編輯
✅ **無需 LaTeX 知識**：AI 輔助降低學習門檻

---

## 架構說明

### 1. 核心服務

#### LaTeXRenderer（OVEREND/Services/LaTeXRenderer.swift）
- 將 LaTeX 公式渲染為 NSImage
- 使用系統 `pdflatex` 編譯公式
- 支援完整的 LaTeX 數學語法（amsmath, amssymb）
- 自動快取避免重複渲染

**系統需求**：
- macOS 需安裝 LaTeX（推薦 MacTeX 或 BasicTeX）
- 下載：https://www.tug.org/mactex/

**使用範例**：
```swift
let result = LaTeXRenderer.render(formula: "E=mc^2", fontSize: 16)
switch result {
case .success(let image):
    // 使用渲染好的圖片
case .error(let message):
    // 處理錯誤
}
```

#### AILatexGenerator（OVEREND/Services/AILatexGenerator.swift）
- 使用 Apple Intelligence 將自然語言轉換為 LaTeX
- 支援公式優化與語法修正
- 內建常用數學公式範例

**使用範例**：
```swift
Task {
    let latex = try await AILatexGenerator.generateFormula(from: "畢氏定理")
    // 輸出：a^2 + b^2 = c^2
}
```

---

### 2. UI 元件

#### LaTeXSupportedTextView（OVEREND/Views/Writer/LaTeXSupportedTextView.swift）
- 繼承自 NSTextView
- 自動檢測 `$...$` 格式的公式
- 延遲渲染機制（避免輸入時頻繁渲染）
- 雙擊公式圖片可轉回文字編輯
- 公式快取提升效能

**關鍵方法**：
```swift
// 渲染所有公式
textView.renderAllLaTeXFormulas()

// 將圖片轉回 LaTeX 文字（編輯）
textView.convertImageToLaTeX(at: location)

// 清除快取
textView.clearFormulaCache()
```

#### LaTeXFormulaSheet（OVEREND/Views/Writer/LaTeXFormulaSheet.swift）
- 公式插入介面
- 提供快速模板（二次方程式、積分、矩陣等）
- AI 智慧生成功能
- 即時預覽

---

### 3. 整合到編輯器

#### EditorTextView 修改
將原本的 `NSTextView` 改為繼承 `LaTeXSupportedTextView`：

```swift
class EditorTextView: LaTeXSupportedTextView {
    // 保留原有的右鍵選單功能
    // 新增「渲染 LaTeX 公式」選單項（⌘⇧L）
}
```

#### ProfessionalEditorView 整合
- 新增「插入 LaTeX 公式...」按鈕
- 綁定 LaTeXFormulaSheet 面板
- 自動觸發渲染

---

## 使用方式

### 方法一：手動輸入（傳統方式）

1. 在編輯器中輸入公式，使用 `$...$` 包圍
   ```
   愛因斯坦質能方程式為 $E=mc^2$，這是相對論的重要結果。
   ```

2. 按下 **⌘⇧L** 或右鍵選單「渲染 LaTeX 公式」

3. 公式自動渲染為圖片

4. 雙擊渲染後的公式可重新編輯

### 方法二：AI 智慧生成（推薦！）

1. 點選工具列「插入」→「插入 LaTeX 公式...」

2. 在「AI 智慧生成」欄位輸入公式描述：
   - 「畢氏定理」
   - 「二次方程式的解」
   - 「高斯積分」
   - 「泰勒級數」

3. 點擊「生成」，AI 自動轉換為 LaTeX

4. 預覽確認後點擊「插入」

### 方法三：快速模板

1. 打開「插入 LaTeX 公式」面板

2. 從快速模板選擇常用公式：
   - 二次方程式
   - 分數
   - 積分
   - 求和
   - 矩陣
   - 平方根

3. 自動填入公式，可進一步編輯

---

## LaTeX 語法範例

### 基本公式
```latex
$E=mc^2$                           # 愛因斯坦質能方程式
$a^2 + b^2 = c^2$                  # 畢氏定理
$\pi \approx 3.14159$              # 圓周率
```

### 分數與根號
```latex
$\frac{a}{b}$                      # 分數
$\frac{-b \pm \sqrt{b^2-4ac}}{2a}$ # 二次方程式解
$\sqrt{x^2 + y^2}$                 # 平方根
$\sqrt[n]{x}$                      # n 次方根
```

### 積分與微分
```latex
$\int_0^\infty e^{-x^2} dx$        # 定積分
$\frac{d}{dx}f(x)$                 # 導數
$\frac{\partial f}{\partial x}$    # 偏微分
```

### 求和與連乘
```latex
$\sum_{i=1}^{n} i$                 # 求和
$\prod_{i=1}^{n} i$                # 連乘
```

### 矩陣
```latex
$\begin{bmatrix} a & b \\ c & d \end{bmatrix}$     # 方括號矩陣
$\begin{pmatrix} 1 & 0 \\ 0 & 1 \end{pmatrix}$     # 圓括號矩陣
```

### 希臘字母
```latex
$\alpha, \beta, \gamma, \delta$    # 小寫
$\Alpha, \Beta, \Gamma, \Delta$    # 大寫
$\theta, \pi, \sigma, \omega$      # 常用符號
```

---

## 技術細節

### 渲染流程

1. **輸入檢測**：監聽 `textDidChange`，檢測 `$...$` 模式
2. **延遲渲染**：使用 Timer 延遲 0.5 秒避免頻繁渲染
3. **LaTeX 編譯**：
   - 建立臨時目錄
   - 產生 `.tex` 文件（使用 `preview` 套件）
   - 呼叫 `pdflatex` 編譯
   - 讀取生成的 PDF
4. **圖片嵌入**：
   - 將 PDF 轉換為 NSImage
   - 建立 NSTextAttachment
   - 設定基線對齊（y: -fontSize * 0.2）
   - 替換文字為圖片
5. **快取管理**：相同公式不重複渲染

### 雙擊編輯機制

```swift
override func mouseDown(with event: NSEvent) {
    if event.clickCount == 2 {
        let point = convert(event.locationInWindow, from: nil)
        let charIndex = characterIndexForInsertion(at: point)

        // 檢查是否為 LaTeX 公式附件
        if convertImageToLaTeX(at: charIndex) {
            return // 已轉回文字，停止處理
        }
    }
    super.mouseDown(with: event)
}
```

### AI 生成實作

使用 Apple Intelligence Writing Tools API：

```swift
let prompt = """
請將以下數學概念轉換為 LaTeX 語法。
只回傳公式本身，不要包含 $ 符號。

描述：\(userInput)
"""

let latex = try await AppleAIService.shared.rewrite(
    text: prompt,
    instruction: "將數學描述轉換為 LaTeX"
)
```

---

## 疑難排解

### Q: 公式無法渲染？
**A**: 檢查系統是否安裝 LaTeX：
```bash
which pdflatex
```
如未安裝，請下載 MacTeX：https://www.tug.org/mactex/

### Q: AI 生成不可用？
**A**: 確認：
1. macOS 版本支援 Apple Intelligence（需 macOS 15.1+）
2. 系統設定中已啟用 Apple Intelligence
3. 裝置符合硬體要求（M1 或更新晶片）

### Q: 公式渲染很慢？
**A**:
- 首次渲染需要編譯，約 1-2 秒
- 之後相同公式會使用快取，瞬間顯示
- 可使用 `clearFormulaCache()` 清除快取重新渲染

### Q: 公式顯示位置不對？
**A**: 調整 NSTextAttachment 的 bounds.y 值：
```swift
attachment.bounds.y = -fontSize * 0.2 // 調整此係數
```

---

## 未來改進方向

- [ ] 支援更多 LaTeX 套件（tikz、chemfig 等）
- [ ] 公式編號與交叉引用
- [ ] 多行公式（align 環境）
- [ ] 公式即時預覽（輸入時浮動顯示）
- [ ] 匯出時保留 LaTeX 原始碼（供 LaTeX 編輯器使用）
- [ ] 支援 MathML 作為替代格式
- [ ] 公式庫（儲存常用公式）

---

## 相關檔案

### 核心服務
- `OVEREND/Services/LaTeXRenderer.swift` - LaTeX 渲染引擎
- `OVEREND/Services/AILatexGenerator.swift` - AI 公式生成器

### UI 元件
- `OVEREND/Views/Writer/LaTeXSupportedTextView.swift` - 支援 LaTeX 的文字視圖
- `OVEREND/Views/Writer/LaTeXFormulaSheet.swift` - 公式插入面板
- `OVEREND/Views/Writer/RichTextEditor.swift` - EditorTextView 定義
- `OVEREND/Views/Writer/ProfessionalEditorView.swift` - 主編輯器整合

### 文件
- `DOCS/LATEX_HYBRID_MODE.md` - 本文件

---

## 授權與致謝

- LaTeX 渲染使用開源的 pdflatex（TeX Live）
- AI 功能基於 Apple Intelligence
- 靈感來自 Notion、Obsidian 等現代筆記軟體
