//
//  VisualizationViewController.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 20.05.2022.
//

import Foundation

import UIKit
import SwiftUI
import Combine
import TinkoffInvestSDK
import Charts

class JumpViewController: UIViewController {
    let padding = 16.0

    var chatRoomsButton: UIBarButtonItem = {
        var button = UIBarButtonItem(title: "Chats", style: .plain, target: self, action: #selector(segueToChatRoomController(_:)))
        return button
    }()

    var exploreButton: UIBarButtonItem = {
        var button = UIBarButtonItem(title: "Explore", style: .plain, target: self, action: #selector(segueToExploreController(_:)))
        return button
    }()

    // Flexible spaces that are added in between each button.
    var flexibleSpace1: UIBarButtonItem = {
        var flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        return flexibleSpace
    }()

    var flexibleSpace2: UIBarButtonItem = {
        var flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        return flexibleSpace
    }()

    var flexibleSpace3: UIBarButtonItem = {
        var flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        return flexibleSpace
    }()

    // These are the functions that are not being called for some mysterious reason.
    @objc func segueToChatRoomController(_ sender: Any) {
        print("segueing to chat rooms controller")
        let chatRoomsController = VisualizationViewController()
        let navController = UINavigationController(rootViewController: chatRoomsController)
        self.present(navController, animated: false, completion: nil)
    }

    @objc func segueToExploreController(_ sender: Any) {
        print("segueing to explore controller")
        let exploreController = DashboardViewController()
        let navController = UINavigationController(rootViewController: exploreController)
        self.present(navController, animated: false, completion: nil)
    }

    func setUpToolbar() {
        print("setting up toolbar")

        view.backgroundColor = .white
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.isUserInteractionEnabled = true

        let exploreController = DashboardViewController()
        let navController = UINavigationController(rootViewController: exploreController)
        self.navigationController?.pushViewController(navController, animated: false)
        
        let toolBarItems = [flexibleSpace1, chatRoomsButton, flexibleSpace2, exploreButton, flexibleSpace3]

        self.setToolbarItems(toolBarItems, animated: true)
        // For some reason, these two methods leave the toolbar empty.

        //self.navigationController?.setToolbarItems(toolBarItems, animated: true)

        //self.navigationController?.toolbar.items = toolBarItems
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpToolbar()
        
//        view.backgroundColor = .white
//        self.navigationItem.title = ""
//        self.navigationController?.navigationBar.prefersLargeTitles = true
//        print(isConnectedToInternet())
//
//        let hostingController = UIHostingController(rootView: VisualizerPageView(model: model))
//        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
//        let swUIViewHC1 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left)
//        let swUIViewHC2 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
//        let swUIViewHC3 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
//        let swUIViewHC4 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0)
//        view.addSubview(hostingController.view)
//        view.addConstraints([swUIViewHC1, swUIViewHC2, swUIViewHC3, swUIViewHC4])
    }
}
