import Foundation

struct SavedLocation: Codable, Equatable {
    var name: String
    var detail: String
    var latitude: Double
    var longitude: Double
}
