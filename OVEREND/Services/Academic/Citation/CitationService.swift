//
//  CitationService.swift
//  OVEREND
//
//  引用格式生成服務 - 符合 APA 7th Edition 規範
//

import Foundation

/// 引用格式生成器
class CitationService {
    static let shared = CitationService()
    
    // MARK: - APA 7th Edition 格式
    
    /// 生成 APA 7th Edition 格式引用（自動偵測中英文）
    func generateAPA(entry: Entry) -> String {
        let fields = entry.fields
        let authorString = fields["author"] ?? "Unknown"
        
        // 偵測是否為中文文獻
        if isChinese(authorString) || isChinese(fields["title"] ?? "") {
            return generateAPAChinese(entry: entry)
        } else {
            return generateAPAEnglish(entry: entry)
        }
    }
    
    /// 生成 APA 7th Edition 英文格式引用
    private func generateAPAEnglish(entry: Entry) -> String {
        let fields = entry.fields
        let authors = formatAuthorsAPA(fields["author"] ?? "Unknown")
        let year = fields["year"] ?? "n.d."
        let title = fields["title"] ?? "Untitled"
        
        switch entry.entryType {
        case "article":
            return formatAPAArticle(authors: authors, year: year, title: title, fields: fields)
            
        case "book":
            return formatAPABook(authors: authors, year: year, title: title, fields: fields)
            
        case "inproceedings":
            return formatAPAConference(authors: authors, year: year, title: title, fields: fields)
            
        case "phdthesis", "mastersthesis":
            return formatAPAThesis(authors: authors, year: year, title: title, fields: fields, isPHD: entry.entryType == "phdthesis")
            
        case "techreport":
            return formatAPAReport(authors: authors, year: year, title: title, fields: fields)
            
        default:
            // Misc or undefined types
            var citation = "\(authors) (\(year)). \(title)."
            if let doi = fields["doi"], !doi.isEmpty {
                citation += " https://doi.org/\(doi)"
            } else if let url = fields["url"], !url.isEmpty {
                citation += " \(url)"
            }
            return citation
        }
    }
    
    /// 生成 APA 7th Edition 中文格式引用
    private func generateAPAChinese(entry: Entry) -> String {
        let fields = entry.fields
        let authors = formatAuthorsAPAChinese(fields["author"] ?? "未知")
        let year = fields["year"] ?? "無日期"
        let title = fields["title"] ?? "無標題"
        
        switch entry.entryType {
        case "article":
            return formatAPAArticleChinese(authors: authors, year: year, title: title, fields: fields)
        case "book":
            return formatAPABookChinese(authors: authors, year: year, title: title, fields: fields)
        default:
            var citation = "\(authors)（\(year)）。\(title)。"
            if let doi = fields["doi"], !doi.isEmpty {
                citation += " https://doi.org/\(doi)"
            } else if let url = fields["url"], !url.isEmpty {
                citation += " \(url)"
            }
            return citation
        }
    }
    
    // MARK: - APA 分類格式
    
    /// 期刊文章格式（中文）
    private func formatAPAArticleChinese(authors: String, year: String, title: String, fields: [String: String]) -> String {
        let journal = fields["journal"] ?? ""
        let volume = fields["volume"] ?? ""
        let pages = fields["pages"] ?? ""
        let doi = fields["doi"] ?? ""
        
        var citation = "\(authors)（\(year)）。\(title)。"
        if !journal.isEmpty {
            citation += "*\(journal)*"
            if !volume.isEmpty {
                citation += "，*\(volume)*"
            }
            if !pages.isEmpty {
                citation += "，頁 \(pages)"
            }
            citation += "。"
        }
        if !doi.isEmpty {
            citation += " https://doi.org/\(doi)"
        }
        return citation
    }
    
