import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    let id: String
    let username: String
    var chips: Int
    var winRate: Double
    var totalGames: Int
    var totalWins: Int
    var bonusChipsAvailable: Bool
    let createdAt: Date
    
    init(id: String, username: String, chips: Int = 2000, winRate: Double = 100.0, totalGames: Int = 0, totalWins: Int = 0, bonusChipsAvailable: Bool = true) {
        self.id = id
        self.username = username
        self.chips = chips
        self.winRate = 100.0 // Начинаем с 100%
        self.totalGames = totalGames
        self.totalWins = totalWins
        self.bonusChipsAvailable = bonusChipsAvailable
        self.createdAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case chips
        case winRate
        case totalGames
        case totalWins
        case bonusChipsAvailable
        case createdAt
    }
}
