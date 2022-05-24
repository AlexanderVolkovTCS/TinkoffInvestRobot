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
}

extension Quotation {
    func asDouble() -> Double {
        return Double(self.units) + (Double(self.nano) / 1e9)
    }
}