    /// 圖書格式（中文）
    private func formatAPABookChinese(authors: String, year: String, title: String, fields: [String: String]) -> String {
        let publisher = fields["publisher"] ?? ""
        var citation = "\(authors)（\(year)）。*\(title)*。"
        if !publisher.isEmpty {
            citation += "\(publisher)。"
        }
        return citation
    }
    
    // MARK: - APA 分類格式（英文）
    
    /// 期刊文章格式
    private func formatAPAArticle(authors: String, year: String, title: String, fields: [String: String]) -> String {
        let journal = fields["journal"] ?? ""
        let volume = fields["volume"] ?? ""
        let issue = fields["number"] ?? fields["issue"] ?? ""
        let pages = fields["pages"] ?? ""
        let doi = fields["doi"] ?? ""
        let url = fields["url"] ?? ""
        
        // 標題首字大寫（句首大寫原則）
        var citation = "\(authors) (\(year)). \(title). "
        
        if !journal.isEmpty {
            // 期刊名稱斜體，標題大寫
            citation += "*\(journal)*"
            
            if !volume.isEmpty {
                // 卷數斜體
                citation += ", *\(volume)*"
                
                if !issue.isEmpty {
                    // 期數不斜體，有括號
                    citation += "(\(issue))"
                }
            }
            
            if !pages.isEmpty {
                citation += ", \(pages)"
            }
            
            citation += "."
        }
        
        // DOI 優先，URL 次之，結尾不加句點
        if !doi.isEmpty {
            citation += " https://doi.org/\(doi)"
        } else if !url.isEmpty {
            citation += " \(url)"
        }
        
        return citation
    }
    
    /// 圖書格式
    private func formatAPABook(authors: String, year: String, title: String, fields: [String: String]) -> String {
        let publisher = fields["publisher"] ?? ""
        let edition = fields["edition"] ?? ""
        let doi = fields["doi"] ?? ""
        let url = fields["url"] ?? ""
        
        var citation = "\(authors) (\(year)). "
        
        // 書名斜體
        citation += "*\(title)*"
        
        // 版次資訊
        if !edition.isEmpty {
            citation += " (\(edition))"
        }
        
        citation += "."
        
        // 出版商（不需出版地）
        if !publisher.isEmpty {
            citation += " \(publisher)."
        }
        
        // DOI 或 URL
        if !doi.isEmpty {
            citation += " https://doi.org/\(doi)"
        } else if !url.isEmpty {
            citation += " \(url)"
        }
        
        return citation
    }
    
    /// 研討會論文格式
    private func formatAPAConference(authors: String, year: String, title: String, fields: [String: String]) -> String {
        let booktitle = fields["booktitle"] ?? ""
        let pages = fields["pages"] ?? ""
        let editor = fields["editor"] ?? ""
        let doi = fields["doi"] ?? ""
        let url = fields["url"] ?? ""
        
        var citation = "\(authors) (\(year)). \(title). "
        
        if !booktitle.isEmpty {
            if !editor.isEmpty {
                citation += "In \(formatEditorsAPA(editor)) (Ed.), "
            } else {
                citation += "In "
            }
            
            // 論文集名稱斜體
            citation += "*\(booktitle)*"
            
            if !pages.isEmpty {
                citation += " (pp. \(pages))"
            }
            
            citation += "."
        }
        
        if !doi.isEmpty {
            citation += " https://doi.org/\(doi)"
        } else if !url.isEmpty {
            citation += " \(url)"
        }
        
        return citation
    }
    
    /// 博碩士論文格式
    private func formatAPAThesis(authors: String, year: String, title: String, fields: [String: String], isPHD: Bool) -> String {
        let school = fields["school"] ?? ""
        let url = fields["url"] ?? ""
        
        let thesisType = isPHD ? "Unpublished doctoral dissertation" : "Unpublished master's thesis"
        
        var citation = "\(authors) (\(year)). "
        
        // 論文標題斜體
        citation += "*\(title)* [\(thesisType)]."
        
 // 學校名稱
        if !school.isEmpty {
            citation += " \(school)."
        }
        
        if !url.isEmpty {
            citation += " \(url)"
        }
        
        return citation
    }
    
