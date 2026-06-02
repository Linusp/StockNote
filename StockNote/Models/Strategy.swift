import Foundation
import SwiftData

@Model
final class Strategy {
    @Attribute(.unique) var id: String
    var name: String
    var desc: String?  // 'description' is reserved
    var currency: String  // CNY, USD, HKD
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var deals: [Deal]

    init(name: String, currency: String = "CNY", desc: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.currency = currency
        self.desc = desc
        self.createdAt = Date()
        self.deals = []
    }

    // Computed: total cash balance
    var cashBalance: Double {
        deals.reduce(0) { result, deal in
            switch deal.type {
            case .deposit:
                return result + deal.price
            case .withdraw:
                return result - deal.price
            case .buy:
                return result - (deal.price * deal.amount + deal.fee)
            case .sell:
                return result + (deal.price * deal.amount - deal.fee)
            }
        }
    }

    // Computed: total invested principal
    var totalPrincipal: Double {
        deals.reduce(0) { result, deal in
            switch deal.type {
            case .deposit:
                return result + deal.price
            case .withdraw:
                return result - deal.price
            default:
                return result
            }
        }
    }
}
