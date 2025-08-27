import SwiftUI

struct MainTabView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var oneOnOneViewModel = OneOnOneGameViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GameView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Game")
                }
                .tag(0)
            
            OneOnOneMainView(authViewModel: authViewModel, gameViewModel: oneOnOneViewModel)
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
        .onChange(of: selectedTab) { oldTab, newTab in
            // Просто логируем переключение - OneOnOneMainView сам обработает alerts
            print("Tab switched from \(oldTab) to \(newTab)")
        }
    }
}

#Preview {
    MainTabView()
}
