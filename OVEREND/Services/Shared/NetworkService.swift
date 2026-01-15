//
//  NetworkService.swift
//  OVEREND
//
//  Created by Antigravity on 2025/12/28.
//  Enhanced with URL caching and performance optimizations
//

import Foundation
import Combine

// MARK: - Cache Policy

/// 網路請求緩存策略
enum NetworkCachePolicy {
    /// 使用緩存，如果緩存不存在則發送網路請求
    case cacheElseNetwork
    /// 優先使用網路，失敗時使用緩存
    case networkElseCache
    /// 只使用網路，忽略緩存
    case networkOnly
    /// 只使用緩存，不發送網路請求
    case cacheOnly
    
    var urlCachePolicy: URLRequest.CachePolicy {
        switch self {
        case .cacheElseNetwork:
            return .returnCacheDataElseLoad
        case .networkElseCache:
            return .reloadRevalidatingCacheData
        case .networkOnly:
            return .reloadIgnoringLocalCacheData
        case .cacheOnly:
            return .returnCacheDataDontLoad
        }
    }
}

// MARK: - Network Service

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    // MARK: - Configuration
    
    /// 代理 URL 前綴
    @Published var proxyURLPrefix: String {
        didSet {
            UserDefaults.standard.set(proxyURLPrefix, forKey: "SchoolProxyURLPrefix")
        }
    }
    
    /// 默認超時時間（秒）
    var defaultTimeout: TimeInterval = 30
    
    /// 默認緩存策略
    var defaultCachePolicy: NetworkCachePolicy = .cacheElseNetwork
    
    // MARK: - URLSession with Cache
    
    /// 配置了緩存的 URLSession
    lazy var cachedSession: URLSession = {
        let config = URLSessionConfiguration.default
        
        // 配置緩存：50MB 記憶體，200MB 磁碟
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50 MB
            diskCapacity: 200 * 1024 * 1024,   // 200 MB
            diskPath: "overend_network_cache"
        )
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        // 連接配置
        config.timeoutIntervalForRequest = defaultTimeout
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        // HTTP 配置
        config.httpMaximumConnectionsPerHost = 6
        
        return URLSession(configuration: config)
    }()
    
    // MARK: - Initialization
    
    private init() {
        self.proxyURLPrefix = UserDefaults.standard.string(forKey: "SchoolProxyURLPrefix") ?? ""
        logInfo("NetworkService initialized with caching enabled", category: .network)
    }
    
    // MARK: - URL Methods
    
    func proxiedURL(for originalURL: URL) -> URL {
        guard !proxyURLPrefix.isEmpty else {
            return originalURL
        }
        
        // Check if the URL is already proxied to avoid double-proxying if called multiple times
        if originalURL.absoluteString.hasPrefix(proxyURLPrefix) {
            return originalURL
        }
        
        // Standard EZProxy format is usually prefix + originalURL
        // But sometimes it's different. We'll assume simple concatenation for now as it's most common
        // e.g. https://ezproxy.lib.ntu.edu.tw/login?url=https://www.airitilibrary.com/...
        
        if let proxied = URL(string: proxyURLPrefix + originalURL.absoluteString) {
            return proxied
        }
        
        return originalURL
    }
    
    // MARK: - Request Creation
    
    /// 創建帶有緩存策略的請求
    /// - Parameters:
    ///   - url: 目標 URL
    ///   - cachePolicy: 緩存策略（默認使用服務默認策略）
    ///   - timeout: 超時時間（默認使用服務默認超時）
    /// - Returns: 配置好的 URLRequest
    func createRequest(
        for url: URL,
        cachePolicy: NetworkCachePolicy? = nil,
        timeout: TimeInterval? = nil
    ) -> URLRequest {
        let finalURL = proxiedURL(for: url)
        var request = URLRequest(url: finalURL)
        
        // 設置緩存策略
        request.cachePolicy = (cachePolicy ?? defaultCachePolicy).urlCachePolicy
        
        // 設置超時
        request.timeoutInterval = timeout ?? defaultTimeout
        
        // 設置 User-Agent
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        
        return request
    }
    
    /// 創建強制從網路獲取的請求（忽略緩存）
    func createFreshRequest(for url: URL, timeout: TimeInterval? = nil) -> URLRequest {
        return createRequest(for: url, cachePolicy: .networkOnly, timeout: timeout)
    }
    
    /// 創建只從緩存獲取的請求
    func createCachedOnlyRequest(for url: URL) -> URLRequest {
        return createRequest(for: url, cachePolicy: .cacheOnly, timeout: nil)
    }
    
    // MARK: - Network Operations
    
    /// 執行網路請求
    /// - Parameters:
    ///   - request: URLRequest
    ///   - useCache: 是否使用緩存 Session
    /// - Returns: 數據和回應
    func fetch(_ request: URLRequest, useCache: Bool = true) async throws -> (Data, URLResponse) {
        let session = useCache ? cachedSession : URLSession.shared
        
        logDebug("Fetching: \(request.url?.absoluteString ?? "unknown")", category: .network)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await session.data(for: request)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        logDebug("Fetched in \(String(format: "%.2f", elapsed * 1000))ms: \(data.count) bytes", category: .network)
        
        return (data, response)
    }
    
    /// 獲取 URL 內容
    /// - Parameters:
    ///   - url: 目標 URL
    ///   - cachePolicy: 緩存策略
    /// - Returns: 數據
    func fetchData(from url: URL, cachePolicy: NetworkCachePolicy? = nil) async throws -> Data {
        let request = createRequest(for: url, cachePolicy: cachePolicy)
        let (data, _) = try await fetch(request)
        return data
    }
    
    // MARK: - Cache Management
    
    /// 清除所有緩存
    func clearCache() {
        cachedSession.configuration.urlCache?.removeAllCachedResponses()
        logInfo("Network cache cleared", category: .network)
    }
    
    /// 移除特定 URL 的緩存
    func removeCache(for url: URL) {
        let request = URLRequest(url: url)
        cachedSession.configuration.urlCache?.removeCachedResponse(for: request)
    }
    
    /// 獲取緩存大小（字節）
    var currentCacheSize: Int {
        return cachedSession.configuration.urlCache?.currentDiskUsage ?? 0
    }
    
    /// 格式化的緩存大小
    var formattedCacheSize: String {
        let bytes = currentCacheSize
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
