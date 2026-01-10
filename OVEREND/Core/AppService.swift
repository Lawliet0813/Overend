//
//  AppService.swift
//  OVEREND
//
//  應用服務層統一協議
//

import Foundation

// MARK: - 服務協議

/// 應用服務基礎協議
protocol AppService {
    /// 服務名稱
    static var serviceName: String { get }
}

/// 可執行的服務（單一輸入輸出）
protocol ExecutableService: AppService {
    associatedtype Input
    associatedtype Output

    /// 執行服務
    func execute(_ input: Input) async throws -> Output
}

/// 批次處理服務
protocol BatchProcessingService: AppService {
    associatedtype Item
    associatedtype Result

    /// 批次處理項目
    func processBatch(_ items: [Item]) async throws -> [Result]

    /// 處理進度回調
    var progressHandler: ((Double) -> Void)? { get set }
}

/// 可取消的服務
protocol CancellableService: AppService {
    /// 取消當前操作
    func cancel()

    /// 是否已取消
    var isCancelled: Bool { get }
}

/// 錯誤報告服務
protocol ErrorReportingService: AppService {
    /// 最後錯誤
    var lastError: AppError? { get }

    /// 錯誤處理器
    var errorHandler: ((AppError) -> Void)? { get set }
}

// MARK: - 服務狀態

/// 服務執行狀態
enum ServiceStatus {
    case idle
    case running
    case completed
    case failed(AppError)
    case cancelled
}

// MARK: - 完整服務協議

/// 完整的服務協議（組合多個特性）
protocol FullFeaturedService: ExecutableService, CancellableService, ErrorReportingService {
    /// 當前狀態
    var status: ServiceStatus { get }
}

// MARK: - 基礎服務實現

/// 基礎服務抽象類
class BaseService: AppService {
    static var serviceName: String {
        return String(describing: Self.self)
    }

    /// 執行狀態
    private(set) var status: ServiceStatus = .idle

    /// 更新狀態
    func updateStatus(_ newStatus: ServiceStatus) {
        status = newStatus
    }
}

/// 可取消的基礎服務
class CancellableBaseService: BaseService, CancellableService {
    private(set) var isCancelled: Bool = false

    func cancel() {
        isCancelled = true
        updateStatus(.cancelled)
    }

    /// 重置取消狀態
    func reset() {
        isCancelled = false
        updateStatus(.idle)
    }
}

// MARK: - 服務註冊表

/// 服務註冊與管理
class ServiceRegistry {
    static let shared = ServiceRegistry()

    private var services: [String: any AppService] = [:]

    private init() {}

    /// 註冊服務
    func register<T: AppService>(_ service: T) {
        let key = T.serviceName
        services[key] = service
    }

    /// 獲取服務
    func get<T: AppService>(_ type: T.Type) -> T? {
        let key = T.serviceName
        return services[key] as? T
    }

    /// 移除服務
    func remove<T: AppService>(_ type: T.Type) {
        let key = T.serviceName
        services.removeValue(forKey: key)
    }

    /// 清除所有服務
    func removeAll() {
        services.removeAll()
    }
}

// MARK: - 服務裝飾器

/// 服務執行計時裝飾器
class TimedServiceDecorator<S: ExecutableService>: ExecutableService {
    typealias Input = S.Input
    typealias Output = S.Output

    static var serviceName: String {
        "Timed\(S.serviceName)"
    }

    private let wrappedService: S

    init(wrapping service: S) {
        self.wrappedService = service
    }

    func execute(_ input: Input) async throws -> Output {
        let startTime = Date()
        let result = try await wrappedService.execute(input)
        let duration = Date().timeIntervalSince(startTime)

        print("[\(S.serviceName)] 執行時間: \(String(format: "%.2f", duration))秒")
        return result
    }
}

/// 服務日誌記錄裝飾器
class LoggingServiceDecorator<S: ExecutableService>: ExecutableService {
    typealias Input = S.Input
    typealias Output = S.Output

    static var serviceName: String {
        "Logged\(S.serviceName)"
    }

    private let wrappedService: S

    init(wrapping service: S) {
        self.wrappedService = service
    }

    func execute(_ input: Input) async throws -> Output {
        #if DEBUG
        print("[\(S.serviceName)] 開始執行")
        #endif
        do {
            let result = try await wrappedService.execute(input)
            #if DEBUG
            print("[\(S.serviceName)] 執行成功")
            #endif
            return result
        } catch {
            #if DEBUG
            print("[\(S.serviceName)] 執行失敗: \(error.localizedDescription)")
            #endif
            throw error
        }
    }
}