    /// 研究報告格式
    private func formatAPAReport(authors: String, year: String, title: String, fields: [String: String]) -> String {
        let institution = fields["institution"] ?? fields["publisher"] ?? ""
        let number = fields["number"] ?? ""
        let doi = fields["doi"] ?? ""
        let url = fields["url"] ?? ""
        
        var citation = "\(authors) (\(year)). "
        
        // 報告標題斜體
        citation += "*\(title)*"
        
        // 報告編號
        if !number.isEmpty {
            citation += " (\(number))"
        }
        
        citation += "."
        
        // 機構名稱
        if !institution.isEmpty {
            citation += " \(institution)."
        }
        
        if !doi.isEmpty {
            citation += " https://doi.org/\(doi)"
        } else if !url.isEmpty {
            citation += " \(url)"
        }
        
        return citation
    }
    
    // MARK: - MLA 9th Edition 格式
    
    /// 生成 MLA 9th Edition 格式引用
    func generateMLA(entry: Entry) -> String {
        let fields = entry.fields
        let authors = formatAuthorsMLA(fields["author"] ?? "Unknown")
        let title = fields["title"] ?? "Untitled"
        let year = fields["year"] ?? ""
        
        switch entry.entryType {
        case "article":
            let journal = fields["journal"] ?? ""
            let volume = fields["volume"] ?? ""
            let issue = fields["number"] ?? fields["issue"] ?? ""
            let pages = fields["pages"] ?? ""
            
            var citation = "\(authors) \"\(title).\" "
            if !journal.isEmpty {
                citation += "*\(journal)*"
                if !volume.isEmpty {
                    citation += ", vol. \(volume)"
                }
                if !issue.isEmpty {
                    citation += ", no. \(issue)"
                }
                if !year.isEmpty {
                    citation += ", \(year)"
                }
                if !pages.isEmpty {
                    citation += ", pp. \(pages)"
                }
                citation += "."
            }
            return citation
            
        case "book":
            let publisher = fields["publisher"] ?? ""
            var citation = "\(authors) *\(title)*."
            if !publisher.isEmpty {
                citation += " \(publisher)"
            }
            if !year.isEmpty {
                citation += ", \(year)"
            }
            citation += "."
            return citation
            
        case "inproceedings":
            let booktitle = fields["booktitle"] ?? ""
            let pages = fields["pages"] ?? ""
            var citation = "\(authors) \"\(title).\" "
            if !booktitle.isEmpty {
                citation += "*\(booktitle)*"
                if !year.isEmpty {
                    citation += ", \(year)"
                }
            if !pages.isEmpty {
                    citation += ", pp. \(pages)"
                }
                citation += "."
            }
            return citation
            
        default:
            return "\(authors) \"\(title).\" \(year)."
        }
    }
    
    // MARK: - APA 作者格式化
    
    /// APA 格式中文作者處理
    private func formatAuthorsAPAChinese(_ authorString: String) -> String {
        var authors: [String]
        if authorString.contains("、") {
            authors = authorString.components(separatedBy: "、")
        } else {
            authors = authorString.components(separatedBy: " and ")
        }
        
        authors = authors.map { $0.trimmingCharacters(in: .whitespaces) }
        
        switch authors.count {
        case 0:
            return "未知"
        case 1, 2:
            return authors.joined(separator: "、")
        default:
            // 3位以上使用「等」
            return "\(authors[0])等"
        }
    }
    
