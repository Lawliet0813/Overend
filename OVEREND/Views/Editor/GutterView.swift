import SwiftUI

struct GutterView: View {
    @Binding var showGlow: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color(nsColor: .textBackgroundColor)
                .opacity(0.5)
            
            // Line Numbers (Placeholder for now)
            VStack(spacing: 4) {
                ForEach(1...20, id: \.self) { i in
                    Text("\(i)")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(height: 14) // Approximate line height
                }
                Spacer()
            }
            .padding(.top, 8)
            
            // AI Glow Indicator
            if showGlow {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "BC82F3"), // Lilac
                                    Color(hex: "F5B9EA"), // Light Pink
                                    Color(hex: "8D9FFF")  // Blue Purple
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 4, height: 40) // Indicator for a specific block
                        .blur(radius: 4)
                        .offset(x: 2, y: 100) // Position placeholder
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: showGlow
                        )
                }
            }
        }
        .frame(width: 40)
        .border(Color.gray.opacity(0.2), width: 0.5)
    }
}
