import UIKit
import SnapKit

final class ProfileViewController: UIViewController {
    private let api: APIClient
    private let tokenStore: TokenStore

    private let infoLabel = UILabel()
    private let loadButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)

    init(api: APIClient, tokenStore: TokenStore) {
        self.api = api
        self.tokenStore = tokenStore
        super.init(nibName: nil, bundle: nil)
        title = "Profile"
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        infoLabel.numberOfLines = 0
        loadButton.setTitle("Load /me", for: .normal)
        loadButton.addTarget(self, action: #selector(loadMe), for: .touchUpInside)

        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [infoLabel, loadButton, logoutButton])
        stack.axis = .vertical
        stack.spacing = 16
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.left.right.equalToSuperview().inset(24)
        }

        loadMe()
    }

    @objc private func loadMe() {
        infoLabel.text = "Loading..."
        requestProfile(retryingOnUnauthorized: true)
    }

    @objc private func logout() {
        tokenStore.clear()
        showLogin()
    }

    private func requestProfile(retryingOnUnauthorized: Bool) {
        guard let access = tokenStore.accessToken else {
            sessionExpired()
            return
        }
        api.me(access: access) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(me):
                    self?.infoLabel.text = "id: \(me.id)\nemail: \(me.email ?? "-")\nvia: \(me.auth_via ?? "jwt")"
                case let .failure(error):
                    self?.handleProfileError(error, canRetry: retryingOnUnauthorized)
                }
            }
        }
    }

    private func handleProfileError(_ error: APIClient.APIError, canRetry: Bool) {
        if case let .httpStatus(status, _) = error, status == 401 {
            if canRetry {
                refreshAndRetryProfile()
            } else {
                sessionExpired(message: error.localizedDescription)
            }
            return
        }
        infoLabel.text = "Error: \(error.localizedDescription)"
    }

    private func refreshAndRetryProfile() {
        guard let refresh = tokenStore.refreshToken else {
            sessionExpired()
            return
        }
        infoLabel.text = "Refreshing session..."
        api.refreshToken(refresh: refresh) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(access):
                    self?.tokenStore.accessToken = access
                    self?.infoLabel.text = "Loading..."
                    self?.requestProfile(retryingOnUnauthorized: false)
                case let .failure(error):
                    self?.sessionExpired(message: error.localizedDescription)
                }
            }
        }
    }

    private func sessionExpired(message: String? = nil) {
        tokenStore.clear()
        let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalMessage: String
        if let trimmed, !trimmed.isEmpty {
            if trimmed.lowercased().hasPrefix("session expired") {
                finalMessage = trimmed
            } else {
                finalMessage = "Session expired. \(trimmed)"
            }
        } else {
            finalMessage = "Session expired. Please log in again."
        }
        showLogin(statusMessage: finalMessage, isError: true)
    }

    private func showLogin(statusMessage: String? = nil, isError: Bool = false) {
        let login = LoginViewController(api: api, tokenStore: tokenStore, statusMessage: statusMessage, isError: isError)
        navigationController?.setViewControllers([login], animated: true)
    }
}