    /// APA 格式作者處理（支援中英文）
    private func formatAuthorsAPA(_ authorString: String) -> String {
        // 分割作者：先嘗試「、」（中文），再嘗試 " and "（英文）
        var authors: [String]
        if authorString.contains("、") {
            authors = authorString.components(separatedBy: "、")
        } else {
            authors = authorString.components(separatedBy: " and ")
        }
        
        authors = authors.map { $0.trimmingCharacters(in: .whitespaces) }
        
        // 格式化每位作者
        let formatted = authors.map { formatSingleAuthorAPA($0) }
        
        // 組合
        switch formatted.count {
        case 0:
            return "Unknown"
        case 1:
            return formatted[0]
        case 2:
            // 中文用「、」，英文用 ", &"
            if isChinese(authors[0]) {
                return "\(formatted[0])、\(formatted[1])"
            } else {
                return "\(formatted[0]), & \(formatted[1])"
            }
        default:
            // 3-20位：列出所有作者
            if formatted.count <= 20 {
                if isChinese(authors[0]) {
                    // 中文：用頓號
                    return formatted.joined(separator: "、")
                } else {
                    // 英文：最後一位用 ", &"
                    let allButLast = formatted.dropLast().joined(separator: ", ")
                    return "\(allButLast), & \(formatted.last ?? "")"
                }
            } else {
                // 21位以上：前19位 + 省略號 + 最後1位
                let first19 = formatted.prefix(19)
                let last = formatted.last ?? ""
                
                if isChinese(authors[0]) {
                    return first19.joined(separator: "、") + "、……、" + last
                } else {
                    return first19.joined(separator: ", ") + ", …, " + last
                }
            }
        }
    }
    
    /// 格式化單一作者（APA）
    private func formatSingleAuthorAPA(_ author: String) -> String {
        let trimmed = author.trimmingCharacters(in: .whitespaces)
        
        // 檢查是否為中文姓名
        if isChinese(trimmed) {
            // 中文：完整姓名（已經有空格分隔的保持原樣）
            return trimmed
        } else {
            // 英文：Last, F. M. 格式
            let parts = trimmed.components(separatedBy: " ")
            if parts.count >= 2 {
                let lastName = parts.last ?? ""
                let initials = parts.dropLast().map { String($0.prefix(1)) + "." }.joined(separator: " ")
                return "\(lastName), \(initials)"
            }
            return trimmed
        }
    }
    
    /// 編輯格式化（用於 In XXX (Ed.) 格式）
    private func formatEditorsAPA(_ editorString: String) -> String {
        let editors = editorString.components(separatedBy: " and ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        if editors.count == 1 {
            return formatSingleAuthorAPA(editors[0])
        } else {
            let formatted = editors.map { formatSingleAuthorAPA($0) }
            return formatted.joined(separator: ", ")
        }
    }
    
    // MARK: - MLA 作者格式化
    
    /// MLA 格式作者處理
    private func formatAuthorsMLA(_ authorString: String) -> String {
        let authors = authorString.components(separatedBy: " and ")
        
        if authors.count == 1 {
            let parts = authors[0].trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
            if parts.count >= 2 {
                let lastName = parts.last ?? ""
                let firstName = parts.dropLast().joined(separator: " ")
                return "\(lastName), \(firstName)."
            }
            return authors[0] + "."
        } else if authors.count == 2 {
            let first = formatFirstAuthorMLA(authors[0])
            let second = authors[1].trimmingCharacters(in: .whitespaces)
            return "\(first), and \(second)."
        } else {
            let first = formatFirstAuthorMLA(authors[0])
            return "\(first), et al."
        }
    }
    
    private func formatFirstAuthorMLA(_ author: String) -> String {
        let parts = author.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
        if parts.count >= 2 {
            let lastName = parts.last ?? ""
            let firstName = parts.dropLast().joined(separator: " ")
            return "\(lastName), \(firstName)"
        }
        return author.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - 輔助函數
    
    /// 判斷字串是否主要為中文
    private func isChinese(_ text: String) -> Bool {
        let chineseCharCount = text.filter { char in
            ("\u{4E00}"..."\u{9FFF}").contains(char)
        }.count
        
        // 如果中文字符超過 30%，認為是中文
        return Double(chineseCharCount) / Double(text.count) > 0.3
    }
}

// MARK: - APA 7th 台灣學術規範擴充

extension CitationService {
    
