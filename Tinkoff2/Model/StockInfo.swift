//
//  StockInfo.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import Foundation
import TinkoffInvestSDK

class StockInfo {
    public var instrument: Instrument? = nil
    public var candles: [CandleData] = []
    
    init () {}
    
    init (instrument: Instrument, candles: [CandleData])
    {
        self.instrument = instrument
        self.candles = candles
    }
}
