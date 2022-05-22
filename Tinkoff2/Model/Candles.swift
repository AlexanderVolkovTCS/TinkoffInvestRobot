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

        print("start")

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

        print("end")
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

class CandleCache {
    public init(figi: String) {
        self.figi = figi
        self.collectHistoricalCandles()
    }

    public func collectHistoricalCandles() {

    }

    var figi: String
}

class CandleFetcher {
    public init(figi: String, callback: @escaping (String, CandleData) -> ()) {
        self.figi = figi
        self.callback = callback
    }

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
    public override init (figi: String, callback: @escaping (String, CandleData) -> ()) {
        super.init(figi: figi, callback: callback)

        // Preload candles for past dates.
        var req = GetCandlesRequest()
        req.figi = self.figi!
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

    public override func fetchHistoricalData(callback: @escaping (String, [CandleData]) -> ()) {
        // Preload candles for past dates.
        var req = GetCandlesRequest()
        req.figi = self.figi!
        req.from = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!)
        req.to = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        req.interval = CandleInterval.candleInterval5Min

        GlobalBotConfig.sdk.marketDataService.getCandels(request: req).sink { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .finished:
                print("loaded")
            }
        } receiveValue: { candles in

            var dataCandles = candles.candles.map { (candle) in CandleData(tinkCandle: candle) }
            DispatchQueue.main.async {
                callback(self.figi!, dataCandles)
            }

        }.store(in: &cancellables)
    }

    public override func cancel() {
        self.shouldStop = true
    }

    var shouldStop = false
    var cancellables = Set<AnyCancellable>()
}


struct RSIConfig {
    public var figis: [String]
    public var upperRsiThreshold = 70
    public var lowerRsiThreshold = 30
    public var takeProfit = 0.15
    public var stopLoss = 0.05
    public var rsiPeriod = 14
}

struct RSIOpenedPosition {
    public var openPrice: Float64
    init(openPrice: Float64) {
        self.openPrice = openPrice
    }
}

class RSIStrategyEngine {
    public init(config: RSIConfig,
                portfolioUpdateCallback: @escaping (PortfolioData) -> ()
    ) {
        self.config = config
        self.portfolioUpdateCallback = portfolioUpdateCallback
        
        switch GlobalBotConfig.mode {
        case .Emu:
            self.portfolioLoader = EmuPortfolioLoader(profile: GlobalBotConfig.account, callback: self.onPortfolio)
        case .Sandbox:
            self.portfolioLoader = SandboxPortfolioLoader(profile: GlobalBotConfig.account, callback: self.onPortfolio)
        case .Tinkoff:
            self.portfolioLoader = TinkoffPortfolioLoader(profile: GlobalBotConfig.account, callback: self.onPortfolio)
        }
        
        for figi in self.config!.figis {
            switch GlobalBotConfig.mode {
            case .Emu:
                self.postOrders[figi] = EmuPostOrder(figi: figi, onBuy: onBuySuccess, onSell: onSellSuccess, emuPortfolioLoader: self.portfolioLoader as! EmuPortfolioLoader)
                self.candlesFetchers[figi] = EmuCandleFetcher(figi: figi, callback: self.onNewCandle)

            case .Sandbox:
                self.postOrders[figi] = SandboxPostOrder(figi: figi, onBuy: onBuySuccess, onSell: onSellSuccess)
                self.candlesFetchers[figi] = EmuCandleFetcher(figi: figi, callback: self.onNewCandle)

            case .Tinkoff:
                self.postOrders[figi] = TinkoffPostOrder(figi: figi, onBuy: onBuySuccess, onSell: onSellSuccess)
                self.candlesFetchers[figi] = EmuCandleFetcher(figi: figi, callback: self.onNewCandle)
            }
        }

        collectHistoricalCandles()
    }

    // Используется один раз для инициализации алгоритма историческими свечами.
    // 3 дня 5 минутных свечей
    public func collectHistoricalCandles() {
        for candlesFetcher in self.candlesFetchers {
            candlesFetcher.value.fetchHistoricalData(callback: onHistoricalCandles)
        }
    }

