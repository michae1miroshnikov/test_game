import SwiftUI
import StoreKit
import FirebaseAuth

struct SettingsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var audioManager = AudioManager.shared
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var hasChanges = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фон
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.1),
                        Color(red: 0.05, green: 0.1, blue: 0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Профиль пользователя
                    UserProfileCard(user: authViewModel.currentUser)
                    
                    // Настройки
                    VStack(spacing: 16) {
                        SettingsButton(
                            title: "RATE APP",
                            icon: "star.fill",
                            color: .yellow
                        ) {
                            requestAppReview()
                        }
                        
                        SettingsButton(
                            title: "SHARE GAME",
                            icon: "square.and.arrow.up",
                            color: .blue
                        ) {
                            showingShareSheet = true
                        }
                        
                        // Музыка
                        HStack {
                            SettingsButton(
                                title: "MUSIC",
                                icon: audioManager.isMusicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                                color: audioManager.isMusicEnabled ? .green : .gray
                            ) {
                                audioManager.toggleMusic()
                                hasChanges = true
                            }
                            
                            Spacer()
                        }
                        
                        SettingsButton(
                            title: "SIGN OUT",
                            icon: "rectangle.portrait.and.arrow.right",
                            color: .orange
                        ) {
                            authViewModel.signOut()
                        }
                        
                        SettingsButton(
                            title: "DELETE ACCOUNT",
                            icon: "trash.fill",
                            color: .red
                        ) {
                            showingDeleteAlert = true
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete account?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This action cannot be undone. All data will be permanently deleted.")
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: ["Try this exciting roulette game! 🎰"])
            }
            .alert("Settings Changed", isPresented: $hasChanges) {
                Button("OK") {
                    hasChanges = false
                }
            } message: {
                Text("Your settings have been updated.")
            }
        }
    }
    
    private func requestAppReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.delete { error in
            if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
            } else {
                authViewModel.signOut()
            }
        }
    }
}

// MARK: - User Profile Card
struct UserProfileCard: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 16) {
            // Аватар
            Circle()
                .fill(Color.gold)
                .frame(width: 80, height: 80)
                .overlay(
                    Text("🎰")
                        .font(.system(size: 40))
                )
            
            // Информация о пользователе
            VStack(spacing: 8) {
                Text(user?.username ?? "Guest")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    VStack {
                        Text("\(user?.chips ?? 0)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)
                        Text("Chips")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text("\(Int(user?.winRate ?? 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Win Rate")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}

// MARK: - Settings Button
struct SettingsButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(authViewModel: AuthViewModel())
}
