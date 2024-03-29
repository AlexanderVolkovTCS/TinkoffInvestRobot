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
import SwiftProtobuf

class SettingsViewController: UIViewController {
	let padding = 16.0

	var profileLoader: ProfileListLoader = ProfileListLoader()

	var model = SettingPageModel()

	var tokenStorage = TokenStorage()

	var visualizerVC: VisualizationViewController? = nil

	var localInstrment: [Instrument] = []

	var cancellables = Set<AnyCancellable>()

	func onNewProfileListData(data: AccountList) {
		self.model.accountList = data
		self.model.isAccountsLoading = false
        view.setNeedsDisplay()
        view.setNeedsLayout()
	}

	func setupToken() {
		let token = tokenStorage.get()
		if token == nil {
			return
		}

		self.navigationController?.isToolbarHidden = false
		GlobalBotConfig.sdk = TinkoffInvestSDK(appName: "GoldenBrazier", tokenProvider: DefaultTokenProvider(token: token!), sandbox: DefaultTokenProvider(token: token!))
		self.model.isWaitingForStocks = true
		onModeChange(tag: 0)
		loadAllStocks()
	}

	@objc
	func onTokenChange() {
		stopBot()
		setupToken()
	}

	func onInstrumentsFinishLoad() {
		DispatchQueue.main.async {
			self.model.tradingInstruments = self.localInstrment
			self.model.isWaitingForStocks = false
		}
	}

	func loadSchedule() {
		var req = TradingSchedulesRequest()
		req.from = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!)
		req.to = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!)
		GlobalBotConfig.sdk.instrumentsService.getTradingSchedules(request: req).sink { result in
			switch result {
			case .failure(let error):
				GlobalBotConfig.logger.debug(error.localizedDescription)
			case .finished:
				break
			}
		} receiveValue: { sched in
			for i in sched.exchanges {
				GlobalBotConfig.tradingSchedule[i.exchange] = i
			}
			self.onInstrumentsFinishLoad()
		}.store(in: &cancellables)
	}

	func loadAllEtfs() {
		GlobalBotConfig.sdk.instrumentsService.getEtfs(with: InstrumentStatus(rawValue: InstrumentStatus.base.rawValue)!).sink { result in
			switch result {
			case .failure(let error):
				GlobalBotConfig.logger.debug(error.localizedDescription)
			case .finished:
				break
			}
		} receiveValue: { order in
			for i in order.instruments {
				self.localInstrment.append(Instrument(etf: i))
			}
			self.loadSchedule()
		}.store(in: &cancellables)
	}

	func loadAllCurrency() {
		GlobalBotConfig.sdk.instrumentsService.getCurrencies(with: InstrumentStatus(rawValue: InstrumentStatus.base.rawValue)!).sink { result in
			switch result {
			case .failure(let error):
				GlobalBotConfig.logger.debug(error.localizedDescription)
			case .finished:
				break
			}
		} receiveValue: { order in
			for i in order.instruments {
				self.localInstrment.append(Instrument(currency: i))
			}
			self.loadAllEtfs()
		}.store(in: &cancellables)
	}

	func loadAllStocks() {
		GlobalBotConfig.sdk.instrumentsService.getShares(with: InstrumentStatus(rawValue: InstrumentStatus.base.rawValue)!).sink { result in
			switch result {
			case .failure(let error):
				DispatchQueue.main.async {
					self.navigationController?.isToolbarHidden = true
					self.tokenStorage.remove()
				}
				GlobalBotConfig.logger.debug(error.localizedDescription)
			case .finished:
				break
			}
		} receiveValue: { order in
			for i in order.instruments {
				self.localInstrment.append(Instrument(share: i))
			}
			self.loadAllCurrency()
		}.store(in: &cancellables)
	}

	@objc
	func onModeChange(tag: Int) {
		let newMode = BotMode.fromIndex(tag)

		// Leaving if mode has not been changed.
		if (newMode == model.currentMode) {
			return
		}

		self.model.isAccountsLoading = true
		self.model.activeAccount = nil

		// Trying to load new profile data
		switch newMode {
		case .Emu:
			profileLoader = EmuProfileListLoader(callback: onNewProfileListData)
		case .Sandbox:
			profileLoader = SandboxProfileListLoader(callback: onNewProfileListData)
		case .Tinkoff:
			profileLoader = TinkoffProfileListLoader(callback: onNewProfileListData)
		}

		model.currentMode = newMode
	}

	func stopBot() {
		self.model.isBotRunning = false
		self.visualizerVC?.onBotFinish()
		let label = self.toolbarItems?[0].customView as? UILabel
		label?.text = "Бот отдыхает"
		self.toolbarItems?[2] = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onBotStatus(_:)))
	}

	@objc
	func onBotStatus(_ sender: UISegmentedControl) {
		var errorFound = false
		self.model.errorInstrumentText = nil
		self.model.errorAccountListText = nil

		if self.model.figiData.isEmpty {
			self.model.errorInstrumentText = "Выберите инструменты"
			errorFound = true
		}
		if self.model.activeAccount == nil {
			self.model.errorAccountListText = "Выберите счет"
			errorFound = true
		}
		if errorFound {
			return
		}

		self.model.isBotRunning = !self.model.isBotRunning

		let label = self.toolbarItems?[0].customView as? UILabel
		if self.model.isBotRunning {
			GlobalBotConfig.account = self.model.activeAccount!
			GlobalBotConfig.mode = self.model.currentMode
			GlobalBotConfig.figis = self.model.figiData
			GlobalBotConfig.algoConfig = self.model.algoConfig
			GlobalBotConfig.emuStartDate = self.model.emuStartDate
			self.visualizerVC?.onBotStartRequested()
			label?.text = "Бот работает"
			self.toolbarItems?[2] = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(onBotStatus(_:)))

			if parent?.parent?.children.count == 1 {
				navigationController!.pushViewController(self.visualizerVC!, animated: true)
			}
		} else {
			stopBot()
		}
	}

	func onConnectionIssue() {
		stopBot()
		print("alert")
	}

	func internetWatcher() {
		DispatchQueue.global(qos: .userInitiated).async {
			while (true) {
				if !isConnectedToInternet() {
					DispatchQueue.main.async {
						self.onConnectionIssue()
					}
				}
				sleep(1)
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.internetWatcher()

		self.model.sdk = GlobalBotConfig.sdk

		view.backgroundColor = .lightGray
		self.navigationItem.title = "ИнвестоБот"
		self.navigationController?.navigationBar.prefersLargeTitles = true

		self.navigationController?.isToolbarHidden = true
		var items = [UIBarButtonItem]()
		let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
		label.text = "Бот отдыхает"
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

		tokenStorage = TokenStorage(callback: onTokenChange)
		setupToken()

		// Initializing Emulating mode.
		model.onModeChange = self.onModeChange

		let hostingController = UIHostingController(rootView: SettingPage(model: model, storage: tokenStorage))
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		let swUIViewHC1 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left)
		let swUIViewHC2 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
		let swUIViewHC3 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
		let swUIViewHC4 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0)
		view.addSubview(hostingController.view)
		view.addConstraints([swUIViewHC1, swUIViewHC2, swUIViewHC3, swUIViewHC4])
	}
}
