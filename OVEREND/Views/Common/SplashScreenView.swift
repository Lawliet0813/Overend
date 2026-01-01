//
//  SplashScreenView.swift
//  OVEREND
//
//  啟動畫面 - 品牌展示與標語
//

import SwiftUI

/// 啟動畫面視圖
struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var sloganOpacity: Double = 0
    @State private var progressOpacity: Double = 0
    
    // 完成回調
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [
                    Color(hex: "1A1A2E"),
                    Color(hex: "16213E"),
                    Color(hex: "0F3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo 區域
                VStack(spacing: 16) {
                    // 主 Logo - 使用 App Icon
                    ZStack {
                        // 光暈效果
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.4),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 30)
                        
                        // App Icon
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 128, height: 128)
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    }
                    
                    // 品牌名稱
                    Text("OVEREND")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(4)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
                
                // 標語
                VStack(spacing: 12) {
                    Text("讓研究者專注於研究本身")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("文獻管理・學術寫作・引用格式")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(sloganOpacity)
                
                Spacer()
                
                // 載入指示器
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    
                    Text("載入中...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(progressOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Logo 淡入並放大
        withAnimation(.easeOut(duration: 0.6)) {
            logoOpacity = 1
            logoScale = 1
        }
        
        // 標語延遲淡入
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            sloganOpacity = 1
        }
        
        // 載入指示器延遲顯示
        withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
            progressOpacity = 1
        }
        
        // 完成後觸發回調
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                onComplete()
            }
        }
    }
}


#Preview {
    SplashScreenView {
        print("Splash completed")
    }
    .frame(width: 800, height: 600)
}

