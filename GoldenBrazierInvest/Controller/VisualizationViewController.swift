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

class VisualizationViewController: UIViewController {
	let padding = 16.0

	var started = false

	var cancellables = Set<AnyCancellable>()

	var settingsVC: SettingsViewController? = nil

	var postOrder: PostOrder? = nil

	var portfolioLoader: PortfolioLoader? = nil

	var consoleVC: DashboardViewController? = nil

	var model = VisualizerPageModel()

	var engine: RSIStrategyEngine? = nil

	func onBotStartRequested() {
		earlySetupModel()

		var figis: [String] = []
		GlobalBotConfig.figis.forEach { figiInstrument in
			figis.append(figiInstrument.figi)
		}
		let uts = GlobalBotConfig.algoConfig.upperRsiThreshold
		let lts = GlobalBotConfig.algoConfig.lowerRsiThreshold
		let rsiPeriod = GlobalBotConfig.algoConfig.rsiPeriod
		let stopLoss = GlobalBotConfig.algoConfig.stopLoss
		let engineConfig = RSIConfig(figis: figis, upperRsiThreshold: uts, lowerRsiThreshold: lts, rsiPeriod: rsiPeriod, stopLoss: stopLoss)
		self.engine = RSIStrategyEngine(config: engineConfig,
			portfolioUpdateCallback: self.onPortfolioUpdate,
			candlesUpdateCallback: self.onCandlesUpdate,
			orderRequestCallback: self.processOrderRequest,
			orderUpdateCallback: self.processOrder,
			rsiUpdateCallback: self.processRSI)
	}

	func onBotReadyToStart(portfolio: PortfolioData) {
		started = true
		setupModel(portfolio: portfolio)
		self.model.isWaitingForAccountData = false

		// Форсим перерисовку
		view.setNeedsDisplay()
		if self.model.activeStock != nil {
			self.navigationItem.title = self.model.activeStock!.instrument.name
		}
		view.setNeedsLayout()
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Статистика", style: .plain, target: self, action: #selector(jumpToConsole))
		GlobalBotConfig.logger.info("Starting Bot")
	}

	func onBotFinish() {
		started = false
		self.engine?.stop()
		self.model.isWaitingForAccountData = false
		GlobalBotConfig.logger.info("Stopping Bot")
	}

	func earlySetupModel() {
		// Set up a loading state.
		self.model.isWaitingForAccountData = true
	}

	func setupModel(portfolio: PortfolioData) {
		self.model.currentMode = GlobalBotConfig.mode
		self.model.stat = GlobalBotConfig.stat
		self.model.logger = GlobalBotConfig.logger
		self.model.tradingSchedule = GlobalBotConfig.tradingSchedule
		self.model.portfolioData = portfolio
		self.model.dismissController = dismissController

		// If Stock is not requestes to be tracked any more, removing it.
		var removeIds: [Int] = []
		for i in 0..<self.model.stockData.count {
			var found = false
			for instrument in GlobalBotConfig.figis {
				if self.model.stockData[i].instrument.figi == instrument.figi {
					found = true
				}
			}

			if !found {
				removeIds.append(i)
			}
		}

		// Remove from the back to not break ids.
		for id in removeIds.reversed() {
			self.model.stockData.remove(at: id)
		}

		// Adding new Stocks to track.
		for instrument in GlobalBotConfig.figis {
			var found = false
			for stock in self.model.stockData {
				if stock.instrument.figi == instrument.figi {
					found = true
				}
			}

			if !found {
				self.model.stockData.append(StockInfo(instrument: instrument, candles: []))
			}
		}

		self.model.onStockChange = self.onStockChange
		if !self.model.stockData.isEmpty {
			onStockChange(stock: self.model.stockData[0])
		}
	}

	func onStockChange(stock: StockInfo) {
		self.model.activeStock = stock
		self.model.activeStock!.hasUpdates = false
		self.navigationItem.title = stock.instrument.name
	}

	func onPortfolioUpdate(portfolio: PortfolioData) {
		if (!started) {
			onBotReadyToStart(portfolio: portfolio)
			return
		}
		self.model.portfolioData = portfolio
		self.model.isWaitingForAccountData = false
	}