    // MARK: - 碩博士論文格式（台灣）
    
    /// 中文碩博士論文格式
    /// 格式：作者（年份）。*論文名稱*〔碩士/博士論文，學校〕。系統名稱。URL
    func formatAPAThesisChinese(
        authors: String,
        year: String,
        title: String,
        fields: [String: String],
        isPhD: Bool
    ) -> String {
        let school = fields["school"] ?? ""
        let department = fields["department"] ?? ""
        let advisor = fields["advisor"] ?? ""
        let url = fields["url"] ?? ""
        
        let thesisType = isPhD ? "博士論文" : "碩士論文"
        
        var citation = "\(authors)（\(year)）。*\(title)*"
        
        // 論文類型與學校
        if !school.isEmpty {
            citation += "〔\(thesisType)，\(school)"
            if !department.isEmpty {
                citation += "\(department)"
            }
            citation += "〕"
        } else {
            citation += "〔\(thesisType)〕"
        }
        
        citation += "。"
        
        // 指導教授（可選，非標準但常見）
        if !advisor.isEmpty {
            citation += "指導教授：\(advisor)。"
        }
        
        // URL
        if !url.isEmpty {
            citation += " \(url)"
        }
        
        return citation
    }
    
    // MARK: - 政府文件格式
    
    /// 政府文件格式
    /// 格式：機關名稱（年份）。*文件名稱*（文號）。URL
    func formatAPAGovernmentChinese(
        institution: String,
        year: String,
        title: String,
        fields: [String: String]
    ) -> String {
        let documentNumber = fields["document_number"] ?? fields["number"] ?? ""
        let url = fields["url"] ?? ""
        
        var citation = "\(institution)（\(year)）。*\(title)*"
        
        if !documentNumber.isEmpty {
            citation += "（\(documentNumber)）"
        }
        
        citation += "。"
        
        if !url.isEmpty {
            citation += " \(url)"
        }
        
        return citation
    }
    
    // MARK: - 法規判例格式
    
    /// 法規格式
    /// 格式：法規名稱（公布或修正日期）
    func formatAPALegalStatute(
        title: String,
        fields: [String: String]
    ) -> String {
        let date = fields["regulation_date"] ?? fields["year"] ?? ""
        let number = fields["regulation_number"] ?? ""
        
        var citation = "\(title)"
        
        if !date.isEmpty {
            citation += "（\(date)"
            if !number.isEmpty {
                citation += "，\(number)"
            }
            citation += "）"
        }
        
        return citation
    }
    
    /// 判例格式
    /// 格式：案件名稱，法院，案號（判決日期）
    func formatAPALegalCase(
        title: String,
        fields: [String: String]
    ) -> String {
        let court = fields["court"] ?? ""
        let caseNumber = fields["case_number"] ?? fields["number"] ?? ""
        let judgmentDate = fields["judgment_date"] ?? ""
        
        var citation = title
        
        if !court.isEmpty {
            citation += "，\(court)"
        }
        
        if !caseNumber.isEmpty {
            citation += "，\(caseNumber)"
        }
        
        if !judgmentDate.isEmpty {
            citation += "（\(judgmentDate)）"
        }
        
        return citation
    }
    
    // MARK: - 中文書籍格式（含出版地）
    
