import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RatingView: View {
    @StateObject private var ratingViewModel = RatingViewModel()
    
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
                
                VStack {
                    if ratingViewModel.isLoading {
                        ProgressView("Loading rating...")
                            .foregroundColor(.white)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(ratingViewModel.players.enumerated()), id: \.element.id) { index, player in
                                    PlayerRatingRow(
                                        rank: index + 1,
                                        player: player,
                                        isCurrentUser: player.id == ratingViewModel.currentUserId
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Rating")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                await ratingViewModel.loadPlayers()
            }
        }
    }
}

// MARK: - Player Rating Row
struct PlayerRatingRow: View {
    let rank: Int
    let player: User
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Ранг
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Аватар
            Circle()
                .fill(Color.gold)
                .frame(width: 50, height: 50)
                .overlay(
                    Text("🎰")
                        .font(.title2)
                )
            
            // Информация о игроке
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.username)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.gold)
                    }
                }
                
                Text("Chips: \(player.chips)")
                    .font(.subheadline)
                    .foregroundColor(.gold)
            }
            
            Spacer()
            
            // Статистика
            VStack(alignment: .trailing, spacing: 4) {
                Text("Win Rate")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(Int(player.winRate))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(winRateColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.gold.opacity(0.2) : Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentUser ? Color.gold : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var winRateColor: Color {
        if player.winRate >= 60 {
            return .green
        } else if player.winRate >= 40 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Rating ViewModel
@MainActor
class RatingViewModel: ObservableObject {
    @Published var players: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    var currentUserId: String?
    
    func loadPlayers() async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("users")
                .order(by: "chips", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            players = snapshot.documents.compactMap { document in
                let data = document.data()
                return User(
                    id: data["id"] as? String ?? document.documentID,
                    username: data["username"] as? String ?? "Unknown",
                    chips: data["chips"] as? Int ?? 0,
                    winRate: data["winRate"] as? Double ?? 0.0
                )
            }
            
            // Получаем ID текущего пользователя
            if let currentUser = Auth.auth().currentUser {
                currentUserId = currentUser.uid
            }
            
        } catch {
            errorMessage = "Error loading rating: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    RatingView()
}
