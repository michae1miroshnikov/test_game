import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    let id: String
    let username: String
    var chips: Int
    var winRate: Double
    let createdAt: Date
    
    init(id: String, username: String, chips: Int = 2000, winRate: Double = 0.0) {
        self.id = id
        self.username = username
        self.chips = chips
        self.winRate = winRate
        self.createdAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case chips
        case winRate
        case createdAt
    }
}
