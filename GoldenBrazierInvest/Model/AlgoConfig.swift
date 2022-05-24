//
//  AlgoConfig.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import Foundation

struct AlgoConfig {
	public var rsiPeriod: Int = 14
	public var upperRsiThreshold: Int = 70
	public var lowerRsiThreshold: Int = 30
	public var stopLoss: Double = 0.98

	init() { }
}
