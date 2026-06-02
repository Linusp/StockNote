import Foundation
import SwiftData

enum DealType: String, Codable {
    case buy = "buy"
    case sell = "sell"
    case deposit = "deposit"
    case withdraw = "withdraw"

    var label: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        case .deposit: return "转入"
        case .withdraw: return "转出"
        }
    }
}

@Model
final class Deal {
    var id: String
    var type: DealType
    var code: String?  // Stock code, nil for deposit/withdraw
    var name: String?  // Stock name
    var price: Double  // Unit price for buy/sell, amount for deposit/withdraw
    var amount: Double  // Number of shares
    var fee: Double  // Transaction fee
    var date: Date

    var strategy: Strategy?

    init(type: DealType, price: Double, amount: Double = 0, fee: Double = 0, code: String? = nil, name: String? = nil, date: Date = Date()) {
        self.id = UUID().uuidString
        self.type = type
        self.code = code
        self.name = name
        self.price = price
        self.amount = amount
        self.fee = fee
        self.date = date
    }

    // Total value of the deal (for display)
    var totalValue: Double {
        switch type {
        case .buy:
            return price * amount + fee
        case .sell:
            return price * amount - fee
        case .deposit, .withdraw:
            return price
        }
    }
}
