//
//  BotConfig.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import Foundation
import TinkoffInvestSDK

public enum BotMode {
	case Emu
	case Sandbox
	case Tinkoff

	static func fromIndex(_ id: Int) -> BotMode {
		switch id {
		case 0:
			return .Emu
		case 1:
			return .Sandbox
		case 2:
			return .Tinkoff
		default:
			return .Emu
		}
	}
}

struct BotConfig {
	public var account = Account()
	public var sdk = TinkoffInvestSDK(tokenProvider: DefaultTokenProvider(token: ""), sandbox: DefaultTokenProvider(token: ""))
	public var mode: BotMode = .Emu
	public var figis: [Instrument] = []

	public var algoConfig: AlgoConfig = AlgoConfig()
	public var logger: MacaLog = MacaLog()

	public var emuStartDate: Date = Date()

	public var tradingSchedule: [String: TradingSchedule] = [:]

	public var stat: MacaStat = MacaStat()

	init() { }
}

var GlobalBotConfig = BotConfig()
