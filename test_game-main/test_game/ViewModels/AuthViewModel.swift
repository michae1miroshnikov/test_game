import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import GoogleSignIn

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
        setupGoogleSignIn()
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
            errorMessage = "Sign in error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
                throw AuthError.presentationError
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.tokenError
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            
            let userId = authResult.user.uid
            let username = result.user.profile?.name ?? "Google User"
            
            // Проверяем, существует ли пользователь уже
            let existingUser = try? await fetchExistingUser(userId: userId)
            
            if let existingUser = existingUser {
                // Пользователь уже существует - обновляем данные
                currentUser = existingUser
                isAuthenticated = true
            } else {
                // Создаем нового пользователя
                let newUser = User(id: userId, username: username)
                try await saveUserToDatabase(newUser)
                currentUser = newUser
                isAuthenticated = true
            }
        } catch {
            errorMessage = "Google sign in error: \(error.localizedDescription)"
            print("Google Sign-In Error: \(error)")
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Sign out error: \(error.localizedDescription)"
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
            errorMessage = "Error loading data: \(error.localizedDescription)"
        }
    }
    
    private func fetchExistingUser(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        
        if let data = document.data() {
            return User(
                id: data["id"] as? String ?? userId,
                username: data["username"] as? String ?? "Unknown",
                chips: data["chips"] as? Int ?? 2000,
                winRate: data["winRate"] as? Double ?? 0.0
            )
        }
        return nil
    }
    
    func updateUserChips(_ newChips: Int) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "chips": newChips
            ])
            
            currentUser?.chips = newChips
        } catch {
            errorMessage = "Error updating chips: \(error.localizedDescription)"
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
            errorMessage = "Error updating statistics: \(error.localizedDescription)"
        }
    }
    
    private func setupGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Error: Could not load GoogleService-Info.plist")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError {
    case presentationError
    case tokenError
    
    var errorDescription: String? {
        switch self {
        case .presentationError:
            return "Failed to present Google Sign-In"
        case .tokenError:
            return "Failed to get Google ID token"
        }
    }
}
