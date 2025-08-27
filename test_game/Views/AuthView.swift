import SwiftUI

struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Фон
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.3),
                    Color(red: 0.2, green: 0.3, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Логотип и название
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.gold, lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color.black)
                            .frame(width: 100, height: 100)
                        
                        Text("🎰")
                            .font(.system(size: 50))
                    }
                    
                    Text("РУЛЕТКА")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.gold)
                    
                    Text("Увлекательная игра в казино")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Кнопки входа
                VStack(spacing: 20) {
                    Button(action: {
                        Task {
                            await authViewModel.signInAnonymously()
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.title2)
                            Text("ИГРАТЬ АНОНИМНО")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading)
                    
                    if authViewModel.isLoading {
                        ProgressView("Вход в игру...")
                            .foregroundColor(.white)
                    }
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Информация
                VStack(spacing: 10) {
                    Text("🎁 Получите 2000 фишек при регистрации!")
                        .font(.headline)
                        .foregroundColor(.gold)
                        .multilineTextAlignment(.center)
                    
                    Text("Играйте бесплатно и соревнуйтесь с другими игроками")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }
}

#Preview {
    AuthView(authViewModel: AuthViewModel())
}
