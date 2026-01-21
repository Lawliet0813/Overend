//
//  LiteratureAgent.swift
//  OVEREND
//
//  文獻 Agent - 自動化文獻整理、分類與標籤 (演算法版本)
//  整合 NLPService, TextSummarizer, CategoryClassifier 以確保單檔編譯。
//

import Foundation
import SwiftUI
import Combine
import CoreData
import PDFKit
import NaturalLanguage

// MARK: - Agent 任務類型

public enum AgentTask: Identifiable, Equatable {
    case analyzeEntry(Entry)
    case classifyEntries([Entry])
    case autoTagEntries([Entry])
    case organizeByTopic(Library)
    case generateSummaries([Entry])
    case findDuplicates(Library)
    case batchProcess([Entry])
    case extractPDFMetadata(URL, strategy: ExtractionStrategy)
    
    public var id: String {
        switch self {
        case .analyzeEntry(let entry): return "analyze-\(entry.id)"
        case .classifyEntries(let entries): return "classify-\(entries.count)"
        case .autoTagEntries(let entries): return "tag-\(entries.count)"
        case .organizeByTopic(let library): return "organize-\(library.id)"
        case .generateSummaries(let entries): return "summaries-\(entries.count)"
        case .findDuplicates(let library): return "duplicates-\(library.id)"
        case .batchProcess(let entries): return "batch-\(entries.count)"
        case .extractPDFMetadata(let url, _): return "pdf-\(url.lastPathComponent)"
        }
    }
    
    public var displayName: String {
        switch self {
        case .analyzeEntry: return "分析文獻"
        case .classifyEntries: return "智慧分類"
        case .autoTagEntries: return "自動標籤"
        case .organizeByTopic: return "主題整理"
        case .generateSummaries: return "生成摘要"
        case .findDuplicates: return "尋找重複"
        case .batchProcess: return "批次處理"
        case .extractPDFMetadata(_, let strategy): 
            switch strategy {
            case .algorithm: return "PDF 提取 (演算法)"
            case .ai: return "PDF 提取 (AI)"
            case .hybrid: return "PDF 提取 (混合)"
            }
        }
    }
    
    public var icon: String {
        switch self {
        case .analyzeEntry: return "doc.text.magnifyingglass"
        case .classifyEntries: return "folder.badge.gearshape"
        case .autoTagEntries: return "tag.fill"
        case .organizeByTopic: return "rectangle.3.group"
        case .generateSummaries: return "doc.plaintext"
        case .findDuplicates: return "doc.on.doc"
        case .batchProcess: return "square.stack.3d.up"
        case .extractPDFMetadata: return "doc.viewfinder"
        }
    }
    
    public static func == (lhs: AgentTask, rhs: AgentTask) -> Bool { lhs.id == rhs.id }
}

public enum ExtractionStrategy: Equatable {
    case algorithm
    case ai
    case hybrid
}

// MARK: - Agent 狀態

public enum AgentState: Equatable {
    case idle, analyzing, classifying, tagging, organizing, summarizing, completed
    case failed(String)
    
    public var isExecuting: Bool {
        switch self {
        case .idle, .completed, .failed: return false
        default: return true
        }
    }
    
    public var statusText: String {
        switch self {
        case .idle: return "準備就緒"
        case .analyzing: return "正在分析..."
        case .classifying: return "正在分類..."
        case .tagging: return "正在標籤..."
        case .organizing: return "正在整理..."
        case .summarizing: return "正在摘要..."
        case .completed: return "已完成"
        case .failed(let error): return "失敗：\(error)"
        }
    }
}

// MARK: - Agent 結果

public struct AgentResult {
    public let task: AgentTask
    public let success: Bool
    public let message: String
    public let suggestions: [AgentSuggestion]
    public let duration: TimeInterval
    
    public init(task: AgentTask, success: Bool, message: String, suggestions: [AgentSuggestion] = [], duration: TimeInterval = 0) {
        self.task = task
        self.success = success
        self.message = message
        self.suggestions = suggestions
        self.duration = duration
    }
}

