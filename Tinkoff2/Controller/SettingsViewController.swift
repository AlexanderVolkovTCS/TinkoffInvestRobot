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
    
    var vizVC : VisualizationViewController? = nil
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
        self.vizVC?.onModeChange(sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        self.navigationItem.title = "Invest Bot"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
//        let header = UIView()
//        header.backgroundColor = UIColor(red: 231, green: 240, blue: 250)
//        header.translatesAutoresizingMaskIntoConstraints = false
//        let headerHC1 = NSLayoutConstraint(item: header, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
//        let headerHC2 = NSLayoutConstraint(item: header, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
//        let headerHC3 = NSLayoutConstraint(item: header, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: view.safeAreaInsets.top + 100)
//        view.addSubview(header)
//        view.addConstraints([headerHC1, headerHC2, headerHC3])
//        
//        let headerLabel = UILabel()
//        headerLabel.text = "Visualizer"
//        headerLabel.textColor = .black
//        headerLabel.translatesAutoresizingMaskIntoConstraints = false
//        let headerLabelHC1 = NSLayoutConstraint(item: headerLabel, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: -self.padding)
//        let headerLabelHC2 = NSLayoutConstraint(item: headerLabel, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left + self.padding)
//        let headerLabelHC3 = NSLayoutConstraint(item: headerLabel, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
//        header.addSubview(headerLabel)
//        header.addConstraints([headerLabelHC1, headerLabelHC2, headerLabelHC3])
        
        let modePicker = UISegmentedControl()
        modePicker.insertSegment(withTitle: "Эмулятор", at: 0, animated: false)
        modePicker.insertSegment(withTitle: "Песочница", at: 1, animated: false)
        modePicker.insertSegment(withTitle: "Тинькофф", at: 2, animated: false)
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
