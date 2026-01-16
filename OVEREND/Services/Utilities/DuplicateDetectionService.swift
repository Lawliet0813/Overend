//
//  DuplicateDetectionService.swift
//  OVEREND
//
//  重複檢測服務 - DOI/標題自動比對
//

import Foundation
import CoreData

// MARK: - 重複檢測服務

/// 重複檢測服務
/// 提供 DOI 完全比對和標題相似度檢測功能
class DuplicateDetectionService {
    
    // MARK: - 類型定義
    
    /// 匹配類型
    enum MatchType: String {
        case exactDOI = "DOI 完全相同"
        case similarTitle = "標題相似"
        case none = "無重複"
    }
    
    /// 檢測結果
    struct DetectionResult {
        let isDuplicate: Bool
        let matchType: MatchType
        let existingEntry: Entry?
        let similarityScore: Double  // 0.0 - 1.0
        let message: String
        
        static let noDuplicate = DetectionResult(
            isDuplicate: false,
            matchType: .none,
            existingEntry: nil,
            similarityScore: 0,
            message: "未發現重複"
        )
    }
    
    /// 批次檢測結果
    struct BatchDetectionResult {
        let entry: BibTeXEntry
        let result: DetectionResult
    }
    
    // MARK: - 配置
    
    /// 標題相似度閾值（預設 90%）
    static let defaultSimilarityThreshold: Double = 0.90
    
    // MARK: - 單一檢測
    
    /// 檢測單一書目是否重複
    /// - Parameters:
    ///   - doi: DOI（可選）
    ///   - title: 標題
    ///   - library: 目標文獻庫
    ///   - context: Core Data 上下文
    ///   - similarityThreshold: 相似度閾值（預設 0.90）
    /// - Returns: 檢測結果
    static func checkDuplicate(
        doi: String?,
        title: String,
        in library: Library,
        context: NSManagedObjectContext,
        similarityThreshold: Double = defaultSimilarityThreshold
    ) -> DetectionResult {
        
        // 1. 優先檢查 DOI（精確匹配）
        if let doi = doi, !doi.isEmpty {
            if let existingEntry = findByDOI(doi, in: library, context: context) {
                return DetectionResult(
                    isDuplicate: true,
                    matchType: .exactDOI,
                    existingEntry: existingEntry,
                    similarityScore: 1.0,
                    message: "發現相同 DOI 的文獻：\(existingEntry.title)"
                )
            }
        }
        
        // 2. 標題相似度檢測
        let normalizedTitle = normalizeTitle(title)
        guard !normalizedTitle.isEmpty else {
            return .noDuplicate
        }
        
        // 獲取所有書目進行比對
        let allEntries = fetchAllEntries(in: library, context: context)
        
        var bestMatch: Entry?
        var bestScore: Double = 0
        
        for entry in allEntries {
            let existingTitle = normalizeTitle(entry.title)
            let score = calculateSimilarity(normalizedTitle, existingTitle)
            
            if score > bestScore {
                bestScore = score
                bestMatch = entry
            }
        }
        
        // 3. 判斷是否超過閾值
        if bestScore >= similarityThreshold, let match = bestMatch {
            return DetectionResult(
                isDuplicate: true,
                matchType: .similarTitle,
                existingEntry: match,
                similarityScore: bestScore,
                message: "發現相似標題（\(Int(bestScore * 100))% 相似）：\(match.title)"
            )
        }
        
        return .noDuplicate
    }
    
    // MARK: - 批次檢測
    
    /// 批次檢測多個書目
    /// - Parameters:
    ///   - entries: 待檢測的 BibTeX 書目列表
    ///   - library: 目標文獻庫
    ///   - context: Core Data 上下文
    /// - Returns: 批次檢測結果
    static func batchCheck(
        entries: [BibTeXEntry],
        in library: Library,
        context: NSManagedObjectContext
    ) -> [BatchDetectionResult] {
        
        return entries.map { entry in
            let result = checkDuplicate(
                doi: entry.fields["doi"],
                title: entry.fields["title"] ?? "",
                in: library,
                context: context
            )
            return BatchDetectionResult(entry: entry, result: result)
        }
    }
    
    /// 篩選出重複的書目
    static func filterDuplicates(
        from results: [BatchDetectionResult]
    ) -> [BatchDetectionResult] {
        return results.filter { $0.result.isDuplicate }
    }
    
    // MARK: - 庫內重複檢測
    
    /// 檢測文獻庫內的重複書目
    /// - Parameters:
    ///   - library: 文獻庫
    ///   - context: Core Data 上下文
    /// - Returns: 重複書目組（每組包含相似的多個書目）
    static func findDuplicatesInLibrary(
        _ library: Library,
        context: NSManagedObjectContext,
        similarityThreshold: Double = defaultSimilarityThreshold
    ) -> [[Entry]] {
        
        let allEntries = fetchAllEntries(in: library, context: context)
        var duplicateGroups: [[Entry]] = []
        var processedIds: Set<UUID> = []
        
        for i in 0..<allEntries.count {
            let entry = allEntries[i]
            
            // 跳過已處理的書目
            guard !processedIds.contains(entry.id) else { continue }
            
            var group: [Entry] = [entry]
            let normalizedTitle = normalizeTitle(entry.title)
            let doi = entry.fields["doi"]
            
            for j in (i + 1)..<allEntries.count {
                let other = allEntries[j]
                guard !processedIds.contains(other.id) else { continue }
                
                // 檢查 DOI
                if let doi = doi, !doi.isEmpty,
                   let otherDOI = other.fields["doi"],
                   doi.lowercased() == otherDOI.lowercased() {
                    group.append(other)
                    processedIds.insert(other.id)
                    continue
                }
                
                // 檢查標題相似度
                let otherTitle = normalizeTitle(other.title)
                let score = calculateSimilarity(normalizedTitle, otherTitle)
                
                if score >= similarityThreshold {
                    group.append(other)
                    processedIds.insert(other.id)
                }
            }
            
            // 只保留有重複的組
            if group.count > 1 {
                duplicateGroups.append(group)
                processedIds.insert(entry.id)
            }
        }
        
        return duplicateGroups
    }
    
