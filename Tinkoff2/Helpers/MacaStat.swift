//
//  MacaStat.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 23.05.2022.
//

import Foundation

class MacaStat {
    fileprivate var _soldStocks: Int64 = 0
    fileprivate var _soldETCs: Int64 = 0
    fileprivate var _soldCurrency: Int64 = 0
    
    var soldStocks: Int64 {
        get {
            return _soldStocks
        }
    }
    
    var soldETCs: Int64 {
        get {
            return _soldETCs
        }
    }
    
    var soldCurrency: Int64 {
        get {
            return _soldCurrency
        }
    }
    
    fileprivate var _boughtStocks: Int64 = 0
    fileprivate var _boughtETCs: Int64 = 0
    fileprivate var _boughtCurrency: Int64 = 0
    
    var boughtStocks: Int64 {
        get {
            return _boughtStocks
        }
    }
    
    var boughtETCs: Int64 {
        get {
            return _boughtETCs
        }
    }
    
    var boughtCurrency: Int64 {
        get {
            return _boughtCurrency
        }
    }
    
    init() { }

    func onBuyOrderPosted(figi: String, amount: Int64) {
        for i in GlobalBotConfig.figis {
            if i.figi == figi {
                switch i.instrumentType {
                case "share":
                    _boughtStocks += amount
                case "etf":
                    _boughtETCs += amount
                case "currency":
                    _boughtCurrency += amount
                default:
                    break
                }
            }
        }
    }
    
    func onSellOrderPosted(figi: String, amount: Int64) {
        for i in GlobalBotConfig.figis {
            if i.figi == figi {
                switch i.instrumentType {
                case "share":
                    _soldStocks += amount
                case "etf":
                    _soldETCs += amount
                case "currency":
                    _soldCurrency += amount
                default:
                    break
                }
            }
        }
    }
}
