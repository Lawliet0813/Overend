//
//  CoverPageGenerator.swift
//  OVEREND
//
//  論文封面生成器 - 符合政大行管碩士學程格式規範
//

import Foundation
import AppKit

/// 封面資訊資料結構
struct CoverPageInfo {
    var schoolName: String = "國立政治大學社會科學學院"
    var programName: String = "行政管理碩士學程"
    var cohort: String = ""  // 屆次，例如 "24"
    var degreeType: String = "碩士論文"
    var chineseTitle: String = ""
    var englishTitle: String = ""
    var advisorName: String = ""
    var advisorTitle: String = "博士"  // 博士/教授
    var studentName: String = ""
    var year: String = ""  // 民國年
    var month: String = ""
}

/// 封面生成器
class CoverPageGenerator {
    
    // 封面開始/結束標記
    static let coverStartMarker = "【COVER_START】"
    static let coverEndMarker = "【COVER_END】"
    static let coverSectionSeparator = "【COVER_SECTION】"
    
    /// 生成封面的 NSAttributedString
    static func generate(info: CoverPageInfo) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // 標楷體
        let kaitiFont18 = NSFont(name: "BiauKai", size: 18) ?? NSFont.systemFont(ofSize: 18)
        let kaitiFont20 = NSFont(name: "BiauKai", size: 20) ?? NSFont.systemFont(ofSize: 20)
        
        // Times New Roman for English
        let timesFont16 = NSFont(name: "Times New Roman", size: 16) ?? NSFont.systemFont(ofSize: 16)
        
        // 段落樣式 - 置中
        let centerParagraph = NSMutableParagraphStyle()
        centerParagraph.alignment = .center
        centerParagraph.lineSpacing = 10
        
        // 段落樣式 - 置中，較大行距
        let centerParagraphLarge = NSMutableParagraphStyle()
        centerParagraphLarge.alignment = .center
        centerParagraphLarge.lineSpacing = 20
        centerParagraphLarge.paragraphSpacing = 30
        
        // ===== 頂部區域：校名/院名 =====
        let schoolAttrs: [NSAttributedString.Key: Any] = [
            .font: kaitiFont18,
            .foregroundColor: NSColor.black,
            .paragraphStyle: centerParagraph
        ]
        result.append(NSAttributedString(string: info.schoolName + "\n", attributes: schoolAttrs))
        
        // 行政管理碩士學程第○○屆碩士論文
        let cohortText = info.cohort.isEmpty ? "○○" : info.cohort
        let programLine = "\(info.programName)第\(cohortText)屆\(info.degreeType)\n"
        result.append(NSAttributedString(string: programLine, attributes: schoolAttrs))
        
        // 空白區域（減少空行數量）
        result.append(NSAttributedString(string: "\n\n\n\n", attributes: schoolAttrs))
        
