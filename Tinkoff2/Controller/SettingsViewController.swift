//
//  ViewController.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 20.05.2022.
//

import UIKit
import Combine
import TinkoffInvestSDK
import SwiftUI

class SettingsViewController: UIViewController {
	let padding = 16.0

	var modeDescriptionView: UITextView = UITextView()
	var profileLoader: ProfileListLoader = ProfileListLoader()

	var currentMode: BotMode = .Emu;
	var model = SettingPageModel()

	var vizVC: VisualizationViewController? = nil
	var cancellables = Set<AnyCancellable>()

	func onNewProfileListData(data: AccountList) {
		model.accountList = data
	}

	@objc
	func onModeChange(tag: Int) {
		let newMode = BotMode.fromIndex(tag)

		// Leaving if mode has not been changed.
		if (newMode == currentMode) {
			return
		}

		// Trying to load new profile data
		switch newMode {
		case .Emu:
			profileLoader = EmuProfileListLoader(callback: onNewProfileListData)
		case .Sandbox:
			profileLoader = SandboxProfileListLoader(callback: onNewProfileListData)
		case .Tinkoff:
			profileLoader = TinkoffProfileListLoader(callback: onNewProfileListData)
		}

		self.modeDescriptionView.text = BotMode.descriptionFor(newMode)
		currentMode = newMode
	}


	@objc
	func onBotStatus(_ sender: UISegmentedControl) {
		self.model.isBotRunning = !self.model.isBotRunning

		let label = self.toolbarItems?[0].customView as? UILabel
		if self.model.isBotRunning {
			GlobalBotConfig.account = self.model.activeAccount ?? Account()
			GlobalBotConfig.mode = currentMode
			self.vizVC?.onBotStart()
			label?.text = "Bot is running"
			self.toolbarItems?[2] = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(onBotStatus(_:)))
            navigationController!.pushViewController(self.vizVC!, animated: true)
		} else {
			self.vizVC?.onBotFinish()
			label?.text = "Bot is stopped"
			self.toolbarItems?[2] = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onBotStatus(_:)))
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white
		self.navigationItem.title = "Invest Bot"
		self.navigationController?.navigationBar.prefersLargeTitles = true

		self.navigationController?.isToolbarHidden = false
		var items = [UIBarButtonItem]()
		let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
		label.text = "Bot is stopped"
		label.center = CGPoint(x: view.frame.midX, y: view.frame.height)
		label.textAlignment = .left
		items.append(
			UIBarButtonItem(customView: label)
		)
		items.append(
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		)
		items.append(
			UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onBotStatus(_:)))
		)

		self.navigationController?.toolbar.barStyle = .default
		self.navigationController?.toolbar.isTranslucent = true
		self.toolbarItems = items

		model.onModeChange = self.onModeChange

		let hostingController = UIHostingController(rootView: SettingPageView(model: model))
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		let swUIViewHC1 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left)
		let swUIViewHC2 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
		let swUIViewHC3 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
		let swUIViewHC4 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0)
		view.addSubview(hostingController.view)
		view.addConstraints([swUIViewHC1, swUIViewHC2, swUIViewHC3, swUIViewHC4])
	}
}