    /// 中文書籍格式（含出版地）
    /// 格式：作者（年份）。*書名*（版次）。出版地：出版社。
    func formatAPABookChineseFull(
        authors: String,
        year: String,
        title: String,
        fields: [String: String]
    ) -> String {
        let publisher = fields["publisher"] ?? ""
        let place = fields["place"] ?? fields["address"] ?? ""
        let edition = fields["edition"] ?? ""
        let doi = fields["doi"] ?? ""
        
        var citation = "\(authors)（\(year)）。*\(title)*"
        
        // 版次
        if !edition.isEmpty {
            citation += "（\(edition)）"
        }
        
        citation += "。"
        
        // 出版地與出版社
        if !place.isEmpty && !publisher.isEmpty {
            citation += "\(place)：\(publisher)。"
        } else if !publisher.isEmpty {
            citation += "\(publisher)。"
        }
        
        // DOI
        if !doi.isEmpty {
            citation += " https://doi.org/\(doi)"
        }
        
        return citation
    }
    
    // MARK: - 標點符號轉換
    
    /// 中英文標點轉換
    /// - Parameters:
    ///   - text: 原始文字
    ///   - toChinese: true = 轉為中文標點，false = 轉為英文標點
    func convertPunctuation(_ text: String, toChinese: Bool) -> String {
        var result = text
        
        let punctuationMap: [(chinese: String, english: String)] = [
            ("，", ","),
            ("。", "."),
            ("：", ":"),
            ("；", ";"),
            ("「", "\""),
            ("」", "\""),
            ("『", "'"),
            ("』", "'"),
            ("（", "("),
            ("）", ")"),
            ("【", "["),
            ("】", "]"),
            ("？", "?"),
            ("！", "!")
        ]
        
        for (chinese, english) in punctuationMap {
            if toChinese {
                result = result.replacingOccurrences(of: english, with: chinese)
            } else {
                result = result.replacingOccurrences(of: chinese, with: english)
            }
        }
        
        return result
    }
}

// MARK: - 參考文獻列表生成

extension CitationService {
    
    /// 排序方式
    enum BibliographySortOrder {
        case author      // 依作者姓氏
        case year        // 依年份
        case title       // 依標題
    }
    
    /// 引用格式
    enum CitationFormat: String, CaseIterable {
        case apa7 = "APA 7th"
        case mla9 = "MLA 9th"
        case chicago = "Chicago"
    }
    
    /// 自動生成參考文獻列表
    /// - Parameters:
    ///   - entries: 書目列表
    ///   - format: 引用格式
    ///   - sortBy: 排序方式
    /// - Returns: 格式化的參考文獻列表
    func generateBibliography(
        entries: [Entry],
        format: CitationFormat = .apa7,
        sortBy: BibliographySortOrder = .author
    ) -> String {
        guard !entries.isEmpty else { return "" }
        
        // 排序
        let sortedEntries = sortEntries(entries, by: sortBy)
        
        // 生成引用
        var bibliography = "參考文獻\n\n"
        
        for entry in sortedEntries {
            let citation: String
            switch format {
            case .apa7:
                citation = generateAPA(entry: entry)
            case .mla9:
                citation = generateMLA(entry: entry)
            case .chicago:
                citation = generateChicago(entry: entry)
            }
            bibliography += citation + "\n\n"
        }
        
        return bibliography.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 排序書目
    private func sortEntries(_ entries: [Entry], by order: BibliographySortOrder) -> [Entry] {
        switch order {
        case .author:
            return entries.sorted { e1, e2 in
                let author1 = e1.fields["author"] ?? ""
                let author2 = e2.fields["author"] ?? ""
                let result = author1.localizedCaseInsensitiveCompare(author2)
                if result == .orderedSame {
                    // 同作者依年份排序
                    let year1 = e1.fields["year"] ?? ""
                    let year2 = e2.fields["year"] ?? ""
                    return year1 < year2
                }
                return result == .orderedAscending
            }
        case .year:
            return entries.sorted { e1, e2 in
                let year1 = e1.fields["year"] ?? ""
                let year2 = e2.fields["year"] ?? ""
                return year1 < year2
            }
        case .title:
            return entries.sorted { e1, e2 in
                let title1 = e1.fields["title"] ?? ""
                let title2 = e2.fields["title"] ?? ""
                return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
            }
        }
    }
    
    /// Chicago 格式（簡化版）
    func generateChicago(entry: Entry) -> String {
        let fields = entry.fields
        let authors = formatAuthorsChicago(fields["author"] ?? "Unknown")
        let title = fields["title"] ?? "Untitled"
        let year = fields["year"] ?? ""
        
        switch entry.entryType {
        case "article":
            let journal = fields["journal"] ?? ""
            let volume = fields["volume"] ?? ""
            let pages = fields["pages"] ?? ""
            
            var citation = "\(authors). \"\(title).\" "
            if !journal.isEmpty {
                citation += "*\(journal)*"
                if !volume.isEmpty {
                    citation += " \(volume)"
                }
                if !pages.isEmpty {
                    citation += ": \(pages)"
                }
                citation += " (\(year))."
            }
            return citation
            
        case "book":
            let publisher = fields["publisher"] ?? ""
            let place = fields["place"] ?? fields["address"] ?? ""
            
            var citation = "\(authors). *\(title)*."
            if !place.isEmpty {
                citation += " \(place):"
            }
            if !publisher.isEmpty {
                citation += " \(publisher),"
            }
            citation += " \(year)."
            return citation
            
        default:
            return "\(authors). \"\(title).\" \(year)."
        }
    }
    
    /// Chicago 格式作者處理
    private func formatAuthorsChicago(_ authorString: String) -> String {
        let authors = authorString.components(separatedBy: " and ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        if authors.count == 1 {
            return authors[0]
        } else if authors.count == 2 {
            return "\(authors[0]) and \(authors[1])"
        } else {
            return "\(authors[0]) et al."
        }
    }
}

// MARK: - 行內引用格式

extension CitationService {
    
