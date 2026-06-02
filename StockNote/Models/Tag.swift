import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var name: String  // e.g., "白酒", "科技", "观望"
    var color: String  // Hex color for display, e.g., "#FF5733"
    var createdAt: Date

    // Inverse relationship
    @Relationship(inverse: \Stock.tags) var stocks: [Stock]

    init(name: String, color: String = "#3B82F6") {
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.stocks = []
    }
}

// Predefined tag colors
extension Tag {
    static let colors: [String] = [
        "#EF4444",  // Red
        "#F97316",  // Orange
        "#EAB308",  // Yellow
        "#22C55E",  // Green
        "#14B8A6",  // Teal
        "#3B82F6",  // Blue
        "#8B5CF6",  // Purple
        "#EC4899",  // Pink
        "#6B7280",  // Gray
    ]
}
