//
//  PostOrder.swift
//  Tinkoff2
//
//  Created by Слава Пачков on 21.05.2022.
//

import Foundation
import TinkoffInvestSDK
import Combine

class PostOrder {
	public init(figi: String) {
		self.figi = figi
	}

	// buyMarketPrice выставляет заявку на покупку акции по рыночной цене.
	public func buyMarketPrice() { }
    // sellMarketPrice выставляет заявку на продажу акции по рыночной цене.
    public func sellMarketPrice() { }
	// sellWithLimit выставляет заявку на продажу акции с учетом лимита.
	public func sellWithLimit(price: Quotation) { }

	var figi: String?
}


class EmuPostOrder: PostOrder {
	public init(figi: String, tradesStreamSubsriber: EmuTradesStreamSubscriber) {
		super.init(figi: figi)
		self.tradesStreamSubsriber = tradesStreamSubsriber
	}

	public override func buyMarketPrice() {
		var trade = Trade()
		trade.figi = self.figi!
		trade.price = Quotation()
		trade.quantity = 1
		trade.direction = TradeDirection.buy
		self.tradesStreamSubsriber?.dispatchOnCall(trade: trade)
	}

	public override func sellWithLimit(price: Quotation) {
		var trade = Trade()
		trade.figi = self.figi!
		trade.price = price
		trade.quantity = 1
		trade.direction = TradeDirection.sell
		self.tradesStreamSubsriber?.dispatchOnCall(trade: trade)
	}
    
    public override func sellMarketPrice() {
        var trade = Trade()
        trade.figi = self.figi!
        trade.price = Quotation()
        trade.quantity = 1
        trade.direction = TradeDirection.sell
        self.tradesStreamSubsriber?.dispatchOnCall(trade: trade)
    }

	var tradesStreamSubsriber: EmuTradesStreamSubscriber?
}

class SandboxPostOrder: PostOrder {
	public override func buyMarketPrice() {
		var cancellables = Set<AnyCancellable>()

		var req = PostOrderRequest()
		req.accountID = GlobalBotConfig.account.id
		req.orderID = UUID().uuidString
		req.quantity = 1
		req.direction = OrderDirection.buy
		req.figi = self.figi!
		req.orderType = OrderType.market
		// Не передаем price, так как продаем по рыночной цене

		GlobalBotConfig.sdk.sandboxService.postOrder(request: req).sink { result in
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
			case .finished:
				print("loaded")
			}
		} receiveValue: { order in
			print("ordr")
		}.store(in: &cancellables)
	}

	public override func sellWithLimit(price: Quotation) {
		var cancellables = Set<AnyCancellable>()

		var req = PostOrderRequest()
		req.accountID = GlobalBotConfig.account.id
		req.orderID = UUID().uuidString
		req.quantity = 1
		req.direction = OrderDirection.sell
		req.figi = self.figi!
		req.orderType = OrderType.limit
		req.price = price

		GlobalBotConfig.sdk.sandboxService.postOrder(request: req).sink { result in
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
			case .finished:
				print("loaded")
			}
		} receiveValue: { order in
			print("ordr")
		}.store(in: &cancellables)
	}
}

class TinkoffPostOrder: PostOrder {
	public override func buyMarketPrice() { }
	public override func sellWithLimit(price: Quotation) { }
}
