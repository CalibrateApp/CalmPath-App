import Foundation

public struct Habit: Identifiable, Codable {
    public let id: String
    public let name: String
    public let icon: String?
    public let isPositive: Bool?
    
    public init(id: String, name: String = "Unnamed Habit", icon: String? = nil, isPositive: Bool? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isPositive = isPositive
    }
}