public struct AgentSuggestion: Identifiable {
    public let id = UUID()
    public let entry: Entry
    public let type: SuggestionType
    public let value: String
    public let confidence: Double
    
    public enum SuggestionType {
        case group(String), tag(String), summary(String), duplicate(Entry)
    }
}

// MARK: - 文獻 Agent

@MainActor
public class LiteratureAgent: ObservableObject {
    public static let shared = LiteratureAgent()
    
    @Published public var state: AgentState = .idle
    @Published public var currentTask: AgentTask?
    
    // ... (Existing properties)

    // MARK: - Helper Methods
    
    // Enum moved to top level

    public func extractPDFMetadata(from url: URL, strategy: ExtractionStrategy = .hybrid) async throws -> PDFExtractionResult {
        _ = try await execute(task: .extractPDFMetadata(url, strategy: strategy))
        if let result = lastExtractionResult {
            return result
        }
        throw NSError(domain: "LiteratureAgent", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve metadata"])
    }
    
    private func extractWithAlgorithm(_ url: URL) async throws -> PDFExtractionResult {
        // Logic moved from previous extractPDFMetadataTask
         let metadata = await pdfMetadataService.extract(from: url)
         let result = PDFExtractionResult(
             title: metadata.title,
             authors: metadata.authors,
             year: metadata.year,
             journal: metadata.journal,
             doi: metadata.doi,
             abstract: metadata.abstract,
             entryType: metadata.entryType,
             confidence: metadata.confidence == .high ? 0.9 : (metadata.confidence == .medium ? 0.6 : 0.3)
         )
         lastExtractionResult = result
         return result
    }
    
    private func extractWithAI(_ url: URL) async throws -> PDFExtractionResult {
        // 1. Extract text from PDF
        let (_, pdfText) = try PDFService.shared.extractPDFMetadata(from: url)
        guard let text = pdfText, !text.isEmpty else {
            throw NSError(domain: "LiteratureAgent", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty PDF text"])
        }
        
        // 2. Call Unified AI Service
        let extracted = try await UnifiedAIService.shared.document.extractMetadata(from: text, filename: url.deletingPathExtension().lastPathComponent)
        
        // 3. Map to PDFExtractionResult
        let result = PDFExtractionResult(
            title: extracted.title ?? url.deletingPathExtension().lastPathComponent,
            authors: extracted.authors,
            year: extracted.year,
            journal: extracted.journal,
            doi: extracted.doi,
            abstract: nil, // AI extraction might typically skip abstract content in struct return, or we can parse it if DocumentAIDomain provided it. DocumentAIDomain doesn't seem to return abstract in ExtractedDocumentMetadata
            entryType: extracted.entryType ?? "article",
            confidence: extracted.confidence == .high ? 0.95 : (extracted.confidence == .medium ? 0.7 : 0.4)
        )
        lastExtractionResult = result
        return result
    }
    @Published public var progress: Double = 0
    @Published public var progressMessage: String = ""
    @Published public var lastResult: AgentResult?
    @Published public var pendingSuggestions: [AgentSuggestion] = []
    
    public struct PDFExtractionResult {
        public let title: String
        public let authors: [String]
        public let year: String?
        public let journal: String?
        public let doi: String?
        public let abstract: String?
        public let entryType: String
        public let confidence: Double
        
        public var fields: [String: String] {
            var result: [String: String] = ["title": title]
            if !authors.isEmpty { result["author"] = authors.joined(separator: " and ") }
            if let year = year { result["year"] = year }
            if let journal = journal { result["journal"] = journal }
            if let doi = doi { result["doi"] = doi }
            if let abstract = abstract { result["abstract"] = abstract }
            return result
        }
    }
    
    @Published public var lastExtractionResult: PDFExtractionResult?

    private let maxSuggestions = 1000
    private var cancellables = Set<AnyCancellable>()
    private var failureCount: [String: Int] = [:]
    
    private let nlp = NLPService.shared
    private let summarizer = TextSummarizer.shared
    private let classifier = CategoryClassifier.shared
    private let keywordExtractor = KeywordExtractor.shared
    private let pdfMetadataService = PDFMetadataService.shared
    
    private var entryRepository: EntryRepositoryProtocol
    
    init(entryRepository: EntryRepositoryProtocol = EntryRepository()) {
        self.entryRepository = entryRepository
        AppLogger.shared.notice("🤖 LiteratureAgent (Algorithm): 初始化完成")
    }
    
    func setEntryRepository(_ repository: EntryRepositoryProtocol) {
        self.entryRepository = repository
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    public func execute(task: AgentTask) async throws -> AgentResult {
        let startTime = Date()
        currentTask = task
        progress = 0
        AppLogger.shared.info("🤖 Agent 開始任務: \(task.displayName)")
        
        do {
            let result: AgentResult
            switch task {
            case .analyzeEntry(let entry):
                state = .analyzing
                result = try await analyzeEntry(entry)
            case .classifyEntries(let entries):
                state = .classifying
                result = try await classifyEntriesTask(entries)
            case .autoTagEntries(let entries):
                state = .tagging
                result = try await autoTagEntriesTask(entries)
            case .organizeByTopic(let library):
                state = .organizing
                result = try await organizeByTopicTask(library)
            case .generateSummaries(let entries):
                state = .summarizing
                result = try await generateSummariesTask(entries)
            case .findDuplicates(let library):
                state = .analyzing
                result = try await findDuplicatesTask(library)
            case .batchProcess(let entries):
                result = try await batchProcessTask(entries)
            case .extractPDFMetadata(let url, let strategy):
                state = .analyzing
                result = try await extractPDFMetadataTask(url, strategy: strategy)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let finalResult = AgentResult(task: task, success: result.success, message: result.message, suggestions: result.suggestions, duration: duration)

            limitSuggestions(adding: result.suggestions)
            state = .completed
            lastResult = finalResult
            currentTask = nil
            progress = 1.0
            AppLogger.shared.notice("🤖 Agent 完成任務: \(task.displayName) (耗時: \(String(format: "%.1f", duration))s)")
            return finalResult

        } catch {
            state = .failed(error.localizedDescription)
            currentTask = nil
            failureCount[task.displayName, default: 0] += 1
            AppLogger.shared.error("🤖 Agent 任務失敗 [\(task.displayName)]: \(error.localizedDescription)")
            throw error
        }
    }

    private func limitSuggestions(adding newSuggestions: [AgentSuggestion]) {
        let totalCount = pendingSuggestions.count + newSuggestions.count
        if totalCount > maxSuggestions {
            let overflow = totalCount - maxSuggestions
            pendingSuggestions.removeFirst(overflow)
        }
        pendingSuggestions.append(contentsOf: newSuggestions)
    }

    /// 應用建議
    public func applySuggestion(_ suggestion: AgentSuggestion, context: NSManagedObjectContext) throws {
        switch suggestion.type {
        case .group(let groupName):
            // 將條目加入群組
            // TODO: 實作群組邏輯
            break
        case .tag(let tagName):
            // 為條目添加標籤
            // TODO: 實作標籤邏輯
            break
        case .summary(let summary):
            // 將摘要保存到條目
            if let abstract = suggestion.entry.fields["abstract"] {
                suggestion.entry.fields["abstract"] = summary
            }
        case .duplicate(let duplicateEntry):
            // 標記為重複
            // TODO: 實作重複處理邏輯
            break
        }

        // 從待處理列表中移除
        if let index = pendingSuggestions.firstIndex(where: { $0.id == suggestion.id }) {
            pendingSuggestions.remove(at: index)
        }

        try context.save()
    }

    private func analyzeEntry(_ entry: Entry) async throws -> AgentResult {
        progressMessage = "正在分析: \(entry.title)"
        let title = entry.title
        let abstract = entry.fields["abstract"] ?? ""
        let content = title + "\n" + abstract
        var suggestions: [AgentSuggestion] = []
        
        progress = 0.3
        let keywords = keywordExtractor.extractKeywords(from: content, limit: 5)
        for keyword in keywords {
            suggestions.append(AgentSuggestion(entry: entry, type: .tag(keyword), value: keyword, confidence: 0.8))
        }
        
        progress = 0.6
        let categories = classifier.classify(content)
        for category in categories {
            suggestions.append(AgentSuggestion(entry: entry, type: .group(category), value: category, confidence: 0.7))
        }
        
        progress = 0.9
        if abstract.isEmpty && title.count > 20 {
            let summary = summarizer.summarize(title, title: title, maxSentences: 1)
             suggestions.append(AgentSuggestion(entry: entry, type: .summary(summary), value: summary, confidence: 0.5))
        }
        
        return AgentResult(task: .analyzeEntry(entry), success: true, message: "分析完成", suggestions: suggestions)
    }
    
    private func classifyEntriesTask(_ entries: [Entry]) async throws -> AgentResult {
        var allSuggestions: [AgentSuggestion] = []
        for (index, entry) in entries.enumerated() {
            progress = Double(index) / Double(entries.count)
            let content = entry.title + "\n" + (entry.fields["abstract"] ?? "")
            let categories = classifier.classify(content)
            for category in categories {
                allSuggestions.append(AgentSuggestion(entry: entry, type: .group(category), value: category, confidence: 0.7))
            }
        }
        return AgentResult(task: .classifyEntries(entries), success: true, message: "分類完成", suggestions: allSuggestions)
    }
    
    private func autoTagEntriesTask(_ entries: [Entry]) async throws -> AgentResult {
        var allSuggestions: [AgentSuggestion] = []
        for (index, entry) in entries.enumerated() {
            progress = Double(index) / Double(entries.count)
            let content = entry.title + "\n" + (entry.fields["abstract"] ?? "")
            let keywords = keywordExtractor.extractKeywords(from: content, limit: 5)
            for keyword in keywords {
                allSuggestions.append(AgentSuggestion(entry: entry, type: .tag(keyword), value: keyword, confidence: 0.8))
            }
        }
        return AgentResult(task: .autoTagEntries(entries), success: true, message: "標籤完成", suggestions: allSuggestions)
    }
    
    private func organizeByTopicTask(_ library: Library) async throws -> AgentResult {
        let allEntries = try await entryRepository.fetchAll(in: library, sortBy: .updated)
        let unclassified = allEntries.filter { ($0.groups?.isEmpty ?? true) }
        if unclassified.isEmpty {
            return AgentResult(task: .organizeByTopic(library), success: true, message: "已無未分類文獻")
        }
        return try await classifyEntriesTask(unclassified)
    }
    
    private func generateSummariesTask(_ entries: [Entry]) async throws -> AgentResult {
        var allSuggestions: [AgentSuggestion] = []
        let entriesNeedingSummary = entries.filter { ($0.fields["abstract"]?.isEmpty ?? true) }
        for (index, entry) in entriesNeedingSummary.enumerated() {
            progress = Double(index) / Double(entriesNeedingSummary.count)
            let summary = summarizer.summarize(entry.title, title: entry.title)
             if !summary.isEmpty {
                allSuggestions.append(AgentSuggestion(entry: entry, type: .summary(summary), value: summary, confidence: 0.5))
            }
        }
        return AgentResult(task: .generateSummaries(entries), success: true, message: "摘要生成完成", suggestions: allSuggestions)
    }
    
    private func findDuplicatesTask(_ library: Library) async throws -> AgentResult {
        let allEntries = try await entryRepository.fetchAll(in: library, sortBy: .updated)
        var duplicates: [AgentSuggestion] = []
        var checked = Set<UUID>()
        let vectors: [UUID: [String: Double]] = allEntries.reduce(into: [:]) { dict, entry in
            dict[entry.id] = nlp.computeTF(for: entry.title)
        }
        for entry in allEntries {
            if checked.contains(entry.id) { continue }
            guard let v1 = vectors[entry.id] else { continue }
            for other in allEntries where other.id != entry.id {
                if checked.contains(other.id) { continue }
                guard let v2 = vectors[other.id] else { continue }
                let similarity = nlp.cosineSimilarity(v1, v2)
                if similarity > 0.85 {
                    duplicates.append(AgentSuggestion(entry: entry, type: .duplicate(other), value: "與「\(other.title)」高度相似 (\(String(format: "%.2f", similarity)))", confidence: similarity))
                    checked.insert(other.id)
                }
            }
            checked.insert(entry.id)
            progress = Double(checked.count) / Double(allEntries.count)
        }
        return AgentResult(task: .findDuplicates(library), success: true, message: "找到 \(duplicates.count) 組重複", suggestions: duplicates)
    }
    
    private func batchProcessTask(_ entries: [Entry]) async throws -> AgentResult {
        var allSuggestions: [AgentSuggestion] = []
        state = .classifying
        let classifyResult = try await classifyEntriesTask(entries)
        allSuggestions.append(contentsOf: classifyResult.suggestions)
        state = .tagging
        let tagResult = try await autoTagEntriesTask(entries)
        allSuggestions.append(contentsOf: tagResult.suggestions)
        return AgentResult(task: .batchProcess(entries), success: true, message: "批次處理完成", suggestions: allSuggestions)
    }
    
    private func extractPDFMetadataTask(_ url: URL, strategy: ExtractionStrategy) async throws -> AgentResult {
        progressMessage = "正在分析 PDF (\(strategy))..."
        
        let result: PDFExtractionResult
        
        switch strategy {
        case .algorithm:
             result = try await extractWithAlgorithm(url)
        case .ai:
             result = try await extractWithAI(url)
        case .hybrid:
             let algoResult = try await extractWithAlgorithm(url)
             if algoResult.confidence > 0.8 { // High confidence
                 result = algoResult
             } else {
                 // Fallback to AI
                 do {
                     AppLogger.shared.notice("🤖 Algorithm confidence low (\(algoResult.confidence)), trying AI...")
                     result = try await extractWithAI(url)
                 } catch {
                     AppLogger.shared.warning("⚠️ AI extraction failed: \(error), returning algorithm result")
                     
                     // Smart Fallback: If Algo confidence is low OR title is generic, use filename
                     let isTitleGeneric = algoResult.title == "Untitled" || algoResult.title.isEmpty || algoResult.title.lowercased() == "untitled"
                     
                     if algoResult.confidence < 0.5 || isTitleGeneric { 
                         result = PDFExtractionResult(
                             title: url.deletingPathExtension().lastPathComponent,
                             authors: algoResult.authors,
                             year: algoResult.year,
                             journal: algoResult.journal,
                             doi: algoResult.doi,
                             abstract: algoResult.abstract,
                             entryType: algoResult.entryType,
                             confidence: algoResult.confidence
                         )
                     } else {
                         result = algoResult
                     }
                 }
             }
        }

        lastExtractionResult = result
        return AgentResult(task: .extractPDFMetadata(url, strategy: strategy), success: true, message: "已提取元數據", suggestions: [])
    }
}

// MARK: - Algorithm Core Services

public class NLPService {
    public static let shared = NLPService()
    private let stopWords: Set<String> = ["the", "a", "an", "and", "but", "in", "on", "at", "to", "for", "of", "with", "is", "are", "was", "were", "this", "that", "it", "from", "as", "which", "的", "了", "和", "是", "在", "中"]
    
    public func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range]).lowercased()
            if !stopWords.contains(word) && !word.isEmpty {
                if word.allSatisfy({ $0.isASCII }) {
                     if word.count > 1 { tokens.append(word) }
                } else { tokens.append(word) }
            }
            return true
        }
        return tokens
    }
    
