import Foundation
import Combine

@MainActor
class GameViewModel: ObservableObject {
    @Published var currentBet: Int = 10
    @Published var placedBets: [Bet] = []
    @Published var gameState: GameState = .betting
    @Published var winningNumber: Int?
    @Published var gameResult: GameResult?
    @Published var totalBetAmount: Int = 0
    @Published var totalWinnings: Int = 0
    @Published var isSpinning = false
    
    private let rouletteNumbers = Array(0...36).map { RouletteNumber($0) }
    private var cancellables = Set<AnyCancellable>()
    
    // Европейская рулетка - числа в порядке на колесе
    private let wheelOrder = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
    
    var allNumbers: [RouletteNumber] {
        return rouletteNumbers
    }
    
    var betStep: Int {
        return max(1, currentBet / 10)
    }
    
    func increaseBet() {
        currentBet += betStep
    }
    
    func decreaseBet() {
        currentBet = max(1, currentBet - betStep)
    }
    
    func placeBet(type: BetType, numbers: [Int]) {
        let bet = Bet(type: type, numbers: numbers, amount: currentBet)
        placedBets.append(bet)
        updateTotalBetAmount()
    }
    
    func removeBet(_ bet: Bet) {
        placedBets.removeAll { $0.id == bet.id }
        updateTotalBetAmount()
    }
    
    func clearAllBets() {
        placedBets.removeAll()
        updateTotalBetAmount()
    }
    
    private func updateTotalBetAmount() {
        totalBetAmount = placedBets.reduce(0) { $0 + $1.amount }
    }
    
    func spinWheel() async {
        guard !placedBets.isEmpty else { return }
        
        gameState = .spinning
        isSpinning = true
        
        // Анимация вращения (симуляция)
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 секунды
        
        // Генерация случайного числа
        let randomIndex = Int.random(in: 0..<wheelOrder.count)
        winningNumber = wheelOrder[randomIndex]
        
        // Определение выигрышных ставок
        let winningBets = calculateWinningBets()
        let totalWinnings = winningBets.reduce(0) { $0 + $1.payout }
        
        gameResult = GameResult(
            winningNumber: winningNumber!,
            winningBets: winningBets,
            totalWinnings: totalWinnings,
            isWin: !winningBets.isEmpty
        )
        
        self.totalWinnings = totalWinnings
        gameState = .result
        isSpinning = false
    }
    
    private func calculateWinningBets() -> [Bet] {
        guard let winningNumber = winningNumber else { return [] }
        
        return placedBets.filter { bet in
            switch bet.type {
            case .straightUp:
                return bet.numbers.contains(winningNumber)
            case .split:
                return bet.numbers.contains(winningNumber)
            case .street:
                let streetStart = (winningNumber - 1) / 3 * 3 + 1
                return bet.numbers.contains(streetStart)
            case .corner:
                let cornerNumbers = getCornerNumbers(for: winningNumber)
                return !Set(bet.numbers).isDisjoint(with: Set(cornerNumbers))
            case .line:
                let lineStart = (winningNumber - 1) / 6 * 6 + 1
                return bet.numbers.contains(lineStart)
            case .dozen:
                let dozen = (winningNumber - 1) / 12 + 1
                return bet.numbers.contains(dozen)
            case .column:
                let column = (winningNumber - 1) % 3 + 1
                return bet.numbers.contains(column)
            case .red:
                return winningNumber != 0 && RouletteNumber.getColor(for: winningNumber) == .red
            case .black:
                return winningNumber != 0 && RouletteNumber.getColor(for: winningNumber) == .black
            case .odd:
                return winningNumber != 0 && winningNumber % 2 == 1
            case .even:
                return winningNumber != 0 && winningNumber % 2 == 0
            case .low:
                return winningNumber >= 1 && winningNumber <= 18
            case .high:
                return winningNumber >= 19 && winningNumber <= 36
            }
        }
    }
    
    private func getCornerNumbers(for number: Int) -> [Int] {
        // Упрощенная логика для угловых ставок
        let row = (number - 1) / 3
        let col = (number - 1) % 3
        
        var corners: [Int] = []
        
        // Добавляем возможные углы
        if row > 0 && col > 0 {
            corners.append((row - 1) * 3 + col)
        }
        if row > 0 && col < 2 {
            corners.append((row - 1) * 3 + col + 1)
        }
        if row < 11 && col > 0 {
            corners.append(row * 3 + col)
        }
        if row < 11 && col < 2 {
            corners.append(row * 3 + col + 1)
        }
        
        return corners
    }
    
    func startNewGame() {
        gameState = .betting
        placedBets.removeAll()
        winningNumber = nil
        gameResult = nil
        totalBetAmount = 0
        totalWinnings = 0
    }
    
    // Вспомогательные методы для создания ставок
    func placeStraightUpBet(number: Int) {
        placeBet(type: .straightUp, numbers: [number])
    }
    
    func placeColorBet(color: RouletteColor) {
        switch color {
        case .red:
            placeBet(type: .red, numbers: [])
        case .black:
            placeBet(type: .black, numbers: [])
        case .green:
            placeBet(type: .straightUp, numbers: [0])
        }
    }
    
    func placeDozenBet(dozen: Int) {
        placeBet(type: .dozen, numbers: [dozen])
    }
    
    func placeColumnBet(column: Int) {
        placeBet(type: .column, numbers: [column])
    }
    
    func placeEvenMoneyBet(type: BetType) {
        placeBet(type: type, numbers: [])
    }
}
