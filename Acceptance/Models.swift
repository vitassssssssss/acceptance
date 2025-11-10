import Foundation

struct TokenPair: Decodable { let access: String; let refresh: String }
struct LoginRequest: Encodable { let email: String; let password: String }
struct RefreshRequest: Encodable { let refresh: String }

struct MeResponse: Decodable {
    let id: Int
    let email: String?
    let is_staff: Bool?
    let auth_via: String?
}
