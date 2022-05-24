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
import Algorithms

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

class CandleFetcher {
    public init(figi: String,
                callback: @escaping (String, CandleData) -> ()) {
        self.figi = figi
        self.callback = callback
    }

    public func run() {}
    public func cancel() { }
    public func fetchHistoricalData(callback: @escaping (String, [CandleData]) -> ()) { }

    func oncall(candle: CandleData) {
        DispatchQueue.main.async {
            self.callback(self.figi!, candle)
        }
    }

    var figi: String?
    var callback: (String, CandleData) -> ()?
}

class EmuCandleFetcher: CandleFetcher {
    public override func run() {
        DispatchQueue.global(qos: .userInitiated).async {
    
        // В режиме эмуляции, загружаем свечи с указаной даты начала эмуляци.
        var currentEmulationDate = GlobalBotConfig.emuStartDate
        let nowDate = Date()
        var attempts = 0
        
        // Загружаем данные со времени начала эмуляции до сегоднешнего дня.
        while (currentEmulationDate <= nowDate && !self.shouldStop) {
            var req = GetCandlesRequest()
            req.figi = self.figi!
            // Загружаем свечи с прошлого дня по текущий.
            req.from = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: -1, to: currentEmulationDate)!)
            req.to = Google_Protobuf_Timestamp(date: currentEmulationDate)
            req.interval = CandleInterval.candleInterval5Min
            
            do {
                let candles = try GlobalBotConfig.sdk.marketDataService.getCandels(request: req).wait(timeout: 10).singleValue()
                for candle in candles.candles {
                    if self.shouldStop {
                        return
                    }
                    DispatchQueue.main.async {
                        self.oncall(candle: CandleData(tinkCandle: candle))
                    }
                    sleep(1)
                }
                
            } catch {
                attempts += 1
                if attempts > 5 {
                    GlobalBotConfig.logger.debug("[EmuCandleFetcher: run] Error while working with Tinkoff API")
                    break
                }
            }
            
            // Сбор свечей прошел успешно, обновляем счетчик попыток на 0.
            attempts = 0
            // Переходим на следующий день.
            currentEmulationDate = Calendar.current.date(byAdding: .day, value: 1, to: currentEmulationDate)!
            }
        }
    }

    public override func fetchHistoricalData(callback: @escaping (String, [CandleData]) -> ()) {
        // Preload candles for past dates.
        DispatchQueue.global(qos: .userInitiated).async {
            let now = GlobalBotConfig.emuStartDate
            var candles: [CandleData] = []
            var i = -3

            repeat {
                var req = GetCandlesRequest()
                req.figi = self.figi!
                req.from = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: i, to: now)!)
                req.to = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: i + 1, to: now)!)
                req.interval = CandleInterval.candleInterval5Min

                do {
                    let historicalCandles = try GlobalBotConfig.sdk.marketDataService.getCandels(request: req).wait(timeout: 10).singleValue()
                    for historicalCandle in historicalCandles.candles {
                        candles.append(CandleData(tinkCandle: historicalCandle))
                    }
                } catch {
                    break
                }
                i+=1
            } while i <= -1

            DispatchQueue.main.async {
                callback(self.figi!, candles)
            }
        }
    }

    public override func cancel() {
        self.shouldStop = true
    }

    var shouldStop = false
    var cancellables = Set<AnyCancellable>()
}

class TinkoffCandleFetcher: CandleFetcher {
    override init(figi: String, callback: @escaping (String, CandleData) -> ()) {
        super.init(figi: figi, callback: callback)
    }
    
    public override func run() {
        GlobalBotConfig.sdk.marketDataServiceStream.subscribeToCandels(figi: self.figi!, interval: SubscriptionInterval.oneMinute).sink { result in
            } receiveValue: { result in
                switch result.payload {
                    case .candle(let candle):
                        if candle.figi == self.figi! {
                            self.oncall(candle: CandleData(tinkCandle: candle))
                        }
                    default:
                        break
                    }
            }.store(in: &cancellables)
    }

    public override func fetchHistoricalData(callback: @escaping (String, [CandleData]) -> ()) {
        // Preload candles for past dates.
        DispatchQueue.global(qos: .userInitiated).async {
            let now = Date()
            var candles: [CandleData] = []
            var i = -3

            repeat {
                var req = GetCandlesRequest()
                req.figi = self.figi!
                req.from = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: i, to: now)!)
                req.to = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: i + 1, to: now)!)
                req.interval = CandleInterval.candleInterval5Min

                do {
                    let historicalCandles = try GlobalBotConfig.sdk.marketDataService.getCandels(request: req).wait(timeout: 10).singleValue()
                    for historicalCandle in historicalCandles.candles {
                        candles.append(CandleData(tinkCandle: historicalCandle))
                    }
                } catch {
                    break
                }
                i+=1
            } while i <= -1

            DispatchQueue.main.async {
                callback(self.figi!, candles)
            }
        }
    }

    public override func cancel() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }

    fileprivate var cancellables = Set<AnyCancellable>()
}
