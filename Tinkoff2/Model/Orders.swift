//
//  EmuOrders.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import Foundation
import TinkoffInvestSDK

public struct QuotationContent {
    /// целая часть суммы, может быть отрицательным числом
    public var units: Int64 = 0

    /// дробная часть суммы, может быть отрицательным числом
    public var nano: Int32 = 0

    public init() {}
    
    /// Init from Tinkoff API
    public init(tinkQ: Quotation?) {
        self.units = tinkQ?.units ?? 0
        self.nano = tinkQ?.nano ?? 0
    }
}

struct OrderContent {
    ///Цена за 1 лот.
    fileprivate var _price: QuotationContent? = nil
    public var price: QuotationContent {
        get {return _price ?? QuotationContent()}
        set {_price = newValue}
    }
    
    /// Returns true if `price` has been explicitly set.
    public var hasPrice: Bool {return self._price != nil}
    
    ///Количество в лотах.
    public var quantity: Int64 = 0
    
    public init() {}
    
    /// Init from Tinkoff API
    public init(tinkOrder: Order?) {
        self.quantity = tinkOrder?.quantity ?? 0
        self.price = QuotationContent(tinkQ: tinkOrder?.price ?? nil)
    }
}


struct OrderBookContent {
    public var figi: String = String()

    ///Глубина стакана.
    public var depth: Int32 = 0

    ///Флаг консистентности стакана. **false** значит не все заявки попали в стакан по причинам сетевых задержек или нарушения порядка доставки.
    public var isConsistent: Bool = false

    ///Массив предложений.
    public var bids: [OrderContent] = []

    ///Массив спроса.
    public var asks: [OrderContent] = []
    
    public init() {}
    
    /// Init from Tinkoff API
    public init(tinkOrderBook: OrderBook?) {
        self.figi = tinkOrderBook?.figi ?? String()
        self.depth = tinkOrderBook?.depth ?? 0
        self.isConsistent = tinkOrderBook?.isConsistent ?? false
        self.bids = tinkOrderBook?.bids.map{(ord) in OrderContent(tinkOrder: ord)} ?? []
        self.asks = tinkOrderBook?.asks.map{(ord) in OrderContent(tinkOrder: ord)} ?? []
    }
}

class OrderSubscriber {
    public init(figi: String, callback: @escaping (OrderBookContent)->()) {
        self.figi = figi
        self.callback = callback
    }
    
    public func cancel() {
        
    }
    
    func oncall(orderbook: OrderBookContent) {
        DispatchQueue.main.async {
            self.callback(orderbook)
        }
    }
    
    var figi : String?
    var callback : (OrderBookContent)->()?
}


class EmuOrderSubscriber : OrderSubscriber {
    public override init(figi: String, callback: @escaping (OrderBookContent)->()) {
        super.init(figi: figi, callback: callback)
        
        // Starting a new thread to emulate recieveing of data
        DispatchQueue.global(qos: .userInitiated).async {
            while (!self.shouldStop) {
                DispatchQueue.main.async {
                    print("Call")
                    self.oncall(orderbook: OrderBookContent())
                }
                sleep(1)
            }
        }
    }
    
    public override func cancel() {
        self.shouldStop = true
    }
    
    var shouldStop = false
}

class TinkoffOrderSubscriber : OrderSubscriber {
    public override init(figi: String, callback: @escaping (OrderBookContent)->()) {
        super.init(figi: figi, callback: callback)
//        self.sdk.marketDataServiceStream.subscribeToOrderBook(figi: figi, depth: 20).sink { result in
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
    }
    
    public override func cancel() {
        super.cancel()
    }
}
