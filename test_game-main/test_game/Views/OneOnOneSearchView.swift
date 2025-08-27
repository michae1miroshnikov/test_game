import SwiftUI

struct OneOnOneSearchView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var gameViewModel: OneOnOneGameViewModel
    @State private var showingLoading = false
    @State private var timeRemaining = 10
    @State private var gameTimer: Timer?
    @State private var showingLeaveAlert = false
    @State private var pendingAction: String?
    @State private var isViewActive = true
    
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
                
                VStack(spacing: 40) {
                    // Заголовок
                    VStack(spacing: 20) {
                        Text("1 vs 1")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)
                        
                        Text("Challenge other players or play against AI")
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Кнопка поиска
                    if !showingLoading {
                        Button(action: {
                            startSearching()
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: "person.2.fill")
                                    .font(.title2)
                                Text("Start Searching")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gold)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // Loading экран
                    if showingLoading {
                        VStack(spacing: 30) {
                            LottieView(name: "Casino Roulette")
                                .frame(width: 150, height: 150)
                            
                            VStack(spacing: 10) {
                                Text("Searching for opponent...")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text("\(timeRemaining)s")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gold)
                            }
                            
                            Button("Cancel Search") {
                                cancelSearch()
                            }
                            .foregroundColor(.red)
                            .font(.headline)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("1 vs 1")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            gameViewModel.authViewModel = authViewModel
            isViewActive = true
            
            // Если поиск активен и view не было активно, показываем alert
            if showingLoading && !isViewActive {
                print("Search is active and view was inactive - showing leave alert")
                DispatchQueue.main.async {
                    showingLeaveAlert = true
                    pendingAction = "leave"
                }
            }
        }
        .onDisappear {
            isViewActive = false
            if showingLoading {
                DispatchQueue.main.async {
                    showingLeaveAlert = true
                    pendingAction = "leave"
                }
            }
        }
        .alert("Leave Search?", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) {
                // Возвращаемся к поиску
                pendingAction = nil
            }
            Button("Leave", role: .destructive) {
                if pendingAction == "leave" {
                    cancelSearch()
                }
            }
        } message: {
            Text("Are you sure you want to leave the search?")
        }
        .onChange(of: showingLeaveAlert) { _, isShowing in
            if !isShowing && pendingAction == "leave" {
                // Если alert закрылся без нажатия кнопок, возвращаемся к поиску
                pendingAction = nil
            }
        }
    }
    
    private func startSearching() {
        showingLoading = true
        timeRemaining = 10
        
        // Останавливаем предыдущий таймер если есть
        gameTimer?.invalidate()
        
        // Таймер поиска противника
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    print("Searching for opponent... \(timeRemaining)s remaining")
                } else {
                    gameTimer?.invalidate()
                    // Если противник не найден, создаем бота
                    gameViewModel.createBotOpponent()
                    showingLoading = false
                    print("Opponent found - starting game")
                    // Здесь нужно перейти к игровому view
                    startGame()
                }
            }
        }
    }
    
    private func cancelSearch() {
        gameTimer?.invalidate()
        gameTimer = nil
        showingLoading = false
        timeRemaining = 10
        print("Search cancelled")
    }
    
    private func startGame() {
        // Игра автоматически начнется, так как isGameActive() вернет true
        print("Game started with opponent: \(gameViewModel.opponent?.username ?? "None")")
        
        // Вызываем callback для запуска таймера игры
        gameViewModel.onGameStarted?()
    }
}

#Preview {
    OneOnOneSearchView(
        authViewModel: AuthViewModel(),
        gameViewModel: OneOnOneGameViewModel()
    )
}
