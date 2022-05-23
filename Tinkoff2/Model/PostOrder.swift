//
//  PostOrder.swift
//  Tinkoff2
//
//  Created by Слава Пачков on 21.05.2022.
//

import Foundation
import TinkoffInvestSDK
import Combine
import CombineWaiting

class PostOrder {
	public init(figi: String,
                onBuy: @escaping (String, Int64) -> (),
                onSell: @escaping (String, Int64) -> ()
    ) {
		self.figi = figi
        self.onBuy = onBuy
        self.onSell = onSell
	}

	// buyMarketPrice выставляет заявку на покупку акции по рыночной цене.
	public func buyMarketPrice() { }
	// sellMarketPrice выставляет заявку на продажу акции по рыночной цене.
	public func sellMarketPrice() { }
    
    public func dispatchOnBuy(amount: Int64) {
        DispatchQueue.main.async {
            self.onBuy(self.figi!, amount)
        }
    }
    
    public func dispatchOnSell(amount: Int64) {
        DispatchQueue.main.async {
            self.onSell(self.figi!, amount)
        }
    }

	var figi: String?
    var onBuy: (String, Int64) -> ()?
    var onSell: (String, Int64) -> ()?
}


class EmuPostOrder: PostOrder {
    public init(figi: String,
                onBuy: @escaping (String, Int64) -> (),
                onSell: @escaping (String, Int64) -> (),
                emuPortfolioLoader: EmuPortfolioLoader
    ) {
        super.init(figi: figi, onBuy: onBuy, onSell: onSell)
        self.emuPortfolioLoader = emuPortfolioLoader
    }
    
    public override func buyMarketPrice() {
        // Emulate porfolio
        let portfolio = self.emuPortfolioLoader!.getPortfolioCached()
        if (portfolio.positions[self.figi!] != nil) {
            portfolio.positions[self.figi!]!.quantity.units += 1
        } else {
            var pp = PortfolioPosition()
            pp.figi = self.figi!
            pp.quantityLots.units = 0
            pp.quantityLots.nano = 0
            portfolio.positions[self.figi!] = pp
        }

        self.dispatchOnBuy(amount: 1)
	}

	public override func sellMarketPrice() {
        // Emulate porfolio
        let portfolio = self.emuPortfolioLoader!.getPortfolioCached()
        if (portfolio.positions[self.figi!] == nil) {
            return
        }
        
        portfolio.positions[self.figi!]!.quantity.units -= 1

        self.dispatchOnSell(amount: 1)
	}
    
    var emuPortfolioLoader: EmuPortfolioLoader?
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
            DispatchQueue.global(qos: .userInitiated).async {
                let orderID = order.orderID
                var executed = order.lotsExecuted
                var status = order.executionReportStatus
                
                while (status == OrderExecutionReportStatus.executionReportStatusNew ||
                       status == OrderExecutionReportStatus.executionReportStatusPartiallyfill) {
                    var orderStateReq = GetOrderStateRequest()
                    orderStateReq.accountID = GlobalBotConfig.account.id
                    orderStateReq.orderID = orderID
                    
                    do {
                        let state = try GlobalBotConfig.sdk.ordersService.getOrderState(request: orderStateReq).wait(timeout: 10).singleValue()
                        if (state.lotsExecuted > executed) {
                            self.dispatchOnBuy(amount: state.lotsExecuted - executed)
                        }
                        status = state.executionReportStatus
                        executed = state.lotsExecuted
                    } catch {
                        break
                    }
                    
                    sleep(1)
                }
            }
		}.store(in: &cancellables)
	}

	public override func sellMarketPrice() {
		var cancellables = Set<AnyCancellable>()

		var req = PostOrderRequest()
		req.accountID = GlobalBotConfig.account.id
		req.orderID = UUID().uuidString
		req.quantity = 1
		req.direction = OrderDirection.sell
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
            DispatchQueue.global(qos: .userInitiated).async {
                let orderID = order.orderID
                var executed = order.lotsExecuted
                var status = order.executionReportStatus
                
                while (status == OrderExecutionReportStatus.executionReportStatusNew ||
                       status == OrderExecutionReportStatus.executionReportStatusPartiallyfill) {
                    var orderStateReq = GetOrderStateRequest()
                    orderStateReq.accountID = GlobalBotConfig.account.id
                    orderStateReq.orderID = orderID
                    
                    do {
                        let state = try GlobalBotConfig.sdk.ordersService.getOrderState(request: orderStateReq).wait(timeout: 10).singleValue()
                        if (state.lotsExecuted > executed) {
                            self.dispatchOnSell(amount: state.lotsExecuted - executed)
                        }
                        status = state.executionReportStatus
                        executed = state.lotsExecuted
                    } catch {
                        break
                    }
                    
                    sleep(1)
                }
            }
		}.store(in: &cancellables)
	}
}

class TinkoffPostOrder: PostOrder {
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

        GlobalBotConfig.sdk.ordersService.postOrder(request: req).sink { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .finished:
                print("loaded")
            }
        } receiveValue: { order in
            DispatchQueue.global(qos: .userInitiated).async {
                let orderID = order.orderID
                var executed = order.lotsExecuted
                var status = order.executionReportStatus
                
                while (status == OrderExecutionReportStatus.executionReportStatusNew ||
                       status == OrderExecutionReportStatus.executionReportStatusPartiallyfill) {
                    var orderStateReq = GetOrderStateRequest()
                    orderStateReq.accountID = GlobalBotConfig.account.id
                    orderStateReq.orderID = orderID
                    
                    do {
                        let state = try GlobalBotConfig.sdk.ordersService.getOrderState(request: orderStateReq).wait(timeout: 10).singleValue()
                        if (state.lotsExecuted > executed) {
                            self.dispatchOnBuy(amount: state.lotsExecuted - executed)
                        }
                        status = state.executionReportStatus
                        executed = state.lotsExecuted
                    } catch {
                        break
                    }
                    
                    sleep(1)
                }
            }
        }.store(in: &cancellables)
    }

    public override func sellMarketPrice() {
        var cancellables = Set<AnyCancellable>()

        var req = PostOrderRequest()
        req.accountID = GlobalBotConfig.account.id
        req.orderID = UUID().uuidString
        req.quantity = 1
        req.direction = OrderDirection.sell
        req.figi = self.figi!
        req.orderType = OrderType.market
        // Не передаем price, так как продаем по рыночной цене

        GlobalBotConfig.sdk.ordersService.postOrder(request: req).sink { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .finished:
                print("loaded")
            }
        } receiveValue: { order in
            DispatchQueue.global(qos: .userInitiated).async {
                let orderID = order.orderID
                var executed = order.lotsExecuted
                var status = order.executionReportStatus
                
                while (status == OrderExecutionReportStatus.executionReportStatusNew ||
                       status == OrderExecutionReportStatus.executionReportStatusPartiallyfill) {
                    var orderStateReq = GetOrderStateRequest()
                    orderStateReq.accountID = GlobalBotConfig.account.id
                    orderStateReq.orderID = orderID
                    
                    do {
                        let state = try GlobalBotConfig.sdk.ordersService.getOrderState(request: orderStateReq).wait(timeout: 10).singleValue()
                        if (state.lotsExecuted > executed) {
                            self.dispatchOnSell(amount: state.lotsExecuted - executed)
                        }
                        status = state.executionReportStatus
                        executed = state.lotsExecuted
                    } catch {
                        break
                    }
                    
                    sleep(1)
                }
            }
        }.store(in: &cancellables)
    }
}
