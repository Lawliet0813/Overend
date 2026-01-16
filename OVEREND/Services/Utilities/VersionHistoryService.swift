//
//  VersionHistoryService.swift
//  OVEREND
//
//  版本歷史服務 - 自動儲存版本快照，支援還原
//

import Foundation
import CoreData
import Combine
import AppKit

/// 文檔版本快照
struct DocumentVersionSnapshot: Identifiable {
    let id: UUID
    let documentID: UUID
    let content: Data
    let wordCount: Int
    let createdAt: Date
    let note: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: createdAt)
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

/// 版本差異
struct VersionDiff {
    let added: Int      // 新增字數
    let removed: Int    // 刪除字數
    let changed: Bool   // 是否有變更
    
    var summary: String {
        if !changed {
            return "無變更"
        }
        
        var parts: [String] = []
        if added > 0 { parts.append("+\(added)") }
        if removed > 0 { parts.append("-\(removed)") }
        return parts.joined(separator: " ")
    }
}

/// 版本歷史服務
class VersionHistoryService: ObservableObject {
    static let shared = VersionHistoryService()
    
    // 版本快照儲存路徑
    private let versionsDirectory: URL
    
    // 最大版本數量
    private let maxVersions = 50
    
    // 自動儲存間隔（秒）
    private let autoSaveInterval: TimeInterval = 300 // 5 分鐘
    
    // 版本快取
    @Published private(set) var versions: [UUID: [DocumentVersionSnapshot]] = [:]
    
