//
//  ExtMoney.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 24.05.2022.
//

import Foundation
import TinkoffInvestSDK

extension MoneyValue {
    func asDouble() -> Double {
        return Double(self.units) + (Double(self.nano) / 1e9)
    }
}

extension MoneyValue {
    func sign() -> String {
        switch currency.uppercased() {
        case "CHF":
            return "CHF"
        case "CNY":
            return "¥"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "HKD":
            return "HKD"
        case "JPY":
            return "¥"
        case "RUB":
            return "₽"
        case "USD":
            return "$"
        default:
            return "\(currency.uppercased())"
        }
    }
}

extension Instrument {
    init(share: Share) {
        self.init()
        name = share.name
        ticker = share.ticker
        isin = share.isin
        classCode = share.classCode
        figi = share.figi
        instrumentType = "share"
        apiTradeAvailableFlag = true
        buyAvailableFlag = share.buyAvailableFlag
        countryOfRisk = share.countryOfRisk
        countryOfRiskName = share.countryOfRiskName
        currency = share.currency
        dlong = share.dlong
        dlongMin = share.dlongMin
        dshort = share.dshort
        dshortMin = share.dshortMin
        exchange = share.exchange
        realExchange = share.realExchange
    }
    
    init(etf: Etf) {
        self.init()
        name = etf.name
        ticker = etf.ticker
        isin = etf.isin
        classCode = etf.classCode
        figi = etf.figi
        instrumentType = "etf"
        apiTradeAvailableFlag = true
        buyAvailableFlag = etf.buyAvailableFlag
        countryOfRisk = etf.countryOfRisk
        countryOfRiskName = etf.countryOfRiskName
        currency = etf.currency
        dlong = etf.dlong
        dlongMin = etf.dlongMin
        dshort = etf.dshort
        dshortMin = etf.dshortMin
        exchange = etf.exchange
        realExchange = etf.realExchange
    }
    
    init(currency: Currency) {
        self.init()
        name = currency.name
        isin = currency.isin
        ticker = currency.ticker
        classCode = currency.classCode
        isin = "noisin"
        figi = currency.figi
        instrumentType = "currency"
        apiTradeAvailableFlag = true
        buyAvailableFlag = currency.buyAvailableFlag
        countryOfRisk = currency.countryOfRisk
        countryOfRiskName = currency.countryOfRiskName
        self.currency = currency.currency
        dlong = currency.dlong
        dlongMin = currency.dlongMin
        dshort = currency.dshort
        dshortMin = currency.dshortMin
        exchange = currency.exchange
        realExchange = currency.realExchange
    }
    
    func sign() -> String {
        switch currency.uppercased() {
        case "CHF":
            return "CHF"
        case "CNY":
            return "¥"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "HKD":
            return "HKD"
        case "JPY":
            return "¥"
        case "RUB":
            return "₽"
        case "USD":
            return "$"
        default:
            return "\(currency.uppercased())"
        }
    }
}

extension MoneyValue {
    func asString() -> String {
        return "\(asDouble()) \(currency)"
    }
    
    mutating func minus(mv: MoneyValue) {
        assert(currency == mv.currency)
        
        if mv.nano > nano {
            nano += Int32(1e9)
            units -= 1
        }
        nano -= mv.nano
        units -= mv.units
    }
}

extension Quotation {
    func asDouble() -> Double {
        return Double(self.units) + (Double(self.nano) / 1e9)
    }
}
