////
////  PostOrder.swift
////  Tinkoff2
////
////  Created by Слава Пачков on 21.05.2022.
////
//
//import Foundation
//import TinkoffInvestSDK
//
//class PostOrder {
//    public init(figi: String,
//                onRequested: @escaping (OrderBookData)->(),
//                onExecuted: @escaping (OrderBookData)->()) {
//        self.figi = figi
//        self.onRequested = onRequested
//        self.onExecuted = onExecuted
//    }
//
//    var figi : String?
//    var onRequested : (OrderBookData)->()?
//    var onExecuted : (OrderBookData)->()?
//}
//
//
//class EmuPostOrder : PostOrder {
//    public override init(figi: String, callback: @escaping (OrderBookData)->()) {
//        super.init(figi: figi, callback: callback)
//
//        // Starting a new thread to emulate recieveing of data
//        DispatchQueue.global(qos: .userInitiated).async {
//            while (!self.shouldStop) {
//                DispatchQueue.main.async {
//                    print("Call")
//                    self.oncall(orderbook: OrderBookData())
//                }
//                sleep(1)
//            }
//        }
//    }
//
//    public override func cancel() {
//        self.shouldStop = true
//    }
//
//    var shouldStop = false
//}
//
//class TinkoffPostOrder : PostOrder {
//    public override init(figi: String, onExecuted: @escaping (OrderBookData)->()) {
//        super.init(figi: figi, onExecuted: onExecuted)
//
//        var req = PostOrderRequest()
//        req.accountID = GlobalBotConfig.account.id
//        req.orderID = UUID().uuidString
//        req.quantity = 1
//        req.direction = OrderDirection.buy
//        req.figi = figi
//        req.orderType = OrderType.market
//        // Не передаем price, так как продаем по рыночной цене
//
//        GlobalBotConfig.sdk.sandboxService.postOrder(request: req)
//        // TODO: await result
//    }
//}
