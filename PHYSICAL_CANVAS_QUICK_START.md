# OverEnd 物理畫布引擎 - 快速開始

## 🎯 5 分鐘快速上手

### 步驟 1：啟動編輯器

```swift
import SwiftUI

@main
struct OverEndApp: App {
    var body: some Scene {
        WindowGroup {
            PhysicalEditorMainView()
        }
    }
}
```

### 步驟 2：設定論文資訊

點擊「編輯元數據」按鈕，填寫：

```
題目：智慧型文獻管理系統之設計與實作
作者：王小明
學號：112753001
指導教授：李大同
系所：資訊科學系
```

### 步驟 3：開始寫作

在畫布上輸入：

```markdown
{{TITLE_CH}}

第一章 緒論

1.1 研究背景

本研究旨在...
```

### 步驟 4：使用 AI 助手

1. 選取一段文字
2. 按下 `Cmd + K`
3. 選擇「第三人稱視角檢查」
4. AI 自動檢查並給出建議

### 步驟 5：導出 PDF

點擊「導出 PDF」→ 選擇儲存位置 → 完成！

---

## 🔥 常用快捷鍵

| 快捷鍵 | 功能 |
|--------|------|
| `Cmd + K` | 開啟 AI 指令面板 |
| `Cmd + B` | 粗體 |
| `Cmd + I` | 斜體 |
| `Cmd + U` | 底線 |
| `Cmd + Return` | 插入分頁符 |
| `Cmd + E` | 導出 PDF |

---

## 📝 動態標籤速查

### 最常用標籤

```
{{TITLE_CH}}     - 論文題目（中文）
{{AUTHOR_CH}}    - 作者姓名
{{ADVISOR_CH}}   - 指導教授
{{DATE_CH}}      - 日期（中文格式）
{{UNIVERSITY_CH}} - 學校名稱
{{DEPARTMENT_CH}} - 系所名稱
```

### 封面頁範例

```
{{UNIVERSITY_CH}}
{{DEPARTMENT_CH}}
{{DEGREE_CH}}

{{TITLE_CH}}

研究生：{{AUTHOR_CH}}
指導教授：{{ADVISOR_CH}}

{{DATE_CH}}
```

---

## 🎨 格式快速設定

### 政大論文規範

```swift
// 系統已預設，無需手動設定
頁面尺寸：A4 (210mm × 297mm)
上/下邊距：2.5cm
左邊距：3.0cm
右邊距：2.0cm
正文字體：Times New Roman 12pt
行距：2.0（雙倍行距）
首行縮排：2 字符（28.35pt）
```

### 快速套用

使用 AI 指令：
```
將此段落改為政大論文格式
```

---

## 🤖 AI 指令範例

### 文體修正
```
檢查學術用語
→ 將「很好」改為「具有顯著意義」

改寫為被動語態
→ 「本研究探討」→「本研究中探討了」

精簡句子
→ 去除冗詞贅字
```

### 引用格式
```
轉換為 APA 格式
→ 自動調整文獻引用格式

生成參考文獻
→ 根據內文引用生成完整書目
```

### 格式調整
```
設定首行縮排為 2 字符
→ AI 自動計算並套用 28.35pt

調整行距為雙倍
→ lineHeightMultiple = 2.0
```

---

## 📄 頁碼設定

### 不同章節使用不同頁碼

```swift
// 封面與目錄：無頁碼
documentViewModel.startNewSection(state: .cover, resetPageNumber: false)

// 前言（謝辭、摘要）：小寫羅馬數字
documentViewModel.startNewSection(state: .preface, resetPageNumber: true)
// 頁碼：i, ii, iii...

// 正文：阿拉伯數字
documentViewModel.startNewSection(state: .mainBody, resetPageNumber: true)
// 頁碼：1, 2, 3...
```

---

## 🔧 常見問題

### Q: 文字超出頁面怎麼辦？
A: 系統會自動創建新頁並流動文字。

### Q: 如何調整邊距？
A: 在側邊欄選擇頁面 → 右鍵 → 自訂邊距

### Q: 動態標籤沒有更新？
A: 確認元數據已儲存，系統會在 0.5 秒內自動同步

### Q: PDF 導出後字體跑版？
A: 系統已自動嵌入字體，如遇問題請確認使用標準字體

### Q: AI 指令無回應？
A: 確認已設定 `GEMINI_API_KEY` 環境變數

---

## 📚 進階功能

### 批次處理

```swift
// 一次導出多章
let chapters = [
    (pages: chapter1, metadata: metadata, filename: "第一章"),
    (pages: chapter2, metadata: metadata, filename: "第二章"),
    (pages: chapter3, metadata: metadata, filename: "第三章")
]

try PhysicalPDFExporter.batchExport(
    documents: chapters,
    to: outputURL
)
```

### 自訂 AI 指令

```swift
let customCommand = AICommand(
    prompt: "請將此段落改寫為口語化風格",
    context: commandContext,
    category: .style
)

await aiExecutor.execute(command: customCommand, in: textView)
```

---

## 🎓 學習資源

- 📖 完整文檔：`PHYSICAL_CANVAS_README.md`
- 💻 程式碼範例：`PhysicalEditorMainView.swift`
- 🎥 教學影片：（即將推出）

---

**祝您論文寫作順利！** 🎉
