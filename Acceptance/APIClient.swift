import Foundation

final class APIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func obtainToken(email: String, password: String, completion: @escaping (Result<TokenPair, Error>) -> Void) {
        var req = URLRequest(url: baseURL.appendingPathComponent("/api/auth/token/"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(LoginRequest(email: email, password: password))
        session.dataTask(with: req) { data, _, err in
            if let err = err { return completion(.failure(err)) }
            guard let data = data else { return completion(.failure(NSError(domain: "net", code: -1))) }
            do { completion(.success(try JSONDecoder().decode(TokenPair.self, from: data))) }
            catch { completion(.failure(error)) }
        }.resume()
    }

    func refreshToken(refresh: String, completion: @escaping (Result<String, Error>) -> Void) {
        var req = URLRequest(url: baseURL.appendingPathComponent("/api/auth/token/refresh/"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(RefreshRequest(refresh: refresh))
        session.dataTask(with: req) { data, _, err in
            if let err = err { return completion(.failure(err)) }
            guard let data = data else { return completion(.failure(NSError(domain: "net", code: -1))) }
            struct AccessOnly: Decodable { let access: String }
            do { completion(.success(try JSONDecoder().decode(AccessOnly.self, from: data).access)) }
            catch { completion(.failure(error)) }
        }.resume()
    }

    func me(access: String, completion: @escaping (Result<MeResponse, Error>) -> Void) {
        var req = URLRequest(url: baseURL.appendingPathComponent("/api/me/"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(access)", forHTTPHeaderField: "Authorization")
        session.dataTask(with: req) { data, _, err in
            if let err = err { return completion(.failure(err)) }
            guard let data = data else { return completion(.failure(NSError(domain: "net", code: -1))) }
            do { completion(.success(try JSONDecoder().decode(MeResponse.self, from: data))) }
            catch { completion(.failure(error)) }
        }.resume()
    }
}