        // ===== 中間區域：論文題目 =====
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "BiauKai", size: 20)?.bold() ?? kaitiFont20,
            .foregroundColor: NSColor.black,
            .paragraphStyle: centerParagraphLarge
        ]
        
        let chineseTitle = info.chineseTitle.isEmpty ? "論文中文題目" : info.chineseTitle
        result.append(NSAttributedString(string: chineseTitle + "\n\n", attributes: titleAttrs))
        
        // 英文題目 - 16pt Times New Roman
        if !info.englishTitle.isEmpty {
            let englishTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: timesFont16,
                .foregroundColor: NSColor.black,
                .paragraphStyle: centerParagraph
            ]
            result.append(NSAttributedString(string: info.englishTitle + "\n", attributes: englishTitleAttrs))
        }
        
        // 空白區域（減少空行）
        result.append(NSAttributedString(string: "\n\n\n\n", attributes: schoolAttrs))
        
        // ===== 底部區域：指導教授、研究生、年月 =====
        let bottomAttrs: [NSAttributedString.Key: Any] = [
            .font: kaitiFont18,
            .foregroundColor: NSColor.black,
            .paragraphStyle: centerParagraph
        ]
        
        // 指導教授
        let advisorName = info.advisorName.isEmpty ? "○ ○ ○" : info.advisorName
        let advisorLine = "指導教授：\(advisorName) \(info.advisorTitle)\n\n"
        result.append(NSAttributedString(string: advisorLine, attributes: bottomAttrs))
        
        // 研究生
        let studentName = info.studentName.isEmpty ? "○ ○ ○" : info.studentName
        let studentLine = "研究生：\(studentName) 撰\n\n"
        result.append(NSAttributedString(string: studentLine, attributes: bottomAttrs))
        
        // 年月
        let year = info.year.isEmpty ? "○○○" : info.year
        let month = info.month.isEmpty ? "○" : info.month
        let dateLine = "中 華 民 國 \(year) 年 \(month) 月\n"
        result.append(NSAttributedString(string: dateLine, attributes: bottomAttrs))
        
        // 分頁線（視覺上的分隔）
        let separatorAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.lightGray,
            .paragraphStyle: {
                let ps = NSMutableParagraphStyle()
                ps.alignment = .center
                return ps
            }()
        ]
        result.append(NSAttributedString(string: "\n─────── 封面結束 ───────\n\n", attributes: separatorAttrs))
        
        return result
    }
    
    /// 生成封面的 HTML（用於 PDF 匯出）
    static func generateHTML(info: CoverPageInfo) -> String {
        let cohortText = info.cohort.isEmpty ? "○○" : info.cohort
        let chineseTitle = info.chineseTitle.isEmpty ? "論文中文題目" : info.chineseTitle
        let advisorName = info.advisorName.isEmpty ? "○ ○ ○" : info.advisorName
        let studentName = info.studentName.isEmpty ? "○ ○ ○" : info.studentName
        let year = info.year.isEmpty ? "○○○" : info.year
        let month = info.month.isEmpty ? "○" : info.month
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                @page {
                    size: A4;
                    margin: 2.54cm;
                }
                body {
                    font-family: 'BiauKai', '標楷體', serif;
                    color: black;
                    text-align: center;
                    height: 100vh;
                    display: flex;
                    flex-direction: column;
                    justify-content: space-between;
                    padding: 0;
                    margin: 0;
                }
                .top-section {
                    padding-top: 2cm;
                }
                .school-name {
                    font-size: 18pt;
                    line-height: 1.5;
                }
                .program-name {
                    font-size: 18pt;
                    line-height: 1.5;
                }
                .middle-section {
                    flex-grow: 1;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                }
                .chinese-title {
                    font-size: 20pt;
                    font-weight: bold;
                    line-height: 1.5;
                    margin-bottom: 1em;
                }
                .english-title {
                    font-family: 'Times New Roman', serif;
                    font-size: 16pt;
                    line-height: 1.5;
                }
                .bottom-section {
                    padding-bottom: 2cm;
                }
                .advisor, .student, .date {
                    font-size: 18pt;
                    line-height: 2;
                }
            </style>
        </head>
        <body>
            <div class="top-section">
                <p class="school-name">\(info.schoolName)</p>
                <p class="program-name">\(info.programName)第\(cohortText)屆\(info.degreeType)</p>
            </div>
            
            <div class="middle-section">
                <p class="chinese-title">\(chineseTitle)</p>
                \(info.englishTitle.isEmpty ? "" : "<p class=\"english-title\">\(info.englishTitle)</p>")
            </div>
            
            <div class="bottom-section">
                <p class="advisor">指導教授：\(advisorName) \(info.advisorTitle)</p>
                <p class="student">研究生：\(studentName) 撰</p>
                <p class="date">中 華 民 國 \(year) 年 \(month) 月</p>
            </div>
        </body>
        </html>
        """
    }
}

// MARK: - NSFont 擴展

extension NSFont {
    func bold() -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.bold)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
