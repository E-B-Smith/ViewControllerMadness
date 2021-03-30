import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var spyWindow: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Log(.log, "Version \(VersionString(bundle: Bundle.main)).")

        UIViewControllerNotifications.start()
        ViewControllerTracker.shared.reportState()

        var frame = UIScreen.main.bounds
        frame.origin.y += 100
        frame.size.height = 5*28
        frame = frame.insetBy(dx: 12, dy: 0)
        spyWindow = UIWindow(frame: frame)
        spyWindow?.rootViewController = NotificationSpyViewController()
        spyWindow?.windowLevel = .statusBar
        spyWindow?.makeKeyAndVisible()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = TabBarController()
        window?.makeKeyAndVisible()

        return true
    }
}
