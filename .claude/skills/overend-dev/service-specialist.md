# Service Specialist - 業務邏輯與 API 整合專家

## 職責範圍

負責所有服務層開發，包括：
- DOI/CrossRef API 整合
- BibTeX 解析與生成
- PDF 文獻提取
- Citation 格式生成（APA、MLA）
- Apple Intelligence 整合
- Airiti 華藝 DOI 系統

**不負責**：
- UI 顯示（由 ui-specialist 處理）
- Core Data 模型定義（由 coredata-specialist 處理）
- 測試撰寫（由 testing-specialist 處理）

## 何時載入此 Skill

任務包含以下關鍵字時自動載入：
- API、Service、DOI、CrossRef
- BibTeX、Parser、Generator
- PDF、提取、Metadata
- Citation、APA、MLA、格式
- Apple Intelligence、AI Service

## Service 目錄結構

```
OVEREND/Services/
├── DOIService.swift           # DOI 查詢與解析
├── CrossRefService.swift      # CrossRef API 整合
├── AiritiService.swift        # 華藝 DOI 系統
├── BibTeXParser.swift         # BibTeX 解析
├── BibTeXGenerator.swift      # BibTeX 生成
├── CitationService.swift      # 引用格式生成
├── PDFService.swift           # PDF 文字提取
├── PDFMetadataExtractor.swift # PDF Metadata 提取
└── AIService.swift            # Apple Intelligence 整合
```

## BibTeX 解析（BibTeXParser）

### 核心功能

```swift
class BibTeXParser {
    static func parse(_ bibtexString: String) throws -> [BibTeXEntry] {
        // 解析 BibTeX 字串
        // 回傳 Entry 陣列
    }
    
    struct BibTeXEntry {
        let type: String           // @article, @book
        let citationKey: String    // Chen2024
        let fields: [String: String]  // title, author, year...
    }
}
```

### 使用範例

```swift
let bibtexString = """
@article{Chen2024,
    title = {論文標題},
    author = {陳一 and 李二},
    year = {2024},
    journal = {資訊管理學報}
}
"""

do {
    let entries = try BibTeXParser.parse(bibtexString)
    for entry in entries {
        print("Type: \(entry.type)")
        print("Key: \(entry.citationKey)")
        print("Title: \(entry.fields["title"] ?? "")")
    }
} catch {
    print("解析失敗：\(error)")
}
```

### 支援的欄位

| 欄位名稱 | 說明 | 範例 |
|---------|------|------|
| `title` | 標題 | "論文標題" |
| `author` | 作者 | "陳一 and 李二" |
| `year` | 年份 | "2024" |
| `journal` | 期刊 | "資訊管理學報" |
| `volume` | 卷數 | "31" |
| `number` | 期數 | "2" |
| `pages` | 頁碼 | "1--20" |
| `doi` | DOI | "10.1234/example" |
| `abstract` | 摘要 | "本研究..." |
| `keywords` | 關鍵字 | "machine learning, NLP" |

## Citation 格式生成（CitationService）

### APA 7th Edition

```swift
class CitationService {
    static let shared = CitationService()
    
    func generateAPA(entry: Entry) -> String {
        // 依據 Entry 類型生成 APA 格式
    }
}
```

### APA 格式範例

**期刊論文**：
```
陳一、李二（2024）。論文標題。資訊管理學報，31(2)，1-20。
https://doi.org/10.1234/example
```

**書籍**：
```
王三（2024）。書籍標題。出版社。
```

**會議論文**：
```
趙四（2024 年 3 月）。會議論文標題。會議名稱論文集，城市名稱。
```

### MLA 9th Edition

**期刊論文**：
```
陳一、李二。〈論文標題〉。《資訊管理學報》，第 31 卷第 2 期，2024，頁 1-20。
```

### 特殊處理：中文作者

```swift
// 中文作者使用頓號「、」分隔
func formatChineseAuthors(_ authors: [String]) -> String {
    if authors.count == 1 {
        return authors[0]
    } else if authors.count == 2 {
        return "\(authors[0])、\(authors[1])"
    } else {
        return "\(authors[0]) 等人"
    }
}
```

