import UIKit

func loadFromNib<Type>() -> Type {
    let array = Bundle.main.loadNibNamed(String(describing: Type.self), owner: nil, options: nil)
    if let object = array?.first(where: { type(of: $0) == Type.self }) as? Type {
        return object
    }
    fatalError("Can't load class '\(String(describing: Type.self))' from nib of same name.")
}

// MARK: -

class TabBarController: UITabBarController {

    lazy var firstViewController: UIViewController = {
        return BasicViewController.withNavigationController()
    }()
    lazy var secondViewController: UIViewController = {
        return BasicViewController.withNavigationController()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setViewControllers([firstViewController, secondViewController], animated: false)
    }
}