    /// 行內引用格式
    struct InlineCitation {
        let text: String           // 顯示文字
        let fullCitation: String   // 完整引用
        let entries: [Entry]       // 相關書目
    }
    
    /// 生成行內引用（Author, Year）
    /// - Parameters:
    ///   - entries: 書目列表（支援多重引用）
    ///   - pageNumber: 頁碼（可選）
    /// - Returns: 行內引用
    func generateInlineCitation(
        entries: [Entry],
        pageNumber: String? = nil
    ) -> InlineCitation {
        guard !entries.isEmpty else {
            return InlineCitation(text: "", fullCitation: "", entries: [])
        }
        
        if entries.count == 1 {
            let entry = entries[0]
            let text = formatSingleInlineCitation(entry: entry, pageNumber: pageNumber)
            return InlineCitation(
                text: text,
                fullCitation: generateAPA(entry: entry),
                entries: entries
            )
        } else {
            // 多重引用
            let text = formatMultipleInlineCitation(entries: entries)
            let fullCitation = entries.map { generateAPA(entry: $0) }.joined(separator: "\n\n")
            return InlineCitation(
                text: text,
                fullCitation: fullCitation,
                entries: entries
            )
        }
    }
    
    /// 格式化單一行內引用
    private func formatSingleInlineCitation(entry: Entry, pageNumber: String?) -> String {
        let author = entry.fields["author"] ?? "Unknown"
        let year = entry.fields["year"] ?? "n.d."
        
        // 提取姓氏
        let lastName: String
        if isChinese(author) {
            // 中文：取整個姓名
            lastName = author.components(separatedBy: "、").first?
                .trimmingCharacters(in: .whitespaces) ?? author
        } else {
            // 英文：取姓氏
            let parts = author.components(separatedBy: " and ").first?
                .trimmingCharacters(in: .whitespaces)
                .components(separatedBy: " ") ?? []
            lastName = parts.last ?? author
        }
        
        var citation = "(\(lastName), \(year)"
        
        if let page = pageNumber, !page.isEmpty {
            citation += ", p. \(page)"
        }
        
        citation += ")"
        
        return citation
    }
    
