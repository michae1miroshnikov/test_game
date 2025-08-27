import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingLoading = false
    
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
                    
                    Text("ROULETTE")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.gold)
                    
                    Text("Exciting casino game")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Кнопки входа
                VStack(spacing: 20) {
                    // Google Sign-In Button
                    GoogleSignInButton(action: {
                        showingLoading = true
                        Task {
                            await authViewModel.signInWithGoogle()
                            // Не убираем showingLoading здесь - это сделает AuthViewModel
                        }
                    })
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .disabled(authViewModel.isLoading)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.3))
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    
                    // Anonymous Sign-In Button
                    Button(action: {
                        showingLoading = true
                        Task {
                            await authViewModel.signInAnonymously()
                            // Не убираем showingLoading здесь - это сделает AuthViewModel
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.title2)
                            Text("PLAY ANONYMOUSLY")
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
                        ProgressView("Entering game...")
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
                    Text("🎁 Get 2000 chips when you register!")
                        .font(.headline)
                        .foregroundColor(.gold)
                        .multilineTextAlignment(.center)
                    
                    Text("Play for free and compete with other players")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .overlay(
            Group {
                if showingLoading {
                    LoadingView()
                }
            }
        )
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                showingLoading = false
            }
        }
        .onChange(of: authViewModel.isLoading) { _, isLoading in
            if !isLoading {
                showingLoading = false
            }
        }
    }
}

#Preview {
    AuthView(authViewModel: AuthViewModel())
}
