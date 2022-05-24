//
//  MacaStat.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 23.05.2022.
//

import Foundation
import TinkoffInvestSDK

class MacaStat {
    fileprivate var _soldStocks: Int64 = 0
    fileprivate var _soldEtfs: Int64 = 0
    fileprivate var _soldCurrency: Int64 = 0
    
    var soldStocks: Int64 { get { return _soldStocks } }
    var soldEtfs: Int64 { get { return _soldEtfs }}
    var soldCurrency: Int64 { get { return _soldCurrency } }
    
    fileprivate var _boughtStocks: Int64 = 0
    fileprivate var _boughtETCs: Int64 = 0
    fileprivate var _boughtCurrency: Int64 = 0

    var boughtStocks: Int64 { get { return _boughtStocks } }
    var boughtETCs: Int64 { get { return _boughtETCs } }
    var boughtCurrency: Int64 { get { return _boughtCurrency } }
    
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
                    _soldEtfs += amount
                case "currency":
                    _soldCurrency += amount
                default:
                    break
                }
            }
        }
    }
    
    fileprivate var _boughtProfitRub: Float64 = 0.0
    var boughtProfitRub: Float64 { get { return _boughtProfitRub } }
    
    fileprivate var _boughtProfitUSD: Float64 = 0.0
    var boughtProfitUSD: Float64 { get { return _boughtProfitUSD } }
    
    fileprivate var _boughtProfitEUR: Float64 = 0.0
    var boughtProfitEUR: Float64 { get { return _boughtProfitEUR } }
    
    func onBuyOrderDone(figi: String, amount: Int64, price: MoneyValue) {
        for i in GlobalBotConfig.figis {
            if i.figi == figi {
                switch i.currency.uppercased() {
                case "RUB":
                    _boughtProfitRub += price.asDouble()
                case "USD":
                    _boughtProfitUSD += price.asDouble()
                case "EUR":
                    _boughtProfitEUR += price.asDouble()
                default:
                    break
                }
            }
        }
    }
    
    fileprivate var _soldProfitRub: Float64 = 0.0
    var soldProfitRub: Float64 { get { return _soldProfitRub } }
    
    fileprivate var _soldProfitUSD: Float64 = 0.0
    var soldProfitUSD: Float64 { get { return _soldProfitUSD } }
    
    fileprivate var _soldProfitEUR: Float64 = 0.0
    var soldProfitEUR: Float64 { get { return _soldProfitEUR } }
    
    func onSellOrderDone(figi: String, amount: Int64, price: MoneyValue) {
        for i in GlobalBotConfig.figis {
            if i.figi == figi {
                switch i.currency.uppercased() {
                case "RUB":
                    _soldProfitRub += price.asDouble()
                case "USD":
                    _soldProfitUSD += price.asDouble()
                case "EUR":
                    _soldProfitEUR += price.asDouble()
                default:
                    break
                }
            }
        }
    }
}
