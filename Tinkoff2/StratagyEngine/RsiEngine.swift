//
//  RsiEngine.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 23.05.2022.
//

import Foundation
import TinkoffInvestSDK

struct RSIConfig {
    public var figis: [String]
    public var upperRsiThreshold = 70
    public var lowerRsiThreshold = 30
    public var rsiPeriod = 14
    public var stopLoss = 0.98
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
        let rsi = calculateRSI(figi: figi)
        self.rsiUpdateCallback(figi, rsi)
        self.candlesFetchers[figi]!.run()
    }

    private func onNewCandle(figi: String, candle: CandleData) {
        GlobalBotConfig.logger.debug("new candle! \(figi) \(candle.high.asDouble()) \(candle.time)")
        
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
        GlobalBotConfig.logger.debug("new rsi = \(rsi)")
        // Продаем, если RSI меньше нижней границы.
        if rsi < Float64(config!.lowerRsiThreshold) {
            closeLong(figi: figi)
            // Покупаем, если RSI больше верхней границы.
        } else if rsi > Float64(config!.upperRsiThreshold) {
            openLong(figi: figi)
        } else if stopLossPositions[figi] != nil && stopLossPositions[figi]! >= candle.close.asDouble() {
            // Продаем, стоп-лосс.
            GlobalBotConfig.logger.info("[\(figi)] Hit stop-loss")
            closeLong(figi: figi)
        }
        
        self.candlesUpdateCallback(figi, self.candles[figi]!)
        self.rsiUpdateCallback(figi, rsi)
    }
    
    private func onPortfolio(portfolioData: PortfolioData) {
        for position in openedPositions {
            openedPositions[position.key] = 0
        }
        
        for figi in self.config!.figis {
            if let position = portfolioData.positions[figi] {
                if openedPositions[figi] == nil {
                    openedPositions[figi] = 0
                }
                openedPositions[figi]! += position.quantity.units + 1
            }
        }
        
        self.portfolioData = portfolioData
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
        var instrument: Instrument? = nil
        for instr in GlobalBotConfig.figis {
            if instr.figi == figi {
                instrument = instr
                break
            }
        }
        
        assert(instrument != nil)
        
        let candle = candles[figi]!.last!.value.close
        var money = MoneyValue()
        money.units = candle.units
        money.nano = candle.nano
        money.currency = instrument!.currency
        
        let hasMoney = portfolioData.getMoneyValue(currency: instrument!.currency)
        if hasMoney != nil && hasMoney!.units < money.units {
            GlobalBotConfig.logger.debug("openLong: Could not buy (no money) has: \(hasMoney!.asString()), want: \(money.asString())")
            return
        }
        
        switch GlobalBotConfig.mode {
        case .Sandbox, .Emu:
            self.postOrders[figi]!.buyPrice(price: money)
        case .Tinkoff:
            self.postOrders[figi]!.buyMarketPrice()
        }
    }

    private func closeLong(figi: String) {
        // Проверяем, есть ли открытые позиции, которые следует закрыть.
        if openedPositions[figi] == nil || openedPositions[figi] == 0 {
            return
        }
        
        var instrument: Instrument? = nil
        for instr in GlobalBotConfig.figis {
            if instr.figi == figi {
                instrument = instr
                break
            }
        }
        
        assert(instrument != nil)
        
        let needClose = openedPositions[figi]!
        switch GlobalBotConfig.mode {
        case .Sandbox, .Emu:
            let candle = candles[figi]!.last!.value.close
            var money = MoneyValue()
            money.units = candle.units
            money.nano = candle.nano
            money.currency = instrument!.currency
            self.postOrders[figi]!.sellPrice(price: money, amount: needClose)
        case .Tinkoff:
            self.postOrders[figi]!.sellMarketPrice(amount: needClose)
        }
    }
    
    private func onBuySuccess(figi: String, amount: Int64, total: MoneyValue) {
        if openedPositions[figi] == nil {
            openedPositions[figi] = 0
        }
        
        self.portfolioLoader!.syncPortfolioWithTink()
        
        let stopLossMoneyValue = total.asDouble()
        stopLossPositions[figi] = stopLossMoneyValue * config!.stopLoss
        
        self.orderUpdateCallback(figi, OrderInfo(type: .Bought, count: amount, price: total))
        GlobalBotConfig.stat.onBuyOrderPosted(figi: figi, amount: amount)
        GlobalBotConfig.stat.onBuyOrderDone(figi: figi, amount: amount, price: total)
    }
    
    private func onSellSuccess(figi: String, amount: Int64, total: MoneyValue) {
        assert(openedPositions[figi] != nil)

        self.portfolioLoader!.syncPortfolioWithTink()
        self.orderUpdateCallback(figi, OrderInfo(type: .Sold, count: amount, price: total))
        GlobalBotConfig.stat.onSellOrderPosted(figi: figi, amount: amount)
        GlobalBotConfig.stat.onSellOrderDone(figi: figi, amount: amount, price: total)
    }

    private var config: RSIConfig? = nil
    
    private var portfolioLoader: PortfolioLoader? = nil
    
    private var postOrders: [String : PostOrder] = [:]
    private var candlesFetchers: [String : CandleFetcher] = [:]
    
    private var candles: [String : LinkedList<CandleData>] = [:]
    private var openedPositions: [String : Int64] = [:]
    private var stopLossPositions: [String : Double] = [:]
    
    private var portfolioData = PortfolioData()
    
    private var portfolioUpdateCallback: (PortfolioData) -> ()?
    private var candlesUpdateCallback: (String, LinkedList<CandleData>) -> ()
    private var orderRequestCallback: (String, OrderInfo) -> ()
    private var orderUpdateCallback: (String, OrderInfo) -> ()
    private var rsiUpdateCallback: (String, Float64) -> ()

}