    public func computeTF(for text: String) -> [String: Double] {
        let tokens = tokenize(text)
        let totalTerms = Double(tokens.count)
        guard totalTerms > 0 else { return [:] }
        var counts: [String: Int] = [:]
        for token in tokens { counts[token, default: 0] += 1 }
        var tf: [String: Double] = [:]
        for (term, count) in counts { tf[term] = Double(count) / totalTerms }
        return tf
    }
    
    public func cosineSimilarity(_ v1: [String: Double], _ v2: [String: Double]) -> Double {
        let allKeys = Set(v1.keys).union(v2.keys)
        var dot = 0.0, mag1 = 0.0, mag2 = 0.0
        for key in allKeys {
            let val1 = v1[key] ?? 0
            let val2 = v2[key] ?? 0
            dot += val1 * val2
            mag1 += val1 * val1
            mag2 += val2 * val2
        }
        if mag1 == 0 || mag2 == 0 { return 0.0 }
        return dot / (sqrt(mag1) * sqrt(mag2))
    }
    
    public func extractKeywords(from text: String, limit: Int = 10) -> [String] {
        let tf = computeTF(for: text)
        return tf.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
}

public class TextSummarizer {
    public static let shared = TextSummarizer()
    private let nlp = NLPService.shared
    
    public func summarize(_ text: String, title: String? = nil, maxSentences: Int = 3) -> String {
        let sentences = segmentSentences(text)
        guard sentences.count > maxSentences else { return text }
        var docTF = nlp.computeTF(for: text)
        if let title = title {
            let titleTokens = nlp.tokenize(title)
            for token in titleTokens { docTF[token, default: 0] += 2.0 }
        }
        var scores: [(index: Int, score: Double, text: String)] = []
        for (i, sentence) in sentences.enumerated() {
            var score = 0.0
            let tokens = nlp.tokenize(sentence)
            if tokens.isEmpty { continue }
            for token in tokens { score += docTF[token] ?? 0 }
            score /= Double(tokens.count)
            let position = Double(i) / Double(sentences.count)
            if position < 0.2 { score *= 1.5 } else if position > 0.8 { score *= 1.2 }
            if tokens.count < 5 { score *= 0.5 }
            scores.append((index: i, score: score, text: sentence))
        }
        let topSentences = scores.sorted { $0.score > $1.score }.prefix(maxSentences)
        let sortedResult = topSentences.sorted { $0.index < $1.index }
        return sortedResult.map { $0.text }.joined(separator: " ")
    }
    
