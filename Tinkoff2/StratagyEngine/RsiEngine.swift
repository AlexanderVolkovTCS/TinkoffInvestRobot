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

// RSIStrategyEngine является главным компонентом стратегии торгового бота.
// В конструкторе он принимает коллбэки на обновление состояния.
// В графическом режиме, коллбэки отвечают за перерисовку интерфейса-визуализации.
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
        
        // Создаем виртуальный загрузчик портфорлио в зависимости от выбраного режима: эмуляция/sandbox/tinkoff.
        switch GlobalBotConfig.mode {
        case .Emu:
            self.portfolioLoader = EmuPortfolioLoader(profile: GlobalBotConfig.account, callback: self.onPortfolio)
        case .Sandbox:
            self.portfolioLoader = SandboxPortfolioLoader(profile: GlobalBotConfig.account, callback: self.onPortfolio)
        case .Tinkoff:
            self.portfolioLoader = TinkoffPortfolioLoader(profile: GlobalBotConfig.account, callback: self.onPortfolio)
        }
        
        // Создаем по виртуальному воркеру для каждой торгуемой акции в зависимости от выбраного режима.
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
        
        // Запрашиваем информацию о исторических свечах для инициализации первичного значения RSI.
        collectHistoricalCandles()
    }
    
    deinit {
        stop()
    }
    
    // stop останавливает работу энжина.
    public func stop() {
        // Отписываемся от виртуальных воркеров. В зависимости от текущего режима, виртуальные воркеры могут
        // 1. Просто остановить работу
        // 2. Остановить работу, преед этим отписавшись от стриминга в Tinkoff API
        for candlesFetcher in self.candlesFetchers {
            candlesFetcher.value.cancel()
        }
    }

    // collectHistoricalCandles используется один раз на старте для инициализации алгоритма историческими свечами.
    private func collectHistoricalCandles() {
        for candlesFetcher in self.candlesFetchers {
            candlesFetcher.value.fetchHistoricalData(callback: onHistoricalCandles)
        }
    }

    // onHistoricalCandles используется один раз в качестве коллбэка при удачном сборе исторических свечей.
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

        // Информируем UI о получении свечей.
        self.candlesUpdateCallback(figi, self.candles[figi]!)
        
        // Информируем UI о первичном значении RSI.
        let rsi = calculateRSI(figi: figi)
        self.rsiUpdateCallback(figi, rsi)
        
        // Запускаем стриминг свечей.
        self.candlesFetchers[figi]!.run()
    }

    // onNewCandle вызывается при стриминге свечей.
    // Параметр candle может содержать:
    // 1. Текущую обновленную свечу
    // 2. Новую свечу
    private func onNewCandle(figi: String, candle: CandleData) {
        GlobalBotConfig.logger.debug("new candle! \(figi) \(candle.high.asDouble()) \(candle.time)")
        
        // Обновляем, если пришла текущая свеча
        var mergedWithLast = false
        let last = self.candles[figi]!.last
        if last != nil {
            if candle.time == last!.value.time {
                last!.value = candle
                mergedWithLast = true
            }
        }
        
        // Добавляем новую, если пришла новая свеча
        if !mergedWithLast {
            // Optimization: алгормтму RSI для расчета состояния требуется информация
            // только о последних свечах. Мы можем удалять предыдущие свечи, если
            // они больше не влияют на показатель RSI.
            //
            // Для быстрого удаления с начала и быстрого добавлвения в конец мы используем LinkedList
            if candles[figi]!.count == self.config!.rsiPeriod {
                candles[figi]!.remove(at: 0)
            }
            candles[figi]!.append(candle)
        }

        // Перерасчитываем новое состояние RSI.
        let rsi = calculateRSI(figi: figi)
        GlobalBotConfig.logger.debug("new rsi = \(rsi)")
        
        // Продаем, если RSI меньше нижней границы.
        if rsi < Float64(config!.lowerRsiThreshold) {
            closeLong(figi: figi)
        // Покупаем, если RSI больше верхней границы.
        } else if rsi > Float64(config!.upperRsiThreshold) {
            openLong(figi: figi)
        // Продаем, стоп-лосс.
        } else if stopLossPositions[figi] != nil && stopLossPositions[figi]! >= candle.close.asDouble() {
            GlobalBotConfig.logger.info("[\(figi)] Hit stop-loss")
            closeLong(figi: figi)
        }
        
        // Информируем UI о получении новой свечи.
        self.candlesUpdateCallback(figi, self.candles[figi]!)
        // Информируем UI о первичном значении RSI.
        self.rsiUpdateCallback(figi, rsi)
    }
    
    // onNewCandle вызывается при обновлении состояния портфолио.
    // Мы используем эту функцию для обновления информации о открытых позициях.
    private func onPortfolio(portfolioData: PortfolioData) {
        for position in openedPositions {
            openedPositions[position.key] = 0
        }
        
        for figi in self.config!.figis {
            if let position = portfolioData.positions[figi] {
                if openedPositions[figi] == nil {
                    openedPositions[figi] = 0
                }
                openedPositions[figi]! += position.quantity.units
            }
        }
        
        // Информируем UI о новом состоянии портфолио.
        self.portfolioUpdateCallback(portfolioData)
    }

    // calculateRSI используется для расчета состояния RSI.
    // Подробнее о алгоритме RSI - https://ru.wikipedia.org/wiki/Индекс_относительной_силы
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
                candleClosePrice = candle.close.asDouble()
                return
            }

            prevCandleClosePrice = candleClosePrice
            candleClosePrice = candle.close.asDouble()
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

    // openLong открывает позицию "figi" для торговли в long, если у пользователя достаточно денег для совершения сделки.
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
        
        // Optimization: используя функцию кэширования портфолио у воркера portfolioLoader, мы можем
        // быстро проверить наличия средств для совершения сделки.
        // Это позволяет избежать лишних запросов в Tinkoff API.
        let hasMoney = self.portfolioLoader?.getPortfolioCached().getMoneyValue(currency: instrument!.currency)
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

    // closeLong проверяет есть ли открытые позиции и закрывает их.
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
    
    // onBuySuccess используется в качетсве коллбэка при удачной продаже позиций.
    private func onBuySuccess(figi: String, amount: Int64, total: MoneyValue) {
        if openedPositions[figi] == nil {
            openedPositions[figi] = 0
        }
        
        // Синхронизируеся с портфолио только при успешной покупке/продаже.
        self.portfolioLoader!.syncPortfolioWithTink()
        
        let stopLossMoneyValue = total.asDouble()
        stopLossPositions[figi] = stopLossMoneyValue * config!.stopLoss
        
        self.orderUpdateCallback(figi, OrderInfo(type: .Bought, count: amount, price: total))
        GlobalBotConfig.stat.onBuyOrderPosted(figi: figi, amount: amount)
        GlobalBotConfig.stat.onBuyOrderDone(figi: figi, amount: amount, price: total)
    }
    
    private func onSellSuccess(figi: String, amount: Int64, total: MoneyValue) {
        assert(openedPositions[figi] != nil)
        
        // Синхронизируеся с портфолио только при успешной покупке/продаже.
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
        
    private var portfolioUpdateCallback: (PortfolioData) -> ()?
    private var candlesUpdateCallback: (String, LinkedList<CandleData>) -> ()
    private var orderRequestCallback: (String, OrderInfo) -> ()
    private var orderUpdateCallback: (String, OrderInfo) -> ()
    private var rsiUpdateCallback: (String, Float64) -> ()

}
