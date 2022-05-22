//
//  Candles.swift
//  Tinkoff2
//
//  Created by Слава Пачков on 21.05.2022.
//

import Foundation
import TinkoffInvestSDK
import Combine
import SwiftProtobuf

struct CandleData {
    public var open: Quotation
    public var high: Quotation
    public var low: Quotation
    public var close: Quotation
    public var volume: Int64
    public var time: Int64
    
    /// Init from Tinkoff API
    public init(tinkCandle: HistoricCandle) {
        self.open = tinkCandle.open
        self.high = tinkCandle.high
        self.low = tinkCandle.low
        self.close = tinkCandle.close
        self.volume = tinkCandle.volume
        self.time = tinkCandle.time.seconds
    }
    
    public init(tinkCandle: Candle) {
        self.open = tinkCandle.open
        self.high = tinkCandle.high
        self.low = tinkCandle.low
        self.close = tinkCandle.close
        self.volume = tinkCandle.volume
        self.time = tinkCandle.time.seconds
    }
}

class CandleStreamSubscriber {
    public init(figi: String, callback: @escaping (String, CandleData) -> ()) {
        self.figi = figi
        self.callback = callback
    }

    public func cancel() { }

    func oncall(candle: CandleData) {
        DispatchQueue.main.async {
            self.callback(self.figi, candle)
        }
    }

    var figi: String = ""
    var callback: (String, CandleData) -> ()?
}

class EmuCandleStreamSubscriber: CandleStreamSubscriber {
    public override init (figi: String, callback: @escaping (String, CandleData) -> ()) {
        super.init(figi: figi, callback: callback)

        // Preload candles for past dates.
        var req = GetCandlesRequest()
        req.figi = self.figi
        req.from = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
        req.to = Google_Protobuf_Timestamp(date: Date())
        req.interval = CandleInterval.day
        
        GlobalBotConfig.sdk.marketDataService.getCandels(request: req).sink { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .finished:
                print("loaded")
            }
        } receiveValue: { candles in
            // Starting a new thread to emulate candels streaming.
            DispatchQueue.global(qos: .userInitiated).async {
                for candle in candles.candles {
                    if self.shouldStop {
                        return
                    }
                    DispatchQueue.main.async {
                        self.oncall(candle: CandleData(tinkCandle: candle))
                    }
                    sleep(1)
                }
            }
        }.store(in: &cancellables)
    }

    public override func cancel() {
        self.shouldStop = true
    }

    var shouldStop = false
    var cancellables = Set<AnyCancellable>()
}

class TinkoffCandleStreamSubscriber: CandleStreamSubscriber {
    public override init (figi: String, callback: @escaping (String, CandleData) -> ()) {
        super.init(figi: figi, callback: callback)
        
        var cancellables = Set<AnyCancellable>()

        GlobalBotConfig.sdk.marketDataServiceStream.subscribeToCandels(figi: self.figi, interval: .oneMinute).sink { result in
           print(result)
        } receiveValue: { result in
           switch result.payload {
           case .candle(let candle):
               print(candle)
               self.oncall(candle: CandleData(tinkCandle: candle))
           default:
              break
           }
        }.store(in: &cancellables)
    }

    public override func cancel() {
        super.cancel()
    }
}