    // Используется один раз в качестве коллбека при удачном сборе исторических свечей.
    private func onHistoricalCandles(figi: String, historicalCandles: [CandleData]) {
        let needCandles = min(config!.rsiPeriod, historicalCandles.count)
        let candlesPayload = historicalCandles.suffix(needCandles)
        for candle in candlesPayload {
            candles[figi]!.append(candle)
        }
    }

    private func onNewCandle(figi: String, candle: CandleData) {
        if candles[figi]!.count == self.config!.rsiPeriod {
            candles[figi]!.remove(at: 0)
        }
        candles[figi]!.append(candle)

        let rsi = calculateRSI(figi: figi)
        // Открываем лонг, если RSI меньше нижней границы
        if rsi < Float64(config!.lowerRsiThreshold) {
            openLong(figi: figi)
            // Закрываем лонг, если RSI больше верхней границы
        } else if rsi > Float64(config!.upperRsiThreshold) {
            closeLong(figi: figi)
        }
    }

    private func onBuySuccess(figi: String, amount: Int64) {
        openedPositions[figi]! += amount
        self.portfolioLoader!.syncPortfolioWithTink()
    }
    
    private func onSellSuccess(figi: String, amount: Int64) {
        openedPositions[figi]! -= amount
        self.portfolioLoader!.syncPortfolioWithTink()
    }
    
    private func onPortfolio(portfolioData: PortfolioData) {
        
        for figi in self.config!.figis {
            if let position = portfolioData.positions[figi] {
                openedPositions[figi]! += position.quantity.units
            }
        }
        
        self.portfolioUpdateCallback(portfolioData)
    }

    private func calculateRSI(figi: String) -> Float64 {
        if (candles.count < 2) {
            return 0
        }

        var totalGain: Float64 = 0
        var gainAmount = 0
        var totalLoss: Float64 = 0
        var lossAmount = 0

        var candleClosePrice: Float64 = 0
        var prevCandleClosePrice: Float64 = 0

        candles[figi]!.forEach { candle in
            if prevCandleClosePrice == 0 {
                prevCandleClosePrice = cast_money(quotation: candle.close)
                return
            }

            prevCandleClosePrice = candleClosePrice
            candleClosePrice = cast_money(quotation: candle.close)
            let change = candleClosePrice - prevCandleClosePrice

            if (change == 0) {
                return
            }
            if change > 0 {
                totalGain += change
                gainAmount += 1
            } else {
                totalLoss += change
                lossAmount += 1
            }
        }

        if gainAmount == 0 {
            gainAmount = 1
        }

        if lossAmount == 0 {
            lossAmount = 1
        }

        var avgGain = totalGain / Float64(gainAmount)
        if (avgGain == 0) {
            avgGain = 1
        }
        var avgLoss = totalLoss / Float64(lossAmount)
        if (avgLoss == 0) {
            avgLoss = 1
        }

        var rs = avgGain / avgLoss
        var rsi = 100 - (1 + rs)

        return rsi
    }

    private func openLong(figi: String) {
        // TOOD: quickly check via cached partfolio if there's enough money to buy.
        self.postOrders[figi]!.buyMarketPrice()
    }

    private func closeLong(figi: String) {
        var needClose = openedPositions[figi]!
        while (needClose > 0) {
            self.postOrders[figi]!.sellMarketPrice()
            needClose -= 1
        }
    }


    private var config: RSIConfig? = nil
    
    private var portfolioLoader: PortfolioLoader? = nil
    
//    private var tradesStreamSubscribers: [String : TradesStreamSubscriber] = [:]
    private var postOrders: [String : PostOrder] = [:]
    private var candlesFetchers: [String : CandleFetcher] = [:]
    
    private var candles: [String : LinkedList<CandleData>] = [:]
    private var openedPositions: [String : Int64] = [:]
    
    private var portfolioUpdateCallback: (PortfolioData) -> ()?

}
