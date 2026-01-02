//
//  ThesisMetadata.swift
//  OVEREND
//
//  論文元數據模型 - 支援動態標籤與全域同步
//

import Foundation
import SwiftData
import SwiftUI

/// 論文元數據 - 包含論文基本資訊
@Model
class ThesisMetadata {
    /// 唯一識別碼
    var id: UUID

    // MARK: - 基本資訊

    /// 論文題目（中文）
    var titleChinese: String

    /// 論文題目（英文）
    var titleEnglish: String

    /// 作者姓名（中文）
    var authorChinese: String

    /// 作者姓名（英文）
    var authorEnglish: String

    /// 學號
    var studentID: String

    // MARK: - 指導教授

    /// 指導教授（中文）
    var advisorChinese: String

    /// 指導教授（英文）
    var advisorEnglish: String

    /// 共同指導教授（可選）
    var coAdvisorChinese: String?

    /// 共同指導教授英文（可選）
    var coAdvisorEnglish: String?

    // MARK: - 學校資訊

    /// 學校名稱（中文）
    var universityChinese: String

    /// 學校名稱（英文）
    var universityEnglish: String

    /// 系所名稱（中文）
    var departmentChinese: String

    /// 系所名稱（英文）
    var departmentEnglish: String

    /// 學位類型（碩士/博士）
    var degreeType: DegreeType

    // MARK: - 日期資訊

    /// 論文年份（民國）
    var yearROC: Int

    /// 論文年份（西元）
    var yearAD: Int

    /// 論文月份
    var month: Int

    /// 口試日期
    var defenseDate: Date?

    // MARK: - 摘要

    /// 中文摘要
    var abstractChinese: String

    /// 英文摘要
    var abstractEnglish: String

    /// 中文關鍵字
    var keywordsChinese: [String]

    /// 英文關鍵字
    var keywordsEnglish: [String]

    // MARK: - 其他資訊

    /// 謝辭
    var acknowledgement: String

    /// 更新時間
    var updatedAt: Date

    /// 創建時間
    var createdAt: Date

    // MARK: - 初始化

