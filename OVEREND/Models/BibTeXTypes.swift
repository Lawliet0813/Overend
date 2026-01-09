//
//  BibTeXTypes.swift
//  OVEREND
//
//  類型安全的書目類型與欄位定義
//

import Foundation

// MARK: - 書目類型枚舉

/// BibTeX 書目類型
/// 支援 24 種書目類型，涵蓋學術論文、書籍、網路資源、數位資源等
enum BibTeXEntryType: String, CaseIterable, Identifiable, Codable {
    // MARK: - 學術論文類
    case article        // 期刊論文
    case inproceedings  // 會議論文
    case conference     // 會議（等同 inproceedings）
    case phdthesis      // 博士論文
    case mastersthesis  // 碩士論文
    case techreport     // 技術報告
    case preprint       // 預印本
    
    // MARK: - 書籍類
    case book           // 書籍
    case inbook         // 書籍章節
    case incollection   // 文集篇章
    case booklet        // 小冊子
    
    // MARK: - 網路資源類
    case webpage        // 網頁
    case website        // 網站
    case online         // 線上資源
    
    // MARK: - 數位資源類
    case dataset        // 資料集
    case software       // 軟體
    case video          // 影片
    
    // MARK: - 其他類
    case patent         // 專利
    case report         // 報告
    case standard       // 標準規範
    case manual         // 技術手冊
    case proceedings    // 會議論文集
    case unpublished    // 未發表
    case misc           // 其他
    
    var id: String { rawValue }
    
    // MARK: - 顯示名稱
    
    /// 中文顯示名稱
    var displayName: String {
        switch self {
        // 學術論文
        case .article:       return "期刊論文"
        case .inproceedings: return "會議論文"
        case .conference:    return "會議論文"
        case .phdthesis:     return "博士論文"
        case .mastersthesis: return "碩士論文"
        case .techreport:    return "技術報告"
        case .preprint:      return "預印本"
        // 書籍
        case .book:          return "書籍"
        case .inbook:        return "書籍章節"
        case .incollection:  return "文集篇章"
        case .booklet:       return "小冊子"
        // 網路資源
        case .webpage:       return "網頁"
        case .website:       return "網站"
        case .online:        return "線上資源"
        // 數位資源
        case .dataset:       return "資料集"
        case .software:      return "軟體"
        case .video:         return "影片"
        // 其他
        case .patent:        return "專利"
        case .report:        return "報告"
        case .standard:      return "標準規範"
        case .manual:        return "技術手冊"
        case .proceedings:   return "會議論文集"
        case .unpublished:   return "未發表"
        case .misc:          return "其他"
        }
    }
    
    /// 英文顯示名稱
    var displayNameEN: String {
        switch self {
        case .article:       return "Journal Article"
        case .inproceedings: return "Conference Paper"
        case .conference:    return "Conference"
        case .phdthesis:     return "PhD Thesis"
        case .mastersthesis: return "Master's Thesis"
        case .techreport:    return "Technical Report"
        case .preprint:      return "Preprint"
        case .book:          return "Book"
        case .inbook:        return "Book Chapter"
        case .incollection:  return "Collection Article"
        case .booklet:       return "Booklet"
        case .webpage:       return "Web Page"
        case .website:       return "Website"
        case .online:        return "Online Resource"
        case .dataset:       return "Dataset"
        case .software:      return "Software"
        case .video:         return "Video"
        case .patent:        return "Patent"
        case .report:        return "Report"
        case .standard:      return "Standard"
        case .manual:        return "Manual"
        case .proceedings:   return "Proceedings"
        case .unpublished:   return "Unpublished"
        case .misc:          return "Miscellaneous"
        }
    }
    
    // MARK: - 圖示
    
    /// SF Symbol 圖示名稱
    var icon: String {
        switch self {
        // 學術論文
        case .article:       return "doc.text"
        case .inproceedings: return "person.3"
        case .conference:    return "person.3"
        case .phdthesis:     return "graduationcap"
        case .mastersthesis: return "graduationcap"
        case .techreport:    return "doc.badge.gearshape"
        case .preprint:      return "doc.badge.clock"
        // 書籍
        case .book:          return "book"
        case .inbook:        return "bookmark"
        case .incollection:  return "books.vertical"
        case .booklet:       return "doc.richtext"
        // 網路資源
        case .webpage:       return "globe"
        case .website:       return "globe"
        case .online:        return "link"
        // 數位資源
        case .dataset:       return "tablecells"
        case .software:      return "laptopcomputer"
        case .video:         return "video"
        // 其他
        case .patent:        return "seal"
        case .report:        return "doc.text.magnifyingglass"
        case .standard:      return "checkmark.seal"
        case .manual:        return "book.pages"
        case .proceedings:   return "folder"
        case .unpublished:   return "doc.badge.ellipsis"
        case .misc:          return "ellipsis.circle"
        }
    }
    
    // MARK: - 分類
    
