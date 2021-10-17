

import UIKit

class BaseTabBarController: UITabBarController {
    
    enum ControllerName:Int {
        case home,search,notification,profile
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITabBar.appearance().tintColor = .black
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 108/255, green: 108/255, blue: 108/255, alpha: 1)
        UITabBarItem.appearance().setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 10, weight: .regular)], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 10)], for: .selected)


        
        viewControllers?.enumerated().forEach({ (index,viewController) in
            if let name = ControllerName.init(rawValue: index) {
                switch name {
                case .home:
                    
                    viewController.tabBarItem.selectedImage = UIImage(named: "home.fill")?.resize(size: .init(width: 50, height: 26))
                    viewController.tabBarItem.image = UIImage(named: "home")?.resize(size: .init(width: 50, height: 26))
                    viewController.tabBarItem.title  = "ホーム"

                    
                case .search:
                    
                    setTabBarInfo(viewController, unselectedImage: "magnifyingglass", selectedImage: "magnifyingglass", tabBarTitle: "検索", width:50, height: 23, pointSize: 100, weight: .regular, weight2: .semibold, scale: .large)
                   
                    
                case .notification:
                    setTabBarInfo(viewController, unselectedImage: "bell", selectedImage: "bell.fill",tabBarTitle: "お知らせ", width: 50, height: 23, pointSize: 0, weight: .regular, weight2: .regular, scale: .large)
                    
                    
                case .profile:
                    setTabBarInfo(viewController, unselectedImage: "person", selectedImage: "person.fill",tabBarTitle: "プロフィール", width: 50, height: 23, pointSize: 0, weight: .regular, weight2: .regular, scale: .large)
                    
                }
            }
        })
    }
    
    
    
    
    private func setTabBarInfo(_ viewController:UIViewController,unselectedImage:String,selectedImage:String, tabBarTitle:String, width:CGFloat, height:CGFloat, pointSize:CGFloat, weight:UIImage.SymbolWeight,weight2:UIImage.SymbolWeight, scale:UIImage.SymbolScale){
        
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight, scale: scale)
        
        let configuration2 = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight2, scale: scale)
        
        viewController.tabBarItem.image = UIImage(systemName: unselectedImage,withConfiguration: configuration)?.resize(size: .init(width: width, height: height))
        
        viewController.tabBarItem.selectedImage = UIImage(systemName: selectedImage,withConfiguration: configuration2)?.resize(size: .init(width: width, height: height))
        
        viewController.tabBarItem.title  = tabBarTitle
        
    }
    
}