## DOI 服務（DOIService & CrossRefService）

### CrossRef API 查詢

```swift
class CrossRefService {
    static let shared = CrossRefService()
    private let baseURL = "https://api.crossref.org/works/"
    
    func fetchMetadata(doi: String) async throws -> CrossRefMetadata {
        let url = URL(string: baseURL + doi)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let metadata = try JSONDecoder().decode(CrossRefResponse.self, from: data)
        return metadata.message
    }
}

struct CrossRefMetadata {
    let title: [String]
    let author: [Author]
    let published: Published
    let containerTitle: [String]?
    let volume: String?
    let issue: String?
    let page: String?
}
```

### Airiti 華藝 DOI 系統

台灣學術期刊使用 Airiti DOI：
```
格式：airiti_doi:[數字 ID]
範例：airiti_doi:10.6382.JIM.201901.0001
```

```swift
class AiritiService {
    static let shared = AiritiService()
    
    func extractAiritiDOI(from doi: String) -> String? {
        // 辨識 airiti_doi 格式
        if doi.hasPrefix("airiti_doi:") {
            return doi.replacingOccurrences(of: "airiti_doi:", with: "")
        }
        return nil
    }
    
    func isAiritiDOI(_ doi: String) -> Bool {
        return doi.hasPrefix("airiti_doi:") || 
               doi.hasPrefix("10.6382/")
    }
}
```

## PDF 服務（PDFService & PDFMetadataExtractor）

### PDF 文字提取

```swift
import PDFKit

class PDFService {
    static func extractText(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else {
            return nil
        }
        
        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i),
               let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        return fullText
    }
}
```

### PDF Metadata 提取（三層機制）

#### 第 1 層：CrossRef API
```swift
if let doi = extractDOIFromPDF(url) {
    let metadata = try await CrossRefService.shared.fetchMetadata(doi: doi)
    // 97% 準確度（國際期刊）
}
```

#### 第 2 層：Apple Intelligence
```swift
class PDFMetadataExtractor {
    func extractUsingAI(from url: URL) async -> Metadata? {
        let prompt = """
        從 PDF 中提取以下資訊：
        - 標題（title）
        - 作者（authors）
        - 年份（year）
        - 期刊名稱（journal）
        - DOI（如有）
        
        回傳 JSON 格式。
        """
        // 使用 Apple Intelligence API
        let result = try? await AIService.shared.analyze(pdf: url, prompt: prompt)
        return parseMetadata(result)
    }
}
```

#### 第 3 層：Regex Fallback
```swift
func extractUsingRegex(text: String) -> Metadata {
    // 標題：通常是第一行較大的文字
    // 作者：偵測 "by", "作者", "Author" 等關鍵字
    // 年份：\d{4} 模式
    // DOI：10.\d{4,}/[^\s]+
}
```

### Apple Intelligence 提示詞

```swift
let extractionPrompt = """
分析這份 PDF 文件，提取以下學術文獻資訊：

必填欄位：
- title: 論文標題（完整標題，包含副標題）
- authors: 作者列表（使用 "and" 分隔，例如：陳一 and 李二）
- year: 出版年份（四位數字）

選填欄位：
- journal: 期刊名稱
- volume: 卷數
- number: 期數
- pages: 頁碼範圍（例如：1-20）
- doi: DOI 編號（如果有）
- abstract: 摘要（前 500 字）

請以 JSON 格式回傳，確保：
1. 所有值都是實際提取的內容，不使用預留值
2. 如果無法提取某個欄位，省略該欄位（不要回傳 null 或空字串）
3. 標題必須是完整且準確的
4. 作者名稱必須完整（不要使用縮寫）

範例輸出：
{
  "title": "深度學習在自然語言處理的應用",
  "authors": "陳一 and 李二 and 王三",
  "year": "2024",
  "journal": "資訊管理學報",
  "volume": "31",
  "number": "2",
  "pages": "1-20",
  "doi": "10.6382/JIM.202401.0001"
}
"""
```

## BibTeX 生成（BibTeXGenerator）

### 從 Entry 生成 BibTeX