    // MARK: - 輔助方法
    
    /// 根據 DOI 查找書目
    private static func findByDOI(
        _ doi: String,
        in library: Library,
        context: NSManagedObjectContext
    ) -> Entry? {
        
        let normalizedDOI = doi.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除常見前綴
        let cleanDOI = normalizedDOI
            .replacingOccurrences(of: "https://doi.org/", with: "")
            .replacingOccurrences(of: "http://doi.org/", with: "")
            .replacingOccurrences(of: "doi:", with: "")
        
        let request = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "library == %@", library)
        
        do {
            let entries = try context.fetch(request)
            return entries.first { entry in
                guard let entryDOI = entry.fields["doi"]?.lowercased() else { return false }
                let cleanEntryDOI = entryDOI
                    .replacingOccurrences(of: "https://doi.org/", with: "")
                    .replacingOccurrences(of: "http://doi.org/", with: "")
                    .replacingOccurrences(of: "doi:", with: "")
                return cleanEntryDOI == cleanDOI
            }
        } catch {
            print("查找 DOI 失敗：\(error)")
            return nil
        }
    }
    
    /// 獲取庫中所有書目
    private static func fetchAllEntries(
        in library: Library,
        context: NSManagedObjectContext
    ) -> [Entry] {
        let request = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "library == %@", library)
        
        do {
            return try context.fetch(request)
        } catch {
            print("獲取書目失敗：\(error)")
            return []
        }
    }
    
    /// 標準化標題（用於比對）
    private static func normalizeTitle(_ title: String) -> String {
        return title
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            // 移除標點符號
            .replacingOccurrences(of: "[^a-z0-9\\u4e00-\\u9fff\\s]", with: "", options: .regularExpression)
            // 壓縮空白
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    /// 計算字串相似度（Levenshtein Distance）
    /// - Returns: 0.0 - 1.0 之間的相似度分數
    static func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        guard !s1.isEmpty && !s2.isEmpty else { return 0 }
        
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    /// Levenshtein 編輯距離算法
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        
        let m = s1Array.count
        let n = s2Array.count
        
        // 快速返回
        if m == 0 { return n }
        if n == 0 { return m }
        
        // 使用滾動數組優化空間
        var previousRow = Array(0...n)
        var currentRow = [Int](repeating: 0, count: n + 1)
        
        for i in 1...m {
            currentRow[0] = i
            
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                currentRow[j] = min(
                    previousRow[j] + 1,      // 刪除
                    currentRow[j - 1] + 1,   // 插入
                    previousRow[j - 1] + cost // 替換
                )
            }
            
            swap(&previousRow, &currentRow)
        }
        
        return previousRow[n]
    }
}

// MARK: - 合併策略

extension DuplicateDetectionService {
    
    /// 合併策略
    enum MergeStrategy {
        case keepExisting      // 保留現有，忽略新的
        case replaceWithNew    // 用新的替換現有
        case mergeFields       // 合併欄位（新的填補空缺）
        case keepBoth          // 保留兩者
    }
    
    /// 合併選項
    struct MergeOption {
        let title: String
        let strategy: MergeStrategy
        let description: String
        
        static let options: [MergeOption] = [
            MergeOption(
                title: "保留現有",
                strategy: .keepExisting,
                description: "忽略新匯入的重複文獻"
            ),
            MergeOption(
                title: "替換為新的",
                strategy: .replaceWithNew,
                description: "用新文獻替換現有文獻"
            ),
            MergeOption(
                title: "合併欄位",
                strategy: .mergeFields,
                description: "保留現有資料，用新資料填補空缺欄位"
            ),
            MergeOption(
                title: "保留兩者",
                strategy: .keepBoth,
                description: "同時保留現有和新的文獻"
            )
        ]
    }
    
    /// 執行合併
    /// - Parameters:
    ///   - existing: 現有書目
    ///   - newEntry: 新書目資料
    ///   - strategy: 合併策略
    ///   - context: Core Data 上下文
    static func merge(
        existing: Entry,
        with newEntry: BibTeXEntry,
        strategy: MergeStrategy,
        context: NSManagedObjectContext
    ) throws {
        switch strategy {
        case .keepExisting:
            // 不做任何事
            break
            
        case .replaceWithNew:
            // 更新所有欄位
            existing.fields = newEntry.fields
            existing.entryType = newEntry.type
            existing.bibtexRaw = existing.generateBibTeX()
            existing.updatedAt = Date()
            try context.save()
            
        case .mergeFields:
            // 只填補空缺欄位
            var mergedFields = existing.fields
            for (key, value) in newEntry.fields {
                if mergedFields[key] == nil || mergedFields[key]?.isEmpty == true {
                    mergedFields[key] = value
                }
            }
            existing.fields = mergedFields
            existing.bibtexRaw = existing.generateBibTeX()
            existing.updatedAt = Date()
            try context.save()
            
        case .keepBoth:
            // 不做任何事，讓呼叫者創建新書目
            break
        }
    }
}
