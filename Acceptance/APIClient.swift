import Foundation

final class APIClient {
    enum APIError: Swift.Error, LocalizedError {
        case invalidResponse
        case httpStatus(Int, Data?)
        case noData
        case encoding(Swift.Error)
        case decoding(Swift.Error)
        case underlying(Swift.Error)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid server response"
            case let .httpStatus(status, data):
                if let detail = data.flatMap(APIError.parseDetailMessage), !detail.isEmpty {
                    return detail
                }
                return "Server responded with status code \(status)"
            case .noData:
                return "Empty response from server"
            case let .encoding(error):
                return "Encoding error: \(error.localizedDescription)"
            case let .decoding(error):
                return "Decoding error: \(error.localizedDescription)"
            case let .underlying(error):
                return error.localizedDescription
            }
        }

        private static func parseDetailMessage(from data: Data) -> String? {
            struct DetailResponse: Decodable { let detail: String }
            if let detail = try? JSONDecoder().decode(DetailResponse.self, from: data).detail {
                return detail
            }
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func obtainToken(email: String, password: String, completion: @escaping (Result<TokenPair, APIError>) -> Void) {
        var req = URLRequest(url: baseURL.appendingPathComponent("/api/auth/token/"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try encoder.encode(LoginRequest(email: email, password: password))
        } catch {
            return completion(.failure(.encoding(error)))
        }
        perform(request: req, completion: completion)
    }

    func refreshToken(refresh: String, completion: @escaping (Result<String, APIError>) -> Void) {
        var req = URLRequest(url: baseURL.appendingPathComponent("/api/auth/token/refresh/"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try encoder.encode(RefreshRequest(refresh: refresh))
        } catch {
            return completion(.failure(.encoding(error)))
        }
        perform(request: req) { (result: Result<AccessOnly, APIError>) in
            switch result {
            case let .success(response):
                completion(.success(response.access))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func me(access: String, completion: @escaping (Result<MeResponse, APIError>) -> Void) {
        var req = URLRequest(url: baseURL.appendingPathComponent("/api/me/"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(access)", forHTTPHeaderField: "Authorization")
        perform(request: req, completion: completion)
    }

    private func perform<Response: Decodable>(request: URLRequest, completion: @escaping (Result<Response, APIError>) -> Void) {
        session.dataTask(with: request) { data, response, err in
            if let err = err {
                return completion(.failure(.underlying(err)))
            }
            guard let http = response as? HTTPURLResponse else {
                return completion(.failure(.invalidResponse))
            }
            guard let data = data else {
                return completion(.failure(.noData))
            }
            guard (200..<300).contains(http.statusCode) else {
                return completion(.failure(.httpStatus(http.statusCode, data)))
            }
            do {
                completion(.success(try self.decoder.decode(Response.self, from: data)))
            } catch {
                completion(.failure(.decoding(error)))
            }
        }.resume()
    }
}

private struct AccessOnly: Decodable { let access: String }
