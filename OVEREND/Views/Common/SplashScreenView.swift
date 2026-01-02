//
//  SplashScreenView.swift
//  OVEREND
//
//  啟動畫面 - 品牌展示與動畫效果
//

import SwiftUI

// MARK: - 浮動粒子模型

struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
}

// MARK: - 啟動畫面視圖

struct SplashScreenView: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.6
    @State private var logoRotation: Double = -10
    @State private var sloganOpacity: Double = 0
    @State private var progressOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0
    @State private var brandLetterOpacities: [Double] = Array(repeating: 0, count: 8)
    @State private var particles: [FloatingParticle] = []
    @State private var animateParticles = false
    
    // 完成回調
    let onComplete: () -> Void
    
    // 品牌名稱字母
    private let brandLetters = Array("OVEREND")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景漸層
                backgroundGradient
                
                // 浮動光粒子
                floatingParticles(in: geometry.size)
                
                // 主內容
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Logo 區域
                    logoSection
                    
                    // 品牌名稱（逐字淡入）
                    brandNameSection
                    
                    // 標語
                    sloganSection
                        .opacity(sloganOpacity)
                    
                    Spacer()
                    
                    // 載入指示器
                    loadingIndicator
                        .opacity(progressOpacity)
                        .padding(.bottom, 60)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            initializeParticles()
            startAnimation()
        }
    }
    
    // MARK: - 背景漸層
    
    private var backgroundGradient: some View {
        ZStack {
            // 主漸層
            LinearGradient(
                colors: [
                    Color(hex: "#1A1A2E"),
                    Color(hex: "#16213E"),
                    Color(hex: "#0F3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 動態光暈
            RadialGradient(
                colors: [
                    Color(hex: "#00D97E").opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .scaleEffect(glowScale)
            .opacity(glowOpacity)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: glowScale
            )
        }
    }
    
    // MARK: - 浮動光粒子
    
    private func floatingParticles(in size: CGSize) -> some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(particle.opacity),
                                Color.white.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size / 2
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(
                        x: particle.x,
                        y: animateParticles 
                            ? particle.y - CGFloat(particle.speed * 100)
                            : particle.y
                    )
                    .animation(
                        Animation.linear(duration: particle.speed * 3)
                            .repeatForever(autoreverses: false),
                        value: animateParticles
                    )
            }
        }
    }
    
    // MARK: - Logo 區域
    
    private var logoSection: some View {
        ZStack {
            // 多層光暈效果
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#00D97E").opacity(0.4 - Double(index) * 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100 + CGFloat(index) * 30
                        )
                    )
                    .frame(
                        width: 200 + CGFloat(index) * 40,
                        height: 200 + CGFloat(index) * 40
                    )
                    .blur(radius: 20 + CGFloat(index) * 10)
                    .scaleEffect(glowScale + CGFloat(index) * 0.1)
            }
            
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
                .shadow(color: Color(hex: "#00D97E").opacity(0.5), radius: 30, x: 0, y: 10)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .opacity(logoOpacity)
        .scaleEffect(logoScale)
        .rotation3DEffect(.degrees(logoRotation), axis: (x: 0, y: 1, z: 0))
    }
    
    // MARK: - 品牌名稱（逐字淡入）
    
    private var brandNameSection: some View {
        HStack(spacing: 4) {
            ForEach(0..<brandLetters.count, id: \.self) { index in
                Text(String(brandLetters[index]))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .white,
                                Color(hex: "#E0E0E0")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "#00D97E").opacity(0.3), radius: 10, x: 0, y: 0)
                    .opacity(brandLetterOpacities[index])
                    .offset(y: brandLetterOpacities[index] == 0 ? 10 : 0)
            }
        }
        .tracking(6)
    }
    
    // MARK: - 標語區域
    
    private var sloganSection: some View {
        VStack(spacing: 12) {
            Text("讓研究者專注於研究本身")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text("文獻管理・學術寫作・引用格式")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    // MARK: - 載入指示器
    
    private var loadingIndicator: some View {
        VStack(spacing: 12) {
            // 自訂載入動畫
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color(hex: "#00D97E"))
                        .frame(width: 8, height: 8)
                        .scaleEffect(progressOpacity > 0 ? 1 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: progressOpacity
                        )
                }
            }
            
            Text("準備中...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - 初始化粒子
    
    private func initializeParticles() {
        particles = (0..<20).map { _ in
            FloatingParticle(
                x: CGFloat.random(in: 0...1200),
                y: CGFloat.random(in: 0...900),
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.1...0.4),
                speed: Double.random(in: 0.5...2.0)
            )
        }
    }
    
    // MARK: - 動畫序列
    
    private func startAnimation() {
        // 啟動粒子動畫
        withAnimation {
            animateParticles = true
        }
        
        // 光暈呼吸效果
        withAnimation(.easeInOut(duration: 0.8)) {
            glowOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowScale = 1.2
            }
        }
        
        // Logo 淡入與 3D 旋轉
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            logoOpacity = 1
            logoScale = 1
            logoRotation = 0
        }
        
        // 品牌名稱逐字淡入
        for (index, _) in brandLetters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(index) * 0.08) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    brandLetterOpacities[index] = 1
                }
            }
        }
        
        // 標語淡入
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            sloganOpacity = 1
        }
        
        // 載入指示器淡入
        withAnimation(.easeOut(duration: 0.3).delay(1.3)) {
            progressOpacity = 1
        }
        
        // 完成後觸發回調
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                onComplete()
            }
        }
    }
}

// MARK: - 預覽

#Preview {
    SplashScreenView {
        print("Splash completed")
    }
    .frame(width: 1000, height: 700)
}
