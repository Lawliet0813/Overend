//
//  PlatformAbstraction.swift
//  OVEREND
//
//  跨平台抽象層 - 統一 macOS 和 iPadOS 的平台差異
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Platform Type Aliases

#if os(macOS)
import AppKit
public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
public typealias PlatformFont = NSFont
public typealias PlatformViewController = NSViewController
#elseif os(iOS)
import UIKit
public typealias PlatformColor = UIColor
public typealias PlatformImage = UIImage
public typealias PlatformFont = UIFont
public typealias PlatformViewController = UIViewController
#endif

// MARK: - Platform Detection

enum Platform {
    case macOS
    case iPad
    case iPhone
    
    static var current: Platform {
        #if os(macOS)
        return .macOS
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPad
        } else {
            return .iPhone
        }
        #endif
    }
    
    static var isMac: Bool {
        current == .macOS
    }
    
    static var isiPad: Bool {
        current == .iPad
    }
    
    static var isiPhone: Bool {
        current == .iPhone
    }
}

// MARK: - File Dialog Protocol

protocol FileDialogProvider {
    func showSavePanel(
        defaultName: String,
        allowedTypes: [UTType],
        completion: @escaping (URL?) -> Void
    )
    
    func showOpenPanel(
        allowedTypes: [UTType],
        allowsMultipleSelection: Bool,
        completion: @escaping ([URL]) -> Void
    )
}

// MARK: - Cross-Platform View Modifiers

extension View {
    /// 適用不同平台的 padding
    @ViewBuilder
    func platformPadding() -> some View {
        #if os(macOS)
        self.padding()
        #else
        self.padding(.horizontal)
        #endif
    }
    
    /// 適用不同平台的導航樣式
    @ViewBuilder
    func platformNavigationStyle() -> some View {
        #if os(macOS)
        self
        #else
        self.navigationViewStyle(.stack)
        #endif
    }
}

// MARK: - Color Extensions for Cross-Platform

extension Color {
    /// 跨平台的系統背景色
    static var platformBackground: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemBackground)
        #endif
    }
    
    /// 跨平台的次要背景色
    static var platformSecondaryBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }
    
    /// 跨平台的分隔線顏色
    static var platformSeparator: Color {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color(uiColor: .separator)
        #endif
    }
}

// MARK: - Image Extensions for Cross-Platform

extension Image {
    /// 從平台圖片類型創建 SwiftUI Image
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}
