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
        guard let access = tokenStore.accessToken else { infoLabel.text = "No access token"; return }
        api.me(access: access) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let me):
                    self?.infoLabel.text = "id: \(me.id)\nemail: \(me.email ?? "-")\nvia: \(me.auth_via ?? "jwt")"
                case .failure(let err):
                    self?.infoLabel.text = "Error: \(err.localizedDescription)"
                }
            }
        }
    }

    @objc private func logout() {
        tokenStore.clear()
        let login = LoginViewController(api: api, tokenStore: tokenStore)
        navigationController?.setViewControllers([login], animated: true)
    }
}
