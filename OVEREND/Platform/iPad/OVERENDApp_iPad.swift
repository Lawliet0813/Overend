//
//  OVERENDApp_iPad.swift
//  OVEREND iPad
//
//  iPad 版本的應用程式入口點
//

#if os(iOS)
import SwiftUI

@main
struct OVERENDApp_iPad: App {
    // Core Data 持久化控制器 - 與 macOS 共用
    let persistenceController = PersistenceController.shared
    
    // Splash Screen 狀態
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 主內容 - iPad 優化版 UI
                iPadContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .opacity(showSplash ? 0 : 1)
                
                // Splash Screen
                if showSplash {
                    iPadSplashScreenView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - iPad Splash Screen

struct iPadSplashScreenView: View {
    let onComplete: () -> Void
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color(hex: "252F3F"),  // Dark Slate Blue
                    Color(hex: "1a2332")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 應用名稱
                Text("OVEREND")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // 副標題
                Text("讓研究者專注於研究本身")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1
            }
            
            // 2 秒後完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onComplete()
            }
        }
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#endif