    private init() {
        // 設定版本儲存目錄
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        versionsDirectory = appSupport.appendingPathComponent("OVEREND/Versions", isDirectory: true)
        
        // 確保目錄存在
        try? FileManager.default.createDirectory(at: versionsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - 公開方法
    
    /// 建立版本快照
    /// - Parameters:
    ///   - document: 文檔
    ///   - note: 版本備註（可選）
    func createVersion(for document: Document, note: String? = nil) async {
        guard let content = document.rtfData else { return }
        
        let snapshot = DocumentVersionSnapshot(
            id: UUID(),
            documentID: document.id,
            content: content,
            wordCount: countWords(in: content),
            createdAt: Date(),
            note: note
        )
        
        // 儲存到磁碟
        await saveSnapshotToDisk(snapshot)
        
        // 更新快取
        await MainActor.run {
            if versions[document.id] == nil {
                versions[document.id] = []
            }
            versions[document.id]?.insert(snapshot, at: 0)
            
            // 保持最大版本數
            if versions[document.id]?.count ?? 0 > maxVersions {
                versions[document.id]?.removeLast()
            }
        }
        
        // 清理舊版本檔案
        await cleanupOldVersions(for: document.id)
    }
    
    /// 取得文檔的版本列表
    /// - Parameter documentID: 文檔 ID
    /// - Returns: 版本快照列表（按時間降序）
    func getVersions(for documentID: UUID) async -> [DocumentVersionSnapshot] {
        // 先檢查快取
        if let cached = versions[documentID], !cached.isEmpty {
            return cached
        }
        
        // 從磁碟載入
        let loadedVersions = await loadVersionsFromDisk(for: documentID)
        
        await MainActor.run {
            versions[documentID] = loadedVersions
        }
        
        return loadedVersions
    }
    
    /// 還原到指定版本
    /// - Parameters:
    ///   - version: 版本快照
    ///   - document: 目標文檔
    func restoreVersion(_ version: DocumentVersionSnapshot, to document: Document) async {
        // 先建立當前版本的備份
        await createVersion(for: document, note: "還原前自動備份")
        
        // 還原內容
        await MainActor.run {
            document.rtfData = version.content
            document.updatedAt = Date()
        }
    }
    
    /// 比較兩個版本
    /// - Parameters:
    ///   - v1: 版本 1
    ///   - v2: 版本 2
    /// - Returns: 版本差異
    func compareVersions(_ v1: DocumentVersionSnapshot, _ v2: DocumentVersionSnapshot) -> VersionDiff {
        let words1 = v1.wordCount
        let words2 = v2.wordCount
        let diff = words2 - words1
        
        return VersionDiff(
            added: diff > 0 ? diff : 0,
            removed: diff < 0 ? -diff : 0,
            changed: words1 != words2
        )
    }
    
    /// 刪除版本
    /// - Parameter version: 版本快照
    func deleteVersion(_ version: DocumentVersionSnapshot) async {
        // 從快取移除
        await MainActor.run {
            versions[version.documentID]?.removeAll { $0.id == version.id }
        }
        
        // 從磁碟刪除
        let filePath = versionFilePath(for: version)
        try? FileManager.default.removeItem(at: filePath)
    }
    
    // MARK: - 私有方法
    
    /// 儲存快照到磁碟
    private func saveSnapshotToDisk(_ snapshot: DocumentVersionSnapshot) async {
        let filePath = versionFilePath(for: snapshot)
        
        // 建立版本目錄
        let docDir = versionsDirectory.appendingPathComponent(snapshot.documentID.uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: docDir, withIntermediateDirectories: true)
        
        // 編碼儲存
        let data = encodeSnapshot(snapshot)
        try? data?.write(to: filePath)
    }
    
    /// 從磁碟載入版本
    private func loadVersionsFromDisk(for documentID: UUID) async -> [DocumentVersionSnapshot] {
        let docDir = versionsDirectory.appendingPathComponent(documentID.uuidString, isDirectory: true)
        
        guard FileManager.default.fileExists(atPath: docDir.path) else {
            return []
        }
        
        var snapshots: [DocumentVersionSnapshot] = []
        
        if let files = try? FileManager.default.contentsOfDirectory(at: docDir, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "version" {
                if let data = try? Data(contentsOf: file),
                   let snapshot = decodeSnapshot(data) {
                    snapshots.append(snapshot)
                }
            }
        }
        
        // 按時間降序排序
        return snapshots.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// 清理舊版本
    private func cleanupOldVersions(for documentID: UUID) async {
        let allVersions = await getVersions(for: documentID)
        
        if allVersions.count > maxVersions {
            let toDelete = allVersions.suffix(from: maxVersions)
            for version in toDelete {
                await deleteVersion(version)
            }
        }
    }
    
    /// 取得版本檔案路徑
    private func versionFilePath(for snapshot: DocumentVersionSnapshot) -> URL {
        versionsDirectory
            .appendingPathComponent(snapshot.documentID.uuidString, isDirectory: true)
            .appendingPathComponent("\(snapshot.id.uuidString).version")
    }
    
    /// 編碼快照
    private func encodeSnapshot(_ snapshot: DocumentVersionSnapshot) -> Data? {
        let dict: [String: Any] = [
            "id": snapshot.id.uuidString,
            "documentID": snapshot.documentID.uuidString,
            "content": snapshot.content,
            "wordCount": snapshot.wordCount,
            "createdAt": snapshot.createdAt.timeIntervalSince1970,
            "note": snapshot.note ?? ""
        ]
        return try? JSONSerialization.data(withJSONObject: dict)
    }
    
    /// 解碼快照
    private func decodeSnapshot(_ data: Data) -> DocumentVersionSnapshot? {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let docIDString = dict["documentID"] as? String,
              let documentID = UUID(uuidString: docIDString),
              let content = dict["content"] as? Data,
              let wordCount = dict["wordCount"] as? Int,
              let createdAtInterval = dict["createdAt"] as? TimeInterval else {
            return nil
        }
        
        return DocumentVersionSnapshot(
            id: id,
            documentID: documentID,
            content: content,
            wordCount: wordCount,
            createdAt: Date(timeIntervalSince1970: createdAtInterval),
            note: dict["note"] as? String
        )
    }
    
    /// 計算字數
    private func countWords(in data: Data) -> Int {
        guard let attrString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            return 0
        }
        
        let text = attrString.string
        
        // 中文字數
        let chineseCount = text.filter { $0.unicodeScalars.allSatisfy { $0.value >= 0x4E00 && $0.value <= 0x9FFF } }.count
        
        // 英文單詞數
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.rangeOfCharacter(from: CharacterSet.letters) != nil }
            .filter { !$0.unicodeScalars.allSatisfy { $0.value >= 0x4E00 && $0.value <= 0x9FFF } }
        
        return chineseCount + words.count
    }
}
