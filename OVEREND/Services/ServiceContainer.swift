//
//  ServiceContainer.swift
//  OVEREND
//
//  服務容器 - 用於依賴注入和服務管理
//

import Foundation
import SwiftUI

/// 服務容器
class ServiceContainer {
    
    /// 單例實例（用於向後兼容和預設配置）
    static let shared = ServiceContainer()
    
    // MARK: - 服務
    
    let pdfService: PDFService
    let citationService: CitationService
    let aiService: UnifiedAIService
    
    // MARK: - 初始化
    
    init(
        pdfService: PDFService = .shared,
        citationService: CitationService = .shared,
        aiService: UnifiedAIService = .shared
    ) {
        self.pdfService = pdfService
        self.citationService = citationService
        self.aiService = aiService
    }
}

// MARK: - Environment Key

struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
