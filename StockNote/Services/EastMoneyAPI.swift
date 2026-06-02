import Foundation

// MARK: - Response Models

struct EastMoneySearchResponse: Codable {
    let QuotationCodeTable: QuotationCodeTable
}

struct QuotationCodeTable: Codable {
    let Data: [QuoteItem]?
}

struct QuoteItem: Codable {
    let Code: String
    let Name: String
    let PinyinShort: String?
    let ID: String?
    let JYS: String?
    let Classify: String?
    let MarketType: String?
    let SecurityTypeName: String?
    let SecurityType: String?
    let MktNum: String?
    let TypeUS: String?
    let QuoteID: String?
    let UnifiedCode: String?
    let InnerCode: String?
}

// MARK: - Quote Model (clean)

struct Quote: Identifiable {
    var id: String { zsCode }
    let code: String
    let name: String
    let zsCode: String  // e.g., "600519.SH"
    let category: String  // stock, index, fund
    let classify: String?
    let securityTypeName: String?
}

// MARK: - API Service

actor EastMoneyAPI {
    static let shared = EastMoneyAPI()

    private let searchURL = "https://searchapi.eastmoney.com/api/suggest/get"
    private let token = "D43BF722C8E33BDC906FB84D85E326E8"  // Public token from EastMoney web

    private init() {}

    /// Search for stocks/indexes/funds by keyword
    func search(keyword: String, category: String? = nil, limit: Int = 15) async throws -> [Quote] {
        var components = URLComponents(string: searchURL)!
        components.queryItems = [
            URLQueryItem(name: "input", value: keyword),
            URLQueryItem(name: "type", value: "14"),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "count", value: String(limit)),
        ]

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(EastMoneySearchResponse.self, from: data)

        guard let items = response.QuotationCodeTable.Data else {
            return []
        }

        var quotes = items.compactMap { item -> Quote? in
            // Parse quote_id to get zsCode
            guard let quoteId = item.QuoteID else { return nil }
            let parts = quoteId.split(separator: ".")
            guard parts.count == 2 else { return nil }

            let market = String(parts[0])
            let code = String(parts[1])

            // Map market code to suffix
            let suffix: String
            switch market {
            case "1": suffix = "SH"
            case "0": suffix = "SZ"
            case "116": suffix = "HK"
            case "105", "106", "107": suffix = "US"
            default: suffix = market
            }

            let zsCode = "\(code).\(suffix)"

            // Determine category
            let cat: String
            if let classify = item.Classify {
                if classify == "Index" || classify == "UniversalIndex" || item.SecurityTypeName == "指数" {
                    cat = "index"
                } else if item.SecurityTypeName == "基金" {
                    cat = "fund"
                } else if classify == "AStock" || classify == "UsStock" ||
                          ["深A", "沪A", "港股", "美股", "科创板", "创业板"].contains(item.SecurityTypeName ?? "") {
                    cat = "stock"
                } else {
                    cat = "stock"
                }
            } else {
                cat = "stock"
            }

            return Quote(
                code: item.Code,
                name: item.Name,
                zsCode: zsCode,
                category: cat,
                classify: item.Classify,
                securityTypeName: item.SecurityTypeName
            )
        }

        // Filter by category if specified
        if let category = category {
            quotes = quotes.filter { $0.category == category }
        }

        return quotes
    }

    enum APIError: Error {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
    }
}
