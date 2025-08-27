import SwiftUI

struct MainTabView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        TabView {
            GameView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Игра")
                }
            
            RatingView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Рейтинг")
                }
            
            SettingsView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Настройки")
                }
        }
        .accentColor(.gold)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
