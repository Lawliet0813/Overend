//
//  CitationService.swift
//  OVEREND
//
//  引用格式生成服務 - 符合 APA 7th Edition 規範
//

import Foundation

/// 引用格式生成器
class CitationService {
    
    // MARK: - APA 7th Edition 格式
    
    /// 生成 APA 7th Edition 格式引用（自動偵測中英文）
    static func generateAPA(entry: Entry) -> String {
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
    private static func generateAPAEnglish(entry: Entry) -> String {
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
    private static func generateAPAChinese(entry: Entry) -> String {
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
    private static func formatAPAArticleChinese(authors: String, year: String, title: String, fields: [String: String]) -> String {
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
    private static func formatAPABookChinese(authors: String, year: String, title: String, fields: [String: String]) -> String {
        let publisher = fields["publisher"] ?? ""
        var citation = "\(authors)（\(year)）。*\(title)*。"
        if !publisher.isEmpty {
            citation += "\(publisher)。"
        }
        return citation
    }
    
    // MARK: - APA 分類格式（英文）
    
    /// 期刊文章格式
    private static func formatAPAArticle(authors: String, year: String, title: String, fields: [String: String]) -> String {
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
    private static func formatAPABook(authors: String, year: String, title: String, fields: [String: String]) -> String {
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
    private static func formatAPAConference(authors: String, year: String, title: String, fields: [String: String]) -> String {
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
    private static func formatAPAThesis(authors: String, year: String, title: String, fields: [String: String], isPHD: Bool) -> String {
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
    private static func formatAPAReport(authors: String, year: String, title: String, fields: [String: String]) -> String {
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
    static func generateMLA(entry: Entry) -> String {
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
    private static func formatAuthorsAPAChinese(_ authorString: String) -> String {
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
    private static func formatAuthorsAPA(_ authorString: String) -> String {
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
                    return "\(allButLast), & \(formatted.last!)"
                }
            } else {
                // 21位以上：前19位 + 省略號 + 最後1位
                let first19 = formatted.prefix(19)
                let last = formatted.last!
                
                if isChinese(authors[0]) {
                    return first19.joined(separator: "、") + "、……、" + last
                } else {
                    return first19.joined(separator: ", ") + ", …, " + last
                }
            }
        }
    }
    
    /// 格式化單一作者（APA）
    private static func formatSingleAuthorAPA(_ author: String) -> String {
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
    private static func formatEditorsAPA(_ editorString: String) -> String {
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
    private static func formatAuthorsMLA(_ authorString: String) -> String {
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
    
    private static func formatFirstAuthorMLA(_ author: String) -> String {
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
    private static func isChinese(_ text: String) -> Bool {
        let chineseCharCount = text.filter { char in
            ("\u{4E00}"..."\u{9FFF}").contains(char)
        }.count
        
        // 如果中文字符超過 30%，認為是中文
        return Double(chineseCharCount) / Double(text.count) > 0.3
    }
}
