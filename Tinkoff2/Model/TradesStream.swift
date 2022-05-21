//
//  TradesStream.swift
//  Tinkoff2
//
//  Created by Слава Пачков on 21.05.2022.
//

import Foundation
import TinkoffInvestSDK
import Combine

class TradesStreamSubscriber {
    public init(figi: String, callback: @escaping (Trade) -> ()) {
        self.figi = figi
        self.callback = callback
    }

    public func cancel() { }

    func oncall(trade: Trade) {
        DispatchQueue.main.async {
            self.callback(trade)
        }
    }

    var figi: String?
    var callback: (Trade) -> ()?
}

class EmuTradesStreamSubscriber: TradesStreamSubscriber {
    // Used through the emulation process.
    public func dispatchOnCall(trade :Trade) {
        DispatchQueue.main.async {
            self.oncall(trade: trade)
        }
    }

    public override func cancel() {
        self.shouldStop = true
    }

    var shouldStop = false
}

class TinkoffTradesStreamSubscriber: TradesStreamSubscriber {
    public override init(figi: String, callback: @escaping (Trade) -> ()) {
        super.init(figi: figi, callback: callback)
        
        var cancellables = Set<AnyCancellable>()
        
        GlobalBotConfig.sdk.marketDataServiceStream.subscribeToTrades(figi: self.figi!).sink {result in
        } receiveValue: { result in
            switch result.payload {
            case .trade(let trade):
                callback(trade)
            default:
                break
            }
        }.store(in: &cancellables)
    }

    public override func cancel() {
        super.cancel()
    }
}
