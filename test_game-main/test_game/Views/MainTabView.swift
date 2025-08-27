import SwiftUI

struct MainTabView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        TabView {
            GameView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Game")
                }
            
            RatingView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Rating")
                }
            
            SettingsView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(.gold)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
