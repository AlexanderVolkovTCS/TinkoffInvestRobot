//
//  StockInfo.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import Foundation
import TinkoffInvestSDK

enum OperationType {
    case SoldRequest
    case BoughtRequest
    case Sold
    case Bought
}

class OrderInfo {
    public var type: OperationType = .Sold
    public var count: Int64 = 0
    public var timeStr: String = ""
    
    init() {}
    
    init(type: OperationType, count: Int64) {
        self.type = type
        self.count = count
    }
}

class StockInfo {
	public var instrument: Instrument = Instrument()
    public var hasUpdates: Bool = false
    public var candles: [CandleData] = []
    public var rsi: [Float64] = []
    public var operations: [OrderInfo] = []

	init () { }

	init (instrument: Instrument, candles: [CandleData])
	{
		self.instrument = instrument
		self.candles = candles
	}
}
