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

	var candleView: GraphView? = nil

	var started = false

	var cancellables = Set<AnyCancellable>()
    
    var candlesStreamSub: CandleStreamSubscriber? = nil
    
    var tradesStreamSub: TradesStreamSubscriber? = nil

	var orderSub: OrderSubscriber? = nil

	var postOrder: PostOrder? = nil

	var model = VisualizerPageModel()

	func onBotStart() {
		started = true
		self.model.figiData = GlobalBotConfig.figis
		initSubcribers()
	}

	func onBotFinish() {
		started = false
		removeSubcribers()
	}

	func removeSubcribers() {
		self.tradesStreamSub?.cancel()
		self.orderSub?.cancel()
        self.candlesStreamSub?.cancel()
	}

	func initSubcribers() {
		// Should uninitilize everything here and reinit data sources.
		removeSubcribers()

		switch GlobalBotConfig.mode {
		case .Emu:
			self.tradesStreamSub = EmuTradesStreamSubscriber(figi: "TSLA", callback: processTrade)
			self.orderSub = EmuOrderSubscriber(figi: "TSLA", callback: processOrderbook)
            self.postOrder = EmuPostOrder(figi: "TSLA", tradesStreamSubsriber: self.tradesStreamSub! as! EmuTradesStreamSubscriber)
            self.candlesStreamSub = EmuCandleStreamSubscriber(figi: "BBG000BBJQV0", callback: self.processCandle)
		case .Sandbox:
			self.tradesStreamSub = TinkoffTradesStreamSubscriber(figi: "TSLA", callback: processTrade)
			self.orderSub = TinkoffOrderSubscriber(figi: "TSLA", callback: processOrderbook)
			self.postOrder = SandboxPostOrder(figi: "TSLA")
            self.candlesStreamSub = TinkoffCandleStreamSubscriber(figi: "BBG000BBJQV0", callback: self.processCandle)
		case .Tinkoff:
			self.tradesStreamSub = TinkoffTradesStreamSubscriber(figi: "TSLA", callback: processTrade)
			self.orderSub = TinkoffOrderSubscriber(figi: "TSLA", callback: processOrderbook)
			self.postOrder = TinkoffPostOrder(figi: "TSLA")
            self.candlesStreamSub = TinkoffCandleStreamSubscriber(figi: "BBG000BBJQV0", callback: self.processCandle)
		}
	}

//  Роботы на "стакане"
//
//  Робот отслеживает "стакан". Если лотов в заявках на покупку больше, чем в лотах на продажу в определенное количество раз, то робот покупает инструмент по рыночной цене, в противном случае – продает, сразу выставляя поручение в обратную сторону, но с определенным процентом прибыли.

//    // buyMarketPrice выставляет заявку на продажу акции с учетом определенного процента прибыли.
//    func sellWithPorfit(figi: String) {
//        sdk.portfolioService.getPortfolio(accountID: (self.botConfig?.account.id)!).sink { result in
//          switch result {
//          case .failure(let error):
//              print(error.localizedDescription)
//          case .finished:
//              print("did finish loading getPortfolio")
//          }
//        } receiveValue: { portfolio in
//            for position in portfolio.positions {
//                print("quantity =", position.quantity)
//                print("current price = ", position.currentPrice)
//                print("averate price = ", position.averagePositionPrice)
//
//                if position.figi == figi {
//                    // Расчет лучшей возможной цены на продажу.
//                    var bestPrice = max(position.currentPrice, position.averagePositionPrice * 1.15)
//                    sell(position.figi, position.a)
//                }
//            }
//        }.store(in: &cancellables)
//    }
    func processTrade(trade: Trade) {
        return
    }
    
    func processCandle(candle: CandleData) {
        print("received candle = ", candle)
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
			self.postOrder?.sellWithLimit(price: price)
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

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white
		self.navigationItem.title = "All"
		self.navigationController?.navigationBar.prefersLargeTitles = true
		print(isConnectedToInternet())
//        subscirbeToOrderBook()

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
