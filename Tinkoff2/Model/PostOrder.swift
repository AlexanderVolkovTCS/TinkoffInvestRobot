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
                onBuy: @escaping (String, Int64, MoneyValue) -> (),
                onSell: @escaping (String, Int64, MoneyValue) -> (),
                orderRequestCallback: @escaping (String, OrderInfo) -> ()
    ) {
		self.figi = figi
        self.onBuy = onBuy
        self.onSell = onSell
        self.orderRequestCallback = orderRequestCallback
	}

    // buyMarketPrice выставляет заявку на покупку одной акции по заданной цене.
    public func buyPrice(price: MoneyValue) { }
    
    // sellMarketPrice выставляет заявку на продажу нескольких акций по заданной цене.
    public func sellPrice(price: MoneyValue, amount: Int64) { }
    
	// buyMarketPrice выставляет заявку на покупку одной акции по рыночной цене.
    public func buyMarketPrice() { self.buyPrice(price: MoneyValue()) }
    
	// sellMarketPrice выставляет заявку на продажу нескольких акций по рыночной цене.
    public func sellMarketPrice(amount: Int64) { self.sellPrice(price: MoneyValue(), amount: amount) }
    
    public func dispatchOnOrderRequest(orderInfo: OrderInfo) {
        DispatchQueue.main.async {
            self.orderRequestCallback(self.figi!, orderInfo)
        }
    }
    
    public func dispatchOnBuy(amount: Int64, total: MoneyValue) {
        DispatchQueue.main.async {
            self.onBuy(self.figi!, amount, total)
        }
    }
    
    public func dispatchOnSell(amount: Int64, total: MoneyValue) {
        DispatchQueue.main.async {
            self.onSell(self.figi!, amount, total)
        }
    }

	var figi: String?
    var onBuy: (String, Int64, MoneyValue) -> ()?
    var onSell: (String, Int64, MoneyValue) -> ()?
    var orderRequestCallback: (String, OrderInfo) -> ()?
}


class EmuPostOrder: PostOrder {
    public init(figi: String,
                onBuy: @escaping (String, Int64, MoneyValue) -> (),
                onSell: @escaping (String, Int64, MoneyValue) -> (),
                orderRequestCallback: @escaping (String, OrderInfo) -> (),
                emuPortfolioLoader: EmuPortfolioLoader
    ) {
        super.init(figi: figi, onBuy: onBuy, onSell: onSell, orderRequestCallback: orderRequestCallback)
        self.emuPortfolioLoader = emuPortfolioLoader
    }
    
    public override func buyPrice(price: MoneyValue) {
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
        GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Opening long with \(price.asString()) price")
        self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.BoughtRequest, count: 1, price: price))
        self.dispatchOnBuy(amount: 1, total: price)
	}

	public override func sellPrice(price: MoneyValue, amount: Int64) {
        // Emulate porfolio
        let portfolio = self.emuPortfolioLoader!.getPortfolioCached()
        if (portfolio.positions[self.figi!] == nil) {
            return
        }
        portfolio.positions[self.figi!]!.quantity.units -= amount
        
        // Add statistics about posting.
        GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Closing long: amount \(amount), price \(price.asString())")
        self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.SoldRequest, count: amount, price: price))
        
        var total = price
        var nano = Int64(total.nano)
        nano *= amount
        total.units += nano / Int64(1e9)
        total.nano = Int32(nano % Int64(1e9))
        total.units *= Int64(amount)
        self.dispatchOnSell(amount: amount, total: total)
	}
    
    var emuPortfolioLoader: EmuPortfolioLoader?
}

class SandboxPostOrder: PostOrder {
    var cancellables = Set<AnyCancellable>()
    
