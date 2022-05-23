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


//	var tradesStreamSub: TradesStreamSubscriber? = nil

	var orderSub: OrderSubscriber? = nil

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
        let engineConfig = RSIConfig(figis: figis, upperRsiThreshold: uts, lowerRsiThreshold: lts, rsiPeriod: rsiPeriod)
        self.engine = RSIStrategyEngine(config: engineConfig,
                                        portfolioUpdateCallback: self.onPortfolioUpdate,
                                        candlesUpdateCallback: self.onCandlesUpdate,
                                        orderUpdateCallback: self.processOrder,
                                        rsiUpdateCallback: self.processRSI)
	}

	func onBotReadyToStart(portfolio: PortfolioData) {
		started = true
		setupModel(portfolio: portfolio)
		initSubcribers()
		self.model.isWaitingForAccountData = false
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Консоль", style: .plain, target: self, action: #selector(jumpToConsole))
		GlobalBotConfig.logger.info("Starting Bot")
	}

	func onBotFinish() {
		started = false
		removeSubcribers()
		self.model.isWaitingForAccountData = false
		GlobalBotConfig.logger.info("Stopping Bot")
	}

	func removeSubcribers() {
//		self.tradesStreamSub?.cancel()
		self.orderSub?.cancel()
	}

	func earlySetupModel() {
		// Set up a loading state.
		self.model.isWaitingForAccountData = true
	}

	func setupModel(portfolio: PortfolioData) {
        self.model.stat = GlobalBotConfig.stat
        self.model.logger = GlobalBotConfig.logger
		self.model.portfolioData = portfolio

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

	func initSubcribers() {
		// Should uninitilize everything here and reinit data sources.
		removeSubcribers()

//		switch GlobalBotConfig.mode {
//		case .Emu:
////			self.tradesStreamSub = EmuTradesStreamSubscriber(figi: "BBG000BBJQV0", callback: processTrade)
//			self.orderSub = EmuOrderSubscriber(figi: "BBG000BBJQV0", callback: processOrderbook)
//			self.postOrder = EmuPostOrder(figi: "BBG000BBJQV0", tradesStreamSubsriber: self.tradesStreamSub! as! EmuTradesStreamSubscriber)
//			self.candlesStreamSub = EmuCandleStreamSubscriber(figi: "BBG000BBJQV0", callback: self.processCandle)
//		case .Sandbox:
//			self.tradesStreamSub = TinkoffTradesStreamSubscriber(figi: "BBG000BBJQV0", callback: processTrade)
//			self.orderSub = TinkoffOrderSubscriber(figi: "BBG000BBJQV0", callback: processOrderbook)
//			self.postOrder = SandboxPostOrder(figi: "BBG000BBJQV0")
//			self.candlesStreamSub = TinkoffCandleStreamSubscriber(figi: "BBG000BBJQV0", callback: self.processCandle)
//		case .Tinkoff:
//			self.tradesStreamSub = TinkoffTradesStreamSubscriber(figi: "BBG000BBJQV0", callback: processTrade)
//			self.orderSub = TinkoffOrderSubscriber(figi: "BBG000BBJQV0", callback: processOrderbook)
//			self.postOrder = TinkoffPostOrder(figi: "BBG000BBJQV0")
//			self.candlesStreamSub = TinkoffCandleStreamSubscriber(figi: "BBG000BBJQV0", callback: self.processCandle)
//		}
	}


	func onPortfolioUpdate(portfolio: PortfolioData) {
        if (!started) {
            onBotReadyToStart(portfolio: portfolio)
            return
        }
		self.model.portfolioData = portfolio
		self.model.isWaitingForAccountData = false
	}

//	func processTrade(trade: Trade) {
//		return
//	}
    
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

    func processOrder(figi: String, order: OrderInfo) {
        for i in 0..<self.model.stockData.count {
            if (self.model.stockData[i].instrument.figi == figi) {
                self.model.stockData[i].operations.append(order)
                
                // Re-setting activeStock to initiate redrawing of swiftUI
                if self.model.activeStock != nil && self.model.activeStock!.instrument.figi == self.model.stockData[i].instrument.figi {
                    self.model.activeStock = self.model.stockData[i]
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

	func processOrderbook(orderbook: OrderBookData) {
		// Расчет количества лотов в заявках на покупку и продажу.
		var countBuy: Int64 = 0
		for bid in orderbook.bids {
			countBuy += bid.quantity
		}

		var countSell: Int64 = 0
		for ask in orderbook.asks {
			countSell += ask.quantity
		}

		self.model.data = [Int(countBuy)]

		print("buy = ", countBuy)
		print("sell = ", countSell)

		// Перевес в количестве заявок на покупку.
		if countBuy > countSell {
			print("more buy, need to buy more!")
			self.postOrder?.buyMarketPrice()
			return
		}

		// Перевес в количестве заявок на продажу.
		if (countSell > countBuy) {
			print("more sell, need to sell some!")
			// Продаем по верхней границе стакана.
			var price = Quotation()
			price.units = orderbook.bids.last!.price.units
			price.nano = orderbook.bids.last!.price.nano
//			self.postOrder?.sellWithLimit(price: price)
			return
		}

		// Ничего не делаем, если нет значимого перевеса.
	}

	// subscirbeToOrderBook подписывает на получение информации по стакану с глубиной 20.
	// ответ асинхронно приходит в "case .orderbook" как только состояние стакана изменится.
	// BBG000BBJQV0 - figi of Nvidia
//    func subscirbeToOrderBook() {
//        self.sdk.marketDataServiceStream.subscribeToOrderBook(figi: "BBG000BBJQV0", depth: 20).sink { result in
//           print(result)
//        } receiveValue: { result in
//           switch result.payload {
//           case .orderbook(let orderbook):
//               self.processOrderbook(orderbook: orderbook)
//           default:
//               print("dai \(result.payload)")
//               break
//           }
//        }.store(in: &cancellables)
//    }

	// TODO:
	// may be use OrdersStreamService for visualizer?

	@objc
	func jumpToConsole() {
		if self.consoleVC == nil {
			return
		}
		present(self.consoleVC!, animated: true, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white
		self.navigationItem.title = ""
		self.navigationController?.navigationBar.prefersLargeTitles = true
		print(isConnectedToInternet())

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


extension UIColor {
	convenience init(red: Int, green: Int, blue: Int) {
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")

		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
	}

	convenience init(rgb: Int) {
		self.init(
			red: (rgb >> 16) & 0xFF,
			green: (rgb >> 8) & 0xFF,
			blue: rgb & 0xFF
		)
	}
}
