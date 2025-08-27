import SwiftUI

struct OneOnOneGameView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var gameViewModel: OneOnOneGameViewModel
    @State private var showingLoading = false // For opponent search
    @State private var showingSpinLoading = false // For spin animation
    @State private var timeRemaining = 60
    @State private var gameTimer: Timer?
    @State private var hasStartedFirstGame = false
    
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Заголовок с таймером
                        GameHeaderView(timeRemaining: timeRemaining)
                        
                        // Профили игроков
                        PlayersComparisonView(
                            player1: authViewModel.currentUser,
                            player2: gameViewModel.opponent,
                            player1Score: gameViewModel.playerScore,
                            player2Score: gameViewModel.opponentScore
                        )
                        
                        // Колесо рулетки
                        RouletteWheelView(
                            winningNumber: gameViewModel.winningNumber,
                            isSpinning: gameViewModel.isSpinning
                        )
                        
                        // Показываем результат игры если есть
                        if let result = gameViewModel.gameResult {
                            OneOnOneGameResultView(result: result, gameViewModel: gameViewModel, onNewGame: startNewGame)
                        } else {
                            // Ставки
                            OneOnOneBettingTableView(gameViewModel: gameViewModel)
                            
                            // Компонент ставки
                            OneOnOneBetStepperView(gameViewModel: gameViewModel)
                            
                            // Размещенные ставки
                            OneOnOnePlacedBetsView(gameViewModel: gameViewModel)
                            
                            // Кнопка спина
                            OneOnOneSpinButtonView(gameViewModel: gameViewModel, authViewModel: authViewModel, showingSpinLoading: $showingSpinLoading)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("1 vs 1")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                // Loading при поиске противника
                Group {
                    if showingLoading {
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            LottieView(name: "Casino Roulette")
                                .frame(width: 150, height: 150)
                            
                            Text("Searching for opponent...")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("\(timeRemaining)s")
                                .font(.title)
                                .foregroundColor(.gold)
                        }
                    }
                    if showingSpinLoading {
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            LottieView(name: "Casino Roulette")
                                .frame(width: 150, height: 150)
                            
                            Text("Spinning...")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
            )
        }
        .onAppear {
            if !hasStartedFirstGame {
                startSearchingForOpponent()
                hasStartedFirstGame = true
            }
        }
        .onDisappear {
            stopGame()
        }
    }
    
    private func startSearchingForOpponent() {
        showingLoading = true
        timeRemaining = 10
        
        // Таймер поиска противника
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                // Если противник не найден, создаем бота
                Task { @MainActor in
                    gameViewModel.createBotOpponent()
                    showingLoading = false
                    startGame()
                }
            }
        }
    }
    
    private func startGame() {
        timeRemaining = 60
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                endGame()
            }
        }
    }
    
    private func endGame() {
        gameViewModel.endGame()
        // Показать результат с победителем
        if let result = gameViewModel.gameResult {
            // Можно добавить алерт с результатом
            print("Game ended! Winner: \(result.winner)")
        }
    }
    
    private func startNewGame() {
        // Сбрасываем игру
        gameViewModel.startNewGame()
        timeRemaining = 60
        showingLoading = false
        showingSpinLoading = false
        
        // Начинаем новую игру
        startSearchingForOpponent()
    }
    
    private func stopGame() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

// MARK: - Game Header View
struct GameHeaderView: View {
    let timeRemaining: Int
    
