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
                onSell: @escaping (String, Int64) -> (),
                orderRequestCallback: @escaping (String, OrderInfo) -> ()
    ) {
		self.figi = figi
        self.onBuy = onBuy
        self.onSell = onSell
        self.orderRequestCallback = orderRequestCallback
	}

	// buyMarketPrice выставляет заявку на покупку одной акции по рыночной цене.
	public func buyMarketPrice() { }
    
	// sellMarketPrice выставляет заявку на продажу нескольких акций по рыночной цене.
	public func sellMarketPrice(amount: Int64) { }
    
    public func dispatchOnOrderRequest(orderInfo: OrderInfo) {
        DispatchQueue.main.async {
            self.orderRequestCallback(self.figi!, orderInfo)
        }
    }
    
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
    var orderRequestCallback: (String, OrderInfo) -> ()?
}


class EmuPostOrder: PostOrder {
    public init(figi: String,
                onBuy: @escaping (String, Int64) -> (),
                onSell: @escaping (String, Int64) -> (),
                orderRequestCallback: @escaping (String, OrderInfo) -> (),
                emuPortfolioLoader: EmuPortfolioLoader
    ) {
        super.init(figi: figi, onBuy: onBuy, onSell: onSell, orderRequestCallback: orderRequestCallback)
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
            pp.quantityLots.units = 1
            pp.quantityLots.nano = 0
            portfolio.positions[self.figi!] = pp
        }
        
        // Add statistics about posting.
        GlobalBotConfig.stat.onBuyOrderPosted(figi: self.figi!)
        GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Opening long with market price")
        self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.BoughtRequest, count: 1))
        self.dispatchOnBuy(amount: 1)
	}

	public override func sellMarketPrice(amount: Int64) {
        // Emulate porfolio
        let portfolio = self.emuPortfolioLoader!.getPortfolioCached()
        if (portfolio.positions[self.figi!] == nil) {
            return
        }
        portfolio.positions[self.figi!]!.quantity.units -= amount
        
        // Add statistics about posting.
        GlobalBotConfig.stat.onSellOrderPosted(figi: self.figi!, amount: amount)
        GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Closing long: amount \(amount)")
        self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.SoldRequest, count: amount))
        self.dispatchOnSell(amount: amount)
	}
    
    var emuPortfolioLoader: EmuPortfolioLoader?
}

class SandboxPostOrder: PostOrder {
    var cancellables = Set<AnyCancellable>()
    
	public override func buyMarketPrice() {
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
                // Add statistics about posting.
                GlobalBotConfig.stat.onBuyOrderPosted(figi: self.figi!)
                GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Opening long with market price")
                self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.BoughtRequest, count: 1))
                
                let executed = order.lotsExecuted
                let status = order.executionReportStatus
                
                // Optimization: quickly check if an order was already completed.
                if (status == OrderExecutionReportStatus.executionReportStatusFill ||
                    status == OrderExecutionReportStatus.executionReportStatusRejected ||
                    status == OrderExecutionReportStatus.executionReportStatusCancelled) {
                    
                    self.dispatchOnBuy(amount: executed)
                    return
                }
                
                // В следствие особенностей взаимодействия с песочницей, мы не дожидаемся исполнения
                // getOrderState при работе с sandbox.
                self.dispatchOnBuy(amount: 1)

            }
		}.store(in: &cancellables)
	}
    
	public override func sellMarketPrice(amount: Int64) {
		var req = PostOrderRequest()
		req.accountID = GlobalBotConfig.account.id
		req.orderID = UUID().uuidString
		req.quantity = amount
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
                // Add statistics about posting.
                GlobalBotConfig.stat.onSellOrderPosted(figi: self.figi!, amount: amount)
                GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Closing long: amount \(amount)")
                self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.SoldRequest, count: amount))
                
                let executed = order.lotsExecuted
                let status = order.executionReportStatus
                
                // Optimization: quickly check if an order was already completed.
                if (status == OrderExecutionReportStatus.executionReportStatusFill ||
                    status == OrderExecutionReportStatus.executionReportStatusRejected ||
                    status == OrderExecutionReportStatus.executionReportStatusCancelled) {
                    
                    self.dispatchOnSell(amount: executed)
                    return
                }
                
                // В следствие особенностей взаимодействия с песочницей, мы не дожидаемся исполнения
                // getOrderState при работе с sandbox.
                self.dispatchOnSell(amount: amount)
            }
		}.store(in: &cancellables)
	}
}

class TinkoffPostOrder: PostOrder {
    var cancellables = Set<AnyCancellable>()
    
    public override func buyMarketPrice() {
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
                // Add statistics about posting.
                GlobalBotConfig.stat.onBuyOrderPosted(figi: self.figi!)
                GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Opening long with market price")
                self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.BoughtRequest, count: 1))
                
                let orderID = order.orderID
                var executed = order.lotsExecuted
                var status = order.executionReportStatus
                
                // Optimization: quickly check if an order was already completed.
                if (status == OrderExecutionReportStatus.executionReportStatusFill ||
                    status == OrderExecutionReportStatus.executionReportStatusRejected ||
                    status == OrderExecutionReportStatus.executionReportStatusCancelled) {
                    
                    self.dispatchOnBuy(amount: executed)
                    return
                }
                
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

    public override func sellMarketPrice(amount: Int64) {
        var req = PostOrderRequest()
        req.accountID = GlobalBotConfig.account.id
        req.orderID = UUID().uuidString
        req.quantity = amount
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
                // Add statistics about posting.
                GlobalBotConfig.stat.onSellOrderPosted(figi: self.figi!, amount: amount)
                GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Closing long: amount \(amount)")
                self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.SoldRequest, count: amount))
                
                let orderID = order.orderID
                var executed = order.lotsExecuted
                var status = order.executionReportStatus
                
                // Optimization: quickly check if an order was already completed.
                if (status == OrderExecutionReportStatus.executionReportStatusFill ||
                    status == OrderExecutionReportStatus.executionReportStatusRejected ||
                    status == OrderExecutionReportStatus.executionReportStatusCancelled) {
                    
                    self.dispatchOnSell(amount: executed)
                    return
                }
                
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
