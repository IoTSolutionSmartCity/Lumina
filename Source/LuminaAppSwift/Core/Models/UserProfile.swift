import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var displayName: String
    var email: String?
    var avatarURL: URL?
    var authProvider: AuthProvider

    enum AuthProvider: String, Codable {
        case apple
        case google
        case anonymous
    }
}