    var body: some View {
        HStack {
            Text("Time: \(timeRemaining)s")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gold)
            
            Spacer()
            
            // Прогресс бар времени
            ProgressView(value: Double(timeRemaining), total: 60)
                .progressViewStyle(LinearProgressViewStyle(tint: .gold))
                .frame(width: 100)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Players Comparison View
struct PlayersComparisonView: View {
    let player1: User?
    let player2: User?
    let player1Score: Int
    let player2Score: Int
    
    var body: some View {
        HStack(spacing: 20) {
            // Игрок 1
            VStack(spacing: 10) {
                Circle()
                    .fill(Color.gold)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("🎰")
                            .font(.title2)
                    )
                
                Text(player1?.username ?? "You")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Score: \(player1Score)")
                    .font(.subheadline)
                    .foregroundColor(.gold)
            }
            
            // VS
            Text("VS")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            // Игрок 2
            VStack(spacing: 10) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(player2?.username == "Bot" ? "🤖" : "🎰")
                            .font(.title2)
                    )
                
                Text(player2?.username ?? "Bot")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Score: \(player2Score)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - One On One Betting Table View
struct OneOnOneBettingTableView: View {
    @ObservedObject var gameViewModel: OneOnOneGameViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            // Ноль
            HStack {
                Button(action: {
                    gameViewModel.placeStraightUpBet(number: 0)
                }) {
                    Text("0")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            
            // Основные числа
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 2) {
                ForEach(1...36, id: \.self) { number in
                    let rouletteNumber = RouletteNumber(number)
                    
                    Button(action: {
                        gameViewModel.placeStraightUpBet(number: number)
                    }) {
                        Text("\(number)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(rouletteNumber.color.color)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Внешние ставки
            HStack(spacing: 2) {
                // Дюжины
                VStack(spacing: 2) {
                    Button("1st 12") {
                        gameViewModel.placeDozenBet(dozen: 1)
                    }
                    .buttonStyle(OutsideBetButtonStyle())
                    
                    Button("2nd 12") {
                        gameViewModel.placeDozenBet(dozen: 2)
                    }
                    .buttonStyle(OutsideBetButtonStyle())
                    
                    Button("3rd 12") {
                        gameViewModel.placeDozenBet(dozen: 3)
                    }
                    .buttonStyle(OutsideBetButtonStyle())
                }
                
                // Колонки
                VStack(spacing: 2) {
                    Button("2:1") {
                        gameViewModel.placeColumnBet(column: 1)
                    }
                    .buttonStyle(OutsideBetButtonStyle())
                    
                    Button("2:1") {
                        gameViewModel.placeColumnBet(column: 2)
                    }
                    .buttonStyle(OutsideBetButtonStyle())
                    
                    Button("2:1") {
                        gameViewModel.placeColumnBet(column: 3)
                    }
                    .buttonStyle(OutsideBetButtonStyle())
                }
            }
            
            // Четные ставки
            HStack(spacing: 2) {
                Button("1-18") {
                    gameViewModel.placeEvenMoneyBet(type: .low)
                }
                .buttonStyle(OutsideBetButtonStyle())
                
                Button("EVEN") {
                    gameViewModel.placeEvenMoneyBet(type: .even)
                }
                .buttonStyle(OutsideBetButtonStyle())
                
                Button("RED") {
                    gameViewModel.placeColorBet(color: .red)
                }
                .buttonStyle(OutsideBetButtonStyle())
                
                Button("BLACK") {
                    gameViewModel.placeColorBet(color: .black)
                }
                .buttonStyle(OutsideBetButtonStyle())
                
                Button("ODD") {
                    gameViewModel.placeEvenMoneyBet(type: .odd)
                }
                .buttonStyle(OutsideBetButtonStyle())
                
                Button("19-36") {
                    gameViewModel.placeEvenMoneyBet(type: .high)
                }
                .buttonStyle(OutsideBetButtonStyle())
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - One On One Bet Stepper View
struct OneOnOneBetStepperView: View {
    @ObservedObject var gameViewModel: OneOnOneGameViewModel
    
    var body: some View {
        HStack {
            Text("BET")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            HStack(spacing: 0) {
                Button(action: {
                    gameViewModel.decreaseBet()
                }) {
                    Image(systemName: "minus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.red)
                }
                
                Text("\(gameViewModel.currentBet)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 44)
                    .background(Color.black)
                
                Button(action: {
                    gameViewModel.increaseBet()
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.green)
                }
            }
            .cornerRadius(8)
            
            Spacer()
            
            Button("CLEAR") {
                gameViewModel.clearAllBets()
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - One On One Placed Bets View
struct OneOnOnePlacedBetsView: View {
    @ObservedObject var gameViewModel: OneOnOneGameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PLACED BETS")
                .font(.headline)
                .foregroundColor(.white)
            
            if gameViewModel.placedBets.isEmpty {
                Text("No placed bets")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(gameViewModel.placedBets) { bet in
                        OneOnOnePlacedBetRow(bet: bet) {
                            gameViewModel.removeBet(bet)
                        }
                    }
                }
                
                HStack {
                    Text("Total bet:")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(gameViewModel.totalBetAmount)")
                        .fontWeight(.bold)
                        .foregroundColor(.gold)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - One On One Placed Bet Row
struct OneOnOnePlacedBetRow: View {
    let bet: Bet
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bet.type.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !bet.numbers.isEmpty {
                    Text("Numbers: \(bet.numbers.map(String.init).joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(bet.amount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                
                Text("Payout: \(bet.payout)")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - One On One Spin Button View
struct OneOnOneSpinButtonView: View {
    @ObservedObject var gameViewModel: OneOnOneGameViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showingSpinLoading: Bool
    
    var body: some View {
        Button(action: {
            showingSpinLoading = true
            Task {
                await gameViewModel.spinWheel()
                showingSpinLoading = false
            }
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("SPIN")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                gameViewModel.placedBets.isEmpty || gameViewModel.isSpinning
                ? Color.gray
                : Color.green
            )
            .cornerRadius(12)
        }
        .disabled(gameViewModel.placedBets.isEmpty || gameViewModel.isSpinning)
        .padding(.horizontal)
    }
}

// MARK: - One On One Game Result View
struct OneOnOneGameResultView: View {
    let result: OneOnOneGameResult
    @ObservedObject var gameViewModel: OneOnOneGameViewModel
    let onNewGame: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок результата
            Text("Game Over!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.gold)
            
            // Победитель
            VStack(spacing: 10) {
                Text("Winner:")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(result.winner)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(result.winner == "You" ? .green : result.winner == "Tie" ? .yellow : .red)
            }
            
            // Финальные счета
            VStack(spacing: 15) {
                HStack {
                    Text("Your Score:")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(result.playerScore)")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Opponent Score:")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(result.opponentScore)")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            
            // Кнопка новой игры
            Button("New Game") {
                onNewGame()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    OneOnOneGameView(authViewModel: AuthViewModel(), gameViewModel: OneOnOneGameViewModel())
}
