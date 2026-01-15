//
//  TemplateManager.swift
//  OVEREND
//
//  範本管理器 - 負責載入、儲存和管理格式範本
//

import Foundation

/// 範本管理器
class TemplateManager {
    static let shared = TemplateManager()
    
    private init() {}
    
    // MARK: - 預設範本
    
    /// 取得所有預設範本
    func builtInTemplates() -> [FormatTemplate] {
        return [
            .nccu,  // 政大論文格式
            .blank,
            .apa,
            .journal,
            .conference
        ]
    }
    
    /// 載入預設範本
    func loadBuiltIn(_ name: String) -> FormatTemplate? {
        switch name {
        case "政大論文格式", "政大行管碩士論文格式", "nccu":
            return .nccu
        case "空白文件", "blank":
            return .blank
        case "APA 格式論文", "apa":
            return .apa
        case "期刊投稿", "journal":
            return .journal
        case "會議論文", "conference":
            return .conference
        default:
            return nil
        }
    }
    
    // MARK: - 自訂範本
    
    /// 取得自訂範本儲存路徑
    private var customTemplatesDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let templatesDir = appSupport
            .appendingPathComponent("OVEREND")
            .appendingPathComponent("Templates")
        
        // 確保目錄存在
        try? FileManager.default.createDirectory(
            at: templatesDir,
            withIntermediateDirectories: true
        )
        
        return templatesDir
    }
    
    /// 載入自訂範本
    func loadCustom(_ filename: String) -> FormatTemplate? {
        let fileURL = customTemplatesDirectory.appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let template = try JSONDecoder().decode(FormatTemplate.self, from: data)
            return template
        } catch {
            print("❌ 載入範本失敗：\(error)")
            return nil
        }
    }
    
    /// 儲存自訂範本
    func saveCustom(_ template: FormatTemplate) throws {
        let filename = "\(template.name).json"
        let fileURL = customTemplatesDirectory.appendingPathComponent(filename)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(template)
        try data.write(to: fileURL)
        
        print("✅ 範本已儲存：\(fileURL.path)")
    }
    
    /// 列出所有自訂範本
    func listCustomTemplates() -> [String] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: customTemplatesDirectory,
                includingPropertiesForKeys: nil
            )
            
            return contents
                .filter { $0.pathExtension == "json" }
                .map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            return []
        }
    }
    
    /// 刪除自訂範本
    func deleteCustom(_ name: String) throws {
        let filename = "\(name).json"
        let fileURL = customTemplatesDirectory.appendingPathComponent(filename)
        
        try FileManager.default.removeItem(at: fileURL)
        print("✅ 範本已刪除：\(name)")
    }
    
    // MARK: - 統一介面
    
    /// 載入範本（自動判斷預設或自訂）
    func load(_ name: String) -> FormatTemplate {
        // 優先使用預設範本
        if let builtin = loadBuiltIn(name) {
            return builtin
        }
        
        // 嘗試載入自訂範本
        if let custom = loadCustom(name) {
            return custom
        }
        
        // 都找不到，返回預設範本
        print("⚠️ 找不到範本「\(name)」，使用預設範本")
        return .nccu
    }
    
    /// 取得所有範本（預設 + 自訂）
    func allTemplates() -> [FormatTemplate] {
        var templates = builtInTemplates()
        
        for name in listCustomTemplates() {
            if let custom = loadCustom(name) {
                templates.append(custom)
            }
        }
        
        return templates
    }
}
