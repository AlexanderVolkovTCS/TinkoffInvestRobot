//
//  ViewController.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 20.05.2022.
//

import UIKit
import Combine
import TinkoffInvestSDK

class SettingsViewController: UIViewController {
    let padding = 16.0
    
    var cancellables = Set<AnyCancellable>()
    var sdk = TinkoffInvestSDK(tokenProvider: DefaultTokenProvider(token: "t."), sandbox: DefaultTokenProvider(token: ""))
    
    func isConnectedToInternet() -> Bool {
        let hostname = "google.com"
        let hostinfo = gethostbyname2(hostname, AF_INET6)//AF_INET6
        if hostinfo != nil {
            return true // internet available
          }
         return false // no internet
    }
    
    @objc
    func onModeChange(_ sender: UISegmentedControl) {
        // We use split view, so VisualizationVC is 2 levels away, as views are wrapped into UINavigationController
        let VisualizationVC = parent?.parent?.children[1].children[0] as! VisualizationViewController
        VisualizationVC.onModeChange(sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        self.navigationItem.title = "Invest Bot"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        let modePicker = UISegmentedControl()
        modePicker.insertSegment(withTitle: "Sandbox", at: 0, animated: false)
        modePicker.insertSegment(withTitle: "Real", at: 1, animated: false)
        modePicker.selectedSegmentIndex = 0
        modePicker.addTarget(self, action: "onModeChange:", for: .valueChanged)
        modePicker.translatesAutoresizingMaskIntoConstraints = false
        let modePickerHC1 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left + self.padding)
        // TODO: This 128 and get size of navigationItem somehow.
        let modePickerHC2 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 128 + self.padding)
        let modePickerHC3 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: -2 * self.padding)
        let modePickerHC4 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 30)
        view.addSubview(modePicker)
        view.addConstraints([modePickerHC1, modePickerHC2, modePickerHC3, modePickerHC4])
        
        
//        print(isConnectedToInternet())
//        self.sdk.userService.getAccounts().sink { result in
//            switch result {
//            case .failure(let error):
//                print(error.localizedDescription)
//            case .finished:
//                print(result)
//                print("did finish loading getPortfolio")
//            default:
//                print(result)
//            }
//          } receiveValue: { portfolio in
//            print(portfolio)
//          }.store(in: &cancellables)
    }


}
