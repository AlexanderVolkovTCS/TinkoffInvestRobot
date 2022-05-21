//
//  Profile.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import Foundation
import TinkoffInvestSDK
import Combine

struct AccountList {
	/// List of accounts
	public var accounts: [Account] = []
}

class ProfileListLoader {
	init() {
	}

	init(callback: @escaping (AccountList) -> ()) {
		self.callback = callback
	}

	func onDataLoaded(profdata: AccountList) {
		if self.callback == nil {
			return
		}

		DispatchQueue.main.async {
			self.callback!(profdata)
		}
	}

	var callback: ((AccountList) -> ())? = nil
}


class EmuProfileListLoader: ProfileListLoader {
	override init(callback: @escaping (AccountList) -> ()) {
		super.init(callback: callback)
		var acc1 = Account()
		acc1.name = "Демо"
		acc1.id = "1"
		self.onDataLoaded(profdata: AccountList(accounts: [acc1]))
	}
}

class SandboxProfileListLoader: ProfileListLoader {
	var cancellables = Set<AnyCancellable>()

	// TODO: Call openAccount if no accunts available.
	override init(callback: @escaping (AccountList) -> ()) {
		super.init(callback: callback)
		GlobalBotConfig.sdk.sandboxService.getAccounts().sink { result in
			switch result {
			case .failure(let error):
				print(result)
				print(error.localizedDescription)
			case .finished:
				print(result)
			}
		} receiveValue: { portfolio in
			print(portfolio)
		}.store(in: &cancellables)
	}
}

class TinkoffProfileListLoader: ProfileListLoader {
	var cancellables = Set<AnyCancellable>()

	override init(callback: @escaping (AccountList) -> ()) {
		super.init(callback: callback)
		GlobalBotConfig.sdk.userService.getAccounts().sink { result in
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
			case .finished:
				print("loaded")
			}
		} receiveValue: { portfolio in
			self.onDataLoaded(profdata: AccountList(accounts: portfolio.accounts))
		}.store(in: &cancellables)
	}
}
