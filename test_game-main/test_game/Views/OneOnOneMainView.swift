import SwiftUI

struct OneOnOneMainView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var gameViewModel: OneOnOneGameViewModel
    @State private var showingLeaveAlert = false
    @State private var pendingAction: String?
    @State private var isViewActive = true
    
    var body: some View {
        Group {
            if gameViewModel.isGameActive() {
                // Показываем игровой view
                OneOnOneGameView(authViewModel: authViewModel, gameViewModel: gameViewModel)
            } else {
                // Показываем поиск
                OneOnOneSearchView(authViewModel: authViewModel, gameViewModel: gameViewModel)
            }
        }
        .onAppear {
            isViewActive = true
            print("OneOnOneMainView appeared")
            
            // Если игра активна и view не было активно, показываем alert
            if gameViewModel.isGameActive() && !isViewActive {
                print("Game is active and view was inactive - showing leave alert")
                DispatchQueue.main.async {
                    showingLeaveAlert = true
                    pendingAction = "leave"
                }
            }
        }
        .onDisappear {
            isViewActive = false
            print("OneOnOneMainView disappeared")
            if gameViewModel.isGameActive() {
                print("Game is active - showing leave alert")
                DispatchQueue.main.async {
                    showingLeaveAlert = true
                    pendingAction = "leave"
                }
            }
        }
        .alert("Leave Game?", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) {
                // Возвращаемся к 1 vs 1
                pendingAction = nil
            }
            Button("Leave", role: .destructive) {
                if pendingAction == "leave" {
                    leaveGame()
                }
            }
        } message: {
            Text("Are you sure you want to leave the current game? You will lose.")
        }
        .onChange(of: showingLeaveAlert) { _, isShowing in
            if !isShowing && pendingAction == "leave" {
                // Если alert закрылся без нажатия кнопок, возвращаемся к 1 vs 1
                pendingAction = nil
            }
        }
    }
    
    private func leaveGame() {
        // Сбрасываем игру
        gameViewModel.startNewGame()
        print("Game left - returning to search view")
    }
}

#Preview {
    OneOnOneMainView(
        authViewModel: AuthViewModel(),
        gameViewModel: OneOnOneGameViewModel()
    )
}