    init(
        titleChinese: String = "",
        titleEnglish: String = "",
        authorChinese: String = "",
        authorEnglish: String = "",
        studentID: String = "",
        advisorChinese: String = "",
        advisorEnglish: String = "",
        universityChinese: String = "國立政治大學",
        universityEnglish: String = "National Chengchi University",
        departmentChinese: String = "",
        departmentEnglish: String = "",
        degreeType: DegreeType = .master,
        yearROC: Int = Calendar.current.component(.year, from: Date()) - 1911,
        yearAD: Int = Calendar.current.component(.year, from: Date()),
        month: Int = Calendar.current.component(.month, from: Date())
    ) {
        self.id = UUID()
        self.titleChinese = titleChinese
        self.titleEnglish = titleEnglish
        self.authorChinese = authorChinese
        self.authorEnglish = authorEnglish
        self.studentID = studentID
        self.advisorChinese = advisorChinese
        self.advisorEnglish = advisorEnglish
        self.universityChinese = universityChinese
        self.universityEnglish = universityEnglish
        self.departmentChinese = departmentChinese
        self.departmentEnglish = departmentEnglish
        self.degreeType = degreeType
        self.yearROC = yearROC
        self.yearAD = yearAD
        self.month = month
        self.abstractChinese = ""
        self.abstractEnglish = ""
        self.keywordsChinese = []
        self.keywordsEnglish = []
        self.acknowledgement = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 計算屬性

    /// 完整中文學位名稱
    var fullDegreeChinese: String {
        "\(universityChinese)\(departmentChinese)\(degreeType.nameChinese)"
    }

    /// 完整英文學位名稱
    var fullDegreeEnglish: String {
        "\(degreeType.nameEnglish) in \(departmentEnglish), \(universityEnglish)"
    }

    /// 格式化日期（中文）
    var formattedDateChinese: String {
        "中華民國 \(yearROC) 年 \(month) 月"
    }

    /// 格式化日期（英文）
    var formattedDateEnglish: String {
        let monthName = DateFormatter().monthSymbols[month - 1]
        return "\(monthName), \(yearAD)"
    }

    // MARK: - 動態標籤

    /// 解析動態標籤
    func resolveTag(_ tag: String) -> String {
        switch tag.uppercased() {
        // 中文標籤
        case "TITLE_CH", "題目":
            return titleChinese
        case "AUTHOR_CH", "作者":
            return authorChinese
        case "ADVISOR_CH", "指導教授":
            return advisorChinese
        case "COADVISOR_CH", "共同指導":
            return coAdvisorChinese ?? ""
        case "UNIVERSITY_CH", "學校":
            return universityChinese
        case "DEPARTMENT_CH", "系所":
            return departmentChinese
        case "DEGREE_CH", "學位":
            return degreeType.nameChinese
        case "YEAR_ROC", "年份民國":
            return "\(yearROC)"
        case "MONTH_CH", "月份":
            return "\(month)"
        case "DATE_CH", "日期":
            return formattedDateChinese
        case "STUDENT_ID", "學號":
            return studentID

        // 英文標籤
        case "TITLE_EN", "TITLE":
            return titleEnglish
        case "AUTHOR_EN", "AUTHOR":
            return authorEnglish
        case "ADVISOR_EN", "ADVISOR":
            return advisorEnglish
        case "COADVISOR_EN", "COADVISOR":
            return coAdvisorEnglish ?? ""
        case "UNIVERSITY_EN", "UNIVERSITY":
            return universityEnglish
        case "DEPARTMENT_EN", "DEPARTMENT":
            return departmentEnglish
        case "DEGREE_EN", "DEGREE":
            return degreeType.nameEnglish
        case "YEAR_AD", "YEAR":
            return "\(yearAD)"
        case "MONTH_EN":
            return DateFormatter().monthSymbols[month - 1]
        case "DATE_EN", "DATE":
            return formattedDateEnglish

        // 摘要與關鍵字
        case "ABSTRACT_CH", "摘要":
            return abstractChinese
        case "ABSTRACT_EN", "ABSTRACT":
            return abstractEnglish
        case "KEYWORDS_CH", "關鍵字":
            return keywordsChinese.joined(separator: "、")
        case "KEYWORDS_EN", "KEYWORDS":
            return keywordsEnglish.joined(separator: ", ")
        case "ACKNOWLEDGEMENT", "謝辭":
            return acknowledgement

        default:
            return "{{\(tag)}}" // 無法解析時返回原標籤
        }
    }

    /// 更新時間戳
    func touch() {
        updatedAt = Date()
    }
}

// MARK: - 學位類型

enum DegreeType: String, Codable, CaseIterable {
    case master = "master"
    case doctoral = "doctoral"

    var nameChinese: String {
        switch self {
        case .master: return "碩士學位論文"
        case .doctoral: return "博士學位論文"
        }
    }

    var nameEnglish: String {
        switch self {
        case .master: return "Master's Thesis"
        case .doctoral: return "Doctoral Dissertation"
        }
    }

    var shortNameChinese: String {
        switch self {
        case .master: return "碩士"
        case .doctoral: return "博士"
        }
    }

    var shortNameEnglish: String {
        switch self {
        case .master: return "Master"
        case .doctoral: return "Ph.D."
        }
    }
}

// MARK: - 預覽資料

extension ThesisMetadata {
    static var preview: ThesisMetadata {
        let metadata = ThesisMetadata(
            titleChinese: "智慧型文獻管理系統之設計與實作",
            titleEnglish: "Design and Implementation of an Intelligent Reference Management System",
            authorChinese: "王小明",
            authorEnglish: "Wang, Hsiao-Ming",
            studentID: "112753001",
            advisorChinese: "李大同",
            advisorEnglish: "Lee, Ta-Tung",
            departmentChinese: "資訊科學系",
            departmentEnglish: "Department of Computer Science",
            degreeType: .master,
            yearROC: 113,
            yearAD: 2024,
            month: 6
        )

        metadata.abstractChinese = "本研究提出一個創新的文獻管理系統..."
        metadata.abstractEnglish = "This study proposes an innovative reference management system..."
        metadata.keywordsChinese = ["文獻管理", "知識組織", "人工智慧"]
        metadata.keywordsEnglish = ["Reference Management", "Knowledge Organization", "Artificial Intelligence"]
        metadata.acknowledgement = "本論文得以完成，首先要感謝指導教授..."

        return metadata
    }
}
