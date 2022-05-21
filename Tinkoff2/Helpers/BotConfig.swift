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
	public var sdk = TinkoffInvestSDK(
		tokenProvider: DefaultTokenProvider(token: ""),
		sandbox: DefaultTokenProvider(token: "")
	)
	public var mode: BotMode = .Emu

	init() { }
}

var GlobalBotConfig = BotConfig()
