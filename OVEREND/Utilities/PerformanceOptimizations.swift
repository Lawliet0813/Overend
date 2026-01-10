//
//  PerformanceOptimizations.swift
//  OVEREND
//
//  效能優化工具集
//

import Foundation
import SwiftUI
import CoreData
import Combine

// MARK: - 延遲載入視圖

/// 延遲載入包裝器 - 減少初始載入時間
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: some View {
        build()
    }
}

// MARK: - 防抖動器

/// 防抖動器 - 減少頻繁操作
actor Debouncer {
    private var task: Task<Void, Never>?
    
    func debounce(delay: TimeInterval = 0.3, action: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await action()
        }
    }
}

// MARK: - 批量操作優化

extension NSManagedObjectContext {
    
    /// 批量更新優化
    func batchUpdate<T: NSManagedObject>(
        _ type: T.Type,
        predicate: NSPredicate? = nil,
        propertiesToUpdate: [String: Any]
    ) throws -> Int {
        let batchUpdate = NSBatchUpdateRequest(entityName: String(describing: type))
        batchUpdate.predicate = predicate
        batchUpdate.propertiesToUpdate = propertiesToUpdate
        batchUpdate.resultType = .updatedObjectsCountResultType
        
        let result = try execute(batchUpdate) as? NSBatchUpdateResult
        return result?.result as? Int ?? 0
    }
    
    /// 批量刪除優化
    func batchDelete<T: NSManagedObject>(
        _ type: T.Type,
        predicate: NSPredicate? = nil
    ) throws -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        fetchRequest.predicate = predicate
        
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDelete.resultType = .resultTypeCount
        
        let result = try execute(batchDelete) as? NSBatchDeleteResult
        return result?.result as? Int ?? 0
    }
}

// MARK: - 分頁載入

/// 分頁資料載入器
@MainActor
class PaginatedLoader<T>: ObservableObject {
    @Published var items: [T] = []
    @Published var isLoading = false
    @Published var hasMoreData = true
    
    private let pageSize: Int
    private var currentPage = 0
    private let fetchAction: (Int, Int) async throws -> [T]
    
    init(pageSize: Int = 20, fetchAction: @escaping (Int, Int) async throws -> [T]) {
        self.pageSize = pageSize
        self.fetchAction = fetchAction
    }
    
    func loadMore() async {
        guard !isLoading, hasMoreData else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let offset = currentPage * pageSize
            let newItems = try await fetchAction(offset, pageSize)
            
            items.append(contentsOf: newItems)
            hasMoreData = newItems.count == pageSize
            currentPage += 1
        } catch {
            hasMoreData = false
        }
    }
    
    func reset() {
        items = []
        currentPage = 0
        hasMoreData = true
    }
}

// MARK: - 效能監控

#if DEBUG
enum PerformanceMonitor {
    
    /// 測量執行時間
    static func measure(_ label: String, action: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        action()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print("⏱️ [\(label)] 耗時: \(String(format: "%.3f", elapsed * 1000))ms")
    }
    
    /// 測量非同步執行時間
    static func measureAsync(_ label: String, action: () async -> Void) async {
        let start = CFAbsoluteTimeGetCurrent()
        await action()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print("⏱️ [\(label)] 耗時: \(String(format: "%.3f", elapsed * 1000))ms")
    }
}
#endif
