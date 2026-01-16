//
//  RelatedLiteratureService.swift
//  OVEREND
//
//  相關文獻推薦服務 - 根據關鍵詞、作者、期刊推薦相似文獻
//

import Foundation
import CoreData

/// 相似原因
enum SimilarityReason: Hashable {
    case sameAuthor(String)
    case sameKeyword(String)
    case sameJournal(String)
    case sameYear(String)
    case sameTopic
    
    var description: String {
        switch self {
        case .sameAuthor(let author):
            return "同作者：\(author)"
        case .sameKeyword(let keyword):
            return "相同關鍵詞：\(keyword)"
        case .sameJournal(let journal):
            return "同期刊：\(journal)"
        case .sameYear(let year):
            return "同年份：\(year)"
        case .sameTopic:
            return "相似主題"
        }
    }
    
    var icon: String {
        switch self {
        case .sameAuthor: return "person.fill"
        case .sameKeyword: return "tag.fill"
        case .sameJournal: return "book.fill"
        case .sameYear: return "calendar"
        case .sameTopic: return "doc.text.magnifyingglass"
        }
    }
}

/// 相關文獻結果
struct RelatedEntry: Identifiable {
    let id = UUID()
    let entry: Entry
    let score: Double
    let reasons: [SimilarityReason]
    
    var primaryReason: SimilarityReason? {
        reasons.first
    }
}

/// 相關文獻推薦服務
class RelatedLiteratureService {
    static let shared = RelatedLiteratureService()
    
    private init() {}
    
    // MARK: - 公開方法
    
    /// 查找相關文獻
    /// - Parameters:
    ///   - entry: 目標文獻
    ///   - context: Core Data 上下文
    ///   - limit: 結果數量限制
    /// - Returns: 相關文獻列表（按相似度排序）
    func findRelated(
        to entry: Entry,
        in context: NSManagedObjectContext,
        limit: Int = 5
    ) -> [RelatedEntry] {
        // 獲取所有其他文獻
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "id != %@", entry.id as CVarArg)
        
        guard let allEntries = try? context.fetch(request) else {
            return []
        }
        
        // 計算每個文獻的相似度
        var relatedEntries: [RelatedEntry] = []
        
        for otherEntry in allEntries {
            let (score, reasons) = calculateSimilarity(between: entry, and: otherEntry)
            
            if score > 0 {
                relatedEntries.append(RelatedEntry(
                    entry: otherEntry,
                    score: score,
                    reasons: reasons
                ))
            }
        }
        
        // 按相似度排序並限制數量
        return relatedEntries
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - 私有方法
    
    /// 計算兩個文獻的相似度
    private func calculateSimilarity(
        between entry1: Entry,
        and entry2: Entry
    ) -> (score: Double, reasons: [SimilarityReason]) {
        var score: Double = 0
        var reasons: [SimilarityReason] = []
        
        // 1. 作者相似度（權重最高）
        let authorScore = calculateAuthorSimilarity(entry1: entry1, entry2: entry2)
        if let (authorPoints, matchedAuthor) = authorScore {
            score += authorPoints * 3.0
            reasons.append(.sameAuthor(matchedAuthor))
        }
        
        // 2. 關鍵詞相似度
        let keywordScore = calculateKeywordSimilarity(entry1: entry1, entry2: entry2)
        if let (keywordPoints, matchedKeyword) = keywordScore {
            score += keywordPoints * 2.0
            reasons.append(.sameKeyword(matchedKeyword))
        }
        
        // 3. 期刊相似度
        if let journal1 = entry1.fields["journal"]?.lowercased(),
           let journal2 = entry2.fields["journal"]?.lowercased(),
           !journal1.isEmpty && journal1 == journal2 {
            score += 2.0
            reasons.append(.sameJournal(entry1.fields["journal"] ?? ""))
        }
        
        // 4. 年份相似度
        if let year1 = entry1.fields["year"],
           let year2 = entry2.fields["year"],
           !year1.isEmpty && year1 == year2 {
            score += 1.0
            reasons.append(.sameYear(year1))
        }
        
        // 5. 標題關鍵詞相似度
        let titleScore = calculateTitleSimilarity(entry1: entry1, entry2: entry2)
        if titleScore > 0.3 {
            score += titleScore * 1.5
            reasons.append(.sameTopic)
        }
        
        return (score, reasons)
    }
    
    /// 計算作者相似度
    private func calculateAuthorSimilarity(entry1: Entry, entry2: Entry) -> (Double, String)? {
        guard let authors1 = entry1.fields["author"],
              let authors2 = entry2.fields["author"] else {
            return nil
        }
        
        let authorList1 = parseAuthors(authors1)
        let authorList2 = parseAuthors(authors2)
        
        for author1 in authorList1 {
            for author2 in authorList2 {
                if authorsMatch(author1, author2) {
                    return (1.0, author1)
                }
            }
        }
        
        return nil
    }
    
    /// 解析作者字串
    private func parseAuthors(_ authorString: String) -> [String] {
        // 支援 "and", "," 分隔
        return authorString
            .replacingOccurrences(of: " and ", with: ",")
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// 比較兩個作者是否相同
    private func authorsMatch(_ author1: String, _ author2: String) -> Bool {
        let normalized1 = author1.lowercased()
        let normalized2 = author2.lowercased()
        
        // 完全匹配
        if normalized1 == normalized2 {
            return true
        }
        
        // 姓氏匹配（對於 "Last, First" 格式）
        let lastName1 = normalized1.components(separatedBy: ",").first ?? normalized1
        let lastName2 = normalized2.components(separatedBy: ",").first ?? normalized2
        
        return lastName1 == lastName2
    }
    
    /// 計算關鍵詞相似度
    private func calculateKeywordSimilarity(entry1: Entry, entry2: Entry) -> (Double, String)? {
        guard let keywords1 = entry1.fields["keywords"],
              let keywords2 = entry2.fields["keywords"] else {
            return nil
        }
        
        let keywordList1 = parseKeywords(keywords1)
        let keywordList2 = parseKeywords(keywords2)
        
        for kw1 in keywordList1 {
            for kw2 in keywordList2 {
                if kw1.lowercased() == kw2.lowercased() {
                    return (1.0, kw1)
                }
            }
        }
        
        return nil
    }
    
    /// 解析關鍵詞字串
    private func parseKeywords(_ keywordString: String) -> [String] {
        return keywordString
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// 計算標題相似度（使用簡單的詞彙重疊）
    private func calculateTitleSimilarity(entry1: Entry, entry2: Entry) -> Double {
        let title1Words = extractSignificantWords(from: entry1.fields["title"] ?? "")
        let title2Words = extractSignificantWords(from: entry2.fields["title"] ?? "")
        
        guard !title1Words.isEmpty && !title2Words.isEmpty else {
            return 0
        }
        
        let intersection = title1Words.intersection(title2Words)
        let union = title1Words.union(title2Words)
        
        return Double(intersection.count) / Double(union.count)
    }
    
    /// 提取重要詞彙（過濾停用詞）
    private func extractSignificantWords(from text: String) -> Set<String> {
        let stopWords = Set([
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "is", "are", "was", "were", "be", "been",
            "being", "have", "has", "had", "do", "does", "did", "will", "would",
            "could", "should", "may", "might", "must", "shall", "can", "need",
            "的", "是", "在", "與", "和", "之", "其", "個", "為", "中", "以"
        ])
        
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopWords.contains($0) }
        
        return Set(words)
    }
}
