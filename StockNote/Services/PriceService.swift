import Foundation

// MARK: - Real-time Quote Response

struct RealTimeQuote {
    let code: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let open: Double
    let high: Double
    let low: Double
    let volume: Double
    let amount: Double
    let timestamp: Date
}

// MARK: - Price Service

actor PriceService {
    static let shared = PriceService()

    // Cache prices for 30 seconds
    private var priceCache: [String: (quote: RealTimeQuote, fetchedAt: Date)] = [:]
    private let cacheDuration: TimeInterval = 30

    private init() {}

    /// Get real-time quote for a single stock
    func getQuote(zsCode: String) async throws -> RealTimeQuote {
        // Check cache
        if let cached = priceCache[zsCode],
           Date().timeIntervalSince(cached.fetchedAt) < cacheDuration {
            return cached.quote
        }

        // Convert zsCode to EastMoney secid format
        let secid = zsCodeToSecid(zsCode)

        let url = URL(string: "https://push2.eastmoney.com/api/qt/stock/get")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secid", value: secid),
            URLQueryItem(name: "fields", value: "f43,f44,f45,f46,f47,f48,f57,f58,f169,f170"),
            URLQueryItem(name: "ut", value: "fa5fd1943c7b386f172d6893dbfba10b"),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: Any] else {
            throw PriceError.invalidResponse
        }

        let quote = RealTimeQuote(
            code: zsCode,
            name: dataDict["f58"] as? String ?? "",
            price: (dataDict["f43"] as? Double ?? 0) / 100,
            change: (dataDict["f169"] as? Double ?? 0) / 100,
            changePercent: (dataDict["f170"] as? Double ?? 0) / 100,
            open: (dataDict["f46"] as? Double ?? 0) / 100,
            high: (dataDict["f44"] as? Double ?? 0) / 100,
            low: (dataDict["f45"] as? Double ?? 0) / 100,
            volume: dataDict["f47"] as? Double ?? 0,
            amount: dataDict["f48"] as? Double ?? 0,
            timestamp: Date()
        )

        priceCache[zsCode] = (quote, Date())
        return quote
    }

    /// Get quotes for multiple stocks
    func getQuotes(zsCodes: [String]) async throws -> [String: RealTimeQuote] {
        var results: [String: RealTimeQuote] = [:]

        // Batch fetch using async let
        await withTaskGroup(of: (String, RealTimeQuote?).self) { group in
            for code in zsCodes {
                group.addTask {
                    do {
                        let quote = try await self.getQuote(zsCode: code)
                        return (code, quote)
                    } catch {
                        return (code, nil)
                    }
                }
            }

            for await (code, quote) in group {
                if let quote = quote {
                    results[code] = quote
                }
            }
        }

        return results
    }

    /// Get historical prices (last N days)
    func getHistory(zsCode: String, days: Int = 30) async throws -> [(date: String, close: Double)] {
        let secid = zsCodeToSecid(zsCode)

        var components = URLComponents(string: "https://push2his.eastmoney.com/api/qt/stock/kline/get")!
        components.queryItems = [
            URLQueryItem(name: "secid", value: secid),
            URLQueryItem(name: "fields1", value: "f1,f2,f3,f4,f5,f6"),
            URLQueryItem(name: "fields2", value: "f51,f52,f53,f54,f55,f56,f57"),
            URLQueryItem(name: "klt", value: "101"),  // Daily
            URLQueryItem(name: "fqt", value: "1"),    // Forward adjusted
            URLQueryItem(name: "lmt", value: String(days)),
            URLQueryItem(name: "end", value: "20500101"),
            URLQueryItem(name: "ut", value: "fa5fd1943c7b386f172d6893dbfba10b"),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: Any],
              let klines = dataDict["klines"] as? [String] else {
            throw PriceError.invalidResponse
        }

        return klines.compactMap { line -> (String, Double)? in
            let parts = line.split(separator: ",")
            guard parts.count >= 3,
                  let close = Double(parts[2]) else { return nil }
            return (String(parts[0]), close)
        }
    }

    // Convert zsCode (600519.SH) to EastMoney secid (1.600519)
    private func zsCodeToSecid(_ zsCode: String) -> String {
        let parts = zsCode.split(separator: ".")
        guard parts.count == 2 else { return zsCode }

        let code = String(parts[0])
        let suffix = String(parts[1])

        let market: String
        switch suffix.uppercased() {
        case "SH": market = "1"
        case "SZ": market = "0"
        case "BJ": market = "0"
        case "HK": market = "116"
        default: market = "1"
        }

        return "\(market).\(code)"
    }

    enum PriceError: Error {
        case invalidResponse
        case networkError(Error)
    }
}
