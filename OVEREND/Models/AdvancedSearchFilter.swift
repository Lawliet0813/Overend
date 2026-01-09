//
//  AdvancedSearchFilter.swift
//  OVEREND
//
//  進階搜尋篩選條件
//

import Foundation
import CoreData

// MARK: - 進階搜尋篩選器

/// 進階搜尋篩選條件
struct AdvancedSearchFilter: Codable, Equatable {
    
    // MARK: - 文字搜尋
    
    /// 搜尋文字（標題、作者、摘要等）
    var textQuery: String = ""
    
    /// 搜尋範圍
    var searchScope: SearchScope = .all
    
    enum SearchScope: String, Codable, CaseIterable {
        case all = "全部"
        case title = "標題"
        case author = "作者"
        case abstract = "摘要"
        case keywords = "關鍵字"
        case notes = "筆記"
    }
    
    // MARK: - 年份範圍
    
    /// 起始年份（如：2020）
    var yearFrom: Int?
    
    /// 結束年份（如：2024）
    var yearTo: Int?
    
    // MARK: - 書目類型
    
    /// 篩選的書目類型（空集合表示全部）
    var entryTypes: Set<String> = []
    
    // MARK: - 附件/識別碼狀態
    
    /// PDF 附件狀態：true = 有, false = 無, nil = 不限
    var hasPDF: Bool?
    
    /// DOI 狀態：true = 有, false = 無, nil = 不限
    var hasDOI: Bool?
    
    /// URL 狀態：true = 有, false = 無, nil = 不限
    var hasURL: Bool?
    
    // MARK: - 群組/標籤
    
    /// 篩選的群組 ID（空集合表示全部）
    var groupIds: Set<UUID> = []
    
    /// 篩選的標籤名稱（空集合表示全部）
    var tagNames: Set<String> = []
    
    // MARK: - 星號標記
    
    /// 星號狀態：true = 有星號, false = 無星號, nil = 不限
    var isStarred: Bool?
    
    // MARK: - 時間範圍
    
    /// 建立時間起始
    var createdAfter: Date?
    
    /// 建立時間結束
    var createdBefore: Date?
    
    /// 更新時間起始
    var updatedAfter: Date?
    
    // MARK: - 計算屬性
    
    /// 是否有任何篩選條件
    var hasFilters: Bool {
        !textQuery.isEmpty ||
        yearFrom != nil ||
        yearTo != nil ||
        !entryTypes.isEmpty ||
        hasPDF != nil ||
        hasDOI != nil ||
        hasURL != nil ||
        !groupIds.isEmpty ||
        !tagNames.isEmpty ||
        isStarred != nil ||
        createdAfter != nil ||
        createdBefore != nil ||
        updatedAfter != nil
    }
    
    /// 篩選條件數量
    var filterCount: Int {
        var count = 0
        if !textQuery.isEmpty { count += 1 }
        if yearFrom != nil || yearTo != nil { count += 1 }
        if !entryTypes.isEmpty { count += 1 }
        if hasPDF != nil { count += 1 }
        if hasDOI != nil { count += 1 }
        if hasURL != nil { count += 1 }
        if !groupIds.isEmpty { count += 1 }
        if !tagNames.isEmpty { count += 1 }
        if isStarred != nil { count += 1 }
        if createdAfter != nil || createdBefore != nil { count += 1 }
        if updatedAfter != nil { count += 1 }
        return count
    }
    
    /// 篩選條件摘要
    var filterSummary: String {
        var parts: [String] = []
        
        if !textQuery.isEmpty {
            parts.append("「\(textQuery)」")
        }
        if let from = yearFrom, let to = yearTo {
            parts.append("\(from)-\(to)年")
        } else if let from = yearFrom {
            parts.append("\(from)年後")
        } else if let to = yearTo {
            parts.append("\(to)年前")
        }
        if !entryTypes.isEmpty {
            parts.append("\(entryTypes.count) 種類型")
        }
        if hasPDF == true {
            parts.append("有 PDF")
        } else if hasPDF == false {
            parts.append("無 PDF")
        }
        if hasDOI == true {
            parts.append("有 DOI")
        }
        if !tagNames.isEmpty {
            parts.append("\(tagNames.count) 個標籤")
        }
        if isStarred == true {
            parts.append("已標星")
        }
        
        return parts.isEmpty ? "無篩選" : parts.joined(separator: "、")
    }
    
    // MARK: - 重置
    
    /// 重置所有篩選條件
    mutating func reset() {
        self = AdvancedSearchFilter()
    }
    
    /// 重置特定類別的篩選條件
    mutating func resetCategory(_ category: FilterCategory) {
        switch category {
        case .text:
            textQuery = ""
            searchScope = .all
        case .year:
            yearFrom = nil
            yearTo = nil
        case .type:
            entryTypes = []
        case .attachment:
            hasPDF = nil
            hasDOI = nil
            hasURL = nil
        case .organization:
            groupIds = []
            tagNames = []
        case .status:
            isStarred = nil
        case .time:
            createdAfter = nil
            createdBefore = nil
            updatedAfter = nil
        }
    }
    
    enum FilterCategory {
        case text, year, type, attachment, organization, status, time
    }
}

// MARK: - NSPredicate 生成

extension AdvancedSearchFilter {
    
