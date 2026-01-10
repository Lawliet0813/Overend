//
//  ThumbnailCache.swift
//  OVEREND
//
//  PDF 及圖片縮圖快取服務
//  減少重複的 PDF 渲染，提升列表滾動效能
//

import Foundation
import SwiftUI
import PDFKit
import Combine

/// 縮圖快取管理器
@MainActor
final class ThumbnailCache: ObservableObject {
    
    static let shared = ThumbnailCache()
    
    // MARK: - 快取
    
    /// 記憶體快取（最多 100 張縮圖）
    private var memoryCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        return cache
    }()
    
    /// 磁碟快取路徑
    private let diskCacheURL: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("ThumbnailCache")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()
    
    /// 進行中的任務（防止重複生成）
    private var pendingTasks: [String: Task<NSImage?, Never>] = [:]
    
    private init() {}
    
    // MARK: - 公開方法
    
    /// 取得 PDF 縮圖（優先快取）
    func thumbnail(for pdfPath: String, size: CGSize = CGSize(width: 120, height: 160)) async -> NSImage? {
        let cacheKey = "\(pdfPath)_\(Int(size.width))x\(Int(size.height))"
        
        // 1. 檢查記憶體快取
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            return cached
        }
        
        // 2. 檢查磁碟快取
        if let diskCached = loadFromDisk(key: cacheKey) {
            memoryCache.setObject(diskCached, forKey: cacheKey as NSString)
            return diskCached
        }
        
        // 3. 檢查是否已有進行中的任務
        if let existingTask = pendingTasks[cacheKey] {
            return await existingTask.value
        }
        
        // 4. 生成新縮圖
        let generateTask = Task<NSImage?, Never> { [weak self] in
            guard let self = self else { return nil }
            let thumbnail = await self.generateThumbnail(pdfPath: pdfPath, size: size)
            
            if let thumbnail = thumbnail {
                self.memoryCache.setObject(thumbnail, forKey: cacheKey as NSString)
                self.saveToDisk(image: thumbnail, key: cacheKey)
            }
            
            self.pendingTasks.removeValue(forKey: cacheKey)
            return thumbnail
        }
        
        pendingTasks[cacheKey] = generateTask
        return await generateTask.value
    }
    
    /// 預載入縮圖（背景執行）
    func preload(pdfPaths: [String], size: CGSize = CGSize(width: 120, height: 160)) {
        Task.detached(priority: .background) { [weak self] in
            for path in pdfPaths.prefix(10) { // 最多預載入 10 張
                _ = await self?.thumbnail(for: path, size: size)
            }
        }
    }
    
    /// 清除快取
    func clearCache() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    // MARK: - 私有方法
    
    private func generateThumbnail(pdfPath: String, size: CGSize) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let url = URL(fileURLWithPath: pdfPath)
                guard let document = PDFDocument(url: url),
                      let page = document.page(at: 0) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let pageRect = page.bounds(for: .mediaBox)
                let scale = min(size.width / pageRect.width, size.height / pageRect.height)
                let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
                
                let image = NSImage(size: scaledSize)
                image.lockFocus()
                
                if let context = NSGraphicsContext.current?.cgContext {
                    context.setFillColor(NSColor.white.cgColor)
                    context.fill(CGRect(origin: .zero, size: scaledSize))
                    context.scaleBy(x: scale, y: scale)
                    page.draw(with: .mediaBox, to: context)
                }
                
                image.unlockFocus()
                continuation.resume(returning: image)
            }
        }
    }
    
    private func diskCachePath(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return diskCacheURL.appendingPathComponent("\(safeKey.hashValue).png")
    }
    
    private func loadFromDisk(key: String) -> NSImage? {
        let path = diskCachePath(for: key)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        return NSImage(contentsOf: path)
    }
    
    private func saveToDisk(image: NSImage, key: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
        
        let path = diskCachePath(for: key)
        try? pngData.write(to: path)
    }
}

// MARK: - SwiftUI View Extension

/// 快取縮圖視圖
struct CachedThumbnailView: View {
    let pdfPath: String
    let size: CGSize
    
    @State private var thumbnail: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .frame(width: size.width, height: size.height)
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        Task {
            thumbnail = await ThumbnailCache.shared.thumbnail(for: pdfPath, size: size)
            isLoading = false
        }
    }
}