	func onCandlesUpdate(figi: String, candles: LinkedList<CandleData>) {
		for i in 0..<self.model.stockData.count {
			if (self.model.stockData[i].instrument.figi == figi) {
				var newCandles: [CandleData] = []
				candles.forEach { candle in
					newCandles.append(candle)
				}

				self.model.stockData[i].candles = newCandles

				// Re-setting activeStock to initiate redrawing of swiftUI
				if self.model.activeStock != nil && self.model.activeStock!.instrument.figi == self.model.stockData[i].instrument.figi {
					self.model.activeStock = self.model.stockData[i]
				}

				break
			}
		}
	}

	func processOrderRequest(figi: String, order: OrderInfo) {
		for i in 0..<self.model.stockData.count {
			if (self.model.stockData[i].instrument.figi == figi) {
				self.model.stockData[i].operations.insert(order, at: 0)
				if self.model.stockData[i].operations.count > 10 {
					let _ = self.model.stockData[i].operations.popLast()
				}

				let std = self.model.stockData[i]
				self.model.stockData.remove(at: i)
				self.model.stockData.insert(std, at: 0)

				// Re-setting activeStock to initiate redrawing of swiftUI
				if self.model.activeStock != nil && self.model.activeStock!.instrument.figi == self.model.stockData[0].instrument.figi {
					self.model.activeStock = self.model.stockData[0]
				} else {
					self.model.stockData[0].hasUpdates = true
				}
				break
			}
		}
	}

	func processOrder(figi: String, order: OrderInfo) {
		for i in 0..<self.model.stockData.count {
			if (self.model.stockData[i].instrument.figi == figi) {
				self.model.stockData[i].operations.insert(order, at: 0)
				if self.model.stockData[i].operations.count > 10 {
					let _ = self.model.stockData[i].operations.popLast()
				}

				if order.type == .Bought {
					self.model.stockData[i].boughtCount += order.count
					self.model.stockData[i].boughtTotalPrice += order.price.asDouble()
				} else {
					self.model.stockData[i].soldCount += order.count
					self.model.stockData[i].soldTotalPrice += order.price.asDouble()
				}
				let boughtPerStock = self.model.stockData[i].boughtTotalPrice / Double(self.model.stockData[i].boughtCount)
				let soldPerStock = self.model.stockData[i].soldTotalPrice / Double(self.model.stockData[i].soldCount)
				let cnt = Double(min(self.model.stockData[i].boughtCount, self.model.stockData[i].soldCount))
				if cnt != 0 {
					self.model.stockData[i].profitPercentage = 100.0 * (soldPerStock * cnt - boughtPerStock * cnt) / (boughtPerStock * cnt)
				} else {
					self.model.stockData[i].profitPercentage = 0.0
				}

				// Re-setting activeStock to initiate redrawing of swiftUI
				if self.model.activeStock != nil && self.model.activeStock!.instrument.figi == self.model.stockData[i].instrument.figi {
					self.model.activeStock = self.model.stockData[i]
				} else {
					self.model.stockData[i].hasUpdates = true
				}

				break
			}
		}
	}

	func processRSI(figi: String, rsiValue: Float64) {
		for i in 0..<self.model.stockData.count {
			if (self.model.stockData[i].instrument.figi == figi) {
				self.model.stockData[i].rsi.append(rsiValue)

				// Re-setting activeStock to initiate redrawing of swiftUI
				if self.model.activeStock != nil && self.model.activeStock!.instrument.figi == self.model.stockData[i].instrument.figi {
					self.model.activeStock = self.model.stockData[i]
				}

				break
			}
		}
	}

	@objc
	func jumpToConsole() {
		if self.consoleVC == nil {
			return
		}
		present(self.consoleVC!, animated: true, completion: nil)
	}

	@objc
	func dismissController() {
		dismiss(animated: true, completion: nil)
	}

	override func viewWillDisappear(_ animated: Bool) {
		settingsVC?.stopBot()
		navigationController?.popViewController(animated: true)
		dismiss(animated: true, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white
		self.navigationItem.title = ""
		self.navigationController?.navigationBar.prefersLargeTitles = true

		let hostingController = UIHostingController(rootView: VisualizerPageView(model: model))
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		let swUIViewHC1 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left)
		let swUIViewHC2 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
		let swUIViewHC3 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
		let swUIViewHC4 = NSLayoutConstraint(item: hostingController.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0)
		view.addSubview(hostingController.view)
		view.addConstraints([swUIViewHC1, swUIViewHC2, swUIViewHC3, swUIViewHC4])
	}
}