    /// 生成 NSPredicate
    /// - Parameter library: 目標文獻庫
    /// - Returns: 組合後的 NSPredicate
    func buildPredicate(for library: Library) -> NSPredicate {
        var predicates: [NSPredicate] = []
        
        // 1. 文獻庫篩選（必要）
        predicates.append(NSPredicate(format: "library == %@", library))
        
        // 2. 文字搜尋
        if !textQuery.isEmpty {
            let searchPredicate: NSPredicate
            switch searchScope {
            case .all:
                searchPredicate = NSPredicate(
                    format: "bibtexRaw CONTAINS[cd] %@ OR userNotes CONTAINS[cd] %@",
                    textQuery, textQuery
                )
            case .title:
                searchPredicate = NSPredicate(format: "fieldsJSON CONTAINS[cd] %@", textQuery)
            case .author:
                searchPredicate = NSPredicate(format: "fieldsJSON CONTAINS[cd] %@", textQuery)
            case .abstract:
                searchPredicate = NSPredicate(format: "fieldsJSON CONTAINS[cd] %@", textQuery)
            case .keywords:
                searchPredicate = NSPredicate(format: "fieldsJSON CONTAINS[cd] %@", textQuery)
            case .notes:
                searchPredicate = NSPredicate(format: "userNotes CONTAINS[cd] %@", textQuery)
            }
            predicates.append(searchPredicate)
        }
        
        // 3. 書目類型篩選
        if !entryTypes.isEmpty {
            let typePredicate = NSPredicate(format: "entryType IN %@", entryTypes)
            predicates.append(typePredicate)
        }
        
        // 4. 時間篩選
        if let createdAfter = createdAfter {
            predicates.append(NSPredicate(format: "createdAt >= %@", createdAfter as NSDate))
        }
        if let createdBefore = createdBefore {
            predicates.append(NSPredicate(format: "createdAt <= %@", createdBefore as NSDate))
        }
        if let updatedAfter = updatedAfter {
            predicates.append(NSPredicate(format: "updatedAt >= %@", updatedAfter as NSDate))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

// MARK: - 記憶體篩選（用於複雜條件）

extension AdvancedSearchFilter {
    
    /// 在記憶體中篩選書目（用於無法用 NSPredicate 表達的條件）
    /// - Parameter entries: 書目列表
    /// - Returns: 篩選後的書目
    func filterInMemory(_ entries: [Entry]) -> [Entry] {
        var result = entries
        
        // 1. 年份範圍篩選
        if let from = yearFrom {
            result = result.filter { entry in
                guard let yearStr = entry.fields["year"],
                      let year = Int(yearStr) else { return false }
                return year >= from
            }
        }
        if let to = yearTo {
            result = result.filter { entry in
                guard let yearStr = entry.fields["year"],
                      let year = Int(yearStr) else { return false }
                return year <= to
            }
        }
        
        // 2. PDF 附件篩選
        if let hasPDF = hasPDF {
            result = result.filter { $0.hasPDF == hasPDF }
        }
        
        // 3. DOI 篩選
        if let hasDOI = hasDOI {
            result = result.filter { entry in
                let doi = entry.fields["doi"] ?? ""
                return hasDOI ? !doi.isEmpty : doi.isEmpty
            }
        }
        
        // 4. URL 篩選
        if let hasURL = hasURL {
            result = result.filter { entry in
                let url = entry.fields["url"] ?? ""
                return hasURL ? !url.isEmpty : url.isEmpty
            }
        }
        
        // 5. 星號標記篩選
        if let isStarred = isStarred {
            result = result.filter { $0.isStarred == isStarred }
        }
        
        // 6. 標籤篩選
        if !tagNames.isEmpty {
            result = result.filter { entry in
                let entryTags = Set(entry.tagArray)
                return !entryTags.isDisjoint(with: tagNames)
            }
        }
        
        // 7. 群組篩選
        if !groupIds.isEmpty {
            result = result.filter { entry in
                guard let groups = entry.groups else { return false }
                let entryGroupIds = Set(groups.map { $0.id })
                return !entryGroupIds.isDisjoint(with: groupIds)
            }
        }
        
        return result
    }
    
    /// 完整篩選流程（Core Data + 記憶體）
    /// - Parameters:
    ///   - library: 文獻庫
    ///   - context: Core Data 上下文
    /// - Returns: 篩選後的書目
    func execute(in library: Library, context: NSManagedObjectContext) throws -> [Entry] {
        // 1. 使用 NSPredicate 進行初步篩選
        let request = Entry.fetchRequest()
        request.predicate = buildPredicate(for: library)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)]
        
        let initialResults = try context.fetch(request)
        
        // 2. 使用記憶體篩選處理複雜條件
        return filterInMemory(initialResults)
    }
}

// MARK: - 預設篩選器

extension AdvancedSearchFilter {
    
    /// 預設篩選器集合
    static let presets: [String: AdvancedSearchFilter] = [
        "recent": {
            var filter = AdvancedSearchFilter()
            filter.updatedAfter = Calendar.current.date(byAdding: .day, value: -7, to: Date())
            return filter
        }(),
        "withPDF": {
            var filter = AdvancedSearchFilter()
            filter.hasPDF = true
            return filter
        }(),
        "withoutDOI": {
            var filter = AdvancedSearchFilter()
            filter.hasDOI = false
            return filter
        }(),
        "starred": {
            var filter = AdvancedSearchFilter()
            filter.isStarred = true
            return filter
        }(),
        "thisYear": {
            var filter = AdvancedSearchFilter()
            let currentYear = Calendar.current.component(.year, from: Date())
            filter.yearFrom = currentYear
            filter.yearTo = currentYear
            return filter
        }()
    ]
}
