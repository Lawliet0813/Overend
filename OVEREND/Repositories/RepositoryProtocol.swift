//
//  RepositoryProtocol.swift
//  OVEREND
//
//  Repository 抽象層協議
//  提供統一的資料存取接口，解耦 Core Data 依賴
//

import Foundation
import CoreData

// MARK: - 通用 Repository 協議

/// 所有 Repository 的基礎協議
protocol Repository {
    associatedtype Entity: NSManagedObject

    /// Core Data Context
    var context: NSManagedObjectContext { get }

    /// 保存變更
    func save() throws
}

// MARK: - 可查詢協議

/// 支援查詢操作的 Repository
protocol FetchableRepository: Repository {
    /// 獲取所有實體
    func fetchAll() async throws -> [Entity]

    /// 根據 ID 獲取單一實體
    func fetch(byId id: UUID) async throws -> Entity?
}

// MARK: - 可創建協議

/// 支援創建操作的 Repository
protocol CreatableRepository: Repository {
    /// 創建新實體
    @discardableResult
    func create() -> Entity
}

// MARK: - 可刪除協議

/// 支援刪除操作的 Repository
protocol DeletableRepository: Repository {
    /// 刪除實體
    func delete(_ entity: Entity) throws

    /// 批量刪除
    func deleteAll(_ entities: [Entity]) throws
}

// MARK: - 完整 CRUD Repository

/// 完整的 CRUD Repository 協議
protocol CRUDRepository: FetchableRepository, CreatableRepository, DeletableRepository {
    /// 更新實體（透過 save() 實現）
    func update(_ entity: Entity) throws
}

// MARK: - Repository Error

/// Repository 層統一錯誤類型
enum RepositoryError: Error, LocalizedError {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case notFound(String)
    case invalidContext

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "查詢失敗: \(message)"
        case .saveFailed(let message):
            return "保存失敗: \(message)"
        case .deleteFailed(let message):
            return "刪除失敗: \(message)"
        case .notFound(let message):
            return "未找到: \(message)"
        case .invalidContext:
            return "無效的 Core Data Context"
        }
    }
}

// MARK: - Base Repository Implementation

/// Repository 基礎實現，提供通用功能
class BaseRepository<T: NSManagedObject>: Repository {
    typealias Entity = T

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    /// 保存 Context 變更
    func save() throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error.localizedDescription)
        }
    }

    /// 執行 Fetch Request（內部輔助方法）
    func executeFetchRequest(_ request: NSFetchRequest<T>) async throws -> [T] {
        return try await context.perform {
            do {
                return try self.context.fetch(request)
            } catch {
                throw RepositoryError.fetchFailed(error.localizedDescription)
            }
        }
    }

    /// 創建 Fetch Request（子類需覆寫）
    func createFetchRequest() -> NSFetchRequest<T> {
        fatalError("Subclasses must implement createFetchRequest()")
    }
}
