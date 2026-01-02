//
//  WritingTemplate.swift
//  OVEREND
//
//  寫作範本模型 - 定義學術寫作範本結構
//

import Foundation

/// 範本分類
enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case thesis = "thesis"           // 碩博士論文
    case journal = "journal"         // 期刊投稿
    case conference = "conference"   // 研討會論文
    case report = "report"           // 報告
    case custom = "custom"           // 自訂
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .thesis: return "碩博士論文"
        case .journal: return "期刊投稿"
        case .conference: return "研討會論文"
        case .report: return "報告"
        case .custom: return "自訂範本"
        }
    }
    
    var icon: String {
        switch self {
        case .thesis: return "graduationcap.fill"
        case .journal: return "newspaper.fill"
        case .conference: return "person.3.fill"
        case .report: return "doc.text.fill"
        case .custom: return "square.and.pencil"
        }
    }
}

/// 寫作範本
struct WritingTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let category: TemplateCategory
    let content: String           // HTML/RTF 範本內容
    let thumbnail: String?        // 縮圖 Base64
    let isBuiltIn: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // 範本設定
    let fontSize: Double
    let lineSpacing: Double
    let marginTop: Double
    let marginBottom: Double
    let marginLeft: Double
    let marginRight: Double
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: TemplateCategory,
        content: String,
        thumbnail: String? = nil,
        isBuiltIn: Bool = false,
        fontSize: Double = 12,
        lineSpacing: Double = 2.0,
        marginTop: Double = 72,
        marginBottom: Double = 72,
        marginLeft: Double = 72,
        marginRight: Double = 72
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.content = content
        self.thumbnail = thumbnail
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
        self.updatedAt = Date()
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.marginTop = marginTop
        self.marginBottom = marginBottom
        self.marginLeft = marginLeft
        self.marginRight = marginRight
    }
    
    // MARK: - 內建範本
    
    /// 空白範本
    static let blank = WritingTemplate(
        name: "空白文件",
        description: "從空白開始，自由創作",
        category: .custom,
        content: "",
        isBuiltIn: true
    )
    
    /// APA 格式論文
    static let apaThesis = WritingTemplate(
        name: "APA 格式論文",
        description: "符合 APA 7th Edition 規範的學術論文格式",
        category: .thesis,
        content: """
        <h1 style="text-align: center;">論文標題</h1>
        <p style="text-align: center;">作者姓名<br>指導教授：XXX 教授<br>系所名稱</p>
        
        <h2>摘要</h2>
        <p>請在此處撰寫摘要內容，約 150-250 字。</p>
        <p><strong>關鍵詞：</strong>關鍵詞一、關鍵詞二、關鍵詞三</p>
        
        <h2>壹、緒論</h2>
        <h3>一、研究背景與動機</h3>
        <p>請在此處撰寫研究背景與動機。</p>
        
        <h3>二、研究目的與問題</h3>
        <p>請在此處撰寫研究目的與問題。</p>
        
        <h2>貳、文獻探討</h2>
        <p>請在此處撰寫文獻探討內容。</p>
        
        <h2>參、研究方法</h2>
        <p>請在此處撰寫研究方法。</p>
        
        <h2>肆、研究結果與討論</h2>
        <p>請在此處撰寫研究結果與討論。</p>
        
        <h2>伍、結論與建議</h2>
        <p>請在此處撰寫結論與建議。</p>
        
        <h2>參考文獻</h2>
        <p>請依 APA 格式列出參考文獻。</p>
        """,
        isBuiltIn: true,
        fontSize: 12,
        lineSpacing: 2.0
    )
    
    /// 期刊投稿範本
    static let journalArticle = WritingTemplate(
        name: "期刊投稿",
        description: "適合學術期刊投稿的標準格式",
        category: .journal,
        content: """
        <h1 style="text-align: center;">文章標題（中文）</h1>
        <h2 style="text-align: center;">Article Title (English)</h2>
        
        <p style="text-align: center;">
        第一作者<sup>1</sup> 第二作者<sup>2</sup><br>
        <sup>1</sup>第一作者服務單位<br>
        <sup>2</sup>第二作者服務單位<br>
        通訊作者：example@email.com
        </p>
        
        <h2>摘要</h2>
        <p>【研究目的】</p>
        <p>【研究方法】</p>
        <p>【研究結果】</p>
        <p>【研究結論】</p>
        <p><strong>關鍵詞：</strong></p>
        
        <h2>Abstract</h2>
        <p>[Purpose]</p>
        <p>[Methods]</p>
        <p>[Results]</p>
        <p>[Conclusions]</p>
        <p><strong>Keywords:</strong></p>
        
        <h2>一、前言</h2>
        <p>請在此處撰寫前言。</p>
        
        <h2>二、文獻探討</h2>
        <p>請在此處撰寫文獻探討。</p>
        
        <h2>三、研究方法</h2>
        <p>請在此處撰寫研究方法。</p>
        
        <h2>四、研究結果</h2>
        <p>請在此處撰寫研究結果。</p>
        
        <h2>五、討論</h2>
        <p>請在此處撰寫討論。</p>
        
        <h2>六、結論</h2>
        <p>請在此處撰寫結論。</p>
        
        <h2>參考文獻</h2>
        <p>請列出參考文獻。</p>
        """,
        isBuiltIn: true,
        fontSize: 12,
        lineSpacing: 1.5
    )
    
    /// 研討會論文範本
    static let conferencePaper = WritingTemplate(
        name: "研討會論文",
        description: "適合學術研討會發表的論文格式",
        category: .conference,
        content: """
        <h1 style="text-align: center;">論文標題</h1>
        
        <p style="text-align: center;">
        作者一<sup>1</sup>、作者二<sup>2</sup><br>
        <sup>1</sup>服務單位一<br>
        <sup>2</sup>服務單位二
        </p>
        
        <h2>摘要</h2>
        <p>請撰寫 300 字以內的摘要。</p>
        <p><strong>關鍵詞：</strong>（3-5 個關鍵詞）</p>
        
        <h2>1. 研究背景與目的</h2>
        <p>請在此處撰寫研究背景與目的。</p>
        
        <h2>2. 文獻回顧</h2>
        <p>請在此處撰寫文獻回顧。</p>
        
        <h2>3. 研究方法</h2>
        <p>請在此處撰寫研究方法。</p>
        
        <h2>4. 研究發現</h2>
        <p>請在此處撰寫研究發現。</p>
        
        <h2>5. 結論與建議</h2>
        <p>請在此處撰寫結論與建議。</p>
        
        <h2>參考文獻</h2>
        <p>請列出參考文獻。</p>
        """,
        isBuiltIn: true,
        fontSize: 11,
        lineSpacing: 1.5
    )
    
    /// 報告範本
    static let report = WritingTemplate(
        name: "一般報告",
        description: "適合課堂報告或工作報告",
        category: .report,
        content: """
        <h1 style="text-align: center;">報告標題</h1>
        
        <p style="text-align: center;">
        報告者：<br>
        日期：
        </p>
        
        <h2>一、前言</h2>
        <p>請在此處撰寫前言。</p>
        
        <h2>二、主要內容</h2>
        <h3>（一）第一部分</h3>
        <p>請在此處撰寫內容。</p>
        
        <h3>（二）第二部分</h3>
        <p>請在此處撰寫內容。</p>
        
        <h2>三、結論</h2>
        <p>請在此處撰寫結論。</p>
        
        <h2>參考資料</h2>
        <p>請列出參考資料。</p>
        """,
        isBuiltIn: true,
        fontSize: 12,
        lineSpacing: 1.5
    )
    
    /// 所有內建範本
    static let builtInTemplates: [WritingTemplate] = [
        .blank,
        .apaThesis,
        .journalArticle,
        .conferencePaper,
        .report
    ]
}
