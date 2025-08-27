import SwiftUI

struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingSpinLoading = false
    @State private var showingBonusAlert = false
    @State private var showingNoBonusAlert = false
    
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
                
                VStack(spacing: 0) {
                    // Заголовок с балансом
                    UserHeaderView(user: authViewModel.currentUser)
                    
                    // Основной контент
                    ScrollView {
                        VStack(spacing: 20) {
                            // Колесо рулетки
                            RouletteWheelView(
                                winningNumber: gameViewModel.winningNumber,
                                isSpinning: gameViewModel.isSpinning
                            )
                            
                            // Ставки
                            BettingTableView(gameViewModel: gameViewModel)
                            
                            // Компонент ставки
                            BetStepperView(gameViewModel: gameViewModel)
                            
                            // Размещенные ставки
                            PlacedBetsView(gameViewModel: gameViewModel)
                            
                            // Кнопка спина
                            SpinButtonView(gameViewModel: gameViewModel, authViewModel: authViewModel, showingSpinLoading: $showingSpinLoading)
                            
                            // Отображение ошибок
                            if let errorMessage = gameViewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Roulette")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                // Результат игры
                Group {
                    if let result = gameViewModel.gameResult {
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()
                        
                        GameResultView(result: result) {
                            gameViewModel.startNewGame()
                        }
                    }
                }
            )
            .overlay(
                // Loading при спинне
                Group {
                    if showingSpinLoading {
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()
                        
                        LoadingView()
                            .onAppear {
                                // Показываем LoadingView на 3 секунды во время спинна
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showingSpinLoading = false
                                }
                            }
                    }
                }
            )
        }
        .onAppear {
            gameViewModel.setAuthViewModel(authViewModel)
        }
        .onReceive(gameViewModel.$gameResult) { result in
            if let result = result {
                handleGameResult(result)
            }
        }
        .alert("Bonus Chips!", isPresented: $showingBonusAlert) {
            Button("OK") { }
        } message: {
            Text("You received 100 bonus chips to continue playing!")
        }
        .alert("No Bonus Available", isPresented: $showingNoBonusAlert) {
            Button("OK") { }
        } message: {
            Text("You have already used your bonus chips. Please add chips to continue playing.")
        }
    }
    
    private func handleGameResult(_ result: GameResult) {
        Task {
            if let user = authViewModel.currentUser {
                // Если выиграли, добавляем выигрыш к балансу
                // Если проиграли, вычитаем ставку из баланса
                let newChips: Int
                if result.isWin {
                    // Выигрыш: добавляем выигрыш к текущему балансу
                    newChips = user.chips + result.totalWinnings
                } else {
                    // Проигрыш: вычитаем ставку из текущего баланса
                    newChips = user.chips - gameViewModel.totalBetAmount
                }
                
                // Если у пользователя 0 или отрицательный баланс
                let finalChips: Int
                if newChips <= 0 {
                    // Проверяем, можно ли дать бонусные фишки
                    if user.bonusChipsAvailable {
                        finalChips = 100
                        await authViewModel.updateBonusChipsAvailable(false)
                        // Показываем уведомление о бонусных фишках
                        await showBonusChipsAlert()
                    } else {
                        finalChips = 0
                        // Показываем предупреждение, что бонусные фишки уже использованы
                        await showNoBonusChipsAlert()
                    }
                } else {
                    finalChips = newChips
                }
                
                await authViewModel.updateUserChips(finalChips)
                
                // Обновляем win rate
                await updateWinRate(isWin: result.isWin)
            }
        }
    }
    
    private func showBonusChipsAlert() async {
        // Показываем алерт о бонусных фишках
        await MainActor.run {
            showingBonusAlert = true
            print("Showing bonus alert")
        }
    }
    
    private func showNoBonusChipsAlert() async {
        // Показываем алерт о том, что бонусные фишки уже использованы
        await MainActor.run {
            showingNoBonusAlert = true
            print("Showing no bonus alert")
        }
    }
    
    private func updateWinRate(isWin: Bool) async {
        guard let user = authViewModel.currentUser else { return }
        
        // Получаем текущую статистику из Firebase
        let totalGames = user.totalGames
        let totalWins = user.totalWins
        
        // Обновляем статистику
        let newTotalGames = totalGames + 1
        let newTotalWins = totalWins + (isWin ? 1 : 0)
        
        // Рассчитываем win rate в процентах
        let newWinRate = newTotalGames > 0 ? (Double(newTotalWins) / Double(newTotalGames)) * 100.0 : 100.0
        
        // Сохраняем в Firebase
        await authViewModel.updateWinRate(newWinRate)
        await authViewModel.updateTotalGames(newTotalGames)
        await authViewModel.updateTotalWins(newTotalWins)
    }
}

// MARK: - User Header View
struct UserHeaderView: View {
    let user: User?
    
    var body: some View {
        HStack {
            // Аватар
            Circle()
                .fill(Color.gold)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("🎰")
                        .font(.title2)
                )
            
            // Имя пользователя
            VStack(alignment: .leading) {
                Text(user?.username ?? "Guest")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Баланс
            HStack(spacing: 8) {
                Text("\(user?.chips ?? 0)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                
                Image(systemName: "circle.fill")
                    .foregroundColor(.gold)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Roulette Wheel View
struct RouletteWheelView: View {
    let winningNumber: Int?
    let isSpinning: Bool
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Внешний круг
            Circle()
                .stroke(Color.gold, lineWidth: 8)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(rotationAngle))
            
            // Внутренний круг
            Circle()
                .fill(Color.black)
                .frame(width: 180, height: 180)
            
            // Числа на колесе
            ForEach(0..<37, id: \.self) { index in
                let angle = Double(index) * (360.0 / 37.0)
                let number = getWheelNumber(at: index)
                let color = RouletteNumber.getColor(for: number)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(color.color)
                            .frame(width: 20, height: 20)
                    )
                    .offset(y: -90)
                    .rotationEffect(.degrees(angle))
            }
            
            // Центральная точка
            Circle()
                .fill(Color.gold)
                .frame(width: 30, height: 30)
                .scaleEffect(isSpinning ? 1.2 : 1.0)
        }
        .onAppear {
            if isSpinning {
                withAnimation(.linear(duration: 3)) {
                    rotationAngle += 720 // 2 полных оборота
                }
            }
        }
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                withAnimation(.linear(duration: 3)) {
                    rotationAngle += 720
                }
            }
        }
    }
    
    private func getWheelNumber(at index: Int) -> Int {
        let wheelOrder = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
        return wheelOrder[index]
    }
}

// MARK: - Betting Table View
struct BettingTableView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
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

// MARK: - Outside Bet Button Style
struct OutsideBetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.green)
            .cornerRadius(4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    GameView(authViewModel: AuthViewModel())
}
