//
//  BotConfig.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import Foundation
import TinkoffInvestSDK

struct BotConfig {
	public var account = Account()
	public var sdk = TinkoffInvestSDK(tokenProvider: DefaultTokenProvider(token: "t.JXmm55rH0MxmzpuuoGJrAvREeKzBy6Vf4vhkHDL1tbbhtHoI6yO83b2d70gHfzBuY1yLk2KNZzlT0B8vYsQIxg"), sandbox: DefaultTokenProvider(token: "t.JXmm55rH0MxmzpuuoGJrAvREeKzBy6Vf4vhkHDL1tbbhtHoI6yO83b2d70gHfzBuY1yLk2KNZzlT0B8vYsQIxg"))
	public var mode: BotMode = .Emu
	public var figis: [Instrument] = []

	public var algoConfig: AlgoConfig = AlgoConfig()

	init() { }
}

var GlobalBotConfig = BotConfig()
