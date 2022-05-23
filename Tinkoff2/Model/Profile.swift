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
		acc1.accessLevel = .accountAccessLevelFullAccess
		self.onDataLoaded(profdata: AccountList(accounts: [acc1]))
	}
}

class SandboxProfileListLoader: ProfileListLoader {
	var cancellables = Set<AnyCancellable>()

	override init(callback: @escaping (AccountList) -> ()) {
		super.init(callback: callback)
		loadAccs()
	}

	func creatAcc() {
		GlobalBotConfig.sdk.sandboxService.openAccount().sink { result in
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
			case .finished:
                break
			}
		} receiveValue: { acc in
			self.payIn(id: acc.accountID)
		}.store(in: &cancellables)
	}

	func payIn(id: String) {
		var mv = MoneyValue()
		mv.currency = "usd"
		mv.units = 1000
		mv.nano = 0
		GlobalBotConfig.sdk.sandboxService.payIn(accountID: id, amount: mv).sink { result in
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
			case .finished:
                break
			}
		} receiveValue: { portfolio in
			self.loadAccs()
		}.store(in: &cancellables)
	}

	func loadAccs() {
		GlobalBotConfig.sdk.sandboxService.getAccounts().sink { result in
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
            case .finished:
                break
			}
		} receiveValue: { accresp in
			if accresp.accounts.count == 0 {
				self.creatAcc()
			} else {
				var cpaccresp = accresp
				for i in 0..<cpaccresp.accounts.count {
					cpaccresp.accounts[i].name = "Sandbox\(i)"
				}
				self.onDataLoaded(profdata: AccountList(accounts: cpaccresp.accounts))
			}
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
		} receiveValue: { accresp in
			self.onDataLoaded(profdata: AccountList(accounts: accresp.accounts))
		}.store(in: &cancellables)
	}
}