    private func segmentSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sent = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sent.isEmpty { sentences.append(sent) }
            return true
        }
        return sentences
    }
}

public class KeywordExtractor {
    public static let shared = KeywordExtractor()
    private let nlp = NLPService.shared
    public func extractKeywords(from text: String, limit: Int = 10) -> [String] {
        return nlp.extractKeywords(from: text, limit: limit)
    }
}

public class CategoryClassifier {
    public static let shared = CategoryClassifier()
    private let nlp = NLPService.shared
    private let defaultCategories: [String: [String]] = [
        "人工智慧": ["artificial intelligence", "ai", "machine learning", "deep learning", "neural network"],
        "軟體工程": ["software", "engineering", "development", "architecture", "pattern"],
        "資訊安全": ["security", "privacy", "crypto", "encryption", "attack"],
        "網路技術": ["network", "protocol", "http", "wireless", "cloud"],
        "教育科技": ["education", "learning", "teaching", "student", "edtech"],
        "人機互動": ["hci", "interaction", "interface", "ux", "design"],
        "醫學資訊": ["medical", "health", "clinical", "disease", "treatment"]
    ]
    public func classify(_ text: String, limit: Int = 3) -> [String] {
        let tokens = nlp.tokenize(text)
        var scores: [String: Double] = [:]
        for (category, keywords) in defaultCategories {
            var score = 0.0
            for token in tokens {
                if keywords.contains(where: { token.contains($0) }) { score += 1.0 }
            }
            if score > 0 { scores[category] = score }
        }
        return scores.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
}