    /// 書目類型分類
    var category: BibTeXTypeCategory {
        switch self {
        case .article, .inproceedings, .conference, .phdthesis, .mastersthesis, .techreport, .preprint:
            return .academic
        case .book, .inbook, .incollection, .booklet:
            return .book
        case .webpage, .website, .online:
            return .web
        case .dataset, .software, .video:
            return .digital
        case .patent, .report, .standard, .manual, .proceedings, .unpublished, .misc:
            return .other
        }
    }
    
    // MARK: - 欄位定義
    
    /// 必填欄位
    var requiredFields: [BibTeXField] {
        switch self {
        // 學術論文
        case .article:
            return [.author, .title, .journal, .year]
        case .inproceedings, .conference:
            return [.author, .title, .booktitle, .year]
        case .phdthesis, .mastersthesis:
            return [.author, .title, .school, .year]
        case .techreport:
            return [.author, .title, .institution, .year]
        case .preprint:
            return [.author, .title, .year]
        // 書籍
        case .book:
            return [.author, .title, .publisher, .year]
        case .inbook:
            return [.author, .title, .publisher, .year]
        case .incollection:
            return [.author, .title, .booktitle, .publisher, .year]
        case .booklet:
            return [.title]
        // 網路資源
        case .webpage, .website, .online:
            return [.title, .url]
        // 數位資源
        case .dataset:
            return [.author, .title, .year]
        case .software:
            return [.author, .title]
        case .video:
            return [.title, .year]
        // 其他
        case .patent:
            return [.author, .title, .number, .year]
        case .report:
            return [.author, .title, .institution, .year]
        case .standard:
            return [.title, .organization, .year]
        case .manual:
            return [.title]
        case .proceedings:
            return [.title, .year]
        case .unpublished:
            return [.author, .title]
        case .misc:
            return []
        }
    }
    
    /// 選填欄位
    var optionalFields: [BibTeXField] {
        switch self {
        case .article:
            return [.volume, .number, .pages, .doi, .url, .abstract, .keywords, .language, .issn]
        case .inproceedings, .conference:
            return [.editor, .volume, .pages, .doi, .url, .abstract, .keywords, .language, .organization]
        case .phdthesis, .mastersthesis:
            return [.advisor, .department, .abstract, .keywords, .language, .url, .doi]
        case .book:
            return [.editor, .volume, .series, .address, .edition, .isbn, .abstract, .url]
        case .webpage, .website, .online:
            return [.author, .year, .accessed, .language]
        case .dataset:
            return [.publisher, .doi, .url, .version, .abstract]
        case .software:
            return [.version, .url, .doi, .year]
        default:
            return [.abstract, .keywords, .url, .doi, .language]
        }
    }
    
    /// 所有相關欄位（必填 + 選填）
    var allFields: [BibTeXField] {
        requiredFields + optionalFields
    }
    
    // MARK: - 靜態方法
    
    /// 從字串建立（支援大小寫不敏感）
    static func from(_ string: String) -> BibTeXEntryType? {
        return BibTeXEntryType(rawValue: string.lowercased())
    }
    
    /// 按分類分組的所有類型
    static var groupedByCategory: [BibTeXTypeCategory: [BibTeXEntryType]] {
        Dictionary(grouping: allCases) { $0.category }
    }
}

// MARK: - 書目類型分類

/// 書目類型分類
enum BibTeXTypeCategory: String, CaseIterable, Identifiable {
    case academic = "學術論文"
    case book = "書籍"
    case web = "網路資源"
    case digital = "數位資源"
    case other = "其他"
    
    var id: String { rawValue }
    
    /// 分類圖示
    var icon: String {
        switch self {
        case .academic: return "doc.text"
        case .book:     return "book"
        case .web:      return "globe"
        case .digital:  return "externaldrive"
        case .other:    return "ellipsis.circle"
        }
    }
}

// MARK: - 書目欄位枚舉

/// BibTeX 書目欄位
enum BibTeXField: String, CaseIterable, Identifiable, Codable {
    // MARK: - 基本資訊
    case title          // 標題
    case author         // 作者
    case year           // 年份
    case abstract       // 摘要
    case keywords       // 關鍵字
    case language       // 語言
    
    // MARK: - 期刊資訊
    case journal        // 期刊名稱
    case volume         // 卷
    case number         // 期
    case pages          // 頁碼
    case issn           // ISSN
    
    // MARK: - 書籍資訊
    case publisher      // 出版社
    case booktitle      // 書名/會議名稱
    case edition        // 版次
    case series         // 叢書
    case address        // 出版地
    case chapter        // 章節
    
    // MARK: - 識別碼
    case doi            // DOI
    case isbn           // ISBN
    case url            // 網址
    case pmid           // PubMed ID
    case arxiv          // arXiv ID
    
    // MARK: - 網路資源
    case accessed       // 存取日期
    case urldate        // 網址存取日期
    