    public override func buyPrice(price: MoneyValue) {
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
                GlobalBotConfig.logger.debug("Error loading SandboxPostOrder.buyMarketPrice \(error.localizedDescription)")
			case .finished:
				break
			}
		} receiveValue: { order in
            DispatchQueue.global(qos: .userInitiated).async {
                // Add statistics about posting.
                GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Opening long with \(price.asString()) price")
                self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.BoughtRequest, count: 1, price: price))
                
                let executed = order.lotsExecuted
                let status = order.executionReportStatus
                let totalOrderPrice = order.executedOrderPrice
                
                // Optimization: quickly check if an order was already completed.
                if (status == OrderExecutionReportStatus.executionReportStatusFill ||
                    status == OrderExecutionReportStatus.executionReportStatusRejected ||
                    status == OrderExecutionReportStatus.executionReportStatusCancelled) {
                    
                    self.dispatchOnSell(amount: executed, total: totalOrderPrice)
                    return
                }
                
                // В следствие особенностей взаимодействия с песочницей, мы не дожидаемся исполнения
                // getOrderState при работе с sandbox.
                self.dispatchOnBuy(amount: 1, total: price)

            }
		}.store(in: &cancellables)
	}
    
	public override func sellPrice(price: MoneyValue, amount: Int64) {
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
                GlobalBotConfig.logger.debug("Error loading SandboxPostOrder.sellMarketPrice \(error.localizedDescription)")
			case .finished:
				break
			}
		} receiveValue: { order in
            DispatchQueue.global(qos: .userInitiated).async {
                var total = price
                total.nano *= Int32(amount)
                total.units += Int64(total.nano) / Int64(1e9)
                total.nano = Int32(Int64(total.nano) % Int64(1e9))
                total.units *= Int64(Int32(amount))
                
                // Add statistics about posting.
                GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Closing long: amount \(amount), price \(price.asString())")
                self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.SoldRequest, count: amount, price: total))
                
                let executed = order.lotsExecuted
                let status = order.executionReportStatus
                let totalOrderPrice = order.executedOrderPrice
                
                // Optimization: quickly check if an order was already completed.
                if (status == OrderExecutionReportStatus.executionReportStatusFill ||
                    status == OrderExecutionReportStatus.executionReportStatusRejected ||
                    status == OrderExecutionReportStatus.executionReportStatusCancelled) {
                    
                    self.dispatchOnSell(amount: executed, total: totalOrderPrice)
                    return
                }
                
                // В следствие особенностей взаимодействия с песочницей, мы не дожидаемся исполнения
                // getOrderState при работе с sandbox.
                self.dispatchOnSell(amount: amount, total: total)
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
                GlobalBotConfig.logger.debug(error.localizedDescription)
            case .finished:
                break
            }
        } receiveValue: { order in
            DispatchQueue.global(qos: .userInitiated).async {
                // Add statistics about posting.
                GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Opening long with market price")
                self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.BoughtRequest, count: 1, price: MoneyValue()))
                
                let orderID = order.orderID
                var executed = order.lotsExecuted
                var status = order.executionReportStatus
                
                // Optimization: quickly check if an order was already completed.
                if (status == OrderExecutionReportStatus.executionReportStatusFill ||
                    status == OrderExecutionReportStatus.executionReportStatusRejected ||
                    status == OrderExecutionReportStatus.executionReportStatusCancelled) {
                    
                    self.dispatchOnBuy(amount: executed, total: order.executedOrderPrice)
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
                            self.dispatchOnBuy(amount: state.lotsExecuted - executed, total: state.executedOrderPrice)
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
                GlobalBotConfig.logger.debug(error.localizedDescription)
            case .finished:
                break
            }
        } receiveValue: { order in
            DispatchQueue.global(qos: .userInitiated).async {
                // Add statistics about posting.
                GlobalBotConfig.logger.info("[\(String(describing: self.figi!))] Closing long: amount \(amount) with market price")
                self.dispatchOnOrderRequest(orderInfo: OrderInfo(type: OperationType.SoldRequest, count: amount, price: MoneyValue()))
                
                let orderID = order.orderID
                var executed = order.lotsExecuted
                var status = order.executionReportStatus
                
                // Optimization: quickly check if an order was already completed.
                if (status == OrderExecutionReportStatus.executionReportStatusFill ||
                    status == OrderExecutionReportStatus.executionReportStatusRejected ||
                    status == OrderExecutionReportStatus.executionReportStatusCancelled) {
                    
                    self.dispatchOnSell(amount: executed, total: order.totalOrderAmount)
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
                            self.dispatchOnSell(amount: state.lotsExecuted - executed, total: state.totalOrderAmount)
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
