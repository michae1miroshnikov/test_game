import Foundation
import SwiftUI

// MARK: - Roulette Number
struct RouletteNumber: Identifiable, Hashable {
    let id = UUID()
    let number: Int
    let color: RouletteColor
    let isZero: Bool
    
    init(_ number: Int) {
        self.number = number
        self.isZero = number == 0
        self.color = RouletteNumber.getColor(for: number)
    }
    
    static func getColor(for number: Int) -> RouletteColor {
        if number == 0 { return .green }
        
        let redNumbers = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
        return redNumbers.contains(number) ? .red : .black
    }
}

// MARK: - Roulette Color
enum RouletteColor: String, CaseIterable {
    case red = "red"
    case black = "black"
    case green = "green"
    
    var color: Color {
        switch self {
        case .red: return .red
        case .black: return .black
        case .green: return .green
        }
    }
}

// MARK: - Bet Types
enum BetType: String, CaseIterable {
    case straightUp = "Straight Up"
    case split = "Split"
    case street = "Street"
    case corner = "Corner"
    case line = "Line"
    case dozen = "Dozen"
    case column = "Column"
    case red = "Red"
    case black = "Black"
    case odd = "Odd"
    case even = "Even"
    case low = "Low (1-18)"
    case high = "High (19-36)"
    
    var payout: Int {
        switch self {
        case .straightUp: return 35
        case .split: return 17
        case .street: return 11
        case .corner: return 8
        case .line: return 5
        case .dozen, .column: return 2
        case .red, .black, .odd, .even, .low, .high: return 1
        }
    }
    
    var numbersCovered: Int {
        switch self {
        case .straightUp: return 1
        case .split: return 2
        case .street: return 3
        case .corner: return 4
        case .line: return 6
        case .dozen, .column: return 12
        case .red, .black, .odd, .even, .low, .high: return 18
        }
    }
}

// MARK: - Bet
struct Bet: Identifiable {
    let id = UUID()
    let type: BetType
    let numbers: [Int]
    let amount: Int
    let payout: Int
    
    init(type: BetType, numbers: [Int], amount: Int) {
        self.type = type
        self.numbers = numbers
        self.amount = amount
        self.payout = amount * type.payout
    }
}

// MARK: - Game State
enum GameState {
    case betting
    case spinning
    case result
}

// MARK: - Game Result
struct GameResult {
    let winningNumber: Int
    let winningBets: [Bet]
    let totalWinnings: Int
    let isWin: Bool
}
