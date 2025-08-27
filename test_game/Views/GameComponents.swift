import SwiftUI

// MARK: - Bet Stepper View
struct BetStepperView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    var body: some View {
        HStack {
            Text("СТАВКА")
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
            
            Button("ОЧИСТИТЬ") {
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

// MARK: - Placed Bets View
struct PlacedBetsView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("РАЗМЕЩЕННЫЕ СТАВКИ")
                .font(.headline)
                .foregroundColor(.white)
            
            if gameViewModel.placedBets.isEmpty {
                Text("Нет размещенных ставок")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(gameViewModel.placedBets) { bet in
                        PlacedBetRow(bet: bet) {
                            gameViewModel.removeBet(bet)
                        }
                    }
                }
                
                HStack {
                    Text("Общая ставка:")
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

// MARK: - Placed Bet Row
struct PlacedBetRow: View {
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
                    Text("Числа: \(bet.numbers.map(String.init).joined(separator: ", "))")
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
                
                Text("Выигрыш: \(bet.payout)")
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

// MARK: - Spin Button View
struct SpinButtonView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        Button(action: {
            Task {
                await gameViewModel.spinWheel()
            }
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("КРУТИТЬ")
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

// MARK: - Game Result View
struct GameResultView: View {
    let result: GameResult
    let onNewGame: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Результат
            VStack(spacing: 10) {
                Text("РЕЗУЛЬТАТ")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(result.winningNumber)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(RouletteNumber.getColor(for: result.winningNumber).color)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
            }
            
            // Выигрыш
            if result.isWin {
                VStack(spacing: 8) {
                    Text("ПОЗДРАВЛЯЕМ!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Выигрыш: \(result.totalWinnings)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.gold)
                }
            } else {
                Text("Попробуйте еще раз!")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            
            // Выигрышные ставки
            if !result.winningBets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Выигрышные ставки:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(result.winningBets) { bet in
                        HStack {
                            Text(bet.type.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                            Text("+\(bet.payout)")
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(6)
                    }
                }
            }
            
            // Кнопка новой игры
            Button(action: onNewGame) {
                Text("НОВАЯ ИГРА")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        BetStepperView(gameViewModel: GameViewModel())
        PlacedBetsView(gameViewModel: GameViewModel())
        SpinButtonView(gameViewModel: GameViewModel(), authViewModel: AuthViewModel())
    }
    .background(Color.black)
}
