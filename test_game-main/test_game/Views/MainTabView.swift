import SwiftUI

struct MainTabView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var oneOnOneViewModel = OneOnOneGameViewModel()
    @State private var showingGameAlert = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GameView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Game")
                }
                .tag(0)
            
            OneOnOneGameView(authViewModel: authViewModel, gameViewModel: oneOnOneViewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("1 vs 1")
                }
                .tag(1)
            
            RatingView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Rating")
                }
                .tag(2)
            
            SettingsView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.gold)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { _, newTab in
            // Проверяем, есть ли активная игра в 1 vs 1
            if newTab != 1 && selectedTab == 1 && oneOnOneViewModel.gameState != .betting {
                showingGameAlert = true
            }
        }
        .alert("Active Game", isPresented: $showingGameAlert) {
            Button("Continue Game") {
                selectedTab = 1 // Возвращаемся к игре
            }
            Button("Leave Game", role: .destructive) {
                oneOnOneViewModel.startNewGame() // Сбрасываем игру
            }
        } message: {
            Text("You have an active 1 vs 1 game. If you leave now, you will lose the current game.")
        }
    }
}

#Preview {
    MainTabView()
}
