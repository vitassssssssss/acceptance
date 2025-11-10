import UIKit
import SnapKit

final class LoginViewController: UIViewController {
    private let api: APIClient
    private let tokenStore: TokenStore

    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    init(api: APIClient, tokenStore: TokenStore) {
        self.api = api
        self.tokenStore = tokenStore
        super.init(nibName: nil, bundle: nil)
        title = "Login"
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        usernameField.placeholder = "Username"
        usernameField.borderStyle = .roundedRect

        passwordField.placeholder = "Password"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect

        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(loginTap), for: .touchUpInside)

        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [usernameField, passwordField, loginButton, statusLabel])
        stack.axis = .vertical
        stack.spacing = 12

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(24)
        }
    }

    @objc private func loginTap() {
        view.endEditing(true)
        statusLabel.text = "Logging in..."
        let u = usernameField.text ?? ""
        let p = passwordField.text ?? ""
        api.obtainToken(email: u, password: p) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let pair):
                    self?.tokenStore.accessToken = pair.access
                    self?.tokenStore.refreshToken = pair.refresh
                    self?.goToProfile()
                case .failure(let err):
                    self?.statusLabel.text = "Error: \(err.localizedDescription)"
                }
            }
        }
    }

    private func goToProfile() {
        let profile = ProfileViewController(api: api, tokenStore: tokenStore)
        navigationController?.setViewControllers([profile], animated: true)
    }
}