    // MARK: - 論文資訊
    case school         // 學校
    case institution    // 機構
    case advisor        // 指導教授
    case degree         // 學位
    case department     // 系所
    
    // MARK: - 其他
    case editor         // 編輯
    case translator     // 譯者
    case organization   // 組織
    case howpublished   // 出版方式
    case note           // 備註
    case version        // 版本
    
    // MARK: - 中文欄位
    case title_zh       // 中文標題
    case author_zh      // 中文作者
    case abstract_zh    // 中文摘要
    case institution_zh // 中文機構
    
    var id: String { rawValue }
    
    // MARK: - 中文標籤
    
    /// 中文顯示標籤
    var label: String {
        switch self {
        // 基本資訊
        case .title:        return "標題"
        case .author:       return "作者"
        case .year:         return "年份"
        case .abstract:     return "摘要"
        case .keywords:     return "關鍵字"
        case .language:     return "語言"
        // 期刊資訊
        case .journal:      return "期刊"
        case .volume:       return "卷"
        case .number:       return "期"
        case .pages:        return "頁碼"
        case .issn:         return "ISSN"
        // 書籍資訊
        case .publisher:    return "出版社"
        case .booktitle:    return "書名/會議"
        case .edition:      return "版次"
        case .series:       return "叢書"
        case .address:      return "出版地"
        case .chapter:      return "章節"
        // 識別碼
        case .doi:          return "DOI"
        case .isbn:         return "ISBN"
        case .url:          return "網址"
        case .pmid:         return "PubMed ID"
        case .arxiv:        return "arXiv ID"
        // 網路資源
        case .accessed:     return "存取日期"
        case .urldate:      return "網址存取日期"
        // 論文資訊
        case .school:       return "學校"
        case .institution:  return "機構"
        case .advisor:      return "指導教授"
        case .degree:       return "學位"
        case .department:   return "系所"
        // 其他
        case .editor:       return "編輯"
        case .translator:   return "譯者"
        case .organization: return "組織"
        case .howpublished: return "出版方式"
        case .note:         return "備註"
        case .version:      return "版本"
        // 中文欄位
        case .title_zh:     return "中文標題"
        case .author_zh:    return "中文作者"
        case .abstract_zh:  return "中文摘要"
        case .institution_zh: return "中文機構"
        }
    }
    
    // MARK: - 輸入設定
    
    /// 是否為多行輸入
    var isMultiline: Bool {
        switch self {
        case .abstract, .abstract_zh, .note, .keywords:
            return true
        default:
            return false
        }
    }
    
    /// 輸入提示
    var placeholder: String {
        switch self {
        case .title:        return "請輸入標題"
        case .author:       return "姓, 名 and 姓, 名"
        case .year:         return "YYYY"
        case .journal:      return "期刊名稱"
        case .volume:       return "如：12"
        case .number:       return "如：3"
        case .pages:        return "如：123-145"
        case .doi:          return "如：10.1234/example"
        case .isbn:         return "如：978-3-16-148410-0"
        case .issn:         return "如：1234-5678"
        case .url:          return "https://..."
        case .accessed:     return "YYYY-MM-DD"
        case .school:       return "如：國立臺灣大學"
        case .advisor:      return "指導教授姓名"
        case .abstract:     return "請輸入摘要"
        case .keywords:     return "關鍵字1, 關鍵字2, ..."
        default:            return ""
        }
    }
    
    /// 欄位分類
    var category: BibTeXFieldCategory {
        switch self {
        case .title, .author, .year, .abstract, .keywords, .language:
            return .basic
        case .journal, .volume, .number, .pages, .issn:
            return .journal
        case .publisher, .booktitle, .edition, .series, .address, .chapter:
            return .book
        case .doi, .isbn, .url, .pmid, .arxiv:
            return .identifier
        case .accessed, .urldate:
            return .web
        case .school, .institution, .advisor, .degree, .department:
            return .thesis
        case .title_zh, .author_zh, .abstract_zh, .institution_zh:
            return .chinese
        default:
            return .other
        }
    }
}

// MARK: - 欄位分類

/// 書目欄位分類
enum BibTeXFieldCategory: String, CaseIterable {
    case basic = "基本資訊"
    case journal = "期刊資訊"
    case book = "書籍資訊"
    case identifier = "識別碼"
    case web = "網路資源"
    case thesis = "論文資訊"
    case chinese = "中文欄位"
    case other = "其他"
}

// MARK: - 擴展：Entry 類型轉換

extension Entry {
    /// 取得類型安全的書目類型
    var bibTeXType: BibTeXEntryType? {
        BibTeXEntryType.from(entryType)
    }
    
    /// 取得書目類型的中文名稱
    var entryTypeDisplayName: String {
        bibTeXType?.displayName ?? entryType.uppercased()
    }
    
    /// 取得書目類型的圖示
    var entryTypeIcon: String {
        bibTeXType?.icon ?? "doc"
    }
}
