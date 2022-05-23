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
        // Preload candles for past dates.
        var req = GetCandlesRequest()
        req.figi = self.figi!
        req.from = Google_Protobuf_Timestamp(date: Calendar.current.date(byAdding: .day, value: -1, to: GlobalBotConfig.emuStartDate)!)
        req.to = Google_Protobuf_Timestamp(date: GlobalBotConfig.emuStartDate)
        req.interval = CandleInterval.candleInterval5Min

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
        let id = Date().timeIntervalSince1970
        GlobalBotConfig.sdk.marketDataServiceStream.subscribeToCandels(figi: self.figi!, interval: SubscriptionInterval.oneMinute).sink { result in
            } receiveValue: { result in
                switch result.payload {
                    case .candle(let candle):
                        print("got \(id) \(self.figi!) \(candle.high.asDouble())", id)
                        self.oncall(candle: CandleData(tinkCandle: candle))
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


struct RSIConfig {
    public var figis: [String]
    public var upperRsiThreshold = 70
    public var lowerRsiThreshold = 30
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
                portfolioUpdateCallback: @escaping (PortfolioData) -> (),
                candlesUpdateCallback: @escaping (String, LinkedList<CandleData>) -> (),
                orderRequestCallback: @escaping (String, OrderInfo) -> (),
                orderUpdateCallback: @escaping (String, OrderInfo) -> (),
                rsiUpdateCallback: @escaping (String, Float64) -> ()
    ) {
        self.config = config
        self.portfolioUpdateCallback = portfolioUpdateCallback
        self.candlesUpdateCallback = candlesUpdateCallback
        self.orderRequestCallback = orderRequestCallback
        self.orderUpdateCallback = orderUpdateCallback
        self.rsiUpdateCallback = rsiUpdateCallback
        
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
                self.postOrders[figi] = EmuPostOrder(
                    figi: figi,
                    onBuy: onBuySuccess,
                    onSell: onSellSuccess,
                    orderRequestCallback: self.orderRequestCallback,
                    emuPortfolioLoader: self.portfolioLoader as! EmuPortfolioLoader
                )
                self.candlesFetchers[figi] = EmuCandleFetcher(figi: figi, callback: self.onNewCandle)

            case .Sandbox:
                self.postOrders[figi] = SandboxPostOrder(
                    figi: figi,
                    onBuy: onBuySuccess,
                    onSell: onSellSuccess,
                    orderRequestCallback: self.orderRequestCallback
                )
                self.candlesFetchers[figi] = TinkoffCandleFetcher(figi: figi, callback: self.onNewCandle)

            case .Tinkoff:
                self.postOrders[figi] = TinkoffPostOrder(
                    figi: figi,
                    onBuy: onBuySuccess,
                    onSell: onSellSuccess,
                    orderRequestCallback: self.orderRequestCallback
                )
                self.candlesFetchers[figi] = TinkoffCandleFetcher(figi: figi, callback: self.onNewCandle)
            }
        }

        collectHistoricalCandles()
    }
    
    deinit {
        stop()
    }
    
    public func stop() {
        for candlesFetcher in self.candlesFetchers {
            candlesFetcher.value.cancel()
        }
    }

    // Используется один раз для инициализации алгоритма историческими свечами.
    public func collectHistoricalCandles() {
        for candlesFetcher in self.candlesFetchers {
            candlesFetcher.value.fetchHistoricalData(callback: onHistoricalCandles)
        }
    }

    // Используется один раз в качестве коллбека при удачном сборе исторических свечей.
    private func onHistoricalCandles(figi: String, historicalCandles: [CandleData]) {
        let needCandles = min(config!.rsiPeriod, historicalCandles.count)
        let candlesPayload = historicalCandles.suffix(needCandles)
        
        if historicalCandles.isEmpty {
            return
        }
        
        for candle in candlesPayload {
            if self.candles[figi] == nil {
                self.candles[figi] = LinkedList<CandleData>()
            }
            self.candles[figi]!.append(candle)
        }

        self.candlesUpdateCallback(figi, self.candles[figi]!)
        self.candlesFetchers[figi]!.run()
    }

    private func onNewCandle(figi: String, candle: CandleData) {
        print("new candle! \(figi)", candle.high.asDouble(), candle.time)
        
        var mergedWithLast = false
        let last = self.candles[figi]!.last
        if last != nil {
            if candle.time == last!.value.time {
                last!.value = candle
                mergedWithLast = true
            }
        }
        
        if !mergedWithLast {
            if candles[figi]!.count == self.config!.rsiPeriod {
                candles[figi]!.remove(at: 0)
            }
            candles[figi]!.append(candle)
        }

        let rsi = calculateRSI(figi: figi)
        print("rsi = ", rsi)
        // Продаем, если RSI меньше нижней границы.
        if rsi < Float64(config!.lowerRsiThreshold) {
            closeLong(figi: figi)
            // Покупаем, если RSI больше верхней границы.
        } else if rsi > Float64(config!.upperRsiThreshold) {
            openLong(figi: figi)
        }
        
        self.candlesUpdateCallback(figi, self.candles[figi]!)
        self.rsiUpdateCallback(figi, rsi)
    }
    
    private func onPortfolio(portfolioData: PortfolioData) {
        print("on portfolio ", portfolioData)
        
        for position in openedPositions {
            openedPositions[position.key] = 0
        }
        
        for figi in self.config!.figis {
            if let position = portfolioData.positions[figi] {
                if openedPositions[figi] == nil {
                    openedPositions[figi] = 0
                }
                openedPositions[figi]! += position.quantity.units
                print("position, ", openedPositions[figi]!)
            }
        }
        
        self.portfolioUpdateCallback(portfolioData)
    }

    private func calculateRSI(figi: String) -> Float64 {
        if (candles[figi]!.count < 2) {
            return 0
        }

        var totalGain: Float64 = 0
        var gainAmount = 0
        var totalLoss: Float64 = 0
        var lossAmount = 0

        var candleClosePrice: Float64 = -1
        var prevCandleClosePrice: Float64 = -1

        candles[figi]!.forEach { candle in
            if candleClosePrice == -1 {
                candleClosePrice = cast_money(quotation: candle.close)
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
                totalLoss -= change
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

        let rs = avgGain / avgLoss
        let rsi = 100 - 100 / (1 + rs)

        return rsi
    }

    private func openLong(figi: String) {
        // TOOD: quickly check via cached partfolio if there's enough money to buy.
        self.postOrders[figi]!.buyMarketPrice()
    }

    private func closeLong(figi: String) {
        // Проверяем, есть ли открытые позиции, которые следует закрыть.
        if openedPositions[figi] == nil || openedPositions[figi] == 0 {
            return
        }
        
        let needClose = openedPositions[figi]!
        self.postOrders[figi]!.sellMarketPrice(amount: needClose)
    }
    
    private func onBuySuccess(figi: String, amount: Int64) {
        if openedPositions[figi] == nil {
            openedPositions[figi] = 0
        }
        
        self.portfolioLoader!.syncPortfolioWithTink()
        self.orderUpdateCallback(figi, OrderInfo(type: .Bought, count: amount))
        GlobalBotConfig.stat.onBuyOrderPosted(figi: figi, amount: amount)
    }
    
    private func onSellSuccess(figi: String, amount: Int64) {
        assert(openedPositions[figi] != nil)

        self.portfolioLoader!.syncPortfolioWithTink()
        self.orderUpdateCallback(figi, OrderInfo(type: .Sold, count: amount))
        GlobalBotConfig.stat.onSellOrderPosted(figi: figi, amount: amount)
    }

    private var config: RSIConfig? = nil
    
    private var portfolioLoader: PortfolioLoader? = nil
    
    private var postOrders: [String : PostOrder] = [:]
    private var candlesFetchers: [String : CandleFetcher] = [:]
    
    private var candles: [String : LinkedList<CandleData>] = [:]
    private var openedPositions: [String : Int64] = [:]
    
    private var portfolioUpdateCallback: (PortfolioData) -> ()?
    private var candlesUpdateCallback: (String, LinkedList<CandleData>) -> ()
    private var orderRequestCallback: (String, OrderInfo) -> ()
    private var orderUpdateCallback: (String, OrderInfo) -> ()
    private var rsiUpdateCallback: (String, Float64) -> ()

}