    /// 格式化多重行內引用
    private func formatMultipleInlineCitation(entries: [Entry]) -> String {
        let citations = entries.map { entry -> String in
            let author = entry.fields["author"] ?? "Unknown"
            let year = entry.fields["year"] ?? "n.d."
            
            let lastName: String
            if isChinese(author) {
                lastName = author.components(separatedBy: "、").first?
                    .trimmingCharacters(in: .whitespaces) ?? author
            } else {
                let parts = author.components(separatedBy: " and ").first?
                    .trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: " ") ?? []
                lastName = parts.last ?? author
            }
            
            return "\(lastName), \(year)"
        }
        
        return "(" + citations.joined(separator: "; ") + ")"
    }
}

// MARK: - ChineseNameFormatter 整合

extension CitationService {
    
    /// 使用 ChineseNameFormatter 進行進階作者格式化
    /// - Parameters:
    ///   - authorString: 作者字串
    ///   - fields: 書目欄位（用於語言偵測）
    ///   - style: 引用風格
    /// - Returns: 格式化後的作者字串
    func formatAuthorsAdvanced(
        _ authorString: String,
        fields: [String: String] = [:],
        style: CitationFormat = .apa7
    ) -> String {
        let formatter = ChineseNameFormatter.shared
        
        // 使用 ChineseNameFormatter 進行格式化
        let formatterStyle: ChineseNameFormatter.CitationStyle
        switch style {
        case .apa7:
            formatterStyle = .apa
        case .mla9:
            formatterStyle = .mla
        case .chicago:
            formatterStyle = .chicago
        }
        
        return formatter.formatAuthorsForCitation(
            authorString,
            fields: fields,
            style: formatterStyle
        )
    }
    
    /// 偵測並處理作者消歧義
    /// - Parameters:
    ///   - entries: 書目條目列表
    ///   - checkFields: 要檢查的欄位
    /// - Returns: 需要消歧義的作者索引
    func detectAuthorDisambiguation(entries: [Entry]) -> [(index: Int, needsDisambiguation: Bool)] {
        let formatter = ChineseNameFormatter.shared
        var results: [(Int, Bool)] = []
        
        // 解析所有作者
        var allParsedNames: [(index: Int, name: ParsedName)] = []
        
        for (index, entry) in entries.enumerated() {
            if let authorString = entry.fields["author"] {
                let names = formatter.parseAuthors(authorString)
                if let firstName = names.first {
                    allParsedNames.append((index, firstName))
                }
            }
        }
        
        // 檢查是否有需要消歧義的情況
        for (index, name) in allParsedNames {
            let needsDisambiguation = allParsedNames.contains { other in
                other.index != index && formatter.needsDisambiguation(name, other.name)
            }
            results.append((index, needsDisambiguation))
        }
        
        return results
    }
    
    /// 格式化單一作者（使用進階解析）
    /// - Parameters:
    ///   - authorName: 作者姓名
    ///   - style: 引用風格
    ///   - disambiguate: 是否需要消歧義
    /// - Returns: 格式化後的作者字串
    func formatSingleAuthorAdvanced(
        _ authorName: String,
        style: CitationFormat = .apa7,
        disambiguate: Bool = false
    ) -> String {
        let formatter = ChineseNameFormatter.shared
        let parsed = formatter.parse(authorName)
        
        if disambiguate {
            let formatterStyle: ChineseNameFormatter.CitationStyle
            switch style {
            case .apa7: formatterStyle = .apa
            case .mla9: formatterStyle = .mla
            case .chicago: formatterStyle = .chicago
            }
            return formatter.disambiguatedFormat(parsed, style: formatterStyle)
        }
        
        switch style {
        case .apa7:
            return parsed.apaFormat
        case .mla9:
            return parsed.mlaFormat
        case .chicago:
            return parsed.mlaFormat // Chicago 使用類似 MLA 的格式
        }
    }
}

