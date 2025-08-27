import Foundation
import Combine

@MainActor
class OneOnOneGameViewModel: ObservableObject {
    @Published var currentBet: Int = 10
    @Published var placedBets: [Bet] = []
    @Published var gameState: GameState = .betting
    @Published var winningNumber: Int?
    @Published var totalBetAmount: Int = 0
    @Published var isSpinning = false
    
    // 1 на 1 специфичные свойства
    @Published var opponent: User?
    @Published var playerScore: Int = 0
    @Published var opponentScore: Int = 0
    @Published var gameResult: OneOnOneGameResult?
    
    weak var authViewModel: AuthViewModel?
    var onGameStarted: (() -> Void)?
    
    private let rouletteNumbers = Array(0...36).map { RouletteNumber($0) }
    private var cancellables = Set<AnyCancellable>()
    private var botTimer: Timer?
    
    // Европейская рулетка - числа в порядке на колесе
    private let wheelOrder = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
    
    var allNumbers: [RouletteNumber] {
        return rouletteNumbers
    }
    
    var betStep: Int {
        return max(1, currentBet / 10)
    }
    
    func createBotOpponent() {
        opponent = User(
            id: "bot_\(UUID().uuidString)",
            username: "Bot",
            chips: Int.max, // Бесконечные фишки для бота
            winRate: Double.random(in: 30...70)
        )
        print("Bot opponent created - game is now active")
        gameState = .betting // Устанавливаем состояние в betting
        startBotGame()
    }
    
    private func startBotGame() {
        print("Starting bot game")
        // Останавливаем предыдущий таймер если есть
        botTimer?.invalidate()
        
        // Бот делает ставки каждые 3-7 секунд независимо от игрока
        botTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...7), repeats: true) { _ in
            Task { @MainActor in
                self.makeBotBet()
            }
        }
    }
    
    private func makeBotBet() {
        // Бот случайно выбирает тип ставки
        let betTypes: [BetType] = [.red, .black, .odd, .even, .low, .high, .straightUp]
        let randomBetType = betTypes.randomElement() ?? .red
        
        // Бот делает случайную ставку от 10 до 200
        let botBetAmount = Int.random(in: 10...200)
        
        var numbers: [Int] = []
        switch randomBetType {
        case .straightUp:
            numbers = [Int.random(in: 0...36)]
        case .red, .black, .odd, .even, .low, .high:
            numbers = []
        default:
            numbers = []
        }
        
        // Создаем ставку бота и добавляем к его счету
        let botBet = Bet(type: randomBetType, numbers: numbers, amount: botBetAmount)
        print("Bot placed bet: \(botBet.type.rawValue) for \(botBet.amount)")
        
        // Обновляем счет бота
        let botWinningChance = Double.random(in: 0...1)
        if botWinningChance > 0.5 {
            // Бот выиграл
            let botWinnings = botBetAmount * randomBetType.payout
            opponentScore += botWinnings
            print("Bot won: \(botWinnings) with bet \(botBetAmount) on \(randomBetType.rawValue)")
        } else {
            // Бот проиграл
            opponentScore -= botBetAmount
            print("Bot lost: -\(botBetAmount) with bet on \(randomBetType.rawValue)")
        }
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
        
        // Запускаем таймер игры когда игрок делает ставку
        onGameStarted?()
        
        // Анимация вращения (симуляция)
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 секунды
        
        // Генерация случайного числа
        let randomIndex = Int.random(in: 0..<wheelOrder.count)
        winningNumber = wheelOrder[randomIndex]
        
        // Определение выигрышных ставок игрока
        let winningBets = calculateWinningBets()
        let totalWinnings = winningBets.reduce(0) { $0 + $1.payout }
        
        // Обновляем счет игрока (как в обычной игре)
        if totalWinnings > 0 {
            // Игрок выиграл - добавляем выигрыш
            playerScore += totalWinnings
        } else {
            // Игрок проиграл - вычитаем ставку
            playerScore -= totalBetAmount
        }
        
        // Бот делает случайную ставку и получает результат
        let botBetAmount = Int.random(in: 10...200)
        let botBetType = [BetType.red, .black, .odd, .even, .low, .high].randomElement() ?? .red
        
        // Симулируем результат бота
        let botWinningChance = Double.random(in: 0...1)
        if botWinningChance > 0.5 { // 50% шанс выигрыша для бота (более сбалансированно)
            // Бот выиграл
            let botWinnings = botBetAmount * botBetType.payout
            opponentScore += botWinnings
            print("Bot won: \(botWinnings) with bet \(botBetAmount) on \(botBetType.rawValue)")
        } else {
            // Бот проиграл
            opponentScore -= botBetAmount
            print("Bot lost: -\(botBetAmount) with bet on \(botBetType.rawValue)")
        }
        
        print("Player score: \(playerScore), Opponent score: \(opponentScore)")
        
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
    
    func endGame() {
        botTimer?.invalidate()
        botTimer = nil
        
        // Определяем победителя
        let isPlayerWinner = playerScore > opponentScore
        let totalPot = abs(playerScore) + abs(opponentScore)
        
        print("Game ended! Player: \(playerScore), Opponent: \(opponentScore), Winner: \(isPlayerWinner ? "Player" : "Opponent")")
        
        gameResult = OneOnOneGameResult(
            playerScore: playerScore,
            opponentScore: opponentScore,
            isPlayerWinner: isPlayerWinner,
            totalPot: totalPot
        )
    }
    
    func startNewGame() {
        // Останавливаем бота
        botTimer?.invalidate()
        botTimer = nil
        
        // Сбрасываем состояние
        gameState = .betting
        placedBets.removeAll()
        winningNumber = nil
        gameResult = nil
        playerScore = 0
        opponentScore = 0
        totalBetAmount = 0
        isSpinning = false
        opponent = nil
        
        print("Game reset - opponent removed, switching tabs allowed")
    }
    
    func isGameActive() -> Bool {
        return opponent != nil || gameState == .spinning
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

// MARK: - One On One Game Result
struct OneOnOneGameResult {
    let playerScore: Int
    let opponentScore: Int
    let isPlayerWinner: Bool
    let totalPot: Int
    
    var winner: String {
        if isPlayerWinner {
            return "You"
        } else if playerScore == opponentScore {
            return "Tie"
        } else {
            return "Opponent"
        }
    }
}
