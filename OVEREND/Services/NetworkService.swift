//
//  NetworkService.swift
//  OVEREND
//
//  Created by Antigravity on 2025/12/28.
//

import Foundation
import Combine

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    @Published var proxyURLPrefix: String {
        didSet {
            UserDefaults.standard.set(proxyURLPrefix, forKey: "SchoolProxyURLPrefix")
        }
    }
    
    private init() {
        self.proxyURLPrefix = UserDefaults.standard.string(forKey: "SchoolProxyURLPrefix") ?? ""
    }
    
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
    
    func createRequest(for url: URL) -> URLRequest {
        let finalURL = proxiedURL(for: url)
        var request = URLRequest(url: finalURL)
        // Add common headers if needed, e.g. User-Agent
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        return request
    }
}