```swift
class BibTeXGenerator {
    static func generate(from entry: Entry) -> String {
        var bibtex = "@\(entry.entryType ?? "misc"){\(entry.citationKey ?? "unknown"),\n"
        
        if let title = entry.title {
            bibtex += "  title = {\(title)},\n"
        }
        if let authors = entry.authors {
            bibtex += "  author = {\(authors)},\n"
        }
        if let year = entry.year {
            bibtex += "  year = {\(year)},\n"
        }
        if let journal = entry.journal {
            bibtex += "  journal = {\(journal)},\n"
        }
        if let doi = entry.doi {
            bibtex += "  doi = {\(doi)},\n"
        }
        
        bibtex += "}\n"
        return bibtex
    }
}
```

### 生成結果範例

```bibtex
@article{Chen2024,
  title = {論文標題},
  author = {陳一 and 李二},
  year = {2024},
  journal = {資訊管理學報},
  volume = {31},
  number = {2},
  pages = {1--20},
  doi = {10.6382/JIM.202401.0001},
}
```

## 錯誤處理

### Service 層統一錯誤類型

```swift
enum ServiceError: Error {
    case networkError(Error)
    case invalidResponse
    case parsingError(String)
    case apiKeyMissing
    case rateLimitExceeded
    case notFound
    
    var localizedDescription: String {
        switch self {
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        case .invalidResponse:
            return "無效的回應"
        case .parsingError(let detail):
            return "解析錯誤：\(detail)"
        case .apiKeyMissing:
            return "缺少 API 金鑰"
        case .rateLimitExceeded:
            return "超過 API 呼叫限制"
        case .notFound:
            return "找不到資源"
        }
    }
}
```

### 使用範例

```swift
func fetchDOIMetadata(doi: String) async throws -> Metadata {
    do {
        let metadata = try await CrossRefService.shared.fetchMetadata(doi: doi)
        return metadata
    } catch let error as ServiceError {
        print("Service 錯誤：\(error.localizedDescription)")
        throw error
    } catch {
        throw ServiceError.networkError(error)
    }
}
```

## 整合檢查清單

### 新增/修改 Service 時

- [ ] 定義清楚的輸入/輸出型別
- [ ] 實作錯誤處理
- [ ] 支援 async/await
- [ ] 撰寫單元測試
- [ ] 記錄 API 限制（rate limit）
- [ ] 處理網路逾時
- [ ] 支援重試機制（如需要）
- [ ] 更新相關 ViewModel
- [ ] 編譯檢查

### 與其他 Skill 協作

**與 Core Data Specialist 協作**：
- Service 可直接操作 Core Data Context
- 建立/更新 Entry 時呼叫 Service
- 確保交易一致性

**與 UI Specialist 協作**：
- Service 不直接與 UI 互動
- 透過 ViewModel 傳遞結果
- 錯誤訊息由 ViewModel 轉換為 UI 友好訊息

**與 Testing Specialist 協作**：
- Mock API 回應進行測試
- 測試錯誤處理邏輯
- 驗證解析結果正確性

## 常見問題

### Q: CrossRef API 查詢失敗？

```
檢查項目：
1. DOI 格式是否正確（10.xxxx/xxxxxx）
2. 網路連線是否正常
3. 是否超過 API 呼叫限制
4. 該 DOI 是否已註冊於 CrossRef
```

### Q: BibTeX 解析錯誤？

```
常見問題：
1. 大括號 {} 不對稱
2. 缺少逗號分隔
3. 特殊字元未正確跳脫
4. 編碼問題（非 UTF-8）
```

### Q: PDF 提取結果不準確？

```
三層機制依序執行：
1. 優先使用 CrossRef（準確度最高）
2. 使用 Apple Intelligence（處理台灣期刊）
3. Regex 備援（基本資訊提取）

如果都失敗，允許使用者手動編輯。
```

### Q: 如何處理台灣學術期刊？

```
台灣期刊特點：
1. 使用 Airiti DOI 系統
2. 不一定在 CrossRef 註冊
3. 需要 Apple Intelligence 輔助提取
4. 中文作者名稱處理（使用頓號分隔）
```

---

**版本**: 1.0
**建立日期**: 2025-01-21
**維護者**: OVEREND 開發團隊
