import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let tokenStore = TokenStore()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }
        let win = UIWindow(windowScene: ws)
        let api = APIClient(baseURL: AppConfig.baseURL)
        let root: UIViewController = (tokenStore.accessToken != nil)
            ? UINavigationController(rootViewController: ProfileViewController(api: api, tokenStore: tokenStore))
            : UINavigationController(rootViewController: LoginViewController(api: api, tokenStore: tokenStore))
        win.rootViewController = root
        win.makeKeyAndVisible()
        window = win
    }
}
