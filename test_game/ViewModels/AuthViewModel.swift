import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.fetchUserData(userId: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            let userId = result.user.uid
            let username = "Player\(Int.random(in: 1000...9999))"
            
            let newUser = User(id: userId, username: username)
            try await saveUserToDatabase(newUser)
            
            currentUser = newUser
            isAuthenticated = true
        } catch {
            errorMessage = "Ошибка входа: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Ошибка выхода: \(error.localizedDescription)"
        }
    }
    
    private func saveUserToDatabase(_ user: User) async throws {
        let userData: [String: Any] = [
            "id": user.id,
            "username": user.username,
            "chips": user.chips,
            "winRate": user.winRate,
            "createdAt": Timestamp(date: user.createdAt)
        ]
        
        try await db.collection("users").document(user.id).setData(userData)
    }
    
    private func fetchUserData(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if let data = document.data() {
                let user = User(
                    id: data["id"] as? String ?? userId,
                    username: data["username"] as? String ?? "Unknown",
                    chips: data["chips"] as? Int ?? 2000,
                    winRate: data["winRate"] as? Double ?? 0.0
                )
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            errorMessage = "Ошибка загрузки данных: \(error.localizedDescription)"
        }
    }
    
    func updateUserChips(_ newChips: Int) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "chips": newChips
            ])
            
            currentUser?.chips = newChips
        } catch {
            errorMessage = "Ошибка обновления фишек: \(error.localizedDescription)"
        }
    }
    
    func updateWinRate(_ newWinRate: Double) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "winRate": newWinRate
            ])
            
            currentUser?.winRate = newWinRate
        } catch {
            errorMessage = "Ошибка обновления статистики: \(error.localizedDescription)"
        }
    }
}
