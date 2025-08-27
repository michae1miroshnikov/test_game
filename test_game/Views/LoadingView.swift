import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.3),
                    Color(red: 0.2, green: 0.3, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Анимированное колесо рулетки
                ZStack {
                    // Внешний круг
                    Circle()
                        .stroke(Color.gold, lineWidth: 8)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    // Внутренний круг
                    Circle()
                        .fill(Color.gold.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-rotationAngle * 0.5))
                    
                    // Центральная точка
                    Circle()
                        .fill(Color.gold)
                        .frame(width: 20, height: 20)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                    
                    // Точки по кругу
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(y: -50)
                            .rotationEffect(.degrees(Double(index) * 45))
                    }
                    
                    ForEach(8..<16, id: \.self) { index in
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                            .offset(y: -50)
                            .rotationEffect(.degrees(Double(index) * 45))
                    }
                }
                
                // Текст загрузки
                VStack(spacing: 10) {
                    Text("РУЛЕТКА")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.gold)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    Text("Загрузка...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Анимированные точки
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.gold)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        isAnimating = true
        
        withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

// Расширение для золотого цвета
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

#Preview {
    LoadingView()
}
