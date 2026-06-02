import Foundation
import SwiftData

@Model
final class Stock {
    @Attribute(.unique) var zsCode: String  // e.g., "600519.SH"
    var code: String
    var name: String
    var category: String  // stock, index, fund
    var addedAt: Date
    var targetPrice: Double?
    var notes: String?

    // Many-to-many relationship with Tag
    var tags: [Tag]

    // Cached price data (not persisted to cloud, just local cache)
    @Transient var lastPrice: Double?
    @Transient var changePercent: Double?
    @Transient var priceHistory: [Double]?

    init(zsCode: String, code: String, name: String, category: String = "stock") {
        self.zsCode = zsCode
        self.code = code
        self.name = name
        self.category = category
        self.addedAt = Date()
        self.tags = []
    }
}
