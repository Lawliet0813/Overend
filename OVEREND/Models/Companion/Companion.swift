//
//  Companion.swift
//  OVEREND
//
//  AI 夥伴角色模型
//
//  支援預設角色與用戶自訂生成角色
//

import Foundation
import SwiftUI

// MARK: - 夥伴表情狀態

/// AI 夥伴的表情/動畫狀態
public enum CompanionMood: String, CaseIterable, Codable {
    case idle = "idle"           // 待機：輕微眨眼、偶爾轉頭
    case excited = "excited"     // 興奮：舉起翅膀、頭上燈泡亮
    case reading = "reading"     // 閱讀：翻開書本、戴上眼鏡
    case celebrating = "celebrating"  // 慶祝：開心跳躍、灑彩帶
    case sleepy = "sleepy"       // 休息：打瞌睡、Zzz 冒泡
    case thinking = "thinking"   // 思考：歪頭、冒出問號
    
    /// 對應的 SF Symbol
    public var icon: String {
        switch self {
        case .idle: return "face.smiling"
        case .excited: return "lightbulb.fill"
        case .reading: return "book.fill"
        case .celebrating: return "party.popper.fill"
        case .sleepy: return "zzz"
        case .thinking: return "questionmark.bubble"
        }
    }
    
    /// 中文顯示名稱
    public var displayName: String {
        switch self {
        case .idle: return "待機"
        case .excited: return "興奮"
        case .reading: return "閱讀"
        case .celebrating: return "慶祝"
        case .sleepy: return "休息"
        case .thinking: return "思考"
        }
    }
}

// MARK: - 夥伴語氣風格

/// AI 夥伴的語氣風格
public enum CompanionTone: String, CaseIterable, Codable {
    case academic = "academic"     // 正經學術
    case friendly = "friendly"     // 活潑輕鬆
    case minimal = "minimal"       // 極簡模式
    case custom = "custom"         // 自訂
    
    public var displayName: String {
        switch self {
        case .academic: return "正經學術"
        case .friendly: return "活潑輕鬆"
        case .minimal: return "極簡模式"
        case .custom: return "自訂"
        }
    }
}

// MARK: - 夥伴位置

/// AI 夥伴在 UI 中的位置
public enum CompanionPosition: String, CaseIterable, Codable {
    case floatingBottomRight = "floating_bottom_right"
    case sidebarEmbedded = "sidebar_embedded"
    case hidden = "hidden"
    
    public var displayName: String {
        switch self {
        case .floatingBottomRight: return "右下角浮動"
        case .sidebarEmbedded: return "側邊欄嵌入"
        case .hidden: return "隱藏"
        }
    }
}

// MARK: - 夥伴角色模型

/// AI 夥伴角色
public struct Companion: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var description: String
    public var isDefault: Bool
    public var isActive: Bool
    
    /// 角色圖片資料（各表情狀態）
    public var moodImages: [CompanionMood: Data]
    
    /// 語氣風格
    public var tone: CompanionTone
    
    /// 自訂口頭禪
    public var customCatchphrase: String?
    
    /// 位置偏好
    public var position: CompanionPosition
    
    /// 創建時間
    public var createdAt: Date
    
    /// 用戶生成的原始 Prompt（如果是 AI 生成的）
    public var generationPrompt: String?
    
    // MARK: - 初始化
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        isDefault: Bool = false,
        isActive: Bool = false,
        moodImages: [CompanionMood: Data] = [:],
        tone: CompanionTone = .friendly,
        customCatchphrase: String? = nil,
        position: CompanionPosition = .floatingBottomRight,
        createdAt: Date = Date(),
        generationPrompt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isDefault = isDefault
        self.isActive = isActive
        self.moodImages = moodImages
        self.tone = tone
        self.customCatchphrase = customCatchphrase
        self.position = position
        self.createdAt = createdAt
        self.generationPrompt = generationPrompt
    }
    
    // MARK: - 預設角色
    
    /// 小研 - 預設 AI 夥伴
    public static var yen: Companion {
        Companion(
            name: "小研",
            description: "翡翠綠的可愛貓頭鷹，戴著小眼鏡和學士帽",
            isDefault: true,
            isActive: true,
            tone: .friendly,
            customCatchphrase: nil,
            position: .floatingBottomRight
        )
    }
}

// MARK: - Codable 擴展

extension Companion {
    enum CodingKeys: String, CodingKey {
        case id, name, description, isDefault, isActive
        case moodImages, tone, customCatchphrase, position
        case createdAt, generationPrompt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        
        // 解碼 moodImages
        let rawMoodImages = try container.decodeIfPresent([String: Data].self, forKey: .moodImages) ?? [:]
        moodImages = Dictionary(uniqueKeysWithValues: rawMoodImages.compactMap { key, value in
            guard let mood = CompanionMood(rawValue: key) else { return nil }
            return (mood, value)
        })
        
        tone = try container.decodeIfPresent(CompanionTone.self, forKey: .tone) ?? .friendly
        customCatchphrase = try container.decodeIfPresent(String.self, forKey: .customCatchphrase)
        position = try container.decodeIfPresent(CompanionPosition.self, forKey: .position) ?? .floatingBottomRight
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        generationPrompt = try container.decodeIfPresent(String.self, forKey: .generationPrompt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encode(isActive, forKey: .isActive)
        
        // 編碼 moodImages
        let rawMoodImages = Dictionary(uniqueKeysWithValues: moodImages.map { ($0.key.rawValue, $0.value) })
        try container.encode(rawMoodImages, forKey: .moodImages)
        
        try container.encode(tone, forKey: .tone)
        try container.encodeIfPresent(customCatchphrase, forKey: .customCatchphrase)
        try container.encode(position, forKey: .position)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(generationPrompt, forKey: .generationPrompt)
    }
}